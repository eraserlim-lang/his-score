import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/tools/presentation/tools_panel.dart';

/// 아래 막대의 음악 도구 버튼: 창을 열면 선택된 모양, 다시 누르면 닫힌다.
void main() {
  // 녹음기와 튜너가 녹음 플러그인을 만든다. 테스트에는 없으니 받아만 준다.
  const recordChannel = MethodChannel('com.llfbandit.record/messages');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, null);
    openToolWindows.value = const {};
  });

  testWidgets('도구 창을 열면 선택된 모양이 되고, 다시 누르면 창이 닫힌다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPathsProvider.overrideWith(
            (ref) async => AppPaths(Directory.systemTemp),
          ),
        ],
        // 실제처럼 화면 맨 아래에 둔다. 창은 오른쪽 위에 떠서 가리지 않는다.
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomLeft,
              child: MusicToolButtons(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    IconButton button(String label) => tester.widget<IconButton>(
      find.ancestor(of: find.byTooltip(label), matching: find.byType(IconButton)),
    );

    expect(button('건반').isSelected, isFalse);

    // 누르면 창이 뜨고, 버튼은 채운 아이콘의 선택된 모양이 된다.
    await tester.tap(find.byTooltip('건반'));
    await tester.pump();
    expect(openToolWindows.value.keys, [MusicTool.keyboard]);
    expect(button('건반').isSelected, isTrue);
    expect(find.byIcon(MusicTool.keyboard.activeIcon), findsWidgets);

    // 다시 누르면 두 번째 창을 띄우지 않고 닫는다.
    await tester.tap(find.byTooltip('건반'));
    await tester.pump();
    expect(openToolWindows.value, isEmpty);
    expect(button('건반').isSelected, isFalse);

    // 툴팁과 창 애니메이션이 건 타이머를 흘려보내고 끝낸다.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
