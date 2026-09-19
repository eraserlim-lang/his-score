import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 종이 한 장을 손가락 자리까지 접어 넘긴 모습을 그린다.
///
/// [corner] 는 잡은 모서리, [finger] 는 그 모서리가 지금 와 있는 자리다.
/// 두 점의 수직이등분선이 접히는 선이다. 선 너머(모서리 쪽)는 접혀 넘어가
/// 선을 축으로 뒤집힌 자리에 뒷면이 보이고, 그 자리에 있던 아래 장이 드러난다.
///
/// 뒷면은 [back] 이 있으면 그 장이다. 책에서 오른쪽 장을 넘기면 그 뒷면이
/// 다음 펼침면의 왼쪽 장이듯, 넘어간 자리에 놓일 장을 뒷면에 인쇄해 둔다.
/// 다 넘어가는 순간 뒷면이 곧 새 장이라 화면이 튀지 않는다. 없으면 흰 종이에
/// 앞면이 옅게 비치는 뒷면을 그린다.
///
/// 종이의 곡면까지 흉내 내지는 않는다. 대신 접히는 선 양쪽에 그늘을 깔아
/// 종이가 들리며 휘는 느낌을 준다. 손가락이 움직일 때마다 다시 그리지만
/// 그리는 것은 이미지 두 번과 그라데이션 몇 개뿐이라 가볍다.
class PageCurlPainter extends CustomPainter {
  PageCurlPainter({
    required this.image,
    required this.rect,
    required this.corner,
    required this.finger,
    this.back,
  });

  /// 넘어가는 장의 스냅샷. [rect] 크기에 맞춰 그린다.
  final ui.Image image;

  /// 뒷면에 인쇄된 장. 넘어간 자리에 놓일 장이다.
  final ui.Image? back;

  /// 넘어가는 장이 화면에서 차지하는 자리.
  final Rect rect;

  final Offset corner;
  final Offset finger;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;

    final pull = corner - finger;
    final length = pull.distance;
    if (length < 1) {
      canvas.drawImageRect(image, src, rect, paint);
      return;
    }

    // 접히는 선: 모서리와 손가락의 수직이등분선. n 은 모서리 쪽을 가리킨다.
    final n = pull / length;
    final m = Offset((corner.dx + finger.dx) / 2, (corner.dy + finger.dy) / 2);

    final page = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    final stay = _clip(page, m, n, keepFront: true);
    final turned = _clip(page, m, n, keepFront: false);

    // 그늘 폭은 접힌 크기를 따른다. 조금 접혔을 때 넓은 그늘은 어색하다.
    final shade = (length * 0.22).clamp(10.0, 72.0);

    // 1) 아직 펼쳐져 있는 앞면.
    if (stay.length >= 3) {
      canvas.save();
      canvas.clipPath(_path(stay));
      canvas.drawImageRect(image, src, rect, paint);
      // 접히는 선 가까이는 종이가 들리며 그늘이 진다.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(m, m - n * shade, [
            const Color(0x40000000),
            const Color(0x00000000),
          ]),
      );
      canvas.restore();
    }

    if (turned.length < 3) return;

    // 2) 드러난 아래 장 위에 접힌 장이 드리우는 그림자.
    canvas.save();
    canvas.clipPath(_path(turned));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(m, m + n * (shade * 1.4), [
          const Color(0x55000000),
          const Color(0x00000000),
        ]),
    );
    canvas.restore();

    // 3) 접혀 넘어온 뒷면. 넘어간 조각을 접히는 선에 대칭시킨 자리다.
    final flipped = [for (final p in turned) _reflect(p, m, n)];
    final backPath = _path(flipped);

    final backImage = back;
    canvas.save();
    canvas.clipPath(backPath);
    canvas.transform(_reflection(m, n).storage);
    if (backImage != null) {
      // 뒷면 인쇄는 좌우가 뒤집혀 있어야 접힌 뒤에 바로 읽힌다.
      canvas.translate(rect.center.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-rect.center.dx, 0);
      final backSrc = Rect.fromLTWH(
        0,
        0,
        backImage.width.toDouble(),
        backImage.height.toDouble(),
      );
      canvas.drawImageRect(backImage, backSrc, rect, paint);
    } else {
      canvas.drawImageRect(image, src, rect, paint);
    }
    canvas.restore();

    canvas.save();
    canvas.clipPath(backPath);
    if (backImage == null) {
      // 종이 뒷면. 앞면 인쇄가 살짝 비친다.
      canvas.drawPath(backPath, Paint()..color = const Color(0xD9FFFFFF));
    }
    // 접히는 선 가까이가 굽으며 어두워진다. 끝으로 갈수록 밝다.
    canvas.drawRect(
      rect.inflate(rect.width),
      Paint()
        ..shader = ui.Gradient.linear(
          m,
          m - n * (shade * 1.6),
          [
            const Color(0x66000000),
            const Color(0x14000000),
            const Color(0x00000000),
          ],
          [0, 0.45, 1],
        ),
    );
    canvas.restore();
  }

  /// 다각형을 접히는 선으로 자른다. [keepFront] 가 참이면 손가락 쪽,
  /// 거짓이면 모서리 쪽을 남긴다.
  static List<Offset> _clip(
    List<Offset> poly,
    Offset m,
    Offset n, {
    required bool keepFront,
  }) {
    final out = <Offset>[];
    double side(Offset p) {
      final d = (p.dx - m.dx) * n.dx + (p.dy - m.dy) * n.dy;
      return keepFront ? -d : d;
    }

    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      final da = side(a);
      final db = side(b);
      if (da >= 0) out.add(a);
      if ((da >= 0) != (db >= 0)) {
        final t = da / (da - db);
        out.add(a + (b - a) * t);
      }
    }
    return out;
  }

  static Offset _reflect(Offset p, Offset m, Offset n) {
    final d = (p.dx - m.dx) * n.dx + (p.dy - m.dy) * n.dy;
    return p - n * (2 * d);
  }

  /// 접히는 선에 대한 대칭 변환. X' = X - 2((X-m)·n)n
  static Matrix4 _reflection(Offset m, Offset n) {
    final a = 1 - 2 * n.dx * n.dx;
    final b = -2 * n.dx * n.dy;
    final d = 1 - 2 * n.dy * n.dy;
    final k = 2 * (m.dx * n.dx + m.dy * n.dy);
    return Matrix4(
      a,
      b,
      0,
      0, //
      b,
      d,
      0,
      0, //
      0,
      0,
      1,
      0, //
      k * n.dx,
      k * n.dy,
      0,
      1,
    );
  }

  static Path _path(List<Offset> poly) => Path()..addPolygon(poly, true);

  @override
  bool shouldRepaint(PageCurlPainter old) =>
      old.image != image ||
      old.back != back ||
      old.rect != rect ||
      old.corner != corner ||
      old.finger != finger;
}
