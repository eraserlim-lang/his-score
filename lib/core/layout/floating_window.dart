import 'package:flutter/material.dart';

import '../i18n/tr.dart';

/// 화면 위에 떠 있는 작은 창.
///
/// 아이패드는 앱이 OS 창을 따로 띄울 수 없다. 그래서 앱 화면 위에 얹어
/// 악보를 보면서 도구를 쓸 수 있게 한다. 제목 줄을 끌어 옮기고, 오른쪽
/// 아래 모서리를 끌어 크기를 바꾸고, 접어 두면 제목 줄만 남는다.
void showFloatingWindow({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context, VoidCallback close) builder,
  Size initialSize = const Size(440, 380),

  /// 내용이 창보다 길면 스크롤할지. 안쪽에서 남은 높이를 직접 나눠 쓰는
  /// 화면(Expanded 를 쓰는 것들)은 꺼야 한다.
  bool scrollable = true,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _FloatingWindow(
      title: title,
      initialSize: initialSize,
      scrollable: scrollable,
      builder: builder,
      onClose: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _FloatingWindow extends StatefulWidget {
  const _FloatingWindow({
    required this.title,
    required this.initialSize,
    required this.scrollable,
    required this.builder,
    required this.onClose,
  });

  final String title;
  final Size initialSize;
  final bool scrollable;
  final Widget Function(BuildContext context, VoidCallback close) builder;
  final VoidCallback onClose;

  @override
  State<_FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<_FloatingWindow> {
  static const _minWidth = 280.0;
  static const _minHeight = 140.0;
  static const _titleBarHeight = 44.0;

  /// 아직 끌지 않았으면 null. 그동안은 화면 크기를 보고 자리를 잡는다.
  Offset? _pos;
  late Size _size = widget.initialSize;
  bool _collapsed = false;

  Offset _startPos(Size screen, EdgeInsets pad) => Offset(
        (screen.width - _size.width - 16).clamp(0.0, double.infinity),
        pad.top + 16,
      );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);

    final width = _size.width
        .clamp(_minWidth, (screen.width - 16).clamp(_minWidth, double.infinity));
    final height = _size.height.clamp(
      _minHeight,
      (screen.height - pad.top - 80).clamp(_minHeight, double.infinity),
    );

    final pos = _pos ?? _startPos(screen, pad);
    final x = pos.dx.clamp(0.0, (screen.width - width).clamp(0.0, double.infinity));
    final y = pos.dy
        .clamp(0.0, (screen.height - _titleBarHeight - 8).clamp(0.0, double.infinity));

    return Positioned(
      left: x,
      top: y,
      width: width,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _titleBar(),
            if (!_collapsed)
              SizedBox(
                height: height,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                      child: widget.scrollable
                          ? SingleChildScrollView(
                              child: widget.builder(context, widget.onClose),
                            )
                          : widget.builder(context, widget.onClose),
                    ),
                    Positioned(right: 0, bottom: 0, child: _resizeGrip()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _titleBar() {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        _pos ??= _startPos(MediaQuery.sizeOf(context), MediaQuery.paddingOf(context));
      },
      onPanUpdate: (d) => setState(() => _pos = _pos! + d.delta),
      child: Container(
        height: _titleBarHeight,
        color: scheme.surfaceContainerHighest,
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            Icon(Icons.drag_indicator, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              tooltip: _collapsed ? tr('펼치기') : tr('접기'),
              icon: Icon(_collapsed ? Icons.expand_more : Icons.expand_less),
              onPressed: () => setState(() => _collapsed = !_collapsed),
            ),
            IconButton(
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              tooltip: tr('닫기'),
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }

  /// 오른쪽 아래 모서리를 끌어 크기를 바꾼다.
  ///
  /// 아이패드가 화면 속 창에 쓰는 모양을 따랐다. 모서리에 붙은 반원 위에
  /// 짧은 빗금이 있고, 끌 수 있는 자리라는 것을 그 모양만으로 알린다.
  Widget _resizeGrip() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => setState(() {
        _size = Size(_size.width + d.delta.dx, _size.height + d.delta.dy);
      }),
      child: SizedBox(
        width: 34,
        height: 34,
        child: CustomPaint(
          painter: _ResizeGripPainter(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            background: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 아래 모서리의 반원 손잡이.
class _ResizeGripPainter extends CustomPainter {
  _ResizeGripPainter({required this.color, required this.background});

  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    // 모서리에 중심을 둔 반원. 창 밖으로 나가는 쪽은 잘려 보이지 않는다.
    final corner = Offset(size.width, size.height);
    canvas.drawCircle(
      corner,
      size.width * 0.82,
      Paint()..color = background.withValues(alpha: 0.9),
    );

    final line = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // 모서리와 나란한 짧은 빗금 두 줄.
    for (final inset in [9.0, 16.0]) {
      canvas.drawLine(
        Offset(size.width - inset, size.height - 3),
        Offset(size.width - 3, size.height - inset),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_ResizeGripPainter old) =>
      old.color != color || old.background != background;
}
