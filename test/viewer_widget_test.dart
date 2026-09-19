import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/tables.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/viewer/data/score_session.dart';
import 'package:his_score/features/viewer/domain/spreads.dart';
import 'package:his_score/features/viewer/domain/viewer_controller.dart';
import 'package:his_score/features/viewer/presentation/sheets/crop_sheet.dart';
import 'package:his_score/features/viewer/presentation/widgets/paged_score_view.dart';
import 'package:his_score/features/viewer/presentation/widgets/score_page_view.dart';
import 'package:his_score/features/viewer/presentation/widgets/strip_score_view.dart';
import 'package:pdfrx/pdfrx.dart';

/// 실제 PDF 로 뷰어 위젯이 페이지를 그리고 넘기는지 확인한다.
///
/// 페이지 굽기는 진짜 비동기 작업이라 [WidgetTester.pumpAndSettle] 로는
/// 끝나지 않는다. 로딩 표시가 계속 돌기 때문이다. 실제 시간을 흘려보낸 뒤
/// 프레임을 몇 번 밀어 주는 방식으로 기다린다.
Future<void> settleWithRender(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  late Directory root;
  late ScoreSession session;

  /// 같은 악보로 세션을 하나 연다. 크롭을 저장한 뒤 다시 여는 상황을 흉내 낼 때도 쓴다.
  Future<ScoreSession> openSession({double cropLeft = 0}) {
    final now = DateTime.now();
    return ScoreSession.openScore(
      score: Score(
        id: 't',
        title: '테스트 악보',
        filePath: 'scores/t.pdf',
        fileSize: 0,
        pageCount: 8,
        startOnRight: false,
        cropLeft: cropLeft,
        cropTop: 0,
        cropRight: 0,
        cropBottom: 0,
        lastPage: 0,
        createdAt: now,
        updatedAt: now,
      ),
      scorePages: [
        for (var i = 0; i < 8; i++)
          ScorePage(
            id: 'p$i',
            scoreId: 't',
            sourceIndex: i,
            displayOrder: i,
            hidden: false,
            rotation: 0,
          ),
      ],
      paths: AppPaths(root),
    );
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Pdfrx.cacheDirectoryPath ??= Directory.systemTemp.path;
    await pdfrxFlutterInitialize();

    root = await Directory.systemTemp.createTemp('hiscore_test');
    await Directory('${root.path}/scores').create(recursive: true);
    await File('test/fixtures/score.pdf').copy('${root.path}/scores/t.pdf');

    session = await openSession();
  });

  tearDownAll(() async {
    session.dispose();
    // 윈도우에서는 pdfium 이 파일 핸들을 늦게 놓아 지우기가 실패할 수 있다.
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // 임시 폴더라 남아도 문제없다.
    }
  });

  testWidgets('세션이 8쪽을 순서대로 들고 있다', (tester) async {
    expect(session.pageCount, 8);
    expect(session.pages.first.sourcePageNumber, 1);
    expect(session.pages.last.sourcePageNumber, 8);
    // A4 세로라 비율이 1 보다 작다.
    expect(session.pages.first.aspectRatio, lessThan(1));
  });

  testWidgets('1페이지 보기에서 오른쪽으로 넘기면 페이지가 올라간다', (tester) async {
    var page = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PagedScoreView(
              session: session,
              map: const SpreadMap(
                pageCount: 8,
                layout: PageLayout.single,
                startOnRight: false,
              ),
              animation: TurnAnimation.slide,
              pageIndex: page,
              onPageChanged: (p) => setState(() => page = p),
            ),
          ),
        ),
      ),
    );
    await settleWithRender(tester);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await settleWithRender(tester);

    expect(page, 1);
  });

  testWidgets('2페이지 보기는 한 화면에 두 장을 놓는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PagedScoreView(
            session: session,
            map: const SpreadMap(
              pageCount: 8,
              layout: PageLayout.dual,
              startOnRight: false,
            ),
            animation: TurnAnimation.slide,
            pageIndex: 0,
            onPageChanged: (_) {},
          ),
        ),
      ),
    );
    await settleWithRender(tester);

    // 현재 묶음의 두 장이 함께 올라와 있어야 한다.
    expect(find.byType(CustomPaint), findsWidgets);
    final row = tester.widgetList<Row>(find.byType(Row));
    expect(row, isNotEmpty);
  });

  testWidgets('세로 스크롤 보기가 8쪽을 한 줄로 잇는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StripScoreView(
            session: session,
            layout: PageLayout.scroll,
            pageIndex: 0,
            onPageChanged: (_) {},
            autoScrolling: false,
            autoScrollSeconds: 180,
            onAutoScrollFinished: () {},
          ),
        ),
      ),
    );
    await settleWithRender(tester);

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.semanticChildCount, 8);
  });

  testWidgets('자동 스크롤을 켜면 위치가 내려간다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StripScoreView(
            session: session,
            layout: PageLayout.scroll,
            pageIndex: 0,
            onPageChanged: (_) {},
            autoScrolling: true,
            autoScrollSeconds: 20,
            onAutoScrollFinished: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final controller =
        tester.widget<ListView>(find.byType(ListView)).controller!;
    final before = controller.position.pixels;

    // 티커는 프레임마다 돌므로 여러 번 밀어 준다.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(controller.position.pixels, greaterThan(before));
  });

  group('2페이지 보기, 한 장씩 넘기기', () {
    const map = SpreadMap(
      pageCount: 8,
      layout: PageLayout.dual,
      startOnRight: false,
      stepOne: true,
    );

    Finder pageView(int sourcePage) => find.byWidgetPredicate(
          (w) => w is ScorePageView && w.page.sourcePageNumber == sourcePage,
        );

    testWidgets('한 번 넘기면 반 화면만 밀려 오른쪽 장이 왼쪽으로 온다', (tester) async {
      var page = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PagedScoreView(
                session: session,
                map: map,
                animation: TurnAnimation.slide,
                pageIndex: page,
                onPageChanged: (p) => setState(() => page = p),
              ),
            ),
          ),
        ),
      );
      await settleWithRender(tester);

      final width = tester.getSize(find.byType(PageView)).width;
      // 처음에는 1쪽이 왼쪽 절반, 2쪽이 오른쪽 절반에 있다.
      expect(tester.getCenter(pageView(1)).dx, lessThan(width / 2));
      expect(tester.getCenter(pageView(2)).dx, greaterThan(width / 2));
      final secondBefore = tester.getRect(pageView(2));

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
      await settleWithRender(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(page, 1);
      final position = tester.widget<PageView>(find.byType(PageView)).controller!.position;
      expect(position.pixels, closeTo(width / 2, 0.5));

      // 2쪽은 갈아 끼워지지 않고 같은 크기 그대로 왼쪽 자리로 옮겨 온다.
      final secondAfter = tester.getRect(pageView(2));
      expect(secondAfter.size, secondBefore.size);
      expect(secondAfter.center.dx, lessThan(width / 2));
      expect(tester.getCenter(pageView(3)).dx, greaterThan(width / 2));

      // 두 장은 가운데에서 맞닿는다.
      expect(secondAfter.right, closeTo(width / 2, 0.5));
      expect(tester.getRect(pageView(3)).left, closeTo(width / 2, 0.5));
    });

    testWidgets('마지막 장까지 갈 수 있다', (tester) async {
      var page = 0;
      late StateSetter update;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return PagedScoreView(
                  session: session,
                  map: map,
                  animation: TurnAnimation.slide,
                  pageIndex: page,
                  // 뷰어 컨트롤러처럼 같은 값이면 다시 그리지 않는다.
                  onPageChanged: (p) {
                    if (p != page) setState(() => page = p);
                  },
                );
              },
            ),
          ),
        ),
      );
      await settleWithRender(tester);

      update(() => page = 7);
      await settleWithRender(tester);

      final width = tester.getSize(find.byType(PageView)).width;
      expect(page, 7);
      expect(tester.getCenter(pageView(8)).dx, lessThan(width / 2));
    });

    testWidgets('두 장씩 넘기기로 바꾸면 묶음 방식으로 돌아간다', (tester) async {
      var stepOne = true;
      late StateSetter update;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return PagedScoreView(
                  session: session,
                  map: SpreadMap(
                    pageCount: 8,
                    layout: PageLayout.dual,
                    startOnRight: false,
                    stepOne: stepOne,
                  ),
                  animation: TurnAnimation.slide,
                  pageIndex: 2,
                  onPageChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );
      await settleWithRender(tester);
      expect(tester.widget<PageView>(find.byType(PageView)).controller!.viewportFraction, 0.5);

      update(() => stepOne = false);
      await settleWithRender(tester);

      final controller = tester.widget<PageView>(find.byType(PageView)).controller!;
      expect(controller.viewportFraction, 1);
      expect(controller.page, 1);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('세션을 다시 열어도 2페이지 보기의 두 장이 모두 그려진다', (tester) async {
    // 여백을 저장하면 세션이 새로 열리고 이전 세션의 캐시 이미지는 버려진다.
    // 화면에 걸려 있던 페이지가 그 죽은 이미지를 계속 그리면 검게 나온다.
    var current = await tester.runAsync(openSession);
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return PagedScoreView(
                session: current!,
                map: const SpreadMap(
                  pageCount: 8,
                  layout: PageLayout.dual,
                  startOnRight: false,
                  stepOne: true,
                ),
                animation: TurnAnimation.slide,
                pageIndex: 0,
                onPageChanged: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await settleWithRender(tester);

    // 해상도 구간이 바뀌지 않을 만큼만 여백을 준다. 이때가 문제의 경우다.
    final old = current!;
    final reopened = await tester.runAsync(() => openSession(cropLeft: 0.01));
    update(() => current = reopened);
    old.dispose();
    await settleWithRender(tester);

    expect(tester.takeException(), isNull);
    final painted = tester
        .widgetList<CustomPaint>(find.descendant(
          of: find.byType(ScorePageView),
          matching: find.byType(CustomPaint),
        ))
        .where((p) => p.painter != null);
    expect(painted.length, greaterThanOrEqualTo(2));

    await tester.pumpWidget(const SizedBox.shrink());
    reopened!.dispose();
  });

  group('여백·기울기 조정', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () => showCropSheet(
                      context,
                      session: session,
                      current: session.pages.first,
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settleWithRender(tester);
    }

    testWidgets('왼쪽 변을 끌면 왼쪽 여백이 생긴다', (tester) async {
      await openSheet(tester);
      expect(find.textContaining('왼쪽 0%'), findsOneWidget);

      // 첫 ScorePageView 가 잘라내지 않은 전체 페이지다.
      final whole = tester.getRect(find.byType(ScorePageView).first);
      await tester.dragFrom(
        whole.centerLeft,
        Offset(whole.width * 0.2, 0),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pump();

      expect(find.textContaining('왼쪽 20%'), findsOneWidget);
      expect(find.textContaining('오른쪽 0%'), findsOneWidget);
    });

    testWidgets('여백은 45% 에서 멈춘다', (tester) async {
      await openSheet(tester);

      final whole = tester.getRect(find.byType(ScorePageView).first);
      await tester.dragFrom(
        whole.topCenter,
        Offset(0, whole.height * 0.8),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pump();

      expect(find.textContaining('위 45%'), findsOneWidget);
    });

    testWidgets('두 손가락을 돌리면 이 페이지의 기울기가 바뀐다', (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('이 페이지'));
      await tester.pump();
      expect(find.textContaining('기울기 0.0°'), findsOneWidget);

      final center = tester.getRect(find.byType(ScorePageView).first).center;
      final a = await tester.startGesture(center + const Offset(-80, 0), pointer: 1);
      final b = await tester.startGesture(center + const Offset(80, 0), pointer: 2);
      await tester.pump();
      // 가운데를 축으로 시계 방향으로 조금씩 돌린다.
      for (var i = 1; i <= 10; i++) {
        final angle = i * 0.02;
        final arm = Offset.fromDirection(angle, 80);
        await a.moveTo(center - arm);
        await b.moveTo(center + arm);
        await tester.pump();
      }
      await a.up();
      await b.up();
      await tester.pump();

      final chip = tester.widget<Text>(find.textContaining('기울기 '));
      final degrees = double.parse(RegExp(r'(-?\d+\.\d)°').firstMatch(chip.data!)!.group(1)!);
      expect(degrees, greaterThan(3));
      expect(degrees, lessThan(12));
      // 돌리는 동안 여백은 건드려지지 않는다.
      expect(find.textContaining('왼쪽 0%'), findsOneWidget);
    });
  });

  group('넘김 명령', () {
    test('다음/이전이 1페이지 보기에서 한 장씩 움직인다', () {
      final c = ViewerController(const ViewerState(pageCount: 8));
      c.handle(TurnCommand.next);
      expect(c.state.pageIndex, 1);
      c.handle(TurnCommand.previous);
      expect(c.state.pageIndex, 0);
    });

    test('2페이지 보기에서 두 장씩 넘기기를 고르면 두 장씩 움직인다', () {
      final c = ViewerController(
        const ViewerState(
          pageCount: 8,
          layout: PageLayout.dual,
          dualStepOne: false,
        ),
      );
      c.handle(TurnCommand.next);
      expect(c.state.pageIndex, 2);
    });

    test('끝에서 더 넘겨도 범위를 벗어나지 않는다', () {
      final c = ViewerController(const ViewerState(pageCount: 3));
      c.handle(TurnCommand.last);
      expect(c.state.pageIndex, 2);
      c.handle(TurnCommand.next);
      expect(c.state.pageIndex, 2);
      c.handle(TurnCommand.first);
      c.handle(TurnCommand.previous);
      expect(c.state.pageIndex, 0);
    });

    test('스크롤이 아닌 보기에서는 자동 스크롤이 켜지지 않는다', () {
      final c = ViewerController(const ViewerState(pageCount: 3));
      c.setAutoScrolling(true);
      expect(c.state.autoScrolling, isFalse);

      c.setLayout(PageLayout.scroll);
      c.setAutoScrolling(true);
      expect(c.state.autoScrolling, isTrue);
    });

    test('보기 방식을 바꾸면 자동 스크롤이 멈춘다', () {
      final c = ViewerController(
        const ViewerState(pageCount: 3, layout: PageLayout.scroll),
      );
      c.setAutoScrolling(true);
      c.setLayout(PageLayout.single);
      expect(c.state.autoScrolling, isFalse);
      expect(c.state.animation, TurnAnimation.slide);
    });

    test('페이지가 바뀔 때만 알림이 간다', () {
      final seen = <int>[];
      final c = ViewerController(const ViewerState(pageCount: 5))
        ..onPageChanged = seen.add;

      c.goToPage(2);
      c.goToPage(2);
      c.setPerformanceMode(true);
      c.goToPage(3);

      expect(seen, [2, 3]);
    });
  });
}
