import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/features/viewer/presentation/widgets/jump_layer.dart';

/// 점프 버튼이 위에 덮인 넘김 탭 영역과의 겨룸에서 이기는지.
///
/// 뷰어에서는 페이지(와 그 위의 점프 버튼) 위를 넘김 탭 영역이 반투명으로
/// 덮는다. 같은 배치를 만들어 누른다.
void main() {
  Widget layout({required Widget button, required VoidCallback onZone}) {
    return MaterialApp(
      home: Stack(
        children: [
          Center(child: button),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onZone,
            ),
          ),
        ],
      ),
    );
  }

  Widget jumpButton(VoidCallback onTap) => RawGestureDetector(
    key: const Key('jump'),
    behavior: HitTestBehavior.opaque,
    gestures: {
      JumpTapRecognizer:
          GestureRecognizerFactoryWithHandlers<JumpTapRecognizer>(
            JumpTapRecognizer.new,
            (r) => r.onTap = onTap,
          ),
    },
    child: const SizedBox(width: 44, height: 44),
  );

  testWidgets('보통 탭이면 덮인 탭 영역이 이긴다 (고치기 전의 모습)', (tester) async {
    var jumped = 0;
    var zone = 0;
    await tester.pumpWidget(
      layout(
        button: GestureDetector(
          key: const Key('jump'),
          behavior: HitTestBehavior.opaque,
          onTap: () => jumped++,
          child: const SizedBox(width: 44, height: 44),
        ),
        onZone: () => zone++,
      ),
    );
    await tester.tap(find.byKey(const Key('jump')));
    await tester.pumpAndSettle();
    expect(jumped, 0);
    expect(zone, 1);
  });

  testWidgets('점프 버튼은 덮인 탭 영역을 이기고 한 번만 넘어간다', (tester) async {
    var jumped = 0;
    var zone = 0;
    await tester.pumpWidget(
      layout(button: jumpButton(() => jumped++), onZone: () => zone++),
    );
    await tester.tap(find.byKey(const Key('jump')));
    await tester.pumpAndSettle();
    expect(jumped, 1);
    expect(zone, 0);
  });

  testWidgets('버튼 밖을 누르면 탭 영역이 그대로 받는다', (tester) async {
    var jumped = 0;
    var zone = 0;
    await tester.pumpWidget(
      layout(button: jumpButton(() => jumped++), onZone: () => zone++),
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(jumped, 0);
    expect(zone, 1);
  });

  testWidgets('버튼에서 시작해 끌면 점프하지 않는다', (tester) async {
    var jumped = 0;
    await tester.pumpWidget(
      layout(button: jumpButton(() => jumped++), onZone: () {}),
    );
    await tester.drag(find.byKey(const Key('jump')), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(jumped, 0);
  });

  testWidgets('겨룰 상대가 없어도 손을 뗄 때 한 번만 넘어간다', (tester) async {
    var jumped = 0;
    await tester.pumpWidget(
      MaterialApp(home: Center(child: jumpButton(() => jumped++))),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('jump'))),
    );
    await tester.pump();
    expect(jumped, 0, reason: '누르는 순간에는 넘어가지 않는다');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(jumped, 1);
  });

  group('편집 중 끌기', () {
    Widget dragLayout({
      required ValueChanged<Offset> onMoved,
      required VoidCallback onPageDrag,
      required VoidCallback onDelete,
    }) {
      var total = Offset.zero;
      return MaterialApp(
        home: Stack(
          children: [
            // 편집 중에도 페이지는 옆으로 밀어 넘길 수 있다. 그 자리를 흉내 낸다.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (_) => onPageDrag(),
              ),
            ),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  RawGestureDetector(
                    key: const Key('chip'),
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      JumpDragRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            JumpDragRecognizer
                          >(JumpDragRecognizer.new, (r) {
                            r.onUpdate = (d) => total += d;
                            r.onEnd = () => onMoved(total);
                          }),
                    },
                    child: const SizedBox(width: 44, height: 44),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      key: const Key('x'),
                      onTap: onDelete,
                      // 실제 X 는 CircleAvatar 라 누름을 받는다. 같게 맞춘다.
                      child: const CircleAvatar(radius: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    testWidgets('가로로 끌면 페이지가 아니라 버튼이 끈 만큼 옮겨진다', (tester) async {
      Offset? moved;
      var pageDrags = 0;
      await tester.pumpWidget(
        dragLayout(
          onMoved: (d) => moved = d,
          onPageDrag: () => pageDrags++,
          onDelete: () {},
        ),
      );
      await tester.drag(find.byKey(const Key('chip')), const Offset(-120, 30));
      await tester.pumpAndSettle();
      expect(pageDrags, 0);
      expect(moved, isNotNull);
      expect(moved!.dx, closeTo(-120, 1));
      expect(moved!.dy, closeTo(30, 1));
    });

    testWidgets('버튼 밖에서 끌면 페이지가 넘어간다', (tester) async {
      Offset? moved;
      var pageDrags = 0;
      await tester.pumpWidget(
        dragLayout(
          onMoved: (d) => moved = d,
          onPageDrag: () => pageDrags++,
          onDelete: () {},
        ),
      );
      await tester.dragFrom(const Offset(20, 300), const Offset(-150, 0));
      await tester.pumpAndSettle();
      expect(pageDrags, 1);
      expect(moved, isNull);
    });

    testWidgets('X 를 누르면 끌기가 끼어들지 않고 지워진다', (tester) async {
      var deleted = 0;
      Offset? moved;
      await tester.pumpWidget(
        dragLayout(
          onMoved: (d) => moved = d,
          onPageDrag: () {},
          onDelete: () => deleted++,
        ),
      );
      await tester.tap(find.byKey(const Key('x')));
      await tester.pumpAndSettle();
      expect(deleted, 1);
      expect(moved, isNull);
    });
  });

  group('길게 누르기', () {
    testWidgets('버튼을 길게 누르면 페이지 메뉴 대신 편집으로 간다', (tester) async {
      var edit = 0;
      var pageMenu = 0;
      var jumped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Center(
                child: RawGestureDetector(
                  key: const Key('jump'),
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    JumpTapRecognizer:
                        GestureRecognizerFactoryWithHandlers<JumpTapRecognizer>(
                          JumpTapRecognizer.new,
                          (r) {
                            r.onTap = () => jumped++;
                            r.onLongPress = () => edit++;
                          },
                        ),
                  },
                  child: const SizedBox(width: 44, height: 44),
                ),
              ),
              // 뷰어의 탭 영역처럼 덮고, 길게 누르면 페이지 메뉴를 연다.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {},
                  onLongPressStart: (_) => pageMenu++,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.longPress(find.byKey(const Key('jump')));
      await tester.pumpAndSettle();
      expect(edit, 1);
      expect(pageMenu, 0);
      expect(jumped, 0, reason: '길게 누른 뒤 뗀 것은 누름이 아니다');
    });

    testWidgets('짧게 누르면 편집이 아니라 점프한다', (tester) async {
      var edit = 0;
      var jumped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RawGestureDetector(
              key: const Key('jump'),
              behavior: HitTestBehavior.opaque,
              gestures: {
                JumpTapRecognizer:
                    GestureRecognizerFactoryWithHandlers<JumpTapRecognizer>(
                      JumpTapRecognizer.new,
                      (r) {
                        r.onTap = () => jumped++;
                        r.onLongPress = () => edit++;
                      },
                    ),
              },
              child: const SizedBox(width: 44, height: 44),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('jump')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(jumped, 1);
      expect(edit, 0);
    });
  });
}
