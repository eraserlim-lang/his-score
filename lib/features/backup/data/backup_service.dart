import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/database.dart';
import '../../../core/storage/app_paths.dart';
import '../../../core/i18n/tr.dart';

/// 전체 백업과 복원.
///
/// DB 의 모든 표를 JSON 으로 적고 파일(악보, 표지, 녹음, 음원)을 함께 zip 에 넣는다.
/// 복원은 모든 표를 비우고 그대로 다시 넣는다. 필기가 사라지지 않게 하는 것이
/// 이 기능의 존재 이유다.
class BackupService {
  BackupService(this._db, this._paths);

  final AppDatabase _db;
  final AppPaths _paths;

  static const formatVersion = 1;

  /// 파일 순서가 중요하다. 참조되는 표가 먼저 와야 외래키가 만족된다.
  List<TableInfo> get _tables => [
        _db.scores,
        _db.scorePages,
        _db.bookmarks,
        _db.jumpButtons,
        _db.tags,
        _db.scoreTags,
        _db.setlists,
        _db.setlistItems,
        _db.inkStrokes,
        _db.annotations,
        _db.recordings,
        _db.appSettings,
      ];

  Future<Uint8List> createBackup({void Function(String stage)? onStage}) async {
    onStage?.call(tr('데이터를 모으는 중'));
    final data = <String, dynamic>{
      'format': 'hiscore-backup',
      'version': formatVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{},
    };
    for (final table in _tables) {
      final rows = await _db.select(table).get();
      (data['tables'] as Map<String, dynamic>)[table.actualTableName] = [
        for (final r in rows) (r as DataClass).toJson(),
      ];
    }

    final archive = Archive();
    archive.addFile(ArchiveFile.bytes('data.json', utf8.encode(jsonEncode(data))));

    onStage?.call(tr('파일을 담는 중'));
    for (final dir in [_paths.scoresDir, _paths.coversDir, _paths.recordingsDir, Directory(p.join(_paths.docsRoot.path, 'audio'))]) {
      if (!dir.existsSync()) continue;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final rel = _paths.relativeOf(entity).replaceAll('\\', '/');
        archive.addFile(ArchiveFile.bytes('files/$rel', await entity.readAsBytes()));
      }
    }

    onStage?.call(tr('압축하는 중'));
    return ZipEncoder().encodeBytes(archive, level: DeflateLevel.bestSpeed);
  }

  /// 백업 내용 미리보기. 복원 전에 무엇이 들었는지 보여준다.
  Future<BackupSummary> inspect(Uint8List zip) async {
    final archive = ZipDecoder().decodeBytes(zip);
    final entry = archive.findFile('data.json');
    if (entry == null) throw FormatException(tr('data.json 이 없습니다'));
    final data = jsonDecode(utf8.decode(entry.readBytes()!)) as Map<String, dynamic>;
    if (data['format'] != 'hiscore-backup') throw FormatException(tr('HIScore 백업 파일이 아닙니다'));
    final tables = data['tables'] as Map<String, dynamic>;
    return BackupSummary(
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
      scores: (tables['scores'] as List?)?.length ?? 0,
      setlists: (tables['setlists'] as List?)?.length ?? 0,
      strokes: (tables['ink_strokes'] as List?)?.length ?? 0,
      files: archive.files.where((f) => f.name.startsWith('files/')).length,
    );
  }

  /// 전부 지우고 백업으로 되돌린다.
  Future<void> restore(Uint8List zip, {void Function(String stage)? onStage}) async {
    final archive = ZipDecoder().decodeBytes(zip);
    final entry = archive.findFile('data.json');
    if (entry == null) throw FormatException(tr('data.json 이 없습니다'));
    final data = jsonDecode(utf8.decode(entry.readBytes()!)) as Map<String, dynamic>;
    if (data['format'] != 'hiscore-backup') throw FormatException(tr('HIScore 백업 파일이 아닙니다'));
    final tables = data['tables'] as Map<String, dynamic>;

    onStage?.call(tr('파일을 푸는 중'));
    await _paths.ensureCreated();
    final kept = <String>{};
    for (final f in archive.files) {
      if (!f.isFile || !f.name.startsWith('files/')) continue;
      final rel = f.name.substring('files/'.length);
      final target = _paths.resolve(rel);
      await target.parent.create(recursive: true);
      await target.writeAsBytes(f.readBytes()!, flush: true);
      kept.add(p.normalize(target.path));
    }
    // 백업에 없는 파일은 지운다. 열려 있는 파일은 지우지 못할 수 있는데,
    // 그 파일은 DB 에서 참조가 사라지므로 남아 있어도 해가 없다.
    for (final dir in [_paths.scoresDir, _paths.coversDir, _paths.recordingsDir]) {
      if (!dir.existsSync()) continue;
      await for (final entity in dir.list()) {
        if (entity is! File || kept.contains(p.normalize(entity.path))) continue;
        try {
          await entity.delete();
        } on FileSystemException {
          // 사용 중인 파일
        }
      }
    }

    onStage?.call(tr('데이터를 넣는 중'));
    await _db.transaction(() async {
      await _db.customStatement('PRAGMA foreign_keys = OFF');
      for (final table in _tables.reversed) {
        await _db.delete(table).go();
      }
      for (final table in _tables) {
        final rows = tables[table.actualTableName] as List? ?? const [];
        for (final raw in rows) {
          final row = _decode(table.actualTableName, raw as Map<String, dynamic>);
          if (row == null) continue;
          await _db.into(table).insert(row, mode: InsertMode.insertOrReplace);
        }
      }
      await _db.customStatement('PRAGMA foreign_keys = ON');
    });
  }

  /// 표 이름으로 데이터 클래스를 되살린다. drift 가 만든 fromJson 을 그대로 쓴다.
  Insertable<dynamic>? _decode(String table, Map<String, dynamic> json) => switch (table) {
        'scores' => Score.fromJson(json),
        'score_pages' => ScorePage.fromJson(json),
        'bookmarks' => Bookmark.fromJson(json),
        'jump_buttons' => JumpButton.fromJson(json),
        'tags' => Tag.fromJson(json),
        'score_tags' => ScoreTag.fromJson(json),
        'setlists' => Setlist.fromJson(json),
        'setlist_items' => SetlistItem.fromJson(json),
        'ink_strokes' => InkStroke.fromJson(json),
        'annotations' => Annotation.fromJson(json),
        'recordings' => Recording.fromJson(json),
        'app_settings' => AppSetting.fromJson(json),
        _ => null,
      };
}

class BackupSummary {
  const BackupSummary({
    required this.createdAt,
    required this.scores,
    required this.setlists,
    required this.strokes,
    required this.files,
  });

  final DateTime? createdAt;
  final int scores;
  final int setlists;
  final int strokes;
  final int files;
}

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return BackupService(ref.watch(appDatabaseProvider), paths);
});
