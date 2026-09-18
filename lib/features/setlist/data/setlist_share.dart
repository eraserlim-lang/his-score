import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/score_dao.dart';
import '../../../core/db/setlist_dao.dart';
import '../../../core/storage/app_paths.dart';
import '../../importer/data/score_importer.dart';

/// 세트리스트 공유 형식.
enum SetlistShareKind {
  /// 곡 제목 목록. 메신저에 붙여 넣는 용도.
  text,

  /// 순서와 구간만. 받는 쪽에 같은 곡이 있어야 한다.
  setlistOnly,

  /// PDF 까지 묶은 zip. 필기와 태그는 들어가지 않는다.
  withScores,
}

/// 세트리스트 파일(.hisetlist / .zip) 의 안쪽 JSON.
///
/// 곡은 id 와 제목을 둘 다 적는다. 받는 쪽은 id 로 먼저 찾고, 없으면
/// 제목으로 찾고, 그래도 없으면 zip 에 든 PDF 를 들여온다.
class SetlistShare {
  SetlistShare(this._setlists, this._scores, this._paths, this._importer);

  final SetlistDao _setlists;
  final ScoreDao _scores;
  final AppPaths _paths;
  final Future<ScoreImporter> Function() _importer;

  static const extension = 'hisetlist';

  Future<String> asText(String setlistId) async {
    final setlist = await _setlists.findById(setlistId);
    final entries = await _setlists.entries(setlistId);
    final b = StringBuffer(setlist?.name ?? '세트리스트')..writeln();
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      b.write('${i + 1}. ${e.score.title}');
      if (e.score.artist != null) b.write(' - ${e.score.artist}');
      if (e.item.startPage != null || e.item.endPage != null) {
        b.write(' (${(e.item.startPage ?? 0) + 1}~${(e.item.endPage ?? e.score.pageCount - 1) + 1}쪽)');
      }
      b.writeln();
    }
    return b.toString();
  }

  Future<Map<String, dynamic>> asJson(String setlistId) async {
    final setlist = await _setlists.findById(setlistId);
    if (setlist == null) throw StateError('세트리스트가 없습니다');
    final entries = await _setlists.entries(setlistId);
    return {
      'format': 'hiscore-setlist',
      'version': 1,
      'name': setlist.name,
      'note': setlist.note,
      'items': [
        for (final e in entries)
          {
            'scoreId': e.score.id,
            'title': e.score.title,
            'artist': e.score.artist,
            'composer': e.score.composer,
            'startPage': e.item.startPage,
            'endPage': e.item.endPage,
            'file': 'scores/${e.score.id}.pdf',
          },
      ],
    };
  }

  /// 순서만 담은 파일.
  Future<Uint8List> asSetlistFile(String setlistId) async =>
      Uint8List.fromList(utf8.encode(jsonEncode(await asJson(setlistId))));

  /// PDF 까지 담은 zip.
  Future<Uint8List> asZip(String setlistId) async {
    final json = await asJson(setlistId);
    final archive = Archive();
    archive.addFile(ArchiveFile.bytes('setlist.json', utf8.encode(jsonEncode(json))));
    final seen = <String>{};
    for (final item in json['items'] as List) {
      final id = (item as Map<String, dynamic>)['scoreId'] as String;
      if (!seen.add(id)) continue;
      final score = await _scores.findById(id);
      if (score == null) continue;
      final file = _paths.resolve(score.filePath);
      if (!await file.exists()) continue;
      archive.addFile(ArchiveFile.bytes('scores/$id.pdf', await file.readAsBytes()));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  /// .hisetlist 나 .zip 을 들여온다. 만든 세트리스트 id 를 준다.
  Future<String> import(File file) async {
    final bytes = await file.readAsBytes();
    Map<String, dynamic> json;
    Archive? archive;
    if (p.extension(file.path).toLowerCase() == '.zip' || _looksLikeZip(bytes)) {
      archive = ZipDecoder().decodeBytes(bytes);
      final entry = archive.findFile('setlist.json');
      if (entry == null) throw const FormatException('setlist.json 이 없는 zip 입니다');
      json = jsonDecode(utf8.decode(entry.readBytes()!)) as Map<String, dynamic>;
    } else {
      json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    }
    if (json['format'] != 'hiscore-setlist') throw const FormatException('HIScore 세트리스트 파일이 아닙니다');
    return importJson(json, archive: archive);
  }

  Future<String> importJson(Map<String, dynamic> json, {Archive? archive}) async {
    final scoreIds = <String>[];
    final ranges = <(int?, int?)>[];
    final missing = <String>[];

    for (final raw in json['items'] as List) {
      final item = raw as Map<String, dynamic>;
      final wantedId = item['scoreId'] as String;
      final title = item['title'] as String? ?? '';

      String? resolved;
      if (await _scores.findById(wantedId) != null) {
        resolved = wantedId;
      } else {
        final byTitle = await _scores.watchScores(ScoreQuery(text: title)).first;
        final exact = byTitle.where((s) => s.title == title).firstOrNull;
        if (exact != null) resolved = exact.id;
      }

      if (resolved == null && archive != null) {
        final entry = archive.findFile(item['file'] as String? ?? 'scores/$wantedId.pdf');
        if (entry != null) {
          final tmp = File(p.join(Directory.systemTemp.path, 'setlist-$wantedId.pdf'));
          await tmp.writeAsBytes(entry.readBytes()!, flush: true);
          final imp = await _importer();
          resolved = await imp.importFile(
            tmp,
            id: wantedId,
            title: title.isEmpty ? null : title,
            artist: item['artist'] as String?,
            composer: item['composer'] as String?,
            deleteSource: true,
          );
        }
      }

      if (resolved == null) {
        missing.add(title.isEmpty ? wantedId : title);
        continue;
      }
      scoreIds.add(resolved);
      ranges.add((item['startPage'] as int?, item['endPage'] as int?));
    }

    final name = (json['name'] as String?)?.trim();
    final id = await _setlists.create(name == null || name.isEmpty ? '받은 세트리스트' : name, scoreIds);
    final note = json['note'] as String?;
    final missingNote = missing.isEmpty ? null : '못 찾은 곡: ${missing.join(', ')}';
    final combined = [if (note != null && note.isNotEmpty) note, ?missingNote].join('\n');
    if (combined.isNotEmpty) await _setlists.rename(id, name ?? '받은 세트리스트', note: combined);

    final entries = await _setlists.entries(id);
    for (var i = 0; i < entries.length && i < ranges.length; i++) {
      final (s, e) = ranges[i];
      if (s != null || e != null) await _setlists.setPageRange(entries[i].item.id, s, e);
    }
    return id;
  }

  static bool _looksLikeZip(Uint8List b) => b.length > 4 && b[0] == 0x50 && b[1] == 0x4B;
}

final setlistShareProvider = FutureProvider<SetlistShare>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return SetlistShare(
    ref.watch(setlistDaoProvider),
    ref.watch(scoreDaoProvider),
    paths,
    () => ref.read(scoreImporterProvider.future),
  );
});
