import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../export/presentation/export_sheet.dart';
import '../../sync/presentation/sync_sheet.dart';
import '../../tools/presentation/tools_panel.dart';
import '../../../core/db/settings_dao.dart';
import '../data/face_turn_service.dart';
import '../domain/turn_input.dart';
import '../../../core/db/database.dart';
import '../data/page_tools_dao.dart';
import '../data/score_session.dart';
import '../domain/open_tabs.dart';
import '../domain/spreads.dart';
import '../domain/viewer_controller.dart';
import 'pages/page_order_page.dart';
import 'sheets/bookmarks_sheet.dart';
import 'sheets/crop_sheet.dart';
import 'widgets/jump_layer.dart';
import 'widgets/paged_score_view.dart';
import 'widgets/score_tab_bar.dart';
import 'widgets/strip_score_view.dart';
import 'widgets/viewer_toolbar.dart';
import '../../../core/i18n/tr.dart';

/// 악보 보기 화면.
class ViewerPage extends ConsumerStatefulWidget {
  const ViewerPage({super.key, required this.sessionKey, this.initialPage});

  final SessionKey sessionKey;
  final int? initialPage;

  @override
  ConsumerState<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<ViewerPage> {
  /// 크롭이나 페이지 순서를 고친 뒤 세션을 다시 열 때 돌아갈 자리.
  int? _restorePage;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scoreSessionProvider(widget.sessionKey));

    return Scaffold(
      backgroundColor: ViewerColors.canvas,
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: '$e'),
        data: (session) => _ViewerBody(
          session: session,
          // 세트리스트는 항상 처음부터 시작한다. 공연 흐름과 맞다.
          // 탭으로 열어 둔 문서는 떠날 때 보던 자리로 돌아간다.
          initialPage: _restorePage ??
              widget.initialPage ??
              ref.read(openTabsProvider.notifier).pageOf(widget.sessionKey) ??
              (session.key.isSetlist ? 0 : session.primaryScore.lastPage),
          onReopen: (page) => setState(() => _restorePage = page),
        ),
      ),
    );
  }
}

class _ViewerBody extends ConsumerStatefulWidget {
  const _ViewerBody({
    required this.session,
    required this.initialPage,
    required this.onReopen,
  });

  final ScoreSession session;
  final int initialPage;

  /// 세션을 다시 열어 달라고 부모에게 알린다. 돌아갈 페이지를 함께 준다.
  final ValueChanged<int> onReopen;

  @override
  ConsumerState<_ViewerBody> createState() => _ViewerBodyState();
}

class _ViewerBodyState extends ConsumerState<_ViewerBody> {
  late final ViewerController _controller;
  late final InkStore _inkStore;
  final _tools = AnnotationToolState();
  bool _chromeVisible = true;

  late final TurnInputHub _hub;
  StreamSubscription<TurnCommand>? _hubSub;
  StreamSubscription<ViewerPosition>? _remoteSub;
  PedalMapping _pedals = PedalMapping.defaults;

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
        dualStepOne: score.dualStepOne ?? true,
        autoScrollSeconds: (score.autoScrollSeconds ?? 180).toDouble(),
      ),
    )
      ..onPageChanged = _handlePageChanged
      ..addListener(_persistViewSettings);

    _inkStore = InkStore(ref.read(annotationDaoProvider));

    // 페달, 얼굴 제스처, 리모컨, 리드 기기가 보내는 명령을 받는다.
    _hub = ref.read(turnInputHubProvider)..viewerOpen = true;
    _hubSub = _hub.commands.listen(_controller.handle);
    _remoteSub = _hub.remotePositions.listen(_applyRemotePosition);
    HardwareKeyboard.instance.addHandler(_onKey);
    ref.read(settingsDaoProvider).get(SettingKeys.pedalNext).then((raw) {
      if (mounted) _pedals = PedalMapping.decode(raw);
    });

    // 첫 화면에 보일 페이지 주변을 미리 굽고, 상단 탭에 이 문서를 올린다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(openTabsProvider.notifier).open(
            widget.session.key,
            widget.session.title,
            page: _controller.state.pageIndex,
          );
      _handlePageChanged(_controller.state.pageIndex);
    });
  }

  @override
  void didUpdateWidget(_ViewerBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.session, widget.session)) return;
    // 페이지 순서나 크롭을 고쳐 세션을 다시 열었다. 페이지 수를 맞추고
    // 보던 자리로 돌아간다. 페달과 필기는 그대로 살려 둔다.
    _controller.resize(widget.session.pageCount, widget.initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handlePageChanged(_controller.state.pageIndex);
    });
  }

  /// 키보드와 블루투스 페달. 글자를 입력하는 중에는 끼어들지 않는다.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.widget is EditableText) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    final cmd = _pedals.commandFor(event.logicalKey);
    if (cmd == null) return false;
    _controller.handle(cmd);
    return true;
  }

  /// 리드 기기가 보낸 위치로 이동한다. 같은 곡이 아니면 그 곡을 연다.
  void _applyRemotePosition(ViewerPosition p) {
    final index = widget.session.pageIndexOf(p.scoreId, p.sourcePage);
    if (index >= 0) {
      _controller.goToPage(index);
      return;
    }
    if (widget.session.scores.any((s) => s.id == p.scoreId)) return;
    // 다른 곡이다. 그 곡으로 화면을 바꾼다.
    context.pushReplacement('/score/${p.scoreId}?page=${p.sourcePage - 1}');
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _hubSub?.cancel();
    _remoteSub?.cancel();
    _hub.viewerOpen = false;
    ref.read(faceTurnServiceProvider).stop();
    _controller.dispose();
    _tools.dispose();
    // 저장 큐를 비운 뒤 정리한다. 마지막 획이 사라지면 안 된다.
    _inkStore.flushAll().whenComplete(_inkStore.dispose);
    super.dispose();
  }

  ViewerState? _lastPersisted;

  /// 보기 방식, 애니메이션, 펼침면, 자동 스크롤 속도를 곡에 남긴다.
  /// 세트리스트는 첫 곡 설정을 빌려 쓰므로 기록하지 않는다.
  void _persistViewSettings() {
    if (widget.session.key.isSetlist) return;
    final s = _controller.state;
    final last = _lastPersisted;
    if (last != null &&
        last.layout == s.layout &&
        last.animation == s.animation &&
        last.startOnRight == s.startOnRight &&
        last.dualStepOne == s.dualStepOne &&
        last.autoScrollSeconds == s.autoScrollSeconds) {
      return;
    }
    _lastPersisted = s;
    ref.read(scoreDaoProvider).updateScore(
          widget.session.primaryScore.id,
          ScoresCompanion(
            layout: Value(s.layout),
            turnAnimation: Value(s.animation),
            startOnRight: Value(s.startOnRight),
            dualStepOne: Value(s.dualStepOne),
            autoScrollSeconds: Value(s.autoScrollSeconds.round()),
          ),
        );
  }

  /// 페이지 위에 얹는 층. 필기가 아래, 점프 버튼이 위다.
  Widget _inkOverlay(BuildContext context, ViewPage page, Size size) {
    final state = _controller.state;
    return Stack(
      fit: StackFit.expand,
      children: [
        InkLayer(
          controller: _inkStore.of(page.scoreId, page.sourcePageNumber),
          crop: page.crop,
          rotation: page.rotation,
          editing: state.annotating,
          tools: _tools,
          onRequestText: (initial) => _askText(context, initial),
        ),
        if (!state.annotating)
          JumpLayer(
            session: widget.session,
            page: page,
            editing: state.editingJumps,
            onJump: _controller.goToPage,
            onPlace: (n) => _placeJump(page, n),
          ),
      ],
    );
  }

  Future<void> _placeJump(ViewPage page, Offset n) async {
    final target = await showDialog<int>(
      context: context,
      builder: (context) => _JumpTargetDialog(
        session: widget.session,
        page: page,
      ),
    );
    if (target == null) return;
    await ref.read(pageToolsDaoProvider).addJump(
          scoreId: page.scoreId,
          fromPage: page.sourcePageNumber,
          x: n.dx,
          y: n.dy,
          toPage: target,
        );
  }

  /// 크롭이나 순서를 바꾼 뒤 세션을 다시 연다. 보던 페이지는 유지한다.
  void _reloadSession() {
    final page = _controller.state.pageIndex;
    if (!widget.session.key.isSetlist) {
      ref.read(scoreDaoProvider).markOpened(widget.session.primaryScore.id, page);
    }
    widget.onReopen(page);
    ref.invalidate(scoreSessionProvider(widget.session.key));
  }

  /// 다른 탭으로 옮겨 간다. 보기 화면은 한 장만 쌓아 둔다.
  void _selectTab(OpenTab tab) =>
      context.pushReplacement('${tab.location}?page=${tab.page}');

  /// 탭을 닫는다. 보고 있던 탭이면 옆 탭으로 옮기고, 마지막이면 화면을 나간다.
  void _closeTab(OpenTab tab) {
    final tabs = ref.read(openTabsProvider.notifier);
    final isCurrent = tab.key == widget.session.key;
    final neighbour = isCurrent ? tabs.neighbourOf(tab.key) : null;
    tabs.close(tab.key);
    if (!isCurrent) return;
    if (neighbour != null) {
      _selectTab(neighbour);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  ViewPage get _currentPage => widget.session.pages[_controller.state.pageIndex];

  Future<void> _openPageMenu(String action) async {
    final state = _controller.state;
    switch (action) {
      case 'bookmarks':
        await showBookmarksSheet(
          context,
          session: widget.session,
          current: _currentPage,
          onJump: _controller.goToPage,
        );
      case 'crop':
        final saved = await showCropSheet(
          context,
          session: widget.session,
          current: _currentPage,
        );
        if (saved) _reloadSession();
      case 'order':
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PageOrderPage(
              session: widget.session,
              // 세트리스트는 세트에 든 모든 곡의 페이지를 한 줄로 놓고 고친다.
              scoreId: widget.session.key.isSetlist ? null : _currentPage.scoreId,
            ),
          ),
        );
        if (saved == true) _reloadSession();
      case 'jumps':
        _controller.setEditingJumps(true);
        setState(() => _chromeVisible = false);
      case 'export':
        final score = widget.session.scoreOf(_currentPage);
        await showExportSheet(
          context,
          score: score,
          visiblePageCount: widget.session.pages.where((p) => p.scoreId == score.id).length,
        );
      case 'startOnRight':
        _controller.setStartOnRight(!state.startOnRight);
      case 'dualStepOne':
        _controller.setDualStepOne(!state.dualStepOne);
      case 'anim_slide':
        _controller.setAnimation(TurnAnimation.slide);
      case 'anim_stack':
        _controller.setAnimation(TurnAnimation.stack);
      case 'anim_curl':
        _controller.setAnimation(TurnAnimation.curl);
    }
  }

  Future<String?> _askText(BuildContext context, String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('텍스트')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(hintText: tr('rit. / 숨 쉬기 / 손가락 번호…')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('취소')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(tr('넣기')),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllInk() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('전체 필기를 지울까요?')),
        content: Text(tr('이 곡의 모든 페이지에서 필기와 스탬프가 지워집니다. 열린 페이지는 실행 취소로 되돌릴 수 있습니다.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('취소')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('지우기')),
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

    // 탭으로 돌아왔을 때 이 자리에서 다시 시작한다.
    ref.read(openTabsProvider.notifier).updatePage(widget.session.key, pageIndex);

    final page = widget.session.pages[pageIndex];
    _hub.reportPosition(
      ViewerPosition(
        scoreId: page.scoreId,
        sourcePage: page.sourcePageNumber,
        pageIndex: pageIndex,
        title: widget.session.scoreOf(page).title,
        setlistId: widget.session.key.isSetlist ? widget.session.key.id : null,
      ),
    );
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
          child: Focus(
              autofocus: true,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildContent(state)),
                  if (!state.overlayEditing)
                    Positioned.fill(child: _TapZones(onTap: _handleTap)),
                  if (state.editingJumps)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Material(
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(tr('빈 곳을 눌러 점프 버튼을 놓으세요')),
                                const SizedBox(width: 8),
                                FilledButton.tonal(
                                  onPressed: () {
                                    _controller.setEditingJumps(false);
                                    setState(() => _chromeVisible = true);
                                  },
                                  child: Text(tr('완료')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
                  if (_chromeVisible && !state.performanceMode && !state.overlayEditing) ...[
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _TopBar(
                        title: _titleFor(state),
                        state: state,
                        sessionKey: widget.session.key,
                        onSelectTab: _selectTab,
                        onCloseTab: _closeTab,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: ToolRail(scoreId: _currentPage.scoreId),
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
                            onPageMenu: _openPageMenu,
                            onSync: () => showSyncSheet(context),
                            faceGesture: FaceTurnService.supported
                                ? ref.watch(faceTurnServiceProvider)
                                : null,
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
                        tooltip: tr('연주 모드 끝내기'),
                      ),
                    ),
                ],
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
        stepOne: state.dualStepOne,
      ),
      animation: state.animation,
      pageIndex: state.pageIndex,
      onPageChanged: _controller.reportPageChanged,
      overlayBuilder: _inkOverlay,
      // 필기나 점프 버튼을 놓는 중에는 한 손가락이 그 일을 한다.
      panEnabled: !state.overlayEditing,
    );
  }

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
              child: Semantics(
                button: true,
                label: tr('이전 페이지'),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onTap(_TapZone.previous),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: sideWidth,
              child: Semantics(
                button: true,
                label: tr('다음 페이지'),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onTap(_TapZone.next),
                ),
              ),
            ),
            Positioned(
              left: sideWidth,
              right: sideWidth,
              top: 0,
              bottom: 0,
              child: Semantics(
                button: true,
                label: tr('메뉴 보이기/숨기기'),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onTap(_TapZone.center),
                ),
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
  const _TopBar({
    required this.title,
    required this.state,
    required this.sessionKey,
    required this.onSelectTab,
    required this.onCloseTab,
  });

  final String title;
  final ViewerState state;
  final SessionKey sessionKey;
  final void Function(OpenTab) onSelectTab;
  final void Function(OpenTab) onCloseTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.95),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScoreTabBar(
              current: sessionKey,
              onSelect: onSelectTab,
              onClose: onCloseTab,
              background: Colors.transparent,
            ),
            SizedBox(
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
          ],
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
        label: tr('{0}쪽', [state.pageIndex + 1]),
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
              tr('악보를 열지 못했습니다'),
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
              child: Text(tr('돌아가기')),
            ),
          ],
        ),
      ),
    );
  }
}

/// 점프 버튼의 목적 페이지를 고른다. 원본 페이지 번호(1-based)를 돌려준다.
class _JumpTargetDialog extends StatefulWidget {
  const _JumpTargetDialog({required this.session, required this.page});

  final ScoreSession session;
  final ViewPage page;

  @override
  State<_JumpTargetDialog> createState() => _JumpTargetDialogState();
}

class _JumpTargetDialogState extends State<_JumpTargetDialog> {
  late int _target = widget.page.sourcePageNumber;

  @override
  Widget build(BuildContext context) {
    final max = widget.session.documentFor(widget.page).pages.length;
    return AlertDialog(
      title: Text(tr('어느 페이지로 갈까요?')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('{0}쪽', [_target]), style: Theme.of(context).textTheme.headlineSmall),
          Slider(
            value: _target.toDouble().clamp(1, max.toDouble()),
            min: 1,
            max: max.toDouble(),
            divisions: max > 1 ? max - 1 : null,
            onChanged: (v) => setState(() => _target = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _target > 1 ? () => setState(() => _target--) : null,
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: _target < max ? () => setState(() => _target++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('취소'))),
        FilledButton(
          onPressed: () => Navigator.pop(context, _target),
          child: Text(tr('놓기')),
        ),
      ],
    );
  }
}
