import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/score_dao.dart';
import 'package:his_score/core/db/setlist_dao.dart';
import 'package:his_score/core/db/tag_dao.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/importer/data/score_importer.dart';
import 'package:his_score/features/library/data/cover_generator.dart';
import 'package:his_score/features/viewer/data/score_session.dart';
import 'package:pdfrx/pdfrx.dart';

/// 태그, 세트리스트, 세트리스트 연속 보기.
void main() {
  late Directory root;
  late AppDatabase db;
  late ScoreDao scores;
  late TagDao tags;
  late SetlistDao setlists;
  late AppPaths paths;
  late ScoreImporter importer;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Pdfrx.cacheDirectoryPath ??= Directory.systemTemp.path;
    await pdfrxFlutterInitialize();
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hiscore_lib');
    paths = AppPaths(root);
    await paths.ensureCreated();
    db = AppDatabase(NativeDatabase.memory());
    scores = ScoreDao(db);
    tags = TagDao(db);
    setlists = SetlistDao(db);
    importer = ScoreImporter(scores, paths, CoverGenerator(paths));
  });

  tearDown(() async {
    await db.close();
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // 윈도우에서 pdfium 이 핸들을 늦게 놓는 경우가 있다.
    }
  });

  Future<String> import(String title) async {
    final id = await importer.importFile(
      File('test/fixtures/score.pdf'),
      title: title,
    );
    return id!;
  }

  group('태그', () {
    test('같은 이름은 한 번만 만든다', () async {
      final a = await tags.findOrCreate('연습');
      final b = await tags.findOrCreate(' 연습 ');
      expect(a.id, b.id);
      expect((await tags.all()).length, 1);
    });

    test('여러 태그를 고르면 전부 붙은 곡만 남는다', () async {
      final s1 = await import('A');
      final s2 = await import('B');
      final s3 = await import('C');
      final t1 = await tags.findOrCreate('재즈');
      final t2 = await tags.findOrCreate('발표회');

      await tags.attachMany([s1, s2], t1.id);
      await tags.attachMany([s2, s3], t2.id);

      final both = await scores
          .watchScores(ScoreQuery(tagIds: {t1.id, t2.id}))
          .first;
      expect(both.map((s) => s.id), [s2]);

      final onlyJazz =
          await scores.watchScores(ScoreQuery(tagIds: {t1.id})).first;
      expect(onlyJazz.map((s) => s.id).toSet(), {s1, s2});
    });

    test('태그를 지우면 곡은 남고 연결만 떨어진다', () async {
      final s1 = await import('A');
      final t = await tags.findOrCreate('임시');
      await tags.attach(s1, t.id);
      await tags.deleteTag(t.id);

      expect(await scores.findById(s1), isNotNull);
      expect(await tags.watchTagsOfScore(s1).first, isEmpty);
    });

    test('태그별 곡 수를 센다', () async {
      final s1 = await import('A');
      final s2 = await import('B');
      final t = await tags.findOrCreate('둘');
      await tags.attachMany([s1, s2], t.id);
      final counts = await tags.watchCounts().first;
      expect(counts[t.id], 2);
    });
  });

  group('세트리스트', () {
    test('만들고 순서를 바꾼다', () async {
      final a = await import('A');
      final b = await import('B');
      final c = await import('C');
      final id = await setlists.create('공연', [a, b, c]);

      var entries = await setlists.entries(id);
      expect(entries.map((e) => e.score.id), [a, b, c]);

      final ids = entries.map((e) => e.item.id).toList();
      await setlists.reorder(id, [ids[2], ids[0], ids[1]]);

      entries = await setlists.entries(id);
      expect(entries.map((e) => e.score.id), [c, a, b]);
    });

    test('복제하면 항목과 구간이 그대로 따라온다', () async {
      final a = await import('A');
      final id = await setlists.create('원본', [a]);
      final item = (await setlists.entries(id)).single.item;
      await setlists.setPageRange(item.id, 2, 4);

      final copy = await setlists.duplicate(id);
      final copied = (await setlists.entries(copy)).single;
      expect(copied.item.startPage, 2);
      expect(copied.item.endPage, 4);
      expect((await setlists.findById(copy))!.name, '원본 복사본');
    });

    test('곡을 지우면 세트리스트에서도 빠진다', () async {
      final a = await import('A');
      final b = await import('B');
      final id = await setlists.create('공연', [a, b]);
      await scores.deleteScores([a]);
      final entries = await setlists.entries(id);
      expect(entries.map((e) => e.score.id), [b]);
    });

    test('구간을 지정하면 그 페이지만 이어 붙여 연다', () async {
      final a = await import('A');
      final b = await import('B');
      final id = await setlists.create('공연', [a, b]);
      final entries = await setlists.entries(id);
      // A 는 3~5쪽(0-based 2~4), B 는 전체 8쪽.
      await setlists.setPageRange(entries.first.item.id, 2, 4);

      final session = await ScoreSession.openSetlist(
        setlist: (await setlists.findById(id))!,
        entries: await setlists.entries(id),
        pagesOf: scores.visiblePages,
        paths: paths,
      );
      addTearDown(session.dispose);

      expect(session.pageCount, 3 + 8);
      expect(session.documents, hasLength(2));
      expect(session.pages.first.scoreId, a);
      expect(session.pages.first.sourcePageNumber, 3);
      expect(session.pages[2].sourcePageNumber, 5);
      expect(session.pages[3].scoreId, b);
      expect(session.pages[3].sourcePageNumber, 1);
      expect(session.scoreOf(session.pages.last).id, b);
    });
  });
}
