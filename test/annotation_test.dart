import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/tables.dart';
import 'package:his_score/features/annotation/data/annotation_dao.dart';
import 'package:his_score/features/annotation/data/page_ink_store.dart';
import 'package:his_score/features/annotation/domain/annotation_tool_state.dart';
import 'package:his_score/features/annotation/domain/ink_models.dart';
import 'package:his_score/features/annotation/presentation/ink_layer.dart';
import 'package:his_score/features/annotation/presentation/ink_painter.dart';

Stroke _line({String id = 's', int n = 11, double y = 0.5}) => Stroke(
      id: id,
      tool: StrokeTool.pen,
      color: const Color(0xFF000000),
      width: 1,
      points: [for (var i = 0; i < n; i++) InkPoint(i / (n - 1), y, 0.5)],
    );

void main() {
  group('직렬화', () {
    test('점을 바이트로 바꿔도 값이 그대로다', () {
      final s = _line();
      final back = Stroke.decodePoints(s.encodePoints());
      expect(back.length, s.points.length);
      expect(back.first.x, closeTo(0, 1e-6));
      expect(back.last.x, closeTo(1, 1e-6));
      expect(back[3].pressure, closeTo(0.5, 1e-6));
    });

    test('페이지 필기를 JSON 으로 왕복한다', () {
      final ink = PageInk(
        strokes: [_line(id: 'a')],
        placed: const [
          PlacedAnnotation(
            id: 'p',
            kind: PlacedKind.stamp,
            value: 'f3',
            x: 0.2,
            y: 0.3,
            color: Color(0xFFFF0000),
          ),
        ],
      );
      final back = PageInk.fromJson(ink.toJson());
      expect(back.strokes.single.id, 'a');
      expect(back.strokes.single.points.length, 11);
      expect(back.placed.single.value, 'f3');
      expect(back.placed.single.color, const Color(0xFFFF0000));
      expect(back.placed.single.boxed, isFalse);
    });

    test('상자를 두른 스탬프는 JSON 으로 왕복해도 상자를 지킨다', () {
      const ink = PageInk(
        placed: [
          PlacedAnnotation(
            id: 'p',
            kind: PlacedKind.stamp,
            value: 'intro',
            x: 0.5,
            y: 0.5,
            color: Color(0xFF000000),
            boxed: true,
          ),
        ],
      );
      expect(PageInk.fromJson(ink.toJson()).placed.single.boxed, isTrue);
    });

    test('상자 칸이 없는 옛 기록은 상자 없이 읽는다', () {
      final back = PageInk.fromJson({
        'placed': [
          {
            'id': 'p',
            'kind': 'stamp',
            'value': 'f1',
            'x': 0.1,
            'y': 0.1,
            'color': 0xFF000000,
          },
        ],
      });
      expect(back.placed.single.boxed, isFalse);
    });
  });

  group('지우개', () {
    test('가운데를 지우면 두 조각이 남는다', () {
      var counter = 0;
      final pieces = eraseFromStroke(
        _line(),
        const Offset(0.5, 0.5),
        0.15,
        () => 'new${counter++}',
      );
      expect(pieces.length, 2);
      // 첫 조각은 원래 id 를 지키고 둘째는 새 id 를 받는다.
      expect(pieces.first.id, 's');
      expect(pieces.last.id, 'new0');
      expect(pieces.first.points.last.x, lessThan(0.4));
      expect(pieces.last.points.first.x, greaterThan(0.6));
    });

    test('닿지 않으면 같은 획을 그대로 돌려준다', () {
      final s = _line();
      final pieces =
          eraseFromStroke(s, const Offset(0.5, 0.9), 0.05, () => 'x');
      expect(identical(pieces.single, s), isTrue);
    });

    test('전부 지우면 아무것도 남지 않는다', () {
      final pieces =
          eraseFromStroke(_line(n: 3), const Offset(0.5, 0.5), 1, () => 'x');
      expect(pieces, isEmpty);
    });

    test('도형은 선에 닿으면 통째로 지워진다', () {
      final arrow = Stroke(
        id: 'a',
        tool: StrokeTool.shape,
        shape: ShapeKind.arrow,
        color: const Color(0xFF000000),
        width: 1,
        points: const [InkPoint(0, 0), InkPoint(1, 1)],
      );
      expect(
        eraseFromStroke(arrow, const Offset(0.5, 0.5), 0.02, () => 'x'),
        isEmpty,
      );
      expect(
        eraseFromStroke(arrow, const Offset(0.9, 0.1), 0.02, () => 'x'),
        hasLength(1),
      );
    });
  });

  group('좌표 변환', () {
    test('크롭된 화면 좌표와 정규화 좌표가 왕복한다', () {
      const t = InkTransform(
        size: Size(400, 600),
        crop: Rect.fromLTRB(0.1, 0.2, 0.9, 0.8),
      );
      final w = t.toWidget(0.5, 0.5);
      expect(w.dx, closeTo(200, 1e-6));
      expect(w.dy, closeTo(300, 1e-6));
      final n = t.toNormalized(const Offset(0, 0));
      expect(n.dx, closeTo(0.1, 1e-6));
      expect(n.dy, closeTo(0.2, 1e-6));
    });
  });

  group('실행 취소와 저장', () {
    late AppDatabase db;
    late AnnotationDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = AnnotationDao(db);
    });
    tearDown(() => db.close());

    Future<void> seedScore() => db.into(db.scores).insert(
          ScoresCompanion.insert(id: 's1', title: 't', filePath: 'x'),
        );

    test('상자를 두른 스탬프가 DB 에 저장됐다 돌아온다', () async {
      await seedScore();
      await dao.upsertPlaced(
        's1',
        1,
        const PlacedAnnotation(
          id: 'boxed',
          kind: PlacedKind.stamp,
          value: 'verse',
          x: 0.3,
          y: 0.3,
          color: Color(0xFF000000),
          boxed: true,
        ),
      );
      await dao.upsertPlaced(
        's1',
        1,
        const PlacedAnnotation(
          id: 'plain',
          kind: PlacedKind.stamp,
          value: 'f1',
          x: 0.6,
          y: 0.6,
          color: Color(0xFF000000),
        ),
      );

      final placed = {
        for (final p in (await dao.loadPage('s1', 1)).placed) p.id: p,
      };
      expect(placed['boxed']!.boxed, isTrue);
      expect(placed['plain']!.boxed, isFalse);
    });

    test('획을 긋고 되돌리고 다시 하면 DB 도 따라온다', () async {
      await seedScore();
      final c = PageInkController(dao: dao, scoreId: 's1', page: 1);
      await c.load();

      c.addStroke(_line(id: 'a'));
      c.addStroke(_line(id: 'b', y: 0.7));
      await c.flush();
      expect((await dao.loadPage('s1', 1)).strokes.length, 2);

      c.undo();
      await c.flush();
      expect(c.ink.strokes.map((s) => s.id), ['a']);
      expect((await dao.loadPage('s1', 1)).strokes.length, 1);

      c.redo();
      await c.flush();
      expect((await dao.loadPage('s1', 1)).strokes.length, 2);
      expect(c.canRedo, isFalse);
    });

    test('지우개 결과를 한 편집으로 되돌린다', () async {
      await seedScore();
      final c = PageInkController(dao: dao, scoreId: 's1', page: 1);
      await c.load();
      final original = _line(id: 'a');
      c.addStroke(original);

      final pieces = eraseFromStroke(
        original,
        const Offset(0.5, 0.5),
        0.15,
        () => 'p2',
      );
      c.erase([c.ink.strokes.single], pieces);
      await c.flush();
      expect(c.ink.strokes.length, 2);
      expect((await dao.loadPage('s1', 1)).strokes.length, 2);

      c.undo();
      await c.flush();
      expect(c.ink.strokes.single.id, 'a');
      expect((await dao.loadPage('s1', 1)).strokes.single.id, 'a');
    });

    test('페이지 전체 삭제도 되돌릴 수 있다', () async {
      await seedScore();
      final c = PageInkController(dao: dao, scoreId: 's1', page: 2);
      await c.load();
      c.addStroke(_line(id: 'a'));
      c.addPlaced(
        const PlacedAnnotation(
          id: 'p',
          kind: PlacedKind.text,
          value: 'rit.',
          x: 0.1,
          y: 0.1,
          color: Color(0xFF000000),
        ),
      );
      c.clear();
      await c.flush();
      expect(c.ink.isEmpty, isTrue);
      expect((await dao.loadPage('s1', 2)).isEmpty, isTrue);

      c.undo();
      await c.flush();
      expect(c.ink.strokes.length, 1);
      expect(c.ink.placed.length, 1);
      final restored = await dao.loadPage('s1', 2);
      expect(restored.strokes.length, 1);
      expect(restored.placed.single.value, 'rit.');
    });

    test('곡을 지우면 필기도 함께 사라진다', () async {
      await seedScore();
      final c = PageInkController(dao: dao, scoreId: 's1', page: 1);
      await c.load();
      c.addStroke(_line(id: 'a'));
      await c.flush();
      await (db.delete(db.scores)..where((t) => t.id.equals('s1'))).go();
      expect((await dao.loadPage('s1', 1)).isEmpty, isTrue);
    });
  });

  group('필기 층 위젯', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    testWidgets('마우스로 그으면 획이 하나 생긴다', (tester) async {
      await db.into(db.scores).insert(
            ScoresCompanion.insert(id: 's1', title: 't', filePath: 'x'),
          );
      final dao = AnnotationDao(db);
      final controller = PageInkController(dao: dao, scoreId: 's1', page: 1);
      await controller.load();
      final tools = AnnotationToolState();

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 400,
              child: InkLayer(
                controller: controller,
                crop: const Rect.fromLTRB(0, 0, 1, 1),
                rotation: 0,
                editing: true,
                tools: tools,
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(InkLayer)) - const Offset(100, 0),
        kind: PointerDeviceKind.mouse,
      );
      for (var i = 1; i <= 10; i++) {
        await gesture.moveBy(const Offset(20, 3));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      expect(controller.ink.strokes.length, 1);
      expect(controller.ink.strokes.single.points.length, greaterThan(5));
      expect(controller.canUndo, isTrue);
      await controller.flush();
      expect((await dao.loadPage('s1', 1)).strokes.length, 1);
    });

    testWidgets('스탬프를 골라 지운 뒤에도 계속 찍고 지울 수 있다', (tester) async {
      await db.into(db.scores).insert(
            ScoresCompanion.insert(id: 's1', title: 't', filePath: 'x'),
          );
      final controller = PageInkController(
        dao: AnnotationDao(db),
        scoreId: 's1',
        page: 1,
      );
      await controller.load();
      final tools = AnnotationToolState()..setStamp('f1');

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 400,
              child: InkLayer(
                controller: controller,
                crop: const Rect.fromLTRB(0, 0, 1, 1),
                rotation: 0,
                editing: true,
                tools: tools,
              ),
            ),
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byType(InkLayer));

      // 손가락은 누르고 떼는 사이에 화면이 한 번은 다시 그려진다. 그 사이에
      // 필기 층의 모양이 바뀌면 떼었다는 소식을 놓친다. 그 틈을 그대로 둔다.
      Future<void> tapAt(Offset local) async {
        final g = await tester.startGesture(
          origin + local,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await g.up();
        await tester.pump();
      }

      // 세 개를 찍는다.
      await tapAt(const Offset(60, 80));
      await tapAt(const Offset(150, 200));
      await tapAt(const Offset(240, 320));
      expect(controller.ink.placed.length, 3);

      // 가운데 것을 골라 지운다.
      tools.setTool(InkTool.select);
      await tester.pump();
      await tapAt(const Offset(150, 200));
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();
      expect(controller.ink.placed.length, 2);

      // 다시 찍을 수 있어야 한다.
      tools.setStamp('f2');
      await tester.pump();
      await tapAt(const Offset(150, 120));
      expect(controller.ink.placed.length, 3);

      // 다른 것을 골라 또 지울 수도 있어야 한다.
      tools.setTool(InkTool.select);
      await tester.pump();
      await tapAt(const Offset(60, 80));
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();
      expect(controller.ink.placed.length, 2);
    });

    testWidgets('그리는 도중 필기 층이 내려가도 획을 잃지 않고 탈도 없다', (tester) async {
      await db.into(db.scores).insert(
            ScoresCompanion.insert(id: 's1', title: 't', filePath: 'x'),
          );
      final controller = PageInkController(
        dao: AnnotationDao(db),
        scoreId: 's1',
        page: 1,
      );
      await controller.load();
      var shown = true;
      late StateSetter update;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Center(
                child: SizedBox(
                  width: 300,
                  height: 400,
                  child: shown
                      ? InkLayer(
                          controller: controller,
                          crop: const Rect.fromLTRB(0, 0, 1, 1),
                          rotation: 0,
                          editing: true,
                          tools: AnnotationToolState(),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
      );

      // 긋는 도중에 쪽이 넘어간 것처럼 층을 내린다. 손은 아직 떼지 않았다.
      final g = await tester.startGesture(
        tester.getCenter(find.byType(InkLayer)),
        kind: PointerDeviceKind.mouse,
      );
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(15, 4));
        await tester.pump(const Duration(milliseconds: 16));
      }
      update(() => shown = false);
      await tester.pump();
      await tester.pump();
      await g.up();

      expect(tester.takeException(), isNull);
      expect(controller.ink.strokes.length, 1);
    });

    testWidgets('보기 모드에서는 입력을 받지 않는다', (tester) async {
      await db.into(db.scores).insert(
            ScoresCompanion.insert(id: 's1', title: 't', filePath: 'x'),
          );
      final controller = PageInkController(
        dao: AnnotationDao(db),
        scoreId: 's1',
        page: 1,
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 300,
            height: 400,
            child: InkLayer(
              controller: controller,
              crop: const Rect.fromLTRB(0, 0, 1, 1),
              rotation: 0,
              editing: false,
              tools: AnnotationToolState(),
            ),
          ),
        ),
      );
      final g = await tester.startGesture(
        const Offset(50, 50),
        kind: PointerDeviceKind.mouse,
      );
      await g.moveBy(const Offset(80, 80));
      await g.up();
      await tester.pump();
      expect(controller.ink.strokes, isEmpty);
    });
  });
}
