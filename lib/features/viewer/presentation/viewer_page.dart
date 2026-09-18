import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/score_dao.dart';
import '../../../core/db/tables.dart';
import '../../../core/theme/app_theme.dart';
import '../../annotation/data/annotation_dao.dart';
import '../../annotation/data/page_ink_store.dart';
import '../../annotation/domain/annotation_tool_state.dart';
import '../../annotation/presentation/annotation_toolbar.dart';
import '../../annotation/presentation/ink_layer.dart';
import '../data/score_session.dart';
import '../domain/spreads.dart';
import '../domain/viewer_controller.dart';
import 'widgets/paged_score_view.dart';
import 'widgets/strip_score_view.dart';
import 'widgets/viewer_toolbar.dart';

/// 악보 보기 화면.
class ViewerPage extends ConsumerWidget {
  const ViewerPage({super.key, required this.sessionKey, this.initialPage});

  final SessionKey sessionKey;
  final int? initialPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(scoreSessionProvider(sessionKey));

    return Scaffold(
      backgroundColor: ViewerColors.canvas,
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: '$e'),
        data: (session) => _ViewerBody(
          session: session,
          // 세트리스트는 항상 처음부터 시작한다. 공연 흐름과 맞다.
          initialPage: initialPage ??
              (session.key.isSetlist ? 0 : session.primaryScore.lastPage),
        ),
      ),
    );
  }
}

class _ViewerBody extends ConsumerStatefulWidget {
  const _ViewerBody({required this.session, required this.initialPage});

  final ScoreSession session;
  final int initialPage;

  @override
  ConsumerState<_ViewerBody> createState() => _ViewerBodyState();
}

class _ViewerBodyState extends ConsumerState<_ViewerBody> {
  late final ViewerController _controller;
  late final InkStore _inkStore;
  final _tools = AnnotationToolState();
  bool _chromeVisible = true;

  /// 미리 굽기에 쓸 목표 폭. 화면이 만들어진 뒤에 정해진다.
  double _renderWidth = 1200;

  @override
  void initState() {
    super.initState();
    final score = widget.session.primaryScore;
    final pageCount = widget.session.pageCount;

    _controller = ViewerController(
      ViewerState(
        pageCount: pageCount,
        layout: score.layout ?? PageLayout.single,
        animation: score.turnAnimation ?? TurnAnimation.slide,
        pageIndex: widget.initialPage.clamp(0, (pageCount - 1).clamp(0, 1 << 30)),
        startOnRight: score.startOnRight,
        autoScrollSeconds: (score.autoScrollSeconds ?? 180).toDouble(),
      ),
    )..onPageChanged = _handlePageChanged;

    _inkStore = InkStore(ref.read(annotationDaoProvider));

    // 첫 화면에 보일 페이지 주변을 미리 굽는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handlePageChanged(_controller.state.pageIndex);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tools.dispose();
    // 저장 큐를 비운 뒤 정리한다. 마지막 획이 사라지면 안 된다.
    _inkStore.flushAll().whenComplete(_inkStore.dispose);
    super.dispose();
  }

  /// 페이지 위에 얹는 필기 층. 빈 페이지에도 필기는 된다.
  Widget _inkOverlay(BuildContext context, ViewPage page, Size size) {
    return InkLayer(
      controller: _inkStore.of(page.scoreId, page.sourcePageNumber),
      crop: page.crop,
      rotation: page.rotation,
      editing: _controller.state.annotating,
      tools: _tools,
      onRequestText: (initial) => _askText(context, initial),
    );
  }

  Future<String?> _askText(BuildContext context, String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('텍스트'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(hintText: 'rit. / 숨 쉬기 / 손가락 번호…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('넣기'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllInk() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 필기를 지울까요?'),
        content: const Text('이 곡의 모든 페이지에서 필기와 스탬프가 지워집니다. 열린 페이지는 실행 취소로 되돌릴 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final score in widget.session.scores) {
      await _inkStore.clearScore(score.id);
    }
  }

  void _handlePageChanged(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= widget.session.pageCount) return;

    final page = widget.session.pages[pageIndex];
    if (!page.isBlank) {
      widget.session.cacheFor(page).prefetch(page.sourcePageNumber, _renderWidth);
    }

    // 본 자리를 남겨 다음에 열 때 그대로 돌아오게 한다.
    // 세트리스트는 곡마다 따로 기록하지 않고 열람 시각만 남긴다.
    final dao = ref.read(scoreDaoProvider);
    if (widget.session.key.isSetlist) {
      dao.markOpened(page.scoreId, page.sourcePageNumber - 1);
    } else {
      dao.markOpened(page.scoreId, pageIndex);
    }
  }

  void _toggleChrome() {
    if (_controller.state.performanceMode) return;
    setState(() => _chromeVisible = !_chromeVisible);
  }

  /// 화면을 세로로 3등분해 좌/우는 넘김, 가운데는 메뉴 토글로 쓴다.
  void _handleTap(_TapZone zone) {
    switch (zone) {
      case _TapZone.firstPage:
        _controller.handle(TurnCommand.first);
      case _TapZone.previous:
        _controller.handle(TurnCommand.previous);
      case _TapZone.next:
        _controller.handle(TurnCommand.next);
      case _TapZone.center:
        _toggleChrome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.aspectRatio > 1;
    _renderWidth = size.width * MediaQuery.devicePixelRatioOf(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        // 가로/세로가 바뀌면 그 방향에서 못 쓰는 레이아웃을 자동으로 바꿔 준다.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (state.layout == PageLayout.dual && !isLandscape) {
            _controller.setLayout(PageLayout.single);
          } else if (state.layout == PageLayout.half && isLandscape) {
            _controller.setLayout(PageLayout.single);
          }
        });

        return PopScope(
          canPop: !state.performanceMode,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _controller.setPerformanceMode(false);
          },
          child: CallbackShortcuts(
            bindings: {
              for (final entry in _keyBindings.entries)
                entry.key: () => _controller.handle(entry.value),
            },
            child: Focus(
              autofocus: true,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildContent(state)),
                  if (!state.annotating)
                    Positioned.fill(child: _TapZones(onTap: _handleTap)),
                  if (state.annotating)
                    ListenableBuilder(
                      listenable: _tools,
                      builder: (context, _) => Positioned(
                        top: _tools.toolbarAtBottom ? null : 0,
                        bottom: _tools.toolbarAtBottom ? 0 : null,
                        left: 0,
                        right: 0,
                        child: AnnotationToolbar(
                          tools: _tools,
                          pageController: _currentInkController(state),
                          onClose: () => _controller.setAnnotating(false),
                          onClearAll: _clearAllInk,
                        ),
                      ),
                    ),
                  if (_chromeVisible && !state.performanceMode && !state.annotating) ...[
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _TopBar(
                        title: _titleFor(state),
                        state: state,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PageSlider(
                            state: state,
                            onChanged: _controller.goToPage,
                          ),
                          ViewerToolbar(
                            state: state,
                            controller: _controller,
                            isLandscape: isLandscape,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (state.performanceMode)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      right: 8,
                      child: IconButton.filledTonal(
                        onPressed: () => _controller.setPerformanceMode(false),
                        icon: const Icon(Icons.close),
                        tooltip: '연주 모드 끝내기',
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 도구 막대의 실행 취소가 다룰 페이지. 2페이지 보기에서는 왼쪽 페이지다.
  PageInkController? _currentInkController(ViewerState state) {
    if (widget.session.pages.isEmpty) return null;
    final page = widget.session.pages[state.pageIndex];
    return _inkStore.of(page.scoreId, page.sourcePageNumber);
  }

  /// 세트리스트를 보는 중이면 지금 페이지가 속한 곡 이름을 보여준다.
  String _titleFor(ViewerState state) {
    if (!widget.session.key.isSetlist || widget.session.pages.isEmpty) {
      return widget.session.title;
    }
    final page = widget.session.pages[state.pageIndex];
    return '${widget.session.title} · ${widget.session.scoreOf(page).title}';
  }

  Widget _buildContent(ViewerState state) {
    if (state.isStrip) {
      return StripScoreView(
        session: widget.session,
        layout: state.layout,
        pageIndex: state.pageIndex,
        onPageChanged: _controller.reportPageChanged,
        overlayBuilder: _inkOverlay,
        autoScrolling: state.autoScrolling,
        autoScrollSeconds: state.autoScrollSeconds,
        onAutoScrollFinished: () => _controller.setAutoScrolling(false),
      );
    }

    return PagedScoreView(
      session: widget.session,
      map: SpreadMap(
        pageCount: state.pageCount,
        layout: state.layout,
        startOnRight: state.startOnRight,
      ),
      animation: state.animation,
      pageIndex: state.pageIndex,
      onPageChanged: _controller.reportPageChanged,
      overlayBuilder: _inkOverlay,
    );
  }

  /// 데스크톱 키보드와 블루투스 페달이 같은 키를 보낸다.
  /// Phase 7 에서 페달 매핑을 설정으로 빼면 여기만 바꾸면 된다.
  static const _keyBindings = <ShortcutActivator, TurnCommand>{
    SingleActivator(LogicalKeyboardKey.arrowRight): TurnCommand.next,
    SingleActivator(LogicalKeyboardKey.arrowDown): TurnCommand.next,
    SingleActivator(LogicalKeyboardKey.space): TurnCommand.next,
    SingleActivator(LogicalKeyboardKey.pageDown): TurnCommand.next,
    SingleActivator(LogicalKeyboardKey.arrowLeft): TurnCommand.previous,
    SingleActivator(LogicalKeyboardKey.arrowUp): TurnCommand.previous,
    SingleActivator(LogicalKeyboardKey.pageUp): TurnCommand.previous,
    SingleActivator(LogicalKeyboardKey.home): TurnCommand.first,
    SingleActivator(LogicalKeyboardKey.end): TurnCommand.last,
  };
}

enum _TapZone { firstPage, previous, next, center }

class _TapZones extends StatelessWidget {
  const _TapZones({required this.onTap});

  final ValueChanged<_TapZone> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 넘김 영역을 넉넉히 준다. 연주 중에 손을 정확히 가져다 댈 수 없다.
        final sideWidth = constraints.maxWidth * 0.3;

        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: sideWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onTap(_TapZone.previous),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: sideWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onTap(_TapZone.next),
              ),
            ),
            Positioned(
              left: sideWidth,
              right: sideWidth,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onTap(_TapZone.center),
              ),
            ),
            // 왼쪽 위 모서리를 두 번 누르면 첫 페이지로 돌아간다.
            Positioned(
              left: 0,
              top: 0,
              width: 64,
              height: 64,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () => onTap(_TapZone.firstPage),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.state});

  final String title;
  final ViewerState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.95),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const BackButton(),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${state.pageIndex + 1} / ${state.pageCount}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageSlider extends StatelessWidget {
  const _PageSlider({required this.state, required this.onChanged});

  final ViewerState state;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (state.pageCount <= 1) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      child: Slider(
        value: state.pageIndex.toDouble().clamp(
              0,
              (state.pageCount - 1).toDouble(),
            ),
        max: (state.pageCount - 1).toDouble(),
        divisions: state.pageCount - 1,
        label: '${state.pageIndex + 1}쪽',
        onChanged: (v) => onChanged(v.round()),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              '악보를 열지 못했습니다',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
