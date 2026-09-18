import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
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
