import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/score_dao.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/importer/data/score_importer.dart';
import 'package:his_score/features/viewer/data/score_session.dart';
import 'package:pdfrx/pdfrx.dart';

/// PDF 를 들여오는 것부터 뷰어 세션을 여는 데까지의 한 바퀴.
void main() {
  late Directory root;
  late AppDatabase db;
  late ScoreDao dao;
  late AppPaths paths;
  late ScoreImporter importer;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Pdfrx.cacheDirectoryPath ??= Directory.systemTemp.path;
    await pdfrxFlutterInitialize();
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hiscore_import');
    paths = AppPaths(root);
    await paths.ensureCreated();
    db = AppDatabase(NativeDatabase.memory());
    dao = ScoreDao(db);
    importer = ScoreImporter(dao, paths);
  });

  tearDown(() async {
    await db.close();
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // 윈도우에서 pdfium 이 핸들을 늦게 놓는 경우가 있다.
    }
  });

  test('PDF 를 들여오면 곡과 페이지가 함께 등록된다', () async {
    final id = await importer.importFile(File('test/fixtures/score.pdf'));
    expect(id, isNotNull);

    final score = await dao.findById(id!);
    expect(score, isNotNull);
    expect(score!.title, 'score');
    expect(score.pageCount, 8);

    final pages = await dao.visiblePages(id);
    expect(pages, hasLength(8));
    expect(pages.map((p) => p.sourceIndex), List.generate(8, (i) => i));
    expect(pages.map((p) => p.displayOrder), List.generate(8, (i) => i));
  });

  test('원본이 아니라 앱 폴더의 사본을 가리킨다', () async {
    final id = await importer.importFile(File('test/fixtures/score.pdf'));
    final score = await dao.findById(id!);

    // 경로는 항상 문서 폴더 기준 상대 경로여야 한다.
    expect(score!.filePath, isNot(contains(':')));
    expect(score.filePath, startsWith('scores'));
    expect(paths.resolve(score.filePath).existsSync(), isTrue);
  });

  test('들여온 악보로 뷰어 세션을 연다', () async {
    final id = await importer.importFile(File('test/fixtures/score.pdf'));
    final score = await dao.findById(id!);
    final pages = await dao.visiblePages(id);

    final session = await ScoreSession.open(
      score: score!,
      scorePages: pages,
      paths: paths,
    );
    addTearDown(session.dispose);

    expect(session.pageCount, 8);
    expect(session.document.pages.length, 8);
  });

  test('여러 개를 한 번에 들여오고 실패한 것만 따로 알린다', () async {
    final result = await importer.importFiles([
      File('test/fixtures/score.pdf'),
      File('test/fixtures/없는파일.pdf'),
    ]);

    expect(result.imported, hasLength(1));
    expect(result.hasFailures, isTrue);
    expect(result.failures.keys.single, '없는파일.pdf');
  });

  test('마지막으로 본 페이지가 남는다', () async {
    final id = await importer.importFile(File('test/fixtures/score.pdf'));
    await dao.markOpened(id!, 5);

    final score = await dao.findById(id);
    expect(score!.lastPage, 5);
    expect(score.lastOpenedAt, isNotNull);
  });

  test('곡을 지우면 페이지도 함께 지워진다', () async {
    final id = await importer.importFile(File('test/fixtures/score.pdf'));
    await dao.deleteScores([id!]);

    expect(await dao.findById(id), isNull);
    expect(await dao.visiblePages(id), isEmpty);
  });
}
