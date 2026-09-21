import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/ink_models.dart';
import '../domain/stamps.dart';

/// 정규화 좌표(원본 페이지 0~1)와 위젯 좌표 사이의 변환.
///
/// 위젯은 크롭된 영역만 보여주므로 크롭 사각형을 알아야 한다.
class InkTransform {
  const InkTransform({
    required this.size,
    required this.crop,
    this.rotation = 0,
    this.scaleOverride,
  });

  /// 위젯(크롭된 페이지가 그려지는 영역)의 크기.
  final Size size;
  final Rect crop;
  final double rotation;

  /// 미리보기처럼 작은 상자에 그릴 때 굵기 배율을 직접 준다.
  final double? scaleOverride;

  /// 페이지 폭 1000 기준 굵기를 위젯 픽셀로 바꿀 때 쓰는 배율.
  double get scale => scaleOverride ?? size.width / crop.width / 1000;

  Offset toWidget(double nx, double ny) => _rotate(
    Offset(
      (nx - crop.left) / crop.width * size.width,
      (ny - crop.top) / crop.height * size.height,
    ),
    rotation,
  );

  Offset toNormalized(Offset widget) {
    final w = _rotate(widget, -rotation);
    return Offset(
      w.dx / size.width * crop.width + crop.left,
      w.dy / size.height * crop.height + crop.top,
    );
  }

  /// 위젯 픽셀 반지름을 정규화 반지름으로. 가로 기준으로 잡는다.
  double toNormalizedRadius(double px) => px / size.width * crop.width;

  Offset _rotate(Offset p, double degrees) {
    if (degrees == 0) return p;
    final c = Offset(size.width / 2, size.height / 2);
    final rad = degrees * math.pi / 180;
    final d = p - c;
    return c +
        Offset(
          d.dx * math.cos(rad) - d.dy * math.sin(rad),
          d.dx * math.sin(rad) + d.dy * math.cos(rad),
        );
  }
}

/// 필기를 그린다. 뷰어에서도, 내보내기에서도 같은 코드로 그린다.
class InkPainter extends CustomPainter {
  InkPainter({
    required this.ink,
    required this.crop,
    this.rotation = 0,
    this.liveStroke,
    this.selectedPlacedId,
    this.eraserCursor,
    this.eraserRadius = 0,
  });

  final PageInk ink;
  final Rect crop;
  final double rotation;

  /// 지금 긋는 중인 획. 아직 확정되지 않았다.
  final Stroke? liveStroke;
  final String? selectedPlacedId;
  final Offset? eraserCursor;
  final double eraserRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final t = InkTransform(size: size, crop: crop, rotation: rotation);

    // 획과 개체를 그린 순서대로 겹친다.
    final items = <(int, Object)>[
      for (final s in ink.strokes) (s.sortOrder, s),
      for (final p in ink.placed) (p.sortOrder, p),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    for (final (_, item) in items) {
      if (item is Stroke) {
        paintStroke(canvas, item, t);
      } else if (item is PlacedAnnotation) {
        paintPlaced(canvas, item, t, selected: item.id == selectedPlacedId);
      }
    }

    if (liveStroke != null) paintStroke(canvas, liveStroke!, t);

    if (eraserCursor != null && eraserRadius > 0) {
      canvas.drawCircle(
        eraserCursor!,
        eraserRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black54,
      );
    }
  }

  static void paintStroke(Canvas canvas, Stroke stroke, InkTransform t) {
    if (stroke.points.isEmpty) return;
    if (stroke.isShape) {
      _paintShape(canvas, stroke, t);
      return;
    }

    final preset = stroke.preset;
    final color = stroke.color.withValues(alpha: stroke.color.a * preset.alpha);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = preset == PenPreset.marker
          ? StrokeCap.square
          : StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    if (stroke.points.length == 1) {
      final p = stroke.points.first;
      canvas.drawCircle(
        t.toWidget(p.x, p.y),
        preset.widthFor(p.pressure, stroke.width) * t.scale / 2,
        Paint()..color = color,
      );
      return;
    }

    if (!preset.pressureSensitive) {
      // 굵기가 일정하면 경로 하나로 그린다. 훨씬 빠르다.
      paint.strokeWidth = preset.widthFor(0.5, stroke.width) * t.scale;
      canvas.drawPath(_smoothPath(stroke.points, t), paint);
      return;
    }

    // 압력에 따라 구간별 굵기를 바꾼다. 붓 느낌은 여기서 난다.
    for (var i = 1; i < stroke.points.length; i++) {
      final a = stroke.points[i - 1];
      final b = stroke.points[i];
      final pressure = (a.pressure + b.pressure) / 2;
      paint.strokeWidth = preset.widthFor(pressure, stroke.width) * t.scale;
      canvas.drawLine(t.toWidget(a.x, a.y), t.toWidget(b.x, b.y), paint);
    }
  }

  /// 점을 이차 베지어로 이어 손떨림을 눌러준다.
  static Path _smoothPath(List<InkPoint> points, InkTransform t) {
    final path = Path();
    final first = t.toWidget(points.first.x, points.first.y);
    path.moveTo(first.dx, first.dy);
    if (points.length == 2) {
      final last = t.toWidget(points.last.x, points.last.y);
      path.lineTo(last.dx, last.dy);
      return path;
    }
    for (var i = 1; i < points.length - 1; i++) {
      final p0 = t.toWidget(points[i].x, points[i].y);
      final p1 = t.toWidget(points[i + 1].x, points[i + 1].y);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    final last = t.toWidget(points.last.x, points.last.y);
    path.lineTo(last.dx, last.dy);
    return path;
  }

  static void _paintShape(Canvas canvas, Stroke stroke, InkTransform t) {
    if (stroke.points.length < 2) return;
    final a = t.toWidget(stroke.points.first.x, stroke.points.first.y);
    final b = t.toWidget(stroke.points.last.x, stroke.points.last.y);
    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * stroke.width * t.scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (stroke.shape ?? ShapeKind.line) {
      case ShapeKind.line:
        canvas.drawLine(a, b, paint);
      case ShapeKind.arrow:
        canvas.drawLine(a, b, paint);
        _arrowHead(canvas, a, b, paint, 12 * stroke.width * t.scale * 1.5);
      case ShapeKind.rect:
        canvas.drawRect(Rect.fromPoints(a, b), paint);
      case ShapeKind.ellipse:
        canvas.drawOval(Rect.fromPoints(a, b), paint);
      case ShapeKind.staff:
        final rect = Rect.fromPoints(a, b);
        for (var i = 0; i < 5; i++) {
          final y = rect.top + rect.height * i / 4;
          canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
        }
      case ShapeKind.crescendo:
        final rect = Rect.fromPoints(a, b);
        final tip = Offset(rect.left, rect.center.dy);
        canvas.drawLine(tip, rect.topRight, paint);
        canvas.drawLine(tip, rect.bottomRight, paint);
      case ShapeKind.decrescendo:
        final rect = Rect.fromPoints(a, b);
        final tip = Offset(rect.right, rect.center.dy);
        canvas.drawLine(rect.topLeft, tip, paint);
        canvas.drawLine(rect.bottomLeft, tip, paint);
    }
  }

  static void _arrowHead(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
    double size,
  ) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const spread = math.pi / 7;
    final p1 =
        to - Offset(math.cos(angle - spread), math.sin(angle - spread)) * size;
    final p2 =
        to - Offset(math.cos(angle + spread), math.sin(angle + spread)) * size;
    canvas.drawLine(to, p1, paint);
    canvas.drawLine(to, p2, paint);
  }

  static void paintPlaced(
    Canvas canvas,
    PlacedAnnotation item,
    InkTransform t, {
    bool selected = false,

    /// 주면 글자가 이 폭을 넘지 않게 줄여 그린다. 팔레트의 네모 칸처럼
    /// 자리가 정해진 곳에서 쓴다. 악보 위에 찍을 때는 주지 않는다.
    double? maxWidth,
  }) {
    final center = t.toWidget(item.x, item.y);
    final base = (item.fontSize ?? 28) * item.scale * t.scale;
    Rect bounds;

    if (item.kind == PlacedKind.text) {
      bounds = _paintText(
        canvas,
        item.value,
        center,
        base,
        item.color,
        italic: false,
        maxWidth: maxWidth,
      );
    } else {
      final def = findStamp(item.value);
      if (def == null) {
        bounds = _paintText(
          canvas,
          '?',
          center,
          base,
          item.color,
          italic: false,
          maxWidth: maxWidth,
        );
      } else if (def.glyph != null) {
        bounds = _paintText(
          canvas,
          def.glyph!,
          center,
          base,
          item.color,
          italic: def.italic,
          serif: true,
          maxWidth: maxWidth,
        );
      } else {
        bounds = StampPainter.paint(canvas, def.id, center, base, item.color);
      }
      if (item.boxed) bounds = _paintBox(canvas, bounds, base, item.color);
    }

    if (selected) {
      canvas.drawRect(
        bounds.inflate(4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.blueAccent,
      );
    }
  }

  /// 스탬프 둘레에 네모를 두른다. 인쇄 악보의 리허설 마크 모양이다.
  ///
  /// 한 글자면 정사각형으로 맞추고, 높이는 글자 크기로만 정한다. 'A' 와
  /// 'Chorus' 를 나란히 찍어도 상자 높이가 같아 가지런하다.
  static Rect _paintBox(Canvas canvas, Rect inner, double size, Color color) {
    final pad = size * 0.16;
    final height = inner.height + pad * 2;
    final width = math.max(inner.width + pad * 2, height);
    final box = Rect.fromCenter(
      center: inner.center,
      width: width,
      height: height,
    );
    canvas.drawRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size * 0.07)
        ..color = color,
    );
    return box;
  }

  static Rect _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color, {
    required bool italic,
    bool serif = false,
    double? maxWidth,
  }) {
    // 먼저 한 번 재어 보고 넘치면 그만큼 줄인다. 'cresc.' 나 'Chorus' 처럼
    // 긴 글자가 네모 칸 밖으로 삐져나오던 것을 막는다.
    var size = fontSize;
    if (maxWidth != null) {
      final probe = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            fontWeight: serif ? FontWeight.w600 : FontWeight.w500,
            fontFamily: serif ? 'serif' : null,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (probe.width > maxWidth) size = fontSize * maxWidth / probe.width;
    }

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          fontWeight: serif ? FontWeight.w600 : FontWeight.w500,
          fontFamily: serif ? 'serif' : null,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    final topLeft = center - Offset(painter.width / 2, painter.height / 2);
    painter.paint(canvas, topLeft);
    return topLeft & painter.size;
  }

  /// 내보내기용. 페이지 비트맵 위에 필기를 얹어 새 이미지로 만든다.
  static Future<ui.Image> composite(
    ui.Image page,
    PageInk ink, {
    Rect crop = const Rect.fromLTRB(0, 0, 1, 1),
    double rotation = 0,
  }) async {
    final recorder = ui.PictureRecorder();
    final size = Size(page.width.toDouble(), page.height.toDouble());
    final canvas = Canvas(recorder);
    canvas.drawImage(page, Offset.zero, Paint());
    InkPainter(ink: ink, crop: crop, rotation: rotation).paint(canvas, size);
    return recorder.endRecording().toImage(page.width, page.height);
  }

  @override
  bool shouldRepaint(InkPainter old) =>
      old.ink != ink ||
      old.liveStroke != liveStroke ||
      old.crop != crop ||
      old.rotation != rotation ||
      old.selectedPlacedId != selectedPlacedId ||
      old.eraserCursor != eraserCursor;
}

/// 글자로 못 그리는 스탬프를 직접 그린다.
abstract final class StampPainter {
  /// 그린 영역을 돌려준다. 선택 표시에 쓴다.
  static Rect paint(Canvas canvas, String id, Offset c, double s, Color color) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final fill = Paint()..color = color;
    final r = s / 2;

    switch (id) {
      case 'accent':
        final path = Path()
          ..moveTo(c.dx - r * 0.8, c.dy - r * 0.5)
          ..lineTo(c.dx + r * 0.8, c.dy)
          ..lineTo(c.dx - r * 0.8, c.dy + r * 0.5);
        canvas.drawPath(path, stroke);
      case 'staccato':
        canvas.drawCircle(c, s * 0.12, fill);
      case 'tenuto':
        canvas.drawLine(
          Offset(c.dx - r * 0.7, c.dy),
          Offset(c.dx + r * 0.7, c.dy),
          stroke,
        );
      case 'marcato':
        final path = Path()
          ..moveTo(c.dx - r * 0.6, c.dy + r * 0.5)
          ..lineTo(c.dx, c.dy - r * 0.6)
          ..lineTo(c.dx + r * 0.6, c.dy + r * 0.5);
        canvas.drawPath(path, stroke);
      case 'fermata':
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(c.dx, c.dy + r * 0.3),
            radius: r * 0.8,
          ),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawCircle(Offset(c.dx, c.dy + r * 0.1), s * 0.1, fill);
      case 'breath':
        final path = Path()
          ..moveTo(c.dx - r * 0.2, c.dy + r * 0.6)
          ..quadraticBezierTo(
            c.dx + r * 0.3,
            c.dy,
            c.dx + r * 0.1,
            c.dy - r * 0.7,
          );
        canvas.drawPath(path, stroke);
      case 'caesura':
        canvas.drawLine(
          Offset(c.dx - r * 0.5, c.dy + r * 0.7),
          Offset(c.dx, c.dy - r * 0.7),
          stroke,
        );
        canvas.drawLine(
          Offset(c.dx, c.dy + r * 0.7),
          Offset(c.dx + r * 0.5, c.dy - r * 0.7),
          stroke,
        );
      case 'mordent':
        final path = Path()..moveTo(c.dx - r * 0.9, c.dy);
        for (var i = 0; i < 4; i++) {
          final x0 = c.dx - r * 0.9 + r * 0.45 * i;
          path.lineTo(x0 + r * 0.225, c.dy - r * 0.4 * (i.isEven ? 1 : -1));
        }
        path.lineTo(c.dx + r * 0.9, c.dy);
        canvas.drawPath(path, stroke);
        canvas.drawLine(
          Offset(c.dx, c.dy - r * 0.7),
          Offset(c.dx, c.dy + r * 0.7),
          stroke,
        );
      case 'turn':
        final path = Path()
          ..moveTo(c.dx - r * 0.9, c.dy + r * 0.3)
          ..cubicTo(
            c.dx - r * 0.9,
            c.dy - r * 0.6,
            c.dx - r * 0.1,
            c.dy - r * 0.6,
            c.dx,
            c.dy,
          )
          ..cubicTo(
            c.dx + r * 0.1,
            c.dy + r * 0.6,
            c.dx + r * 0.9,
            c.dy + r * 0.6,
            c.dx + r * 0.9,
            c.dy - r * 0.3,
          );
        canvas.drawPath(path, stroke);
      case 'downbow':
        final rect = Rect.fromCenter(
          center: c,
          width: r * 1.2,
          height: r * 0.9,
        );
        canvas.drawRect(
          Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + r * 0.3),
          fill,
        );
        canvas.drawLine(rect.bottomLeft, rect.topLeft, stroke);
        canvas.drawLine(rect.bottomRight, rect.topRight, stroke);
      case 'upbow':
        final path = Path()
          ..moveTo(c.dx - r * 0.5, c.dy - r * 0.7)
          ..lineTo(c.dx, c.dy + r * 0.7)
          ..lineTo(c.dx + r * 0.5, c.dy - r * 0.7);
        canvas.drawPath(path, stroke);
      case 'whole':
        canvas.drawOval(
          Rect.fromCenter(center: c, width: r * 1.2, height: r * 0.8),
          stroke,
        );
      case 'half':
        canvas.save();
        canvas.translate(c.dx, c.dy + r * 0.4);
        canvas.rotate(-0.4);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 1.0,
            height: r * 0.65,
          ),
          stroke,
        );
        canvas.restore();
        canvas.drawLine(
          Offset(c.dx + r * 0.45, c.dy + r * 0.3),
          Offset(c.dx + r * 0.45, c.dy - r * 1.2),
          stroke,
        );
      case 'circle':
        canvas.drawCircle(c, r * 0.8, stroke);

      case 'dsharp':
        // 굵은 ×. 네 끝이 살짝 두꺼운 겹올림표 모양이다.
        final bold = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.16
          ..strokeCap = StrokeCap.square;
        canvas.drawLine(
          Offset(c.dx - r * 0.5, c.dy - r * 0.5),
          Offset(c.dx + r * 0.5, c.dy + r * 0.5),
          bold,
        );
        canvas.drawLine(
          Offset(c.dx + r * 0.5, c.dy - r * 0.5),
          Offset(c.dx - r * 0.5, c.dy + r * 0.5),
          bold,
        );

      case 'rest':
        // 4분쉼표. 위에서 아래로 꺾어 내려오다 끝에 갈고리가 붙는다.
        final path = Path()
          ..moveTo(c.dx - r * 0.25, c.dy - r * 0.75)
          ..lineTo(c.dx + r * 0.3, c.dy - r * 0.15)
          ..lineTo(c.dx - r * 0.25, c.dy + r * 0.2)
          ..cubicTo(
            c.dx + r * 0.45,
            c.dy + r * 0.15,
            c.dx + r * 0.1,
            c.dy + r * 0.7,
            c.dx - r * 0.35,
            c.dy + r * 0.8,
          );
        canvas.drawPath(path, stroke);

      case 'segno':
        // S 를 비스듬히 가로지르는 선과 양쪽 점.
        final path = Path()
          ..moveTo(c.dx + r * 0.55, c.dy - r * 0.45)
          ..cubicTo(
            c.dx + r * 0.1,
            c.dy - r * 0.95,
            c.dx - r * 0.6,
            c.dy - r * 0.5,
            c.dx - r * 0.1,
            c.dy,
          )
          ..cubicTo(
            c.dx + r * 0.6,
            c.dy + r * 0.5,
            c.dx - r * 0.1,
            c.dy + r * 0.95,
            c.dx - r * 0.55,
            c.dy + r * 0.45,
          );
        canvas.drawPath(path, stroke);
        canvas.drawLine(
          Offset(c.dx - r * 0.7, c.dy + r * 0.7),
          Offset(c.dx + r * 0.7, c.dy - r * 0.7),
          stroke,
        );
        canvas.drawCircle(
          Offset(c.dx - r * 0.55, c.dy - r * 0.35),
          s * 0.07,
          fill,
        );
        canvas.drawCircle(
          Offset(c.dx + r * 0.55, c.dy + r * 0.35),
          s * 0.07,
          fill,
        );

      case 'coda':
        // 동그라미를 열십자가 꿰뚫는다.
        canvas.drawOval(
          Rect.fromCenter(center: c, width: r * 1.1, height: r * 1.4),
          stroke,
        );
        canvas.drawLine(
          Offset(c.dx - r * 0.9, c.dy),
          Offset(c.dx + r * 0.9, c.dy),
          stroke,
        );
        canvas.drawLine(
          Offset(c.dx, c.dy - r * 0.95),
          Offset(c.dx, c.dy + r * 0.95),
          stroke,
        );

      case 'repeat':
        // 굵은 세로줄 + 가는 세로줄 + 점 둘. 도돌이표다.
        final thick = Paint()
          ..color = color
          ..strokeWidth = s * 0.14
          ..strokeCap = StrokeCap.butt;
        canvas.drawLine(
          Offset(c.dx - r * 0.65, c.dy - r * 0.8),
          Offset(c.dx - r * 0.65, c.dy + r * 0.8),
          thick,
        );
        canvas.drawLine(
          Offset(c.dx - r * 0.3, c.dy - r * 0.8),
          Offset(c.dx - r * 0.3, c.dy + r * 0.8),
          stroke,
        );
        canvas.drawCircle(
          Offset(c.dx + r * 0.25, c.dy - r * 0.3),
          s * 0.08,
          fill,
        );
        canvas.drawCircle(
          Offset(c.dx + r * 0.25, c.dy + r * 0.3),
          s * 0.08,
          fill,
        );

      case 'eye':
        // 안경. 눈여겨볼 곳에 붙인다.
        canvas.drawCircle(Offset(c.dx - r * 0.45, c.dy), r * 0.35, stroke);
        canvas.drawCircle(Offset(c.dx + r * 0.45, c.dy), r * 0.35, stroke);
        canvas.drawLine(
          Offset(c.dx - r * 0.1, c.dy),
          Offset(c.dx + r * 0.1, c.dy),
          stroke,
        );
        canvas.drawLine(
          Offset(c.dx - r * 0.8, c.dy - r * 0.1),
          Offset(c.dx - r * 0.95, c.dy - r * 0.35),
          stroke,
        );
        canvas.drawLine(
          Offset(c.dx + r * 0.8, c.dy - r * 0.1),
          Offset(c.dx + r * 0.95, c.dy - r * 0.35),
          stroke,
        );

      default:
        canvas.drawCircle(c, r * 0.5, stroke);
    }
    return Rect.fromCircle(center: c, radius: r);
  }
}
