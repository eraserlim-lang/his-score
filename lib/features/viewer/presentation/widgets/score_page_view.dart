import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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
  ui.Image? _image;
  PageRenderKey? _requested;

  @override
  void didUpdateWidget(ScorePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다른 페이지를 그리게 되면 이전 이미지를 잡고 있으면 안 된다.
    if (oldWidget.page.sourcePageNumber != widget.page.sourcePageNumber ||
        oldWidget.page.docIndex != widget.page.docIndex) {
      _image = null;
      _requested = null;
    }
  }

  @override
  void dispose() {
    // 이미지는 캐시가 소유하므로 여기서 dispose 하지 않는다.
    _image = null;
    super.dispose();
  }

  void _ensure(double targetWidth) {
    if (widget.page.isBlank) return;
    final key = PageRenderKey.forWidth(widget.page.sourcePageNumber, targetWidth);
    if (key == _requested && _image != null) return;
    _requested = key;

    final cache = widget.session.cacheFor(widget.page);
    final cached = cache.peek(key);
    if (cached != null) {
      // 같은 프레임 안에서 바로 그린다. setState 로 미루면 한 프레임 깜빡인다.
      _image = cached;
      return;
    }

    cache.render(key).then((image) {
      if (!mounted || _requested != key) return;
      setState(() => _image = image);
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

        return AspectRatio(
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
