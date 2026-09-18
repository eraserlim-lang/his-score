import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/tables.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/viewer/data/score_session.dart';
import 'package:his_score/features/viewer/domain/spreads.dart';
import 'package:his_score/features/viewer/domain/viewer_controller.dart';
import 'package:his_score/features/viewer/presentation/widgets/paged_score_view.dart';
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

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Pdfrx.cacheDirectoryPath ??= Directory.systemTemp.path;
    await pdfrxFlutterInitialize();

    root = await Directory.systemTemp.createTemp('hiscore_test');
    await Directory('${root.path}/scores').create(recursive: true);
    await File('test/fixtures/score.pdf').copy('${root.path}/scores/t.pdf');

    final now = DateTime.now();
    session = await ScoreSession.open(
      score: Score(
        id: 't',
        title: '테스트 악보',
        filePath: 'scores/t.pdf',
        fileSize: 0,
        pageCount: 8,
        startOnRight: false,
        cropLeft: 0,
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

  group('넘김 명령', () {
    test('다음/이전이 1페이지 보기에서 한 장씩 움직인다', () {
      final c = ViewerController(const ViewerState(pageCount: 8));
      c.handle(TurnCommand.next);
      expect(c.state.pageIndex, 1);
      c.handle(TurnCommand.previous);
      expect(c.state.pageIndex, 0);
    });

    test('2페이지 보기에서는 두 장씩 움직인다', () {
      final c = ViewerController(
        const ViewerState(pageCount: 8, layout: PageLayout.dual),
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
