import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/features/annotation/data/annotation_dao.dart';
import 'package:his_score/features/annotation/data/page_ink_store.dart';
import 'package:his_score/features/annotation/domain/annotation_tool_state.dart';
import 'package:his_score/features/annotation/domain/ink_models.dart';
import 'package:his_score/features/annotation/presentation/ink_layer.dart';
import 'package:his_score/features/annotation/presentation/ink_painter.dart';

/// 안드로이드처럼 Flutter 가 그리는 필기를 지우개로 지울 때.
void main() {
  late AppDatabase db;
  late PageInkController controller;
  late AnnotationToolState tools;

  // DB 를 기다리는 일은 모두 테스트 본문 안에서 한다. setUp/tearDown 에서
  // 기다리면 위젯 테스트의 가짜 시계가 돌지 않아 멈춘다. 기존 필기 층
  // 테스트와 같은 꼴이다.
  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  Future<void> prepare() async {
    await db
        .into(db.scores)
        .insert(ScoresCompanion.insert(id: 's1', title: 't', filePath: 'x'));
    controller = PageInkController(
      dao: AnnotationDao(db),
      scoreId: 's1',
      page: 1,
    );
    await controller.load();
    tools = AnnotationToolState();
  }

  tearDown(() => db.close());

  Future<void> pumpLayer(WidgetTester tester) => tester.pumpWidget(
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

  Offset center(WidgetTester tester) => tester.getCenter(find.byType(InkLayer));

  /// 가로로 긴 선 하나를 긋는다.
  Future<void> drawLine(WidgetTester tester) async {
    tools.setTool(InkTool.pen);
    final g = await tester.startGesture(
      center(tester) - const Offset(120, 0),
      kind: PointerDeviceKind.mouse,
    );
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pump();
  }

  /// 지우개로 x 자리를 위에서 아래로 훑는다. 손은 아직 떼지 않는다.
  Future<TestGesture> startErasing(WidgetTester tester, double dx) async {
    tools.setTool(InkTool.eraser);
    final g = await tester.startGesture(
      center(tester) + Offset(dx, -40),
      kind: PointerDeviceKind.mouse,
    );
    for (var i = 0; i < 8; i++) {
      await g.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    return g;
  }

  PageInk painted(WidgetTester tester) =>
      (tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) => w is CustomPaint && w.painter is InkPainter,
                    ),
                  )
                  .painter!
              as InkPainter)
          .ink;

  testWidgets('지우는 동안 바로 지워져 보인다', (tester) async {
    await prepare();
    await pumpLayer(tester);
    await drawLine(tester);
    final whole = controller.ink.strokes.single.points.length;

    final g = await startErasing(tester, 0);
    // 손을 떼기 전. 화면에는 가운데가 잘린 조각 둘이 보여야 한다.
    final shown = painted(tester).strokes;
    expect(shown.length, 2);
    expect(shown.fold<int>(0, (n, s) => n + s.points.length), lessThan(whole));
    // 확정(되돌리기 기록)은 아직이다.
    expect(controller.ink.strokes.length, 1);

    await g.up();
    await tester.pump();
    expect(controller.ink.strokes.length, 2);
    await controller.flush();
  });

  testWidgets('한 번 잘려 남은 조각도 다시 지울 수 있다', (tester) async {
    await prepare();
    await pumpLayer(tester);
    await drawLine(tester);
    final original = controller.ink.strokes.single.id;

    var g = await startErasing(tester, 0);
    await g.up();
    await tester.pump();
    expect(controller.ink.strokes.length, 2, reason: '가운데가 잘려 두 조각');

    // 지우개는 자를 때 왼쪽 조각에 원래 ID 를 남기고 오른쪽에 새 ID 를 준다.
    // 고치기 전에는 오른쪽 조각을 다시 지우면 옛 기록 때문에 왼쪽을 원본으로
    // 착각해 왼쪽을 지우고 오른쪽은 남겼다.
    final left = controller.ink.strokes.firstWhere((s) => s.id == original);
    final right = controller.ink.strokes.firstWhere((s) => s.id != original);
    final before = controller.ink.strokes.map((s) => s.id).toSet();

    g = await startErasing(tester, 70);
    await g.up();
    await tester.pump();

    // 자를 때 앞쪽 조각이 ID 를 이어받으므로 ID 로는 가리지 않는다.
    final strokes = controller.ink.strokes;
    expect(
      strokes.map((s) => s.id).toSet().length,
      strokes.length,
      reason: '같은 ID 의 획이 둘이면 안 된다',
    );
    expect(strokes.length, 3, reason: '왼쪽 그대로, 오른쪽은 둘로');
    expect(
      strokes.firstWhere((s) => s.id == original).points,
      left.points,
      reason: '왼쪽 조각은 그대로',
    );
    expect(
      strokes.firstWhere((s) => s.id == right.id).points.length,
      lessThan(right.points.length),
      reason: '오른쪽 조각이 잘려야 한다',
    );

    // 되돌리기 한 번에 두 번째 지우개만 되돌아간다.
    controller.undo();
    expect(controller.ink.strokes.map((s) => s.id).toSet(), before);
    await controller.flush();
  });
}
