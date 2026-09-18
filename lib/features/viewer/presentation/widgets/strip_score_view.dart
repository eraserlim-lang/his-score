import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/db/tables.dart';
import '../../data/score_session.dart';
import 'score_page_view.dart';

/// 세로 스크롤 보기와 반페이지 보기.
///
/// 둘 다 페이지를 위에서 아래로 이어 붙인 한 줄이고, 반페이지 보기만
/// 페이지 위쪽과 한가운데에 멈추도록 스냅을 건다. 반페이지 넘김의 목적은
/// 다음 줄이 항상 화면에 미리 보이게 하는 것이다.
class StripScoreView extends StatefulWidget {
  const StripScoreView({
    super.key,
    required this.session,
    required this.layout,
    required this.pageIndex,
    required this.onPageChanged,
    required this.autoScrolling,
    required this.autoScrollSeconds,
    required this.onAutoScrollFinished,
  });

  final ScoreSession session;
  final PageLayout layout;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final bool autoScrolling;
  final double autoScrollSeconds;
  final VoidCallback onAutoScrollFinished;

  @override
  State<StripScoreView> createState() => StripScoreViewState();
}

class StripScoreViewState extends State<StripScoreView>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  _StripMetrics? _metrics;

  /// 스크롤로 바뀐 페이지를 다시 스크롤 명령으로 되돌리지 않기 위한 표시.
  bool _drivingScroll = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _scroll.addListener(_onScroll);
    // 이미 자동 스크롤이 켜진 채로 만들어질 수 있다. 여기서 시작하지 않으면
    // 값이 바뀌는 순간까지 티커가 영영 돌지 않는다.
    if (widget.autoScrolling) _ticker.start();
  }

  @override
  void didUpdateWidget(StripScoreView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pageIndex != oldWidget.pageIndex) {
      _jumpToPage(widget.pageIndex);
    }
    if (widget.autoScrolling != oldWidget.autoScrolling) {
      if (widget.autoScrolling) {
        _lastTick = Duration.zero;
        _ticker.start();
      } else {
        _ticker.stop();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final metrics = _metrics;
    if (!_scroll.hasClients || metrics == null) return;

    final dt = _lastTick == Duration.zero
        ? Duration.zero
        : elapsed - _lastTick;
    _lastTick = elapsed;
    if (dt == Duration.zero) return;

    final position = _scroll.position;
    // 문서 전체를 정해진 시간에 훑는 속도. 페이지 수와 무관하게 체감이 같다.
    final pixelsPerSecond = metrics.totalExtent / widget.autoScrollSeconds;
    final next = position.pixels +
        pixelsPerSecond * (dt.inMicroseconds / Duration.microsecondsPerSecond);

    if (next >= position.maxScrollExtent) {
      _scroll.jumpTo(position.maxScrollExtent);
      _ticker.stop();
      widget.onAutoScrollFinished();
      return;
    }
    _scroll.jumpTo(next);
  }

  void _onScroll() {
    final metrics = _metrics;
    if (metrics == null || _drivingScroll || !_scroll.hasClients) return;
    final page = metrics.pageAt(_scroll.position.pixels);
    if (page != widget.pageIndex) widget.onPageChanged(page);
  }

  void _jumpToPage(int page) {
    final metrics = _metrics;
    if (metrics == null || !_scroll.hasClients) return;
    final target = metrics
        .offsetOfPage(page)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    if ((target - _scroll.position.pixels).abs() < 1) return;

    _drivingScroll = true;
    _scroll
        .animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _drivingScroll = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _StripMetrics(
          session: widget.session,
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
        );

        // 창 크기가 바뀌면 오프셋 기준이 달라지므로 현재 페이지로 다시 맞춘다.
        final previous = _metrics;
        _metrics = metrics;
        if (previous != null && previous.viewportWidth != metrics.viewportWidth) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _jumpToPage(widget.pageIndex),
          );
        }

        return ListView.builder(
          controller: _scroll,
          itemCount: widget.session.pageCount,
          padding: EdgeInsets.zero,
          physics: widget.layout == PageLayout.half
              ? _SnapPhysics(metrics: metrics)
              : const ClampingScrollPhysics(),
          itemExtentBuilder: (index, _) => metrics.heightOf(index),
          itemBuilder: (context, index) => ScorePageView(
            session: widget.session,
            page: widget.session.pages[index],
          ),
        );
      },
    );
  }
}

/// 페이지 높이와 누적 위치. 뷰포트 폭이 정해져야 계산할 수 있다.
class _StripMetrics {
  _StripMetrics({
    required this.session,
    required this.viewportWidth,
    required this.viewportHeight,
  }) {
    var running = 0.0;
    for (final page in session.pages) {
      _offsets.add(running);
      final height = viewportWidth / page.aspectRatio;
      _heights.add(height);
      running += height;
    }
    totalExtent = running;
  }

  final ScoreSession session;
  final double viewportWidth;
  final double viewportHeight;

  final _offsets = <double>[];
  final _heights = <double>[];
  late final double totalExtent;

  double heightOf(int index) => _heights[index];
  double offsetOfPage(int index) =>
      _offsets[index.clamp(0, _offsets.length - 1)];

  /// 화면 위쪽 3분의 1 지점에 걸친 페이지를 현재 페이지로 본다.
  /// 화면 맨 위 기준으로 하면 페이지가 조금만 넘어가도 번호가 바뀐다.
  int pageAt(double offset) {
    final probe = offset + viewportHeight / 3;
    for (var i = _offsets.length - 1; i >= 0; i--) {
      if (probe >= _offsets[i]) return i;
    }
    return 0;
  }

  /// 반페이지 보기에서 멈출 수 있는 위치. 페이지 위쪽과 한가운데다.
  double nearestStop(double offset) {
    var best = 0.0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _offsets.length; i++) {
      for (final candidate in [_offsets[i], _offsets[i] + _heights[i] / 2]) {
        final distance = (candidate - offset).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          best = candidate;
        }
      }
    }
    return best;
  }
}

/// 반페이지 보기 전용 스냅 물리.
class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics({required this.metrics, super.parent});

  final _StripMetrics metrics;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(metrics: metrics, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // 손을 뗀 속도만큼 먼저 흘려보낸 뒤 가장 가까운 정지점으로 붙인다.
    final proposed = position.pixels + velocity * 0.15;
    final target = metrics
        .nearestStop(proposed)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    if ((target - position.pixels).abs() < toleranceFor(position).distance) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
