import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/db/tables.dart';
import '../data/annotation_dao.dart';
import '../data/page_ink_store.dart';
import '../domain/annotation_tool_state.dart';
import '../domain/ink_models.dart';
import 'ink_painter.dart';
import 'pencilkit_canvas.dart';
import '../../../core/i18n/tr.dart';

/// 페이지 위에 얹히는 필기 층.
///
/// 보기만 할 때는 그리기만 하고 입력을 받지 않는다. 필기 모드에서는
/// 스타일러스 입력을 먼저 가져가고, 손가락은 설정에 따라 그리거나 넘긴다.
/// iOS 에서는 자유곡선을 PencilKit 이 맡고 스탬프/텍스트/도형만 여기서 다룬다.
class InkLayer extends StatefulWidget {
  const InkLayer({
    super.key,
    required this.controller,
    required this.crop,
    required this.rotation,
    required this.editing,
    required this.tools,
    this.onRequestText,
  });

  final PageInkController controller;
  final Rect crop;
  final double rotation;
  final bool editing;
  final AnnotationToolState tools;

  /// 텍스트 도구로 화면을 찍었을 때 본문을 받아 오는 콜백.
  final Future<String?> Function(String initial)? onRequestText;

  @override
  State<InkLayer> createState() => _InkLayerState();
}

class _InkLayerState extends State<InkLayer> {
  Stroke? _live;
  int? _activePointer;
  Offset? _eraserCursor;

  /// 지우개가 한 번 지나가는 동안 잘라낸 것들. 손을 떼면 한 편집으로 묶는다.
  final _erasedOriginal = <String, Stroke>{};
  var _erasedResult = <Stroke>[];

  String? _selectedId;
  Offset? _dragStart;
  PlacedAnnotation? _dragOriginal;

  static bool get _usePencilKit => !kIsWeb && Platform.isIOS;

  InkTransform _transform(Size size) =>
      InkTransform(size: size, crop: widget.crop, rotation: widget.rotation);

  bool _accepts(PointerEvent e) {
    if (e.kind == PointerDeviceKind.stylus ||
        e.kind == PointerDeviceKind.invertedStylus) {
      widget.tools.noteStylus();
      return true;
    }
    if (e.kind == PointerDeviceKind.mouse) return true;
    return widget.tools.fingerDraws;
  }

  void _down(PointerDownEvent e, Size size) {
    if (!widget.editing || _activePointer != null || !_accepts(e)) return;
    _activePointer = e.pointer;
    final t = _transform(size);
    final n = t.toNormalized(e.localPosition);
    final tools = widget.tools;

    // 지우개 뒷면(Apple Pencil 2 의 뒤집기 등)은 도구와 무관하게 지운다.
    final erasing = tools.tool == InkTool.eraser ||
        e.kind == PointerDeviceKind.invertedStylus;

    if (erasing) {
      _erasedOriginal.clear();
      _erasedResult = [];
      _eraserCursor = e.localPosition;
      _eraseAt(n, t);
      setState(() {});
      return;
    }

    switch (tools.tool) {
      case InkTool.pen:
        if (_usePencilKit) {
          _activePointer = null; // PencilKit 이 받는다
          return;
        }
        _live = Stroke(
          id: AnnotationDao.newId(),
          tool: StrokeTool.pen,
          color: tools.color,
          width: tools.width,
          preset: tools.preset,
          points: [InkPoint(n.dx, n.dy, _pressure(e))],
        );
      case InkTool.shape:
        _live = Stroke(
          id: AnnotationDao.newId(),
          tool: StrokeTool.shape,
          color: tools.color,
          width: tools.width,
          shape: tools.shape,
          points: [InkPoint(n.dx, n.dy), InkPoint(n.dx, n.dy)],
        );
      case InkTool.stamp:
        widget.controller.addPlaced(
          PlacedAnnotation(
            id: AnnotationDao.newId(),
            kind: PlacedKind.stamp,
            value: tools.stampId,
            x: n.dx,
            y: n.dy,
            color: tools.color,
            fontSize: 28 * tools.width,
          ),
        );
        _activePointer = null;
      case InkTool.text:
        _activePointer = null;
        _placeText(n);
      case InkTool.select:
        final hit = _hitPlaced(e.localPosition, size);
        _selectedId = hit?.id;
        _dragStart = e.localPosition;
        _dragOriginal = hit;
      case InkTool.eraser:
        break;
    }
    setState(() {});
  }

  void _move(PointerMoveEvent e, Size size) {
    if (e.pointer != _activePointer) return;
    final t = _transform(size);
    final n = t.toNormalized(e.localPosition);

    if (_eraserCursor != null) {
      _eraserCursor = e.localPosition;
      _eraseAt(n, t);
      setState(() {});
      return;
    }

    final live = _live;
    if (live != null) {
      if (live.isShape) {
        _live = live.copyWith(points: [live.points.first, InkPoint(n.dx, n.dy)]);
      } else {
        // 너무 촘촘한 점은 버린다. 파일이 커지고 렌더만 느려진다.
        final last = live.points.last;
        final dx = (n.dx - last.x) * size.width;
        final dy = (n.dy - last.y) * size.height;
        if (dx * dx + dy * dy < 1.5) return;
        _live = live.copyWith(
          points: [...live.points, InkPoint(n.dx, n.dy, _pressure(e))],
        );
      }
      setState(() {});
      return;
    }

    if (_dragOriginal != null && _dragStart != null) {
      final delta = e.localPosition - _dragStart!;
      final moved = _dragOriginal!.copyWith(
        x: _dragOriginal!.x + delta.dx / size.width * widget.crop.width,
        y: _dragOriginal!.y + delta.dy / size.height * widget.crop.height,
      );
      // 드래그 중에는 화면만 바꾸고, 손을 뗄 때 한 번 기록한다.
      _previewPlaced = moved;
      setState(() {});
    }
  }

  PlacedAnnotation? _previewPlaced;

  void _up(PointerEvent e) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;

    if (_eraserCursor != null) {
      _eraserCursor = null;
      widget.controller.erase(_erasedOriginal.values.toList(), _erasedResult);
      _erasedOriginal.clear();
      _erasedResult = [];
      setState(() {});
      return;
    }

    final live = _live;
    if (live != null) {
      _live = null;
      if (live.isShape || live.points.isNotEmpty) {
        widget.controller.addStroke(live);
      }
      setState(() {});
      return;
    }

    if (_previewPlaced != null && _dragOriginal != null) {
      widget.controller.updatePlaced(_dragOriginal!, _previewPlaced!);
    }
    _previewPlaced = null;
    _dragOriginal = null;
    _dragStart = null;
    setState(() {});
  }

  double _pressure(PointerEvent e) {
    if (e.pressureMax <= e.pressureMin) return 0.5;
    return ((e.pressure - e.pressureMin) / (e.pressureMax - e.pressureMin))
        .clamp(0.0, 1.0);
  }

  void _eraseAt(Offset n, InkTransform t) {
    final radius = t.toNormalizedRadius(widget.tools.eraserRadius);
    // 이번 스와이프에서 이미 잘린 조각들도 계속 지워질 수 있다.
    final pool = <Stroke>[
      for (final s in widget.controller.ink.strokes)
        if (!_erasedOriginal.containsKey(s.id)) s,
      ..._erasedResult,
    ];
    final nextResult = <Stroke>[];
    for (final s in pool) {
      if (!s.bounds.inflate(radius).contains(n)) {
        if (_erasedResult.contains(s)) nextResult.add(s);
        continue;
      }
      final pieces = eraseFromStroke(s, n, radius, AnnotationDao.newId);
      final changed = pieces.length != 1 || !identical(pieces.first, s);
      if (!changed) {
        if (_erasedResult.contains(s)) nextResult.add(s);
        continue;
      }
      // 원본 획을 처음 건드리면 기억해 둔다.
      final originalId = _originalIdOf(s.id);
      if (!_erasedOriginal.containsKey(originalId)) {
        final original = widget.controller.ink.strokes
            .where((o) => o.id == originalId)
            .firstOrNull;
        if (original != null) _erasedOriginal[originalId] = original;
      }
      for (final p in pieces) {
        _pieceOrigin[p.id] = originalId;
      }
      nextResult.addAll(pieces);
    }
    _erasedResult = nextResult;

    // 지우개는 스탬프도 지운다.
    for (final p in widget.controller.ink.placed) {
      final d = (Offset(p.x, p.y) - n).distance;
      if (d <= radius) widget.controller.removePlaced(p);
    }
  }

  /// 조각 id → 원본 획 id. 같은 스와이프 안에서 조각이 다시 잘릴 때 쓴다.
  final _pieceOrigin = <String, String>{};
  String _originalIdOf(String id) => _pieceOrigin[id] ?? id;

  PlacedAnnotation? _hitPlaced(Offset local, Size size) {
    final t = _transform(size);
    PlacedAnnotation? best;
    var bestDist = double.infinity;
    for (final p in widget.controller.ink.placed) {
      final c = t.toWidget(p.x, p.y);
      final r = (p.fontSize ?? 28) * p.scale * t.scale * 0.8;
      final d = (c - local).distance;
      if (d <= r && d < bestDist) {
        best = p;
        bestDist = d;
      }
    }
    return best;
  }

  Future<void> _placeText(Offset n) async {
    final text = await widget.onRequestText?.call('');
    if (text == null || text.trim().isEmpty) return;
    widget.controller.addPlaced(
      PlacedAnnotation(
        id: AnnotationDao.newId(),
        kind: PlacedKind.text,
        value: text.trim(),
        x: n.dx,
        y: n.dy,
        color: widget.tools.color,
        fontSize: widget.tools.textSize,
      ),
    );
  }

  Future<void> _editSelected() async {
    final id = _selectedId;
    if (id == null) return;
    final item =
        widget.controller.ink.placed.where((p) => p.id == id).firstOrNull;
    if (item == null) return;
    if (item.kind == PlacedKind.text) {
      final text = await widget.onRequestText?.call(item.value);
      if (text == null) return;
      if (text.trim().isEmpty) {
        widget.controller.removePlaced(item);
      } else {
        widget.controller.updatePlaced(item, item.copyWith(value: text.trim()));
      }
    }
  }

  void _deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    final item =
        widget.controller.ink.placed.where((p) => p.id == id).firstOrNull;
    if (item != null) widget.controller.removePlaced(item);
    setState(() => _selectedId = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.tools]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            var ink = widget.controller.ink;
            if (_previewPlaced != null) {
              ink = ink.copyWith(
                placed: [
                  for (final p in ink.placed)
                    p.id == _previewPlaced!.id ? _previewPlaced! : p,
                ],
              );
            }

            final painter = CustomPaint(
              painter: InkPainter(
                ink: ink,
                crop: widget.crop,
                rotation: widget.rotation,
                liveStroke: _live,
                selectedPlacedId: widget.editing ? _selectedId : null,
                eraserCursor: _eraserCursor,
                eraserRadius: widget.tools.eraserRadius,
              ),
              size: size,
            );

            final pencil = _usePencilKit
                ? PencilKitCanvas(
                    controller: widget.controller,
                    tools: widget.tools,
                    crop: widget.crop,
                    size: size,
                    // 펜 획은 PencilKit 이 들고 있어 지우개도 PencilKit 이 받아야 지워진다.
                    // 도형처럼 Flutter 가 그린 획은 같은 손짓을 이 층이 함께 받아 지운다.
                    editing: widget.editing &&
                        (widget.tools.tool == InkTool.pen ||
                            widget.tools.tool == InkTool.eraser),
                  )
                : null;

            if (!widget.editing) {
              return IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [?pencil, painter],
                ),
              );
            }

            final layer = Stack(
              fit: StackFit.expand,
              children: [
                ?pencil,
                // 그림은 보여 주기만 한다. 입력은 바깥의 인식기가 받는다.
                // 여기서 터치를 먹으면 아래 PencilKit 캔버스까지 닿지 않아
                // iOS 에서 펜으로도 손가락으로도 써지지 않는다.
                IgnorePointer(child: painter),
                if (_selectedId != null && widget.tools.tool == InkTool.select)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: _editSelected,
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: tr('내용 고치기'),
                        ),
                        IconButton.filledTonal(
                          onPressed: _deleteSelected,
                          icon: const Icon(Icons.delete, size: 18),
                          tooltip: tr('지우기'),
                        ),
                      ],
                    ),
                  ),
              ],
            );

            // 스타일러스(또는 손가락 그리기 설정 시 손가락)를 제스처 경쟁에서
            // 먼저 가져간다. 그래야 페이지뷰가 획을 스와이프로 오해하지 않는다.
            return RawGestureDetector(
              gestures: {
                _InkRecognizer: GestureRecognizerFactoryWithHandlers<_InkRecognizer>(
                  () => _InkRecognizer(
                    accepts: _accepts,
                    onDown: (e) => _down(e, size),
                    onMove: (e) => _move(e, size),
                    onUp: _up,
                  ),
                  (r) {
                    r.accepts = _accepts;
                    r.onDown = (e) => _down(e, size);
                    r.onMove = (e) => _move(e, size);
                    r.onUp = _up;
                  },
                ),
              },
              behavior: HitTestBehavior.opaque,
              child: layer,
            );
          },
        );
      },
    );
  }
}

/// 그리기 입력만 골라 즉시 가져가는 인식기.
///
/// 조건에 맞는 포인터는 경쟁 없이 바로 이긴다. 조건에 안 맞으면
/// 아예 참여하지 않아 페이지 넘김 제스처가 정상적으로 돈다.
class _InkRecognizer extends OneSequenceGestureRecognizer {
  _InkRecognizer({
    required this.accepts,
    required this.onDown,
    required this.onMove,
    required this.onUp,
  });

  bool Function(PointerEvent) accepts;
  void Function(PointerDownEvent) onDown;
  void Function(PointerMoveEvent) onMove;
  void Function(PointerEvent) onUp;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!accepts(event)) return;
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onDown(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onMove(event);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      onUp(event);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'ink';
}
