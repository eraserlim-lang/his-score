import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/db/tables.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/page_render_cache.dart';
import '../../data/score_session.dart';
import '../../domain/spreads.dart';
import 'page_curl.dart';
import 'score_page_view.dart';

/// 1페이지 / 2페이지 보기. 한 묶음씩 넘긴다.
///
/// 2페이지 보기에서 한 장씩 넘길 때는 묶음을 통째로 갈아 끼우지 않는다.
/// 페이지를 한 줄로 이어 붙인 띠를 반 화면씩 밀어, 이어진 카드를 옆으로
/// 넘기듯 오른쪽 장이 왼쪽 자리로 미끄러져 들어오게 한다.
///
/// 넘김 효과가 "넘기기" 면 PageView 대신 종이를 접어 넘기는 화면을 쓴다.
/// 손가락이 잡은 모서리를 끌고 다니면 접히는 선이 따라오고, 놓으면 넘어가거나
/// 되돌아간다. 탭이나 페달로 넘길 때도 같은 동작을 자동으로 재생한다.
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

class PagedScoreViewState extends State<PagedScoreView>
    with SingleTickerProviderStateMixin {
  late PageController _controller;
  late int _spread;
  late bool _sliding;
  late bool _curl;

  final _zoomKey = GlobalKey<_ZoomableState>();
  bool _zoomed = false;

  // ---- 종이 넘김 ----

  /// 깔아 둔 묶음의 페이지별 RepaintBoundary 열쇠. (묶음 번호, 칸) 마다
  /// 하나라 묶음이 바뀌어도 같은 페이지는 같은 열쇠를 쓴다.
  final _pageKeys = <(int, int), GlobalKey>{};

  /// 넘어가는 중인 장. null 이면 가만히 펼쳐져 있다.
  _PageTurn? _turn;

  /// 스냅샷을 뜨는 중. 그동안 들어오는 손가락은 무시한다.
  bool _preparing = false;

  /// 늦게 도착한 스냅샷을 버리기 위한 번호.
  int _turnGen = 0;

  Offset? _dragStart;
  bool _dragDecided = false;

  /// 가장 최근 손가락 자리. 스냅샷을 뜨는 한두 프레임 동안 움직인 만큼을
  /// 넘김이 만들어질 때 따라잡는다.
  Offset? _latestDrag;

  /// 손을 뗀 뒤 끝까지 넘어가거나 제자리로 돌아가는 움직임.
  late final AnimationController _settle =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
        )
        ..addListener(_onSettleTick)
        ..addStatusListener(_onSettleStatus);
  Offset? _settleFrom;
  Offset? _settleTo;
  bool _settleCommit = false;

  /// 한 장뿐이면 밀 것이 없다. 가운데에 세우는 보통 방식으로 그린다.
  bool _slidingFor(SpreadMap map) => map.isSliding && map.pageCount > 1;

  /// 종이 넘김. 2페이지 보기에서는 한 장씩 밀든 두 장씩 넘기든 오른쪽 장을
  /// 책등 너머로 접어 넘긴다. 띠보다 이쪽이 먼저다.
  bool _curlFor(SpreadMap map) =>
      widget.animation == TurnAnimation.curl && map.pageCount > 1;

  bool get _hasPrev => _spread > 0;
  bool get _hasNext => _spread < widget.map.spreadCount - 1;

  PageController _controllerFor(int spread) =>
      PageController(initialPage: spread, viewportFraction: _sliding ? 0.5 : 1);

  @override
  void initState() {
    super.initState();
    _spread = widget.map.spreadOf(widget.pageIndex);
    _sliding = _slidingFor(widget.map);
    _curl = _curlFor(widget.map);
    _controller = _controllerFor(_spread);
  }

  @override
  void didUpdateWidget(PagedScoreView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final target = widget.map.spreadOf(widget.pageIndex);
    final sliding = _slidingFor(widget.map);
    final curl = _curlFor(widget.map);

    if (sliding != _sliding || curl != _curl) {
      // 띠·묶음·종이 넘김은 화면을 나누는 방식이 달라 컨트롤러를 새로 만든다.
      final old = _controller;
      _sliding = sliding;
      _curl = curl;
      _spread = target;
      _controller = _controllerFor(target);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      _cancelTurn();
      _resetZoom();
      return;
    }

    if (_curl) {
      // PageView 가 없으니 넘김도 여기서 직접 재생한다.
      if (target == _spread) return;
      if (_turn != null || _preparing) {
        // 넘기는 도중 바깥에서 쪽이 바뀌면(탭 영역·페달) 손에 든 장을 놓지
        // 않는다. 끊으면 장이 사라지고 그냥 점프한다. 끝난 뒤 _reconcile 이 맞춘다.
        return;
      }
      _turnTo(target);
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
    _settle.dispose();
    _turn?.dispose();
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
      child: _curl
          ? _buildCurl()
          : _sliding
          ? _buildStrip(physics)
          : _buildSpreads(physics),
    );
  }

  // ---------------------------------------------------------------- 종이 넘김

  GlobalKey _keyFor(int spread, int slot) =>
      _pageKeys.putIfAbsent((spread, slot), GlobalKey.new);

  RenderRepaintBoundary? _boundary(int spread, int slot) {
    final object = _pageKeys[(spread, slot)]?.currentContext
        ?.findRenderObject();
    if (object is! RenderRepaintBoundary || !object.attached) return null;
    return object;
  }

  /// 종이를 접어 넘기는 화면.
  ///
  /// 가만히 있을 때는 지금 묶음을 그리되, 이웃 묶음을 그 아래에 깔아 둔다.
  /// 바탕색으로 덮여 보이지 않지만 이미지를 미리 받아 두고, 넘기기 시작할 때
  /// 앞면과 뒷면 스냅샷을 뜰 수 있다. 넘기는 동안에는 드러날 장들을 아래에
  /// 두고 그 위에 접힌 장을 그린다.
  Widget _buildCurl() {
    final map = widget.map;
    final background = ViewerColors.canvasOf(Theme.of(context).brightness);
    final turn = _turn;

    Widget spread(int index) {
      final pages = map.pagesOf(index);
      return _Spread(
        key: ValueKey(index),
        session: widget.session,
        pages: pages,
        overlayBuilder: widget.overlayBuilder,
        pageKeys: [for (var i = 0; i < pages.length; i++) _keyFor(index, i)],
      );
    }

    final layers = <Widget>[];
    if (turn == null) {
      if (_hasPrev) layers.add(spread(_spread - 1));
      if (_hasNext) layers.add(spread(_spread + 1));
      layers.add(ColoredBox(color: background));
      layers.add(spread(_spread));
    } else {
      layers.add(_underLayer(turn));
      layers.add(
        IgnorePointer(
          child: CustomPaint(
            painter: PageCurlPainter(
              image: turn.image,
              back: turn.back,
              rect: turn.rect,
              corner: turn.corner,
              finger: turn.finger,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 가로 끌기로 겨루어야 탭 영역·확대와 사이좋게 지낸다. 손가락의
      // 세로 위치는 그 안에서도 그대로 받는다.
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () {
        _dragStart = null;
        _dragDecided = false;
        _latestDrag = null;
      },
      child: Stack(fit: StackFit.expand, children: layers),
    );
  }

  /// 넘기는 동안 접힌 장 아래에 보이는 장들. 자리는 넘기기 시작할 때 잰 값이다.
  Widget _underLayer(_PageTurn turn) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final slot in turn.under)
          Positioned.fromRect(
            rect: slot.rect,
            child: Center(
              child: ScorePageView(
                session: widget.session,
                page: widget.session.pages[slot.page],
                overlayBuilder: widget.overlayBuilder,
              ),
            ),
          ),
      ],
    );
  }

  void _onDragStart(DragStartDetails d) {
    if (_zoomed) return;
    _dragStart = d.localPosition;
    _dragDecided = _turn != null;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_zoomed) return;
    _latestDrag = d.localPosition;
    final turn = _turn;
    if (turn != null) {
      if (!_settle.isAnimating) {
        setState(() => turn.finger = turn.clamp(d.localPosition));
      }
      return;
    }
    if (_preparing || _dragDecided) return;
    final start = _dragStart;
    if (start == null) return;

    // 처음 몇 픽셀로 방향을 정한다. 왼쪽으로 끌면 다음 장, 오른쪽이면 이전 장.
    // 여백에서 시작해도 똑같이 접는다. 모서리가 손가락으로 튀어 오는 편이
    // 그냥 넘어가 버리는 것보다 손에 붙는다.
    final dx = d.localPosition.dx - start.dx;
    if (dx.abs() < 6) return;
    _dragDecided = true;
    final dir = dx < 0 ? _TurnDir.forward : _TurnDir.backward;
    if (dir == _TurnDir.forward && !_hasNext) return;
    if (dir == _TurnDir.backward && !_hasPrev) return;
    _beginTurn(dir, at: d.localPosition);
  }

  /// 스냅샷을 뜰 수 없을 때 캐시의 페이지 이미지로 장을 다시 만든다.
  ///
  /// 화면의 페이지가 쓰는 것과 같은 열쇠로 캐시를 들여다보므로, 보이는
  /// 장이면 이미 구워져 있다. 필기는 빠지지만 넘김은 된다.
  Future<ui.Image?> _renderFromCache(
    int pageIndex,
    Rect rect,
    double dpr,
  ) async {
    final page = widget.session.pages[pageIndex];
    if (page.isBlank || rect.isEmpty) return null;
    final key = PageRenderKey.forWidth(
      page.sourcePageNumber,
      rect.width * dpr / page.crop.width,
    );
    final source = widget.session.cacheFor(page).peek(key);
    if (source == null) return null;

    final recorder = ui.PictureRecorder();
    final size = Size(rect.width * dpr, rect.height * dpr);
    PagePainter(
      image: source,
      crop: page.crop,
      rotation: page.rotation,
    ).paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(size.width.ceil(), size.height.ceil());
    } finally {
      picture.dispose();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final start = _dragStart;
    _dragStart = null;
    _dragDecided = false;
    _latestDrag = null;
    final turn = _turn;
    if (turn == null || _settle.isAnimating) return;

    // 넘기는 쪽으로 튕기거나 손가락이 그쪽으로 웬만큼 갔으면 넘어간다.
    // 반대쪽으로 튕기면 되돌린다. 둘 다 아니면 접힌 선이 가운데를 지났는지로.
    // 짧고 빠른 스와이프가 보통이라 문턱을 낮게 둔다. 높으면 "안 넘어간다".
    final forward = turn.dir == _TurnDir.forward;
    final vx = d.velocity.pixelsPerSecond.dx;
    final toward = forward ? -vx : vx;
    final moved = start == null
        ? 0.0
        : (forward ? start.dx - turn.finger.dx : turn.finger.dx - start.dx);
    final bool commit;
    if (toward < -200) {
      commit = false;
    } else if (toward > 150 || moved > 48) {
      commit = true;
    } else {
      commit = turn.pastHalf;
    }
    _settleTurn(commit: commit);
  }

  /// 탭·페달로 옆 묶음에 가면 손가락 없이 넘김을 재생한다. 멀리 뛰면 그냥 간다.
  void _turnTo(int target) {
    _cancelTurn();
    final delta = target - _spread;
    if (delta.abs() != 1) {
      setState(() => _spread = target);
      _resetZoom();
      return;
    }
    _beginTurn(delta > 0 ? _TurnDir.forward : _TurnDir.backward, auto: true);
  }

  /// 넘어갈 장의 앞뒤 스냅샷을 뜨고 넘김을 시작한다.
  ///
  /// 앞으로 넘길 때는 오른쪽 끝 장의 오른쪽 모서리를, 되돌릴 때는 왼쪽 끝
  /// 장의 왼쪽 모서리를 잡는다. 두 장 보기에서는 넘어간 자리에 놓일 이웃
  /// 묶음의 장을 뒷면으로 쓴다. [at] 은 손가락 자리. 없으면(자동 재생)
  /// 아래 모서리를 잡은 것으로 친다.
  Future<void> _beginTurn(_TurnDir dir, {Offset? at, bool auto = false}) async {
    final map = widget.map;
    final forward = dir == _TurnDir.forward;
    final cur = map.pagesOf(_spread);
    final neighbourIndex = forward ? _spread + 1 : _spread - 1;
    final neighbour = map.pagesOf(neighbourIndex);
    final host = context.findRenderObject() as RenderBox?;
    if (cur.isEmpty || neighbour.isEmpty || host == null) {
      debugPrint(
        '종이 넘김: 이웃 없음 cur=$cur neighbour=$neighbour host=${host != null}',
      );
      if (auto) _jump(dir);
      return;
    }

    final turningSlot = forward ? cur.length - 1 : 0;
    final front = _boundary(_spread, turningSlot);
    final slots = [for (var i = 0; i < cur.length; i++) _boundary(_spread, i)];
    if (front == null || slots.any((b) => b == null)) {
      debugPrint(
        '종이 넘김: 경계 없음 front=${front != null} '
        'slots=${slots.map((b) => b != null).toList()}',
      );
      if (auto) _jump(dir);
      return;
    }
    Rect rectOf(RenderRepaintBoundary b) =>
        b.localToGlobal(Offset.zero, ancestor: host) & b.size;
    final slotRects = [for (final b in slots) rectOf(b!)];

    // 두 장 보기: 넘어가지 않는 칸은 남고, 넘어가는 칸 자리에는 이웃 묶음의
    // 같은 쪽 장이 드러난다. 뒷면에는 이웃 묶음의 반대쪽 장이 인쇄된다.
    // 한 장 보기: 아래에 이웃 장이 통째로 드러나고 뒷면은 없다.
    final dual = cur.length == 2;
    final under = <({Rect rect, int page})>[];
    RenderRepaintBoundary? backBoundary;
    int? backPage;
    Rect? backRect;
    if (dual) {
      final stayingSlot = forward ? 0 : 1;
      under.add((rect: slotRects[stayingSlot], page: cur[stayingSlot]));
      if (neighbour.length == 2) {
        under.add((rect: slotRects[turningSlot], page: neighbour[turningSlot]));
        backBoundary = _boundary(neighbourIndex, stayingSlot);
        backPage = neighbour[stayingSlot];
        backRect = slotRects[stayingSlot];
      }
    } else {
      under.add((rect: slotRects[0], page: neighbour[0]));
    }

    // 느리게 끌면 화면이 안 바뀌어 프레임이 멈추고, 스냅샷도 그때까지 기다린다.
    // setState 로 프레임을 하나 돌려 바로 완료되게 한다.
    setState(() => _preparing = true);
    final gen = ++_turnGen;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final rect = rectOf(front);

    // 앞면과 뒷면을 한꺼번에 요청한다. 차례로 뜨면 둘째 스냅샷이 다음
    // 프레임까지 기다려 느린 끌기에서 장이 늦게 나타난다. 스냅샷은 플랫폼
    // 뷰(PencilKit)가 섞이면 실패할 수 있어, 그때는 캐시의 페이지 이미지로
    // 대신하고 무슨 일인지 로그에 남긴다.
    Future<ui.Image?> snap(RenderRepaintBoundary b, String what) async {
      try {
        return await b.toImage(pixelRatio: dpr);
      } on Object catch (e, st) {
        debugPrint('종이 넘김: $what 스냅샷 실패, 캐시로 대신한다. $e\n$st');
        return null;
      }
    }

    final canBack =
        backBoundary != null && backPage != null && backRect != null;
    final snaps = await Future.wait([
      snap(front, '앞면'),
      if (canBack && backBoundary.attached) snap(backBoundary, '뒷면'),
    ]);

    var image = snaps[0];
    image ??= await _renderFromCache(cur[turningSlot], rect, dpr);

    ui.Image? back;
    if (canBack) {
      back = snaps.length > 1 ? snaps[1] : null;
      back ??= await _renderFromCache(backPage, backRect, dpr);
    }

    if (!mounted || gen != _turnGen || !_curl || image == null) {
      image?.dispose();
      back?.dispose();
      if (mounted && gen == _turnGen) {
        _preparing = false;
        if (image == null && auto) _jump(dir);
      }
      return;
    }
    final grabY = at?.dy ?? rect.bottom;
    final turn = _PageTurn(
      dir: dir,
      image: image,
      back: back,
      rect: rect,
      corner: Offset(
        forward ? rect.right : rect.left,
        grabY < rect.center.dy ? rect.top : rect.bottom,
      ),
      under: under,
    );
    if (at != null) turn.finger = turn.clamp(_latestDrag ?? at);

    setState(() {
      _preparing = false;
      _turn = turn;
    });
    if (auto) _settleTurn(commit: true);
  }

  /// 스냅샷 없이 바로 옆 묶음으로 간다. 넘김을 그릴 수 없을 때의 대비다.
  void _jump(_TurnDir dir) {
    setState(() => _spread += dir == _TurnDir.forward ? 1 : -1);
    _resetZoom();
  }

  void _settleTurn({required bool commit}) {
    final turn = _turn;
    if (turn == null) return;
    _settleCommit = commit;
    _settleFrom = turn.finger;
    _settleTo = commit ? turn.away : turn.corner;
    // 남은 거리만큼만 걸린다. 거의 다 넘긴 장이 느리게 마무리되면 답답하다.
    final remaining = (_settleTo! - _settleFrom!).distance / turn.rect.width;
    _settle.duration = Duration(
      milliseconds: (remaining * 420).clamp(140, 420).round(),
    );
    _settle.forward(from: 0);
  }

  void _onSettleTick() {
    final turn = _turn;
    final from = _settleFrom;
    final to = _settleTo;
    if (turn == null || from == null || to == null) return;
    final t = Curves.easeOutCubic.transform(_settle.value);
    setState(() => turn.finger = Offset.lerp(from, to, t)!);
  }

  void _onSettleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final turn = _turn;
    if (turn == null) return;
    setState(() {
      _turn = null;
      if (_settleCommit) {
        _spread += turn.dir == _TurnDir.forward ? 1 : -1;
      }
    });
    // 방금 그린 프레임이 아직 이 이미지를 쓴다. 한 프레임 뒤에 버린다.
    WidgetsBinding.instance.addPostFrameCallback((_) => turn.dispose());
    if (_settleCommit) {
      _resetZoom();
      widget.onPageChanged(widget.map.firstPageOf(_spread));
    }
    // 넘기는 동안 보류한 바깥 변경이 있으면 이제 따라간다. 부모가 새 쪽으로
    // 다시 그린 뒤에 봐야 하므로 한 프레임 뒤에 한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_curl || _turn != null || _preparing) return;
      final target = widget.map.spreadOf(widget.pageIndex);
      if (target != _spread) _turnTo(target);
    });
  }

  void _cancelTurn() {
    _turnGen++;
    _preparing = false;
    _settle.stop();
    final turn = _turn;
    if (turn == null) return;
    _turn = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => turn.dispose());
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
  /// 넘김 효과는 밀기 하나만 쓴다. 쌓기는 묶음 전체가 갈리는 것을 전제로
  /// 만든 것이라 이어진 띠와 맞지 않는다. 넘기기는 _buildCurl 이 맡는다.
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
        // 종이 넘김은 _buildCurl 이 따로 그린다. 여기로는 오지 않는다.
        return child;
    }
  }
}

enum _TurnDir { forward, backward }

/// 넘어가는 중인 장 하나.
///
/// [corner] 는 잡은 모서리다. 앞으로 넘길 때는 오른쪽, 되돌릴 때는 왼쪽
/// 모서리이고 반대쪽 변이 책등이다. [finger] 는 그 모서리가 지금 와 있는
/// 자리다. 두 방향의 기하는 좌우가 뒤집혔을 뿐 같다.
class _PageTurn {
  _PageTurn({
    required this.dir,
    required this.image,
    required this.back,
    required this.rect,
    required this.corner,
    required this.under,
  }) : finger = corner;

  final _TurnDir dir;
  final ui.Image image;
  final ui.Image? back;

  /// 넘어가는 장이 화면에서 차지하는 자리.
  final Rect rect;
  final Offset corner;
  Offset finger;

  /// 접힌 장 아래에 보일 장들과 그 자리.
  final List<({Rect rect, int page})> under;

  bool get _forward => dir == _TurnDir.forward;

  /// 책등. 잡은 모서리의 반대쪽 변이다.
  double get _spineX => _forward ? rect.left : rect.right;

  /// 다 넘어간 자리. 책등 너머로 한 폭만큼 나가야 접히는 선이 책등에 닿는다.
  Offset get away => Offset(
    _forward ? rect.left - rect.width : rect.right + rect.width,
    corner.dy,
  );

  Offset get _spineSameRow => Offset(_spineX, corner.dy);
  Offset get _spineOtherRow =>
      Offset(_spineX, corner.dy == rect.top ? rect.bottom : rect.top);

  /// 손가락 자리를 종이가 찢어지지 않는 범위로 붙든다.
  ///
  /// 종이는 책등에 묶여 있어 모서리가 같은 줄 책등 모서리에서 폭보다,
  /// 반대 줄 모서리에서 대각선보다 멀리 갈 수 없다.
  Offset clamp(Offset p) {
    var q = Offset(
      _forward
          ? p.dx.clamp(rect.left - rect.width, rect.right - 0.5)
          : p.dx.clamp(rect.left + 0.5, rect.right + rect.width),
      p.dy.clamp(rect.top, rect.bottom),
    );
    q = _within(q, _spineSameRow, rect.width);
    q = _within(q, _spineOtherRow, (rect.bottomRight - rect.topLeft).distance);
    return q;
  }

  static Offset _within(Offset p, Offset center, double radius) {
    final d = p - center;
    final len = d.distance;
    if (len <= radius) return p;
    return center + d / len * radius;
  }

  /// 접히는 선이 장 가운데를 책등 쪽으로 지났는지. 지났으면 반 넘게 넘어간 것이다.
  bool get pastHalf {
    final mid = (corner.dx + finger.dx) / 2;
    return _forward ? mid < rect.center.dx : mid > rect.center.dx;
  }

  void dispose() {
    image.dispose();
    back?.dispose();
  }
}

class _Spread extends StatelessWidget {
  const _Spread({
    super.key,
    required this.session,
    required this.pages,
    this.overlayBuilder,
    this.pageKeys,
  });

  final ScoreSession session;
  final List<int> pages;
  final PageOverlayBuilder? overlayBuilder;

  /// 주어지면 장마다 꼭 맞는 RepaintBoundary 를 두른다. 종이 넘김이
  /// 그 경계로 스냅샷을 뜨고 자리를 잰다. 여백까지 접히면 안 된다.
  final List<Key>? pageKeys;

  Widget _page(int slot) {
    final view = ScorePageView(
      session: session,
      page: session.pages[pages[slot]],
      overlayBuilder: overlayBuilder,
    );
    final key = pageKeys?[slot];
    return key == null ? view : RepaintBoundary(key: key, child: view);
  }

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return const SizedBox.shrink();

    if (pages.length == 1) return Center(child: _page(0));

    // 두 장에 꼭 맞게 줄어들어야 경계가 여백을 품지 않는다.
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < pages.length; i++) Flexible(child: _page(i)),
        ],
      ),
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
