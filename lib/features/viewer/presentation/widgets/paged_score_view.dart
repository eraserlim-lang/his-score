import 'package:flutter/material.dart';

import '../../../../core/db/tables.dart';
import '../../data/score_session.dart';
import '../../domain/spreads.dart';
import 'score_page_view.dart';

/// 1페이지 / 2페이지 보기. 한 묶음씩 넘긴다.
///
/// 2페이지 보기에서 한 장씩 넘길 때는 묶음을 통째로 갈아 끼우지 않는다.
/// 페이지를 한 줄로 이어 붙인 띠를 반 화면씩 밀어, 이어진 카드를 옆으로
/// 넘기듯 오른쪽 장이 왼쪽 자리로 미끄러져 들어오게 한다.
///
/// 확대는 화면 전체에 건다. 넘기면 확대가 풀리는 편이 연주 중에 안전하다.
class PagedScoreView extends StatefulWidget {
  const PagedScoreView({
    super.key,
    required this.session,
    required this.map,
    required this.animation,
    required this.pageIndex,
    required this.onPageChanged,
    this.overlayBuilder,
    this.panEnabled = true,
  });

  final ScoreSession session;
  final SpreadMap map;
  final TurnAnimation animation;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final PageOverlayBuilder? overlayBuilder;

  /// 확대한 화면을 한 손가락으로 끌어 옮길 수 있는지.
  /// 필기 중에는 한 손가락이 펜이므로 꺼 둔다.
  final bool panEnabled;

  @override
  State<PagedScoreView> createState() => PagedScoreViewState();
}

class PagedScoreViewState extends State<PagedScoreView> {
  late PageController _controller;
  late int _spread;
  late bool _sliding;

  final _zoomKey = GlobalKey<_ZoomableState>();
  bool _zoomed = false;

  /// 한 장뿐이면 밀 것이 없다. 가운데에 세우는 보통 방식으로 그린다.
  bool _slidingFor(SpreadMap map) => map.isSliding && map.pageCount > 1;

  PageController _controllerFor(int spread) => PageController(
        initialPage: spread,
        viewportFraction: _sliding ? 0.5 : 1,
      );

  @override
  void initState() {
    super.initState();
    _spread = widget.map.spreadOf(widget.pageIndex);
    _sliding = _slidingFor(widget.map);
    _controller = _controllerFor(_spread);
  }

  @override
  void didUpdateWidget(PagedScoreView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final target = widget.map.spreadOf(widget.pageIndex);
    final sliding = _slidingFor(widget.map);

    if (sliding != _sliding) {
      // 띠와 묶음은 화면 폭을 나누는 방식이 달라 컨트롤러를 새로 만든다.
      final old = _controller;
      _sliding = sliding;
      _spread = target;
      _controller = _controllerFor(target);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      _resetZoom();
      return;
    }

    if (target != _spread && _controller.hasClients) {
      _spread = target;
      _resetZoom();
      // 멀리 건너뛸 때 중간 페이지를 전부 스쳐 지나가면 느리다.
      if (((_controller.page ?? 0).round() - target).abs() > 1) {
        _controller.jumpToPage(target);
      } else {
        _controller.animateToPage(
          target,
          duration: Duration(milliseconds: _sliding ? 280 : 220),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePageChanged(int spread) {
    _spread = spread;
    widget.onPageChanged(widget.map.firstPageOf(spread));
  }

  void _resetZoom() {
    if (!_zoomed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoomKey.currentState?.reset();
    });
  }

  void _handleZoomChanged(bool zoomed) {
    if (zoomed == _zoomed || !mounted) return;
    setState(() => _zoomed = zoomed);
  }

  /// 지금 스크롤 위치(묶음 단위). 아직 배치 전이면 목표 묶음을 돌려준다.
  double get _position =>
      _controller.hasClients && _controller.position.hasContentDimensions
          ? (_controller.page ?? _spread.toDouble())
          : _spread.toDouble();

  @override
  Widget build(BuildContext context) {
    // 확대한 동안에는 한 손가락 끌기가 화면 이동이다. 넘김은 탭과 페달로 한다.
    final physics = _zoomed
        ? const NeverScrollableScrollPhysics()
        : const PageScrollPhysics(parent: ClampingScrollPhysics());

    return _Zoomable(
      key: _zoomKey,
      panEnabled: widget.panEnabled,
      onZoomChanged: _handleZoomChanged,
      child: _sliding ? _buildStrip(physics) : _buildSpreads(physics),
    );
  }

  Widget _buildSpreads(ScrollPhysics physics) {
    return PageView.builder(
      key: const ValueKey('spreads'),
      controller: _controller,
      itemCount: widget.map.spreadCount,
      onPageChanged: _handlePageChanged,
      physics: physics,
      itemBuilder: (context, spread) {
        final content = _Spread(
          session: widget.session,
          pages: widget.map.pagesOf(spread),
          overlayBuilder: widget.overlayBuilder,
        );

        if (widget.animation == TurnAnimation.slide) return content;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) =>
              _applyAnimation(widget.animation, _position - spread, child!),
          child: content,
        );
      },
    );
  }

  /// 한 장씩 넘기는 2페이지 보기. 칸 하나가 페이지 한 장이고 반 화면씩 민다.
  ///
  /// 넘김 효과는 밀기 하나만 쓴다. 쌓기와 말기는 묶음 전체가 갈리는 것을
  /// 전제로 만든 것이라 이어진 띠와 맞지 않는다.
  Widget _buildStrip(ScrollPhysics physics) {
    final pageCount = widget.map.pageCount;
    return PageView.builder(
      key: const ValueKey('strip'),
      controller: _controller,
      padEnds: false,
      // 마지막 장이 왼쪽 자리까지 올 수 있게 빈 칸을 하나 덧붙인다.
      itemCount: pageCount + 1,
      onPageChanged: _handlePageChanged,
      physics: physics,
      itemBuilder: (context, index) {
        if (index >= pageCount) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // 왼쪽 자리(0)에서는 오른쪽으로, 오른쪽 자리(1)에서는 왼쪽으로 붙여
            // 두 장이 가운데에서 맞닿게 한다. 넘기는 동안에는 그 사이를 잇는다.
            final slot = (index - _position).clamp(0.0, 1.0);
            return Align(alignment: Alignment(1 - 2 * slot, 0), child: child);
          },
          child: ScorePageView(
            session: widget.session,
            page: widget.session.pages[index],
            overlayBuilder: widget.overlayBuilder,
          ),
        );
      },
    );
  }

  /// offset 0 이면 화면 정중앙, -1 은 왼쪽 밖, 1 은 오른쪽 밖이다.
  Widget _applyAnimation(TurnAnimation animation, double offset, Widget child) {
    switch (animation) {
      case TurnAnimation.slide:
      case TurnAnimation.scroll:
        return child;

      case TurnAnimation.stack:
        // 나가는 장만 움직이고 들어오는 장은 제자리에서 기다린다.
        if (offset <= 0) {
          return Transform.translate(
            offset: Offset(-offset * MediaQuery.sizeOf(context).width, 0),
            child: child,
          );
        }
        return Opacity(opacity: (1 - offset).clamp(0.0, 1.0), child: child);

      case TurnAnimation.curl:
        // 종이를 넘기는 느낌만 낸다. 실제 곡면 말림은 셰이더가 필요하다.
        final t = offset.clamp(-1.0, 1.0);
        return Transform(
          alignment: t < 0 ? Alignment.centerRight : Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(t * 1.2),
          child: child,
        );
    }
  }
}

class _Spread extends StatelessWidget {
  const _Spread({
    required this.session,
    required this.pages,
    this.overlayBuilder,
  });

  final ScoreSession session;
  final List<int> pages;
  final PageOverlayBuilder? overlayBuilder;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return const SizedBox.shrink();

    if (pages.length == 1) {
      return Center(
        child: ScorePageView(
          session: session,
          page: session.pages[pages.first],
          overlayBuilder: overlayBuilder,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final index in pages)
          Flexible(
            child: ScorePageView(
              session: session,
              page: session.pages[index],
              overlayBuilder: overlayBuilder,
            ),
          ),
      ],
    );
  }
}

/// 핀치로 확대하고 축소한다.
///
/// 확대하지 않았을 때는 두 손가락에만 반응해 한 손가락 스와이프 넘김과
/// 겹치지 않는다. 확대한 뒤에는 한 손가락으로 끌어 화면을 옮긴다.
class _Zoomable extends StatefulWidget {
  const _Zoomable({
    super.key,
    required this.child,
    required this.panEnabled,
    required this.onZoomChanged,
  });

  final Widget child;
  final bool panEnabled;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_Zoomable> createState() => _ZoomableState();
}

class _ZoomableState extends State<_Zoomable> {
  final _controller = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransform);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void reset() => _controller.value = Matrix4.identity();

  void _handleTransform() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.02;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged(zoomed);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      minScale: 1,
      maxScale: 6,
      // 확대하지 않았을 때는 드래그를 PageView 가 가져가야 넘김이 된다.
      panEnabled: _zoomed && widget.panEnabled,
      scaleEnabled: true,
      onInteractionEnd: (_) {
        if (!_zoomed) reset();
      },
      child: widget.child,
    );
  }
}
