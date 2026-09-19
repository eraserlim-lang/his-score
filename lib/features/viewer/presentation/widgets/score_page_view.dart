import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/i18n/tr.dart';
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

  @override
  void didUpdateWidget(ScorePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다른 페이지를 그리게 되면 이전 이미지를 잡고 있으면 안 된다.
    if (oldWidget.page.sourcePageNumber != widget.page.sourcePageNumber ||
        oldWidget.page.docIndex != widget.page.docIndex) {
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

  void _ensure(double targetWidth) {
    if (widget.page.isBlank) return;
    final key = PageRenderKey.forWidth(widget.page.sourcePageNumber, targetWidth);
    if (key == _requested) return;
    _requested = key;

    final cache = widget.session.cacheFor(widget.page);
    final cached = cache.peek(key);
    if (cached != null) {
      // 같은 프레임 안에서 바로 그린다. setState 로 미루면 한 프레임 깜빡인다.
      _hold(cached);
      return;
    }

    cache.render(key).then((image) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final logicalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        // 잘라낸 뒤의 폭이 화면을 채우므로, 원본은 그보다 크게 구워야 한다.
        final targetWidth = logicalWidth * dpr / widget.page.crop.width;

        _ensure(targetWidth);

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
            painter: _PagePainter(
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
          child: LayoutBuilder(
            builder: (context, inner) {
              final size = Size(inner.maxWidth, inner.maxHeight);
              final overlay = widget.overlayBuilder?.call(
                context,
                widget.page,
                size,
              );
              if (overlay == null) return body;
              return Stack(
                fit: StackFit.expand,
                children: [body, overlay],
              );
            },
          ),
          ),
        );
      },
    );
  }
}

class _PagePainter extends CustomPainter {
  _PagePainter({
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
  bool shouldRepaint(_PagePainter old) =>
      old.image != image || old.crop != crop || old.rotation != rotation;
}
