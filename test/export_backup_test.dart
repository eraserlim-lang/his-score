import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/score_dao.dart';
import 'package:his_score/core/db/setlist_dao.dart';
import 'package:his_score/core/db/tables.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/annotation/data/annotation_dao.dart';
import 'package:his_score/features/annotation/domain/ink_models.dart';
import 'package:his_score/features/backup/data/backup_service.dart';
import 'package:his_score/features/export/data/score_exporter.dart';
import 'package:his_score/features/importer/data/score_importer.dart';
import 'package:his_score/features/library/data/cover_generator.dart';
import 'package:his_score/features/setlist/data/setlist_share.dart';
import 'package:pdfrx/pdfrx.dart';

class _Env {
  late Directory root;
  late AppDatabase db;
  late AppPaths paths;
  late ScoreDao scores;
  late SetlistDao setlists;
  late AnnotationDao ink;
  late ScoreImporter importer;

  Future<void> up(String tag) async {
    root = await Directory.systemTemp.createTemp('hiscore_$tag');
    paths = AppPaths(root);
    await paths.ensureCreated();
    db = AppDatabase(NativeDatabase.memory());
    scores = ScoreDao(db);
    setlists = SetlistDao(db);
    ink = AnnotationDao(db);
    importer = ScoreImporter(scores, paths, CoverGenerator(paths));
  }

  Future<void> down() async {
    await db.close();
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // pdfium 핸들
    }
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Pdfrx.cacheDirectoryPath ??= Directory.systemTemp.path;
    await pdfrxFlutterInitialize();
  });

  group('내보내기', () {
    late _Env env;
    setUp(() async {
      env = _Env();
      await env.up('export');
    });
    tearDown(() => env.down());

    test('구간과 필기를 반영한 PDF 를 만든다', () async {
      final id = (await env.importer.importFile(File('test/fixtures/score.pdf')))!;
      await env.ink.upsertStroke(
        id,
        2,
        Stroke(
          id: 's',
          tool: StrokeTool.pen,
          color: const Color(0xFFFF0000),
          width: 3,
          points: [for (var i = 0; i <= 10; i++) InkPoint(0.1 + i * 0.08, 0.5, 0.8)],
        ),
      );
      final score = (await env.scores.findById(id))!;
      final exporter = ScoreExporter(env.paths, env.scores, env.ink);

      final bytes = await exporter.build(
        score,
        const ExportOptions(withInk: true, firstPage: 1, lastPage: 3, dpi: 60),
      );
      expect(bytes.length, greaterThan(1000));

      final doc = await PdfDocument.openData(bytes);
      addTearDown(doc.dispose);
      expect(doc.pages.length, 3);

      // 필기가 있는 장(원본 2쪽 = 구간의 첫 장)에 빨간 픽셀이 있어야 한다.
      final rendered = await doc.pages.first.render(fullWidth: 300, fullHeight: 424);
      addTearDown(rendered!.dispose);
      var red = 0;
      final px = rendered.pixels;
      for (var i = 0; i + 3 < px.length; i += 4) {
        final b = px[i], g = px[i + 1], r = px[i + 2];
        if (r > 180 && g < 100 && b < 100) red++;
      }
      expect(red, greaterThan(50));
    });

    test('원본 그대로는 가져온 파일과 같다', () async {
      final id = (await env.importer.importFile(File('test/fixtures/score.pdf')))!;
      final score = (await env.scores.findById(id))!;
      final exporter = ScoreExporter(env.paths, env.scores, env.ink);
      final bytes = await exporter.originalBytes(score);
      expect(bytes.length, await File('test/fixtures/score.pdf').length());
    });
  });

  group('세트리스트 공유', () {
    late _Env a;
    late _Env b;
    setUp(() async {
      a = _Env();
      b = _Env();
      await a.up('share_a');
      await b.up('share_b');
    });
    tearDown(() async {
      await a.down();
      await b.down();
    });

    test('텍스트 목록에 순서와 구간이 적힌다', () async {
      final s1 = (await a.importer.importFile(File('test/fixtures/score.pdf'), title: '첫 곡', artist: '홍길동'))!;
      final s2 = (await a.importer.importFile(File('test/fixtures/score.pdf'), title: '둘째 곡'))!;
      final id = await a.setlists.create('발표회', [s1, s2]);
      final entries = await a.setlists.entries(id);
      await a.setlists.setPageRange(entries.last.item.id, 1, 3);

      final share = SetlistShare(a.setlists, a.scores, a.paths, () async => a.importer);
      final text = await share.asText(id);
      expect(text, contains('발표회'));
      expect(text, contains('1. 첫 곡 - 홍길동'));
      expect(text, contains('2. 둘째 곡 (2~4쪽)'));
    });

    test('zip 으로 보내면 받는 쪽에 곡과 세트리스트가 생긴다', () async {
      final s1 = (await a.importer.importFile(File('test/fixtures/score.pdf'), title: '보낼 곡'))!;
      final id = await a.setlists.create('투어', [s1]);
      final entries = await a.setlists.entries(id);
      await a.setlists.setPageRange(entries.single.item.id, 2, 5);

      final shareA = SetlistShare(a.setlists, a.scores, a.paths, () async => a.importer);
      final zip = await shareA.asZip(id);

      final tmp = File('${b.root.path}/incoming.zip');
      await tmp.writeAsBytes(zip);
      final shareB = SetlistShare(b.setlists, b.scores, b.paths, () async => b.importer);
      final newId = await shareB.import(tmp);

      final got = await b.setlists.entries(newId);
      expect(got.single.score.id, s1);
      expect(got.single.score.title, '보낼 곡');
      expect(got.single.item.startPage, 2);
      expect(got.single.item.endPage, 5);
      expect((await b.setlists.findById(newId))!.name, '투어');
    });

    test('순서만 보내면 제목이 같은 곡을 찾아 쓰고 없는 곡은 메모에 남긴다', () async {
      final s1 = (await a.importer.importFile(File('test/fixtures/score.pdf'), title: '공통 곡'))!;
      final s2 = (await a.importer.importFile(File('test/fixtures/score.pdf'), title: '없는 곡'))!;
      final id = await a.setlists.create('연습', [s1, s2]);
      // 받는 쪽에는 id 는 다르지만 제목이 같은 곡만 있다.
      await b.importer.importFile(File('test/fixtures/score.pdf'), title: '공통 곡');

      final shareA = SetlistShare(a.setlists, a.scores, a.paths, () async => a.importer);
      final file = File('${b.root.path}/in.hisetlist');
      await file.writeAsBytes(await shareA.asSetlistFile(id));

      final shareB = SetlistShare(b.setlists, b.scores, b.paths, () async => b.importer);
      final newId = await shareB.import(file);
      final got = await b.setlists.entries(newId);
      expect(got.map((e) => e.score.title), ['공통 곡']);
      expect((await b.setlists.findById(newId))!.note, contains('없는 곡'));
    });
  });

  group('백업', () {
    late _Env a;
    late _Env b;
    setUp(() async {
      a = _Env();
      b = _Env();
      await a.up('backup_a');
      await b.up('backup_b');
    });
    tearDown(() async {
      await a.down();
      await b.down();
    });

    test('백업을 다른 환경에 복원하면 필기와 세트리스트가 그대로다', () async {
      final id = (await a.importer.importFile(File('test/fixtures/score.pdf'), title: '백업 곡'))!;
      await a.ink.upsertStroke(
        id,
        3,
        Stroke(
          id: 'k',
          tool: StrokeTool.pen,
          color: const Color(0xFF0000FF),
          width: 1,
          points: const [InkPoint(0.1, 0.1), InkPoint(0.5, 0.5)],
        ),
      );
      await a.ink.upsertPlaced(
        id,
        3,
        const PlacedAnnotation(id: 'p', kind: PlacedKind.text, value: 'rit.', x: 0.3, y: 0.3, color: Color(0xFF000000)),
      );
      final setlistId = await a.setlists.create('공연', [id]);
      await a.scores.updateScore(id, const ScoresCompanion(cropLeft: Value(0.1)));

      final zip = await BackupService(a.db, a.paths).createBackup();
      final summary = await BackupService(b.db, b.paths).inspect(zip);
      expect(summary.scores, 1);
      expect(summary.setlists, 1);
      expect(summary.strokes, 1);
      expect(summary.files, greaterThanOrEqualTo(2)); // PDF + 표지

      // 받는 쪽에 잡동사니가 있어도 전부 바뀐다.
      await b.importer.importFile(File('test/fixtures/score.pdf'), title: '지워질 곡');
      await BackupService(b.db, b.paths).restore(zip);

      final restored = await b.scores.findById(id);
      expect(restored, isNotNull);
      expect(restored!.title, '백업 곡');
      expect(restored.cropLeft, 0.1);
      expect(await b.scores.count(), 1);
      expect(b.paths.resolve(restored.filePath).existsSync(), isTrue);

      final ink = await b.ink.loadPage(id, 3);
      expect(ink.strokes.single.id, 'k');
      expect(ink.strokes.single.points.length, 2);
      expect(ink.placed.single.value, 'rit.');

      final entries = await b.setlists.entries(setlistId);
      expect(entries.single.score.id, id);
    });
  });
}
