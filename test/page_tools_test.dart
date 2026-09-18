import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/score_dao.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/importer/data/score_importer.dart';
import 'package:his_score/features/library/data/cover_generator.dart';
import 'package:his_score/features/viewer/data/page_tools_dao.dart';
import 'package:his_score/features/viewer/data/score_session.dart';
import 'package:pdfrx/pdfrx.dart';

/// 페이지 순서 편집, 크롭, 북마크, 점프 버튼.
void main() {
  late Directory root;
  late AppDatabase db;
  late ScoreDao scores;
  late PageToolsDao tools;
  late AppPaths paths;
  late String scoreId;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Pdfrx.cacheDirectoryPath ??= Directory.systemTemp.path;
    await pdfrxFlutterInitialize();
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hiscore_tools');
    paths = AppPaths(root);
    await paths.ensureCreated();
    db = AppDatabase(NativeDatabase.memory());
    scores = ScoreDao(db);
    tools = PageToolsDao(db);
    final importer = ScoreImporter(scores, paths, CoverGenerator(paths));
    scoreId = (await importer.importFile(File('test/fixtures/score.pdf')))!;
  });

  tearDown(() async {
    await db.close();
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // pdfium 이 핸들을 늦게 놓는다.
    }
  });

  Future<ScoreSession> open() async => ScoreSession.openScore(
        score: (await scores.findById(scoreId))!,
        scorePages: await scores.visiblePages(scoreId),
        paths: paths,
      );

  test('순서를 뒤집고 하나를 숨기면 세션이 그대로 따른다', () async {
    final rows = await scores.allPages(scoreId);
    final reversed = rows.reversed.toList();
    await scores.replacePages(scoreId, [
      for (var i = 0; i < reversed.length; i++)
        ScorePagesCompanion.insert(
          id: reversed[i].id,
          scoreId: scoreId,
          sourceIndex: reversed[i].sourceIndex,
          displayOrder: i,
          hidden: Value(i == 0),
        ),
    ]);

    final session = await open();
    addTearDown(session.dispose);
    expect(session.pageCount, 7);
    // 8쪽이 숨겨졌으니 첫 장은 원본 7쪽이다.
    expect(session.pages.first.sourcePageNumber, 7);
    expect(session.pages.last.sourcePageNumber, 1);
    expect((await scores.findById(scoreId))!.pageCount, 7);
  });

  test('빈 페이지와 복제 페이지를 끼워 넣는다', () async {
    final rows = await scores.allPages(scoreId);
    await scores.replacePages(scoreId, [
      ScorePagesCompanion.insert(
        id: rows[0].id, scoreId: scoreId, sourceIndex: 0, displayOrder: 0,
      ),
      ScorePagesCompanion.insert(
        id: 'blank', scoreId: scoreId, sourceIndex: -1, displayOrder: 1,
      ),
      ScorePagesCompanion.insert(
        id: 'dup', scoreId: scoreId, sourceIndex: 0, displayOrder: 2,
      ),
    ]);

    final session = await open();
    addTearDown(session.dispose);
    expect(session.pageCount, 3);
    expect(session.pages[1].isBlank, isTrue);
    expect(session.pages[1].sourcePageNumber, 0);
    expect(session.pages[2].sourcePageNumber, 1);
    // 빈 페이지도 A4 비율을 따른다.
    expect(session.pages[1].aspectRatio, closeTo(595 / 842, 0.01));
  });

  test('곡 전체 크롭과 페이지 단독 크롭이 겹치면 페이지가 이긴다', () async {
    await scores.updateScore(
      scoreId,
      const ScoresCompanion(cropLeft: Value(0.1), cropRight: Value(0.1)),
    );
    final rows = await scores.visiblePages(scoreId);
    await scores.updatePage(
      rows[2].id,
      const ScorePagesCompanion(
        cropLeft: Value(0.3), cropTop: Value(0), cropRight: Value(0), cropBottom: Value(0),
        rotation: Value(2.5),
      ),
    );

    final session = await open();
    addTearDown(session.dispose);
    expect(session.pages[0].crop.left, closeTo(0.1, 1e-9));
    expect(session.pages[0].crop.right, closeTo(0.9, 1e-9));
    expect(session.pages[2].crop.left, closeTo(0.3, 1e-9));
    expect(session.pages[2].crop.right, closeTo(1.0, 1e-9));
    expect(session.pages[2].rotation, 2.5);
    // 잘라낸 만큼 비율이 좁아진다.
    expect(session.pages[0].aspectRatio, lessThan(session.pages[1].aspectRatio + 1e-9));
  });

  test('크롭 값이 터무니없어도 페이지가 사라지지 않는다', () {
    final r = ScoreSession.cropRect(left: 0.9, top: 0.9, right: 0.9, bottom: 0.9);
    expect(r.width, greaterThan(0));
    expect(r.height, greaterThan(0));
  });

  test('북마크를 추가하고 이름을 바꾸고 지운다', () async {
    await tools.addBookmark(scoreId, 3, '2악장');
    await tools.addBookmark(scoreId, 6, '카덴차');
    var list = await tools.bookmarksOf(scoreId);
    expect(list.map((b) => b.label), ['2악장', '카덴차']);

    await tools.renameBookmark(list.first.id, '2악장 Andante');
    await tools.deleteBookmark(list.last.id);
    list = await tools.bookmarksOf(scoreId);
    expect(list.single.label, '2악장 Andante');
    expect(list.single.page, 3);
  });

  test('목차가 없는 PDF 는 0을 돌려준다', () async {
    final session = await open();
    addTearDown(session.dispose);
    final n = await tools.importOutline(scoreId, session.documents.single);
    expect(n, 0);
  });

  test('점프 버튼을 놓고 옮기고 지운다', () async {
    await tools.addJump(scoreId: scoreId, fromPage: 4, x: 0.8, y: 0.9, toPage: 2);
    var jumps = await tools.watchJumps(scoreId).first;
    expect(jumps.single.toPage, 2);

    await tools.moveJump(jumps.single.id, 0.5, 0.5);
    jumps = await tools.watchJumps(scoreId).first;
    expect(jumps.single.x, 0.5);

    await tools.deleteJump(jumps.single.id);
    expect(await tools.watchJumps(scoreId).first, isEmpty);
  });

  test('점프 목적지가 숨긴 페이지면 세션에서 찾을 수 없다', () async {
    final rows = await scores.allPages(scoreId);
    await scores.updatePage(rows[1].id, const ScorePagesCompanion(hidden: Value(true)));
    final session = await open();
    addTearDown(session.dispose);
    expect(session.pageIndexOf(scoreId, 2), -1);
    expect(session.pageIndexOf(scoreId, 3), 1);
  });

  test('곡을 지우면 북마크와 점프도 사라진다', () async {
    await tools.addBookmark(scoreId, 1, 'a');
    await tools.addJump(scoreId: scoreId, fromPage: 1, x: 0, y: 0, toPage: 2);
    await scores.deleteScores([scoreId]);
    expect(await tools.bookmarksOf(scoreId), isEmpty);
    expect(await tools.watchJumps(scoreId).first, isEmpty);
  });
}
