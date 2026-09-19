import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/features/viewer/data/score_session.dart';
import 'package:his_score/features/viewer/domain/open_tabs.dart';
import 'package:his_score/features/viewer/presentation/widgets/score_tab_bar.dart';

void main() {
  late ProviderContainer container;
  OpenTabs tabs() => container.read(openTabsProvider.notifier);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('열어 둔 탭', () {
    test('같은 문서를 다시 열면 탭이 늘지 않는다', () {
      tabs().open(const SessionKey.score('a'), '가곡');
      tabs().open(const SessionKey.score('a'), '가곡');
      expect(container.read(openTabsProvider).length, 1);
    });

    test('악보와 세트리스트는 id 가 같아도 다른 탭이다', () {
      tabs().open(const SessionKey.score('a'), '곡');
      tabs().open(const SessionKey.setlist('a'), '세트');
      expect(container.read(openTabsProvider).length, 2);
    });

    test('보던 자리를 기억했다가 돌려준다', () {
      const key = SessionKey.score('a');
      tabs().open(key, '곡');
      tabs().updatePage(key, 7);
      expect(tabs().pageOf(key), 7);
      expect(tabs().pageOf(const SessionKey.score('b')), isNull);
    });

    test('탭이 없으면 자리를 기억하지 않는다', () {
      tabs().updatePage(const SessionKey.score('a'), 3);
      expect(container.read(openTabsProvider), isEmpty);
    });

    test('닫으면 옆 탭을 알려 주고 마지막 하나면 알려 줄 것이 없다', () {
      tabs().open(const SessionKey.score('a'), 'A');
      tabs().open(const SessionKey.score('b'), 'B');
      tabs().open(const SessionKey.score('c'), 'C');

      expect(tabs().neighbourOf(const SessionKey.score('b'))!.title, 'A');
      expect(tabs().neighbourOf(const SessionKey.score('a'))!.title, 'B');

      tabs().close(const SessionKey.score('a'));
      tabs().close(const SessionKey.score('b'));
      expect(tabs().neighbourOf(const SessionKey.score('c')), isNull);
    });

    test('지운 문서의 탭은 함께 사라진다', () {
      tabs().open(const SessionKey.score('a'), 'A');
      tabs().open(const SessionKey.setlist('s'), 'S');
      tabs().closeIds(['a']);
      expect(container.read(openTabsProvider).single.title, 'S');
    });

    test('너무 많이 쌓이면 가장 오래된 탭부터 밀려난다', () {
      for (var i = 0; i < OpenTabs.maxTabs + 3; i++) {
        tabs().open(SessionKey.score('s$i'), '곡 $i');
      }
      final open = container.read(openTabsProvider);
      expect(open.length, OpenTabs.maxTabs);
      expect(open.first.title, '곡 3');
    });
  });

  testWidgets('탭 줄이 열어 둔 문서를 보여 주고 고르면 알려 준다', (tester) async {
    tabs().open(const SessionKey.score('a'), '첫 곡');
    tabs().open(const SessionKey.setlist('s'), '주일 예배');

    OpenTab? picked;
    OpenTab? closed;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ScoreTabBar(
              current: const SessionKey.score('a'),
              onSelect: (t) => picked = t,
              onClose: (t) => closed = t,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('첫 곡'), findsOneWidget);
    expect(find.text('주일 예배'), findsOneWidget);

    await tester.tap(find.text('주일 예배'));
    expect(picked?.key, const SessionKey.setlist('s'));

    // 보고 있는 탭을 다시 눌러도 옮겨 가지 않는다.
    picked = null;
    await tester.tap(find.text('첫 곡'));
    expect(picked, isNull);

    await tester.tap(find.byIcon(Icons.close).first);
    expect(closed?.key, const SessionKey.score('a'));
  });

  testWidgets('열어 둔 탭이 없으면 자리를 차지하지 않는다', (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ScoreTabBar())),
      ),
    );
    expect(tester.getSize(find.byType(ScoreTabBar)).height, 0);
  });
}
