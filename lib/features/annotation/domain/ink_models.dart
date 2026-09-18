import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../core/db/tables.dart';

/// 필기 좌표계.
///
/// 모든 좌표는 원본 페이지(크롭 전) 기준 0.0~1.0 비율이다.
/// 크롭을 바꾸거나 기기가 달라져도 필기가 같은 자리에 남는다.
@immutable
class InkPoint {
  const InkPoint(this.x, this.y, [this.pressure = 0.5]);

  final double x;
  final double y;

  /// 0.0~1.0. 압력을 모르는 입력은 0.5.
  final double pressure;

  Offset get offset => Offset(x, y);
}

/// 펜 프리셋. 같은 "펜" 도구라도 굵기와 투명도 느낌이 다르다.
enum PenPreset {
  pen('펜', baseWidth: 2.0, alpha: 1.0, pressureSensitive: true),
  marker('형광펜', baseWidth: 14.0, alpha: 0.35, pressureSensitive: false),
  pencil('연필', baseWidth: 1.4, alpha: 0.85, pressureSensitive: true),
  brush('붓', baseWidth: 4.0, alpha: 1.0, pressureSensitive: true);

  const PenPreset(
    this.label, {
    required this.baseWidth,
    required this.alpha,
    required this.pressureSensitive,
  });

  final String label;

  /// 사용자 굵기 1.0 일 때 페이지 폭 1000 기준 픽셀 굵기.
  final double baseWidth;
  final double alpha;
  final bool pressureSensitive;

  /// 붓만 압력에 따라 굵기가 크게 달라진다. 펜과 연필은 살짝만.
  double widthFor(double pressure, double userWidth) {
    final base = baseWidth * userWidth;
    if (!pressureSensitive) return base;
    final gain = this == PenPreset.brush ? 1.6 : 0.5;
    return base * (0.7 + pressure * gain);
  }

  static PenPreset parse(String? name) => PenPreset.values.firstWhere(
        (p) => p.name == name,
        orElse: () => PenPreset.pen,
      );
}

/// 도형 종류.
enum ShapeKind {
  line('직선'),
  arrow('화살표'),
  rect('사각형'),
  ellipse('타원'),
  staff('오선'),
  crescendo('크레셴도'),
  decrescendo('데크레셴도');

  const ShapeKind(this.label);
  final String label;

  static ShapeKind parse(String? name) => ShapeKind.values.firstWhere(
        (s) => s.name == name,
        orElse: () => ShapeKind.line,
      );
}

/// 획 하나. 펜으로 그은 자유곡선이거나 두 점으로 정의되는 도형이다.
@immutable
class Stroke {
  const Stroke({
    required this.id,
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
    this.preset = PenPreset.pen,
    this.shape,
    this.sortOrder = 0,
  });

  final String id;
  final StrokeTool tool;
  final Color color;

  /// 사용자가 고른 굵기 배율. 1.0 이 기본.
  final double width;
  final PenPreset preset;

  /// [tool] 이 shape 일 때만. 그때 [points] 는 시작점과 끝점 둘이다.
  final ShapeKind? shape;
  final List<InkPoint> points;
  final int sortOrder;

  bool get isShape => tool == StrokeTool.shape;

  Stroke copyWith({List<InkPoint>? points, int? sortOrder, String? id}) => Stroke(
        id: id ?? this.id,
        tool: tool,
        color: color,
        width: width,
        points: points ?? this.points,
        preset: preset,
        shape: shape,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  /// 점을 (x, y, 압력) float32 세 개씩 이어 붙인다. JSON 보다 10배 작다.
  Uint8List encodePoints() {
    final data = Float32List(points.length * 3);
    for (var i = 0; i < points.length; i++) {
      data[i * 3] = points[i].x;
      data[i * 3 + 1] = points[i].y;
      data[i * 3 + 2] = points[i].pressure;
    }
    return data.buffer.asUint8List();
  }

  static List<InkPoint> decodePoints(Uint8List bytes) {
    // 4바이트 정렬이 안 된 버퍼가 올 수 있어 복사해서 읽는다.
    final aligned = Uint8List.fromList(bytes);
    final data = aligned.buffer.asFloat32List(0, aligned.length ~/ 4);
    final count = data.length ~/ 3;
    return [
      for (var i = 0; i < count; i++)
        InkPoint(data[i * 3], data[i * 3 + 1], data[i * 3 + 2]),
    ];
  }

  String? get subtype => isShape ? shape?.name : preset.name;

  /// 지우개가 닿았는지 검사할 때 쓰는 대략의 외곽.
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    var l = double.infinity, t = double.infinity;
    var r = double.negativeInfinity, b = double.negativeInfinity;
    for (final p in points) {
      l = math.min(l, p.x);
      t = math.min(t, p.y);
      r = math.max(r, p.x);
      b = math.max(b, p.y);
    }
    return Rect.fromLTRB(l, t, r, b);
  }
}

/// 배치형 주석의 종류.
enum PlacedKind { stamp, text }

/// 스탬프나 텍스트처럼 한 점에 놓이는 주석.
@immutable
class PlacedAnnotation {
  const PlacedAnnotation({
    required this.id,
    required this.kind,
    required this.value,
    required this.x,
    required this.y,
    required this.color,
    this.scale = 1.0,
    this.rotation = 0,
    this.fontSize,
    this.sortOrder = 0,
  });

  final String id;
  final PlacedKind kind;

  /// 스탬프면 스탬프 id, 텍스트면 본문.
  final String value;

  /// 원본 페이지 기준 0~1 비율 좌표. 개체의 중심이다.
  final double x;
  final double y;
  final Color color;
  final double scale;
  final double rotation;

  /// 텍스트 크기. 페이지 폭 1000 기준 픽셀.
  final double? fontSize;
  final int sortOrder;

  PlacedAnnotation copyWith({
    String? value,
    double? x,
    double? y,
    Color? color,
    double? scale,
    double? fontSize,
    int? sortOrder,
  }) =>
      PlacedAnnotation(
        id: id,
        kind: kind,
        value: value ?? this.value,
        x: x ?? this.x,
        y: y ?? this.y,
        color: color ?? this.color,
        scale: scale ?? this.scale,
        rotation: rotation,
        fontSize: fontSize ?? this.fontSize,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

/// 한 페이지의 필기 전체.
@immutable
class PageInk {
  const PageInk({
    this.strokes = const [],
    this.placed = const [],
    this.pencilKitData,
  });

  final List<Stroke> strokes;
  final List<PlacedAnnotation> placed;

  /// iOS PencilKit 이 만든 PKDrawing 바이트. 다른 플랫폼에서는 그리지 못하고
  /// 보관만 한다. 그 기기로 돌아가면 그대로 살아난다.
  final Uint8List? pencilKitData;

  bool get isEmpty =>
      strokes.isEmpty && placed.isEmpty && (pencilKitData?.isEmpty ?? true);

  int get nextOrder {
    var max = -1;
    for (final s in strokes) {
      if (s.sortOrder > max) max = s.sortOrder;
    }
    for (final p in placed) {
      if (p.sortOrder > max) max = p.sortOrder;
    }
    return max + 1;
  }

  PageInk copyWith({
    List<Stroke>? strokes,
    List<PlacedAnnotation>? placed,
    Uint8List? pencilKitData,
    bool clearPencilKit = false,
  }) =>
      PageInk(
        strokes: strokes ?? this.strokes,
        placed: placed ?? this.placed,
        pencilKitData: clearPencilKit ? null : (pencilKitData ?? this.pencilKitData),
      );

  /// 직렬화. 세트리스트 공유와 백업에서 쓴다.
  Map<String, dynamic> toJson() => {
        'strokes': [
          for (final s in strokes)
            {
              'id': s.id,
              'tool': s.tool.name,
              'color': s.color.toARGB32(),
              'width': s.width,
              'subtype': s.subtype,
              'order': s.sortOrder,
              'points': base64Encode(s.encodePoints()),
            },
        ],
        'placed': [
          for (final p in placed)
            {
              'id': p.id,
              'kind': p.kind.name,
              'value': p.value,
              'x': p.x,
              'y': p.y,
              'color': p.color.toARGB32(),
              'scale': p.scale,
              'rotation': p.rotation,
              'fontSize': p.fontSize,
              'order': p.sortOrder,
            },
        ],
        if (pencilKitData != null) 'pencilKit': base64Encode(pencilKitData!),
      };

  static PageInk fromJson(Map<String, dynamic> json) {
    final strokes = <Stroke>[];
    for (final raw in (json['strokes'] as List? ?? const [])) {
      final m = raw as Map<String, dynamic>;
      final tool = StrokeTool.values.firstWhere(
        (t) => t.name == m['tool'],
        orElse: () => StrokeTool.pen,
      );
      strokes.add(
        Stroke(
          id: m['id'] as String,
          tool: tool,
          color: Color(m['color'] as int),
          width: (m['width'] as num).toDouble(),
          preset: PenPreset.parse(m['subtype'] as String?),
          shape: tool == StrokeTool.shape
              ? ShapeKind.parse(m['subtype'] as String?)
              : null,
          sortOrder: m['order'] as int? ?? 0,
          points: Stroke.decodePoints(base64Decode(m['points'] as String)),
        ),
      );
    }
    final placed = <PlacedAnnotation>[];
    for (final raw in (json['placed'] as List? ?? const [])) {
      final m = raw as Map<String, dynamic>;
      placed.add(
        PlacedAnnotation(
          id: m['id'] as String,
          kind: m['kind'] == 'text' ? PlacedKind.text : PlacedKind.stamp,
          value: m['value'] as String,
          x: (m['x'] as num).toDouble(),
          y: (m['y'] as num).toDouble(),
          color: Color(m['color'] as int),
          scale: (m['scale'] as num?)?.toDouble() ?? 1,
          rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
          fontSize: (m['fontSize'] as num?)?.toDouble(),
          sortOrder: m['order'] as int? ?? 0,
        ),
      );
    }
    final pk = json['pencilKit'] as String?;
    return PageInk(
      strokes: strokes,
      placed: placed,
      pencilKitData: pk == null ? null : base64Decode(pk),
    );
  }
}

/// 지우개가 지나간 자리에서 획을 잘라 낸다.
///
/// 반지름 안의 점을 빼고, 남은 점들을 연속 구간별로 새 획으로 나눈다.
/// 통째로 지우는 것보다 종이 지우개에 가깝다.
List<Stroke> eraseFromStroke(
  Stroke stroke,
  Offset center,
  double radius,
  String Function() newId,
) {
  if (stroke.isShape) {
    // 도형은 선 위 어느 점이든 닿으면 통째로 지운다.
    return _shapeHit(stroke, center, radius) ? const [] : [stroke];
  }

  final r2 = radius * radius;
  final segments = <List<InkPoint>>[];
  var current = <InkPoint>[];
  var touched = false;

  for (final p in stroke.points) {
    final dx = p.x - center.dx;
    final dy = p.y - center.dy;
    if (dx * dx + dy * dy <= r2) {
      touched = true;
      if (current.length >= 2) segments.add(current);
      current = [];
    } else {
      current.add(p);
    }
  }
  if (current.length >= 2) segments.add(current);

  if (!touched) return [stroke];
  if (segments.isEmpty) return const [];

  // 첫 조각은 원래 id 를 유지해 실행 취소 기록이 단순해진다.
  return [
    for (var i = 0; i < segments.length; i++)
      stroke.copyWith(points: segments[i], id: i == 0 ? stroke.id : newId()),
  ];
}

bool _shapeHit(Stroke shape, Offset c, double radius) {
  if (shape.points.length < 2) return false;
  final a = shape.points.first.offset;
  final b = shape.points.last.offset;
  final kind = shape.shape ?? ShapeKind.line;

  switch (kind) {
    case ShapeKind.rect:
    case ShapeKind.staff:
    case ShapeKind.ellipse:
      // 외곽 상자를 조금 넓혀 닿았는지 본다.
      final rect = Rect.fromPoints(a, b).inflate(radius);
      final inner = Rect.fromPoints(a, b).deflate(radius);
      return rect.contains(c) && !(inner.width > 0 && inner.height > 0 && inner.contains(c));
    case ShapeKind.line:
    case ShapeKind.arrow:
    case ShapeKind.crescendo:
    case ShapeKind.decrescendo:
      return _distanceToSegment(c, a, b) <= radius;
  }
}

double _distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (len2 == 0) return (p - a).distance;
  var t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2;
  t = t.clamp(0.0, 1.0);
  final proj = a + ab * t;
  return (p - proj).distance;
}
