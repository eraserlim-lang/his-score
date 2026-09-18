import 'package:flutter/material.dart';

import '../../../../core/db/tables.dart';
import '../../data/score_session.dart';
import '../../domain/spreads.dart';
import 'score_page_view.dart';

/// 1페이지 / 2페이지 보기. 한 묶음씩 넘긴다.
///
/// 확대는 묶음 단위로 건다. 넘기면 확대가 풀리는 편이 연주 중에 안전하다.
class PagedScoreView extends StatefulWidget {
  const PagedScoreView({
    super.key,
    required this.session,
    required this.map,
    required this.animation,
    required this.pageIndex,
    required this.onPageChanged,
  });

  final ScoreSession session;
  final SpreadMap map;
  final TurnAnimation animation;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;

  @override
  State<PagedScoreView> createState() => PagedScoreViewState();
}

class PagedScoreViewState extends State<PagedScoreView> {
  late PageController _controller;
  late int _spread;

  /// 확대 상태를 묶음마다 새로 만든다.
  final _zoomKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _spread = widget.map.spreadOf(widget.pageIndex);
    _controller = PageController(initialPage: _spread);
  }

  @override
  void didUpdateWidget(PagedScoreView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final target = widget.map.spreadOf(widget.pageIndex);
    if (target != _spread && _controller.hasClients) {
      _spread = target;
      // 멀리 건너뛸 때 중간 페이지를 전부 스쳐 지나가면 느리다.
      if ((_controller.page ?? 0).round() - target != 0 &&
          ((_controller.page ?? 0).round() - target).abs() > 1) {
        _controller.jumpToPage(target);
      } else {
        _controller.animateToPage(
          target,
          duration: const Duration(milliseconds: 220),
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

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      key: _zoomKey,
      controller: _controller,
      itemCount: widget.map.spreadCount,
      onPageChanged: _handlePageChanged,
      physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
      itemBuilder: (context, spread) {
        final content = _Spread(
          session: widget.session,
          pages: widget.map.pagesOf(spread),
        );

        if (widget.animation == TurnAnimation.slide) {
          return _Zoomable(child: content);
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = _controller.hasClients &&
                    _controller.position.hasContentDimensions
                ? (_controller.page ?? _spread.toDouble()) - spread
                : 0.0;
            return _applyAnimation(widget.animation, offset, child!);
          },
          child: _Zoomable(child: content),
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
  const _Spread({required this.session, required this.pages});

  final ScoreSession session;
  final List<int> pages;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return const SizedBox.shrink();

    if (pages.length == 1) {
      return Center(
        child: ScorePageView(
          session: session,
          page: session.pages[pages.first],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final index in pages)
          Flexible(
            child: ScorePageView(session: session, page: session.pages[index]),
          ),
      ],
    );
  }
}

/// 핀치 확대. 두 손가락일 때만 반응해 한 손가락 스와이프 넘김과 겹치지 않는다.
class _Zoomable extends StatefulWidget {
  const _Zoomable({required this.child});

  final Widget child;

  @override
  State<_Zoomable> createState() => _ZoomableState();
}

class _ZoomableState extends State<_Zoomable> {
  final _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      minScale: 1,
      maxScale: 6,
      // 확대하지 않았을 때는 드래그를 PageView 가 가져가야 넘김이 된다.
      panEnabled: false,
      scaleEnabled: true,
      onInteractionEnd: (_) {
        final scale = _controller.value.getMaxScaleOnAxis();
        if (scale <= 1.02) _controller.value = Matrix4.identity();
      },
      child: widget.child,
    );
  }
}
