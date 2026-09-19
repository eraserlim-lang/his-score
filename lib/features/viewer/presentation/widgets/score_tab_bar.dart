import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/tr.dart';
import '../../data/score_session.dart';
import '../../domain/open_tabs.dart';

/// 열어 둔 악보와 세트리스트를 늘어놓는 상단 탭 줄.
///
/// 악보 보기 화면과 목록 화면이 같은 줄을 나눠 쓴다.
/// 탭을 고르면 그 문서를 열고, 보던 페이지로 되돌아간다.
class ScoreTabBar extends ConsumerStatefulWidget {
  const ScoreTabBar({
    super.key,
    this.current,
    this.onSelect,
    this.onClose,
    this.background,
  });

  /// 지금 보고 있는 문서. 목록 화면에서는 null.
  final SessionKey? current;

  /// 탭을 골랐을 때. 주지 않으면 그 문서를 새 화면으로 연다.
  final void Function(OpenTab tab)? onSelect;

  /// 탭을 닫았을 때. 주지 않으면 목록에서만 뺀다.
  final void Function(OpenTab tab)? onClose;

  final Color? background;

  @override
  ConsumerState<ScoreTabBar> createState() => _ScoreTabBarState();
}

class _ScoreTabBarState extends ConsumerState<ScoreTabBar> {
  final _controller = ScrollController();
  final _currentKey = GlobalKey();
  SessionKey? _scrolledTo;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 고른 탭이 화면 밖에 있으면 끌어다 보여 준다.
  void _revealCurrent() {
    final current = widget.current;
    if (current == null || current == _scrolledTo) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _currentKey.currentContext;
      if (!mounted || context == null) return;
      _scrolledTo = current;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(openTabsProvider);
    if (tabs.isEmpty) return const SizedBox.shrink();
    _revealCurrent();

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: widget.background ?? scheme.surfaceContainerHighest,
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          itemCount: tabs.length,
          separatorBuilder: (context, _) => const SizedBox(width: 4),
          itemBuilder: (context, i) {
            final tab = tabs[i];
            final selected = tab.key == widget.current;
            return _Tab(
              key: selected ? _currentKey : ValueKey(tab.key),
              tab: tab,
              selected: selected,
              onTap: () {
                if (selected) return;
                final onSelect = widget.onSelect;
                if (onSelect != null) {
                  onSelect(tab);
                } else {
                  context.push('${tab.location}?page=${tab.page}');
                }
              },
              onClose: () {
                final onClose = widget.onClose;
                if (onClose != null) {
                  onClose(tab);
                } else {
                  ref.read(openTabsProvider.notifier).close(tab.key);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final OpenTab tab;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.key.isSetlist ? Icons.queue_music : Icons.music_note,
                size: 16,
                color: fg,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  tab.title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 14),
                color: fg,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: tr('탭 닫기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
