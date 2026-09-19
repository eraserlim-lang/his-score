import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/viewer/domain/open_tabs.dart';
import '../../features/viewer/presentation/widgets/score_tab_bar.dart';
import '../i18n/tr.dart';
import 'breakpoints.dart';

/// 목적지 하나. 폰에서는 하단 탭, 태블릿/데스크톱에서는 좌측 레일로 나온다.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

const shellDestinations = <ShellDestination>[
  ShellDestination(
    label: '악보',
    icon: Icons.library_music_outlined,
    selectedIcon: Icons.library_music,
    path: '/library',
  ),
  ShellDestination(
    label: '세트리스트',
    icon: Icons.queue_music_outlined,
    selectedIcon: Icons.queue_music,
    path: '/setlists',
  ),
  ShellDestination(
    label: '가져오기',
    icon: Icons.add_circle_outline,
    selectedIcon: Icons.add_circle,
    path: '/import',
  ),
  ShellDestination(
    label: '설정',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: '/settings',
  ),
];

/// 폭에 따라 하단 탭과 좌측 레일을 바꿔 다는 껍데기.
///
/// 악보 보기 화면은 이 껍데기 밖에서 전체 화면으로 띄운다.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final formFactor = Breakpoints.of(context);

    if (formFactor.isCompact) {
      return Scaffold(
        body: _WithTabs(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final d in shellDestinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: tr(d.label),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            extended: formFactor.isExpanded,
            leading: const _RailHeader(),
            destinations: [
              for (final d in shellDestinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(tr(d.label)),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _WithTabs(child: child)),
        ],
      ),
    );
  }
}

/// 열어 둔 악보 탭을 목록 화면 위에도 걸어 둔다.
/// 보기 화면을 닫아도 탭은 남아 있어 곧장 되돌아갈 수 있다.
class _WithTabs extends ConsumerWidget {
  const _WithTabs({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTabs = ref.watch(openTabsProvider).isNotEmpty;
    if (!hasTabs) return child;

    return Column(
      children: [
        const SafeArea(bottom: false, child: ScoreTabBar()),
        // 상단 여백은 탭 줄이 이미 먹었다. 아래 화면의 앱바가 또 밀지 않게 한다.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader();

  @override
  Widget build(BuildContext context) {
    final extended = Breakpoints.of(context).isExpanded;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: extended
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'HIScore',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            )
          : Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary),
    );
  }
}
