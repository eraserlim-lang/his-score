import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/i18n/tr.dart';
import '../../../../core/layout/page_preview_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/page_render_cache.dart';
import '../../data/score_session.dart';

/// 페이지 위에 겹쳐 그릴 것을 만드는 콜백. 필기 층과 점프 버튼이 쓴다.
typedef PageOverlayBuilder = Widget Function(
  BuildContext context,
  ViewPage page,
  Size pageSize,
);

/// 페이지 한 장을 그린다.
///
/// 이미 구워진 이미지가 있으면 첫 프레임부터 그대로 그린다. 넘김 순간에
/// 빈 화면이 스치지 않게 하는 것이 이 위젯의 존재 이유다.
class ScorePageView extends StatefulWidget {
  const ScorePageView({
    super.key,
    required this.session,
    required this.page,
    this.overlayBuilder,
  });

  final ScoreSession session;
  final ViewPage page;
  final PageOverlayBuilder? overlayBuilder;

  /// 종이 둘레에 두는 틈. 장과 장 사이, 그리고 화면 가장자리와의 사이다.
  /// 가장자리 선과 함께 밝은 테마에서도 장이 어디서 끝나는지 보이게 한다.
  static const gap = 3.0;

  @override
  State<ScorePageView> createState() => _ScorePageViewState();
}

class _ScorePageViewState extends State<ScorePageView> {
  /// 캐시가 든 이미지의 복제 핸들.
  ///
  /// 캐시는 자리가 차거나 세션이 닫히면 제 이미지를 버린다. 그 이미지를 그대로
  /// 빌려 쓰면 화면에 걸린 채로 죽어 검게 나온다. 크롭을 저장해 세션을 다시
  /// 열 때가 그랬다. 복제 핸들은 이 위젯이 버릴 때까지 살아 있다.
  ui.Image? _image;
  PageRenderKey? _requested;

  /// 훑는 동안 청한 거친 굽기 중 아직 오지 않은 것. 다른 쪽으로 넘어가면
  /// 거둬 줄을 비운다. 그래야 일꾼이 손가락이 멈춘 쪽을 곧장 굽는다.
  PageRenderKey? _coarsePending;

  /// 훑는 동안 굽는 비율. 한 장을 이만큼의 폭으로 구우면 넓이는 1/11 이다.
  /// 어느 쪽인지 알아볼 만큼은 보인다.
  static const _coarseScale = 0.3;

  void _cancelCoarse(ScorePageView owner) {
    final key = _coarsePending;
    if (key == null) return;
    _coarsePending = null;
    owner.session.cacheFor(owner.page).cancel(key);
  }

  @override
  void didUpdateWidget(ScorePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다른 페이지를 그리게 되면 이전 이미지를 잡고 있으면 안 된다.
    if (oldWidget.page.sourcePageNumber != widget.page.sourcePageNumber ||
        oldWidget.page.docIndex != widget.page.docIndex) {
      _cancelCoarse(oldWidget);
      _hold(null);
      _requested = null;
    } else if (!identical(oldWidget.session, widget.session)) {
      // 같은 페이지지만 세션이 새로 열렸다. 새 캐시에서 다시 받는다.
      // 그동안은 들고 있던 복제본을 그대로 보여 줘 깜빡이지 않게 한다.
      _requested = null;
    }
  }

  @override
  void dispose() {
    _cancelCoarse(widget);
    _hold(null);
    super.dispose();
  }

  /// 캐시 이미지의 복제 핸들로 바꿔 든다. 들고 있던 것은 버린다.
  void _hold(ui.Image? source) {
    ui.Image? next;
    try {
      next = source?.clone();
    } on Object {
      // 받는 사이에 캐시가 이미 버렸다. 다음 build 에서 다시 요청한다.
      next = null;
      _requested = null;
    }
    _image?.dispose();
    _image = next;
  }

  void _ensure(double targetWidth, {required bool preview}) {
    if (widget.page.isBlank) return;
    final cache = widget.session.cacheFor(widget.page);
    final number = widget.page.sourcePageNumber;
    final full = PageRenderKey.forWidth(number, targetWidth);

    // 훑는 중에는 거칠게 굽는다. 제 해상도로 구운 것이 이미 있으면 그걸 쓴다.
    final coarse = preview && cache.peek(full) == null;
    final key = coarse
        ? PageRenderKey.forWidth(
            number,
            math.max(256.0, targetWidth * _coarseScale),
          )
        : full;
    if (key == _requested) return;

    // 손을 놓아 제 해상도로 돌아왔다. 아직 오지 않은 거친 판은 거둔다.
    // 들고 있던 거친 그림은 제 그림이 올 때까지 그대로 보여 준다.
    if (!coarse) _cancelCoarse(widget);
    _requested = key;

    final cached = cache.peek(key);
    if (cached != null) {
      // 같은 프레임 안에서 바로 그린다. setState 로 미루면 한 프레임 깜빡인다.
      _hold(cached);
      return;
    }

    if (coarse) _coarsePending = key;
    cache.render(key).then((image) {
      if (_coarsePending == key) _coarsePending = null;
      if (!mounted || _requested != key) return;
      if (image == null) {
        // 굽기에 실패했거나 세션이 닫혔다. 다음 build 에서 다시 요청하게 둔다.
        _requested = null;
        return;
      }
      setState(() => _hold(image));
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = PagePreviewScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final logicalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        // 잘라낸 뒤의 폭이 화면을 채우므로, 원본은 그보다 크게 구워야 한다.
        final targetWidth = logicalWidth * dpr / widget.page.crop.width;

        _ensure(targetWidth, preview: preview);

        final image = _image;
        final Widget body;
        if (widget.page.isBlank) {
          body = const ColoredBox(color: Colors.white);
        } else if (image == null) {
          body = const ColoredBox(
            color: Colors.white,
            child: Center(
              child: SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        } else {
          body = CustomPaint(
            painter: PagePainter(
              image: image,
              crop: widget.page.crop,
              rotation: widget.page.rotation,
            ),
            size: Size.infinite,
          );
        }

        return Semantics(
          image: true,
          label: tr('악보 페이지 {0}', [widget.page.sourcePageNumber]),
          child: AspectRatio(
            aspectRatio: widget.page.aspectRatio,
            // 종이 가장자리를 그림 위에 얹는다. 자리를 차지하지 않아 페이지
            // 크기와 필기 좌표는 그대로다.
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: ViewerColors.pageEdge, width: 1),
              ),
              child: LayoutBuilder(
                builder: (context, inner) {
                  final size = Size(inner.maxWidth, inner.maxHeight);
                  final overlay = widget.overlayBuilder?.call(
                    context,
                    widget.page,
                    size,
                  );
                  if (overlay == null) return body;
                  return Stack(fit: StackFit.expand, children: [body, overlay]);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 구워진 페이지 이미지를 잘라내고 돌려 그린다.
///
/// 화면의 페이지가 쓰고, 종이 넘김이 스냅샷을 뜨지 못할 때 같은 모습을
/// 캐시 이미지로 다시 만드는 데도 쓴다.
class PagePainter extends CustomPainter {
  PagePainter({
    required this.image,
    required this.crop,
    required this.rotation,
  });

  final ui.Image image;
  final Rect crop;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTRB(
      crop.left * image.width,
      crop.top * image.height,
      crop.right * image.width,
      crop.bottom * image.height,
    );
    final dst = Offset.zero & size;

    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    if (rotation == 0) {
      canvas.drawImageRect(image, src, dst, paint);
      return;
    }

    canvas.save();
    canvas.clipRect(dst);
    canvas.drawRect(dst, Paint()..color = Colors.white);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation * math.pi / 180);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PagePainter old) =>
      old.image != image || old.crop != crop || old.rotation != rotation;
}
