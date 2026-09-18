import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/database.dart';
import '../../../core/db/score_dao.dart';
import '../../../core/storage/app_paths.dart';
import '../../library/data/cover_generator.dart';

/// 암호가 걸린 PDF 를 만났을 때 사용자에게 물어보는 콜백.
typedef PasswordPrompt = Future<String?> Function(String fileName);

class ImportResult {
  const ImportResult({required this.imported, required this.failures});

  final List<String> imported;

  /// 파일 이름과 실패 사유.
  final Map<String, String> failures;

  bool get hasFailures => failures.isNotEmpty;
}

/// 파일을 앱 폴더로 들여오고 DB 에 등록한다.
///
/// 원본은 건드리지 않고 복사한다. 외부 폴더의 파일을 그대로 참조하면
/// iOS 샌드박스와 안드로이드 SAF 에서 다음 실행 때 접근 권한이 사라진다.
class ScoreImporter {
  ScoreImporter(this._dao, this._paths, this._covers);

  final ScoreDao _dao;
  final AppPaths _paths;
  final CoverGenerator _covers;
  static const _uuid = Uuid();

  /// 파일 선택 창을 띄워 PDF 여러 개를 가져온다.
  /// 사용자가 취소하면 null 을 준다.
  Future<ImportResult?> pickAndImport({PasswordPrompt? onPasswordNeeded}) async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: '가져올 PDF 악보 선택',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (picked.isEmpty) return null;

    final files = picked
        .map((f) => f.path)
        .whereType<String>()
        .map(File.new)
        .toList();
    if (files.isEmpty) return null;

    return importFiles(files, onPasswordNeeded: onPasswordNeeded);
  }

  Future<ImportResult> importFiles(
    List<File> files, {
    PasswordPrompt? onPasswordNeeded,
    String? titleOverride,
  }) async {
    final imported = <String>[];
    final failures = <String, String>{};

    for (final file in files) {
      final name = p.basename(file.path);
      try {
        final id = await importFile(
          file,
          onPasswordNeeded: onPasswordNeeded,
          title: titleOverride,
        );
        if (id == null) {
          failures[name] = '암호를 입력하지 않아 건너뛰었습니다';
        } else {
          imported.add(id);
        }
      } on Object catch (e) {
        failures[name] = _describe(e);
      }
    }

    return ImportResult(imported: imported, failures: failures);
  }

  /// PDF 한 개를 들여온다. 암호가 필요한데 받지 못하면 null 을 준다.
  ///
  /// [deleteSource] 가 참이면 복사 후 원본을 지운다. 앱이 직접 만든
  /// 임시 PDF(카메라 촬영, 다운로드)를 넘길 때 쓴다.
  Future<String?> importFile(
    File source, {
    PasswordPrompt? onPasswordNeeded,
    String? title,
    String? artist,
    String? composer,
    bool deleteSource = false,
  }) async {
    final id = _uuid.v4();
    final fileName = p.basename(source.path);
    final target = File(p.join(_paths.scoresDir.path, '$id.pdf'));

    await source.copy(target.path);

    // 암호를 물어본 경우 DB 에 보관해 다음에 열 때 다시 묻지 않는다.
    String? password;
    PdfDocument doc;
    try {
      doc = await PdfDocument.openFile(
        target.path,
        passwordProvider: () async {
          if (onPasswordNeeded == null) return null;
          password = await onPasswordNeeded(fileName);
          return password;
        },
      );
    } on Object {
      await target.delete();
      if (password == null && onPasswordNeeded != null) return null;
      rethrow;
    }

    try {
      final pageCount = doc.pages.length;
      if (pageCount == 0) {
        await target.delete();
        throw const FormatException('페이지가 없는 PDF 입니다');
      }

      // 표지는 실패해도 가져오기를 막지 않는다.
      String? cover;
      try {
        cover = await _covers.fromPage(id, doc, 1);
      } on Object catch (e) {
        debugPrint('표지 생성 실패 $fileName: $e');
      }

      await _dao.insertScore(
        ScoresCompanion.insert(
          id: id,
          title: title ?? p.basenameWithoutExtension(fileName),
          artist: Value(artist),
          composer: Value(composer),
          filePath: _paths.relativeOf(target),
          fileSize: Value(await target.length()),
          pageCount: Value(pageCount),
          pdfPassword: Value(password),
          coverPath: Value(cover),
        ),
        [
          for (var i = 0; i < pageCount; i++)
            ScorePagesCompanion.insert(
              id: _uuid.v4(),
              scoreId: id,
              sourceIndex: i,
              displayOrder: i,
            ),
        ],
      );

      if (deleteSource && await source.exists()) await source.delete();
      return id;
    } finally {
      doc.dispose();
    }
  }

  /// 곡을 지울 때 파일도 함께 지운다.
  Future<void> deleteScores(List<Score> scores) async {
    await _dao.deleteScores(scores.map((s) => s.id).toList());
    for (final score in scores) {
      final file = _paths.resolve(score.filePath);
      if (await file.exists()) await file.delete();
      await _covers.deleteCover(score.coverPath);
    }
  }

  String _describe(Object e) => switch (e) {
        FormatException(:final message) => message,
        PathAccessException() => '파일을 읽을 권한이 없습니다',
        FileSystemException(:final message) => message,
        _ => '$e',
      };
}

final coverGeneratorProvider = FutureProvider<CoverGenerator>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return CoverGenerator(paths);
});

final scoreImporterProvider = FutureProvider<ScoreImporter>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return ScoreImporter(
    ref.watch(scoreDaoProvider),
    paths,
    CoverGenerator(paths),
  );
});
