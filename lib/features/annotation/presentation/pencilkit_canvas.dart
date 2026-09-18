
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/page_ink_store.dart';
import '../domain/annotation_tool_state.dart';

/// iOS/iPadOS 의 PencilKit 캔버스.
///
/// PKCanvasView 를 플랫폼 뷰로 얹는다. 자유곡선 필기만 맡기고
/// 스탬프, 텍스트, 도형은 Flutter 층이 위에서 처리한다.
///
/// 좌표는 "원본 페이지 폭 1000pt" 기준 공간으로 정규화해 저장한다.
/// 기기나 크롭이 달라도 그림이 같은 자리에 온다. 변환은 네이티브 쪽이
/// [PKDrawing.transformed] 로 처리한다.
class PencilKitCanvas extends StatefulWidget {
  const PencilKitCanvas({
    super.key,
    required this.controller,
    required this.tools,
    required this.crop,
    required this.size,
    required this.editing,
  });

  final PageInkController controller;
  final AnnotationToolState tools;
  final Rect crop;
  final Size size;
  final bool editing;

  static const viewType = 'hiscore/pencilkit';

  @override
  State<PencilKitCanvas> createState() => _PencilKitCanvasState();
}

class _PencilKitCanvasState extends State<PencilKitCanvas> {
  MethodChannel? _channel;
  Uint8List? _lastSent;

  @override
  void didUpdateWidget(PencilKitCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_channel == null) return;
    if (oldWidget.editing != widget.editing) _pushEditing();
    if (oldWidget.crop != widget.crop || oldWidget.size != widget.size) {
      _pushGeometry();
    }
    _pushTool();
    _pushDrawingIfChanged();
  }

  @override
  void initState() {
    super.initState();
    widget.tools.addListener(_pushTool);
    widget.controller.addListener(_pushDrawingIfChanged);
  }

  @override
  void dispose() {
    widget.tools.removeListener(_pushTool);
    widget.controller.removeListener(_pushDrawingIfChanged);
    super.dispose();
  }

  Map<String, double> get _geometry => {
        'viewWidth': widget.size.width,
        'viewHeight': widget.size.height,
        'cropLeft': widget.crop.left,
        'cropTop': widget.crop.top,
        'cropWidth': widget.crop.width,
        'cropHeight': widget.crop.height,
      };

  Future<void> _onCreated(int id) async {
    _channel = MethodChannel('${PencilKitCanvas.viewType}_$id')
      ..setMethodCallHandler(_fromNative);
    await _pushGeometry();
    await _pushTool();
    await _pushEditing();
    await _pushDrawingIfChanged(force: true);
  }

  Future<void> _pushGeometry() async =>
      _channel?.invokeMethod('setGeometry', _geometry);

  Future<void> _pushEditing() async => _channel?.invokeMethod('setEditing', {
        'editing': widget.editing,
        'fingerDraws': widget.tools.fingerDraws,
      });

  Future<void> _pushTool() async {
    final t = widget.tools;
    await _channel?.invokeMethod('setTool', {
      'preset': t.preset.name,
      'color': t.color.toARGB32(),
      'width': t.width,
      'eraser': t.tool == InkTool.eraser,
      'fingerDraws': t.fingerDraws,
    });
  }

  Future<void> _pushDrawingIfChanged({bool force = false}) async {
    final data = widget.controller.ink.pencilKitData ?? Uint8List(0);
    if (!force && listEquals(data, _lastSent)) return;
    _lastSent = data;
    await _channel?.invokeMethod('setDrawing', {'data': data});
  }

  Future<dynamic> _fromNative(MethodCall call) async {
    switch (call.method) {
      case 'drawingChanged':
        final data = call.arguments as Uint8List;
        _lastSent = data;
        widget.controller.setPencilKit(data.isEmpty ? null : data);
      case 'stylusSeen':
        widget.tools.noteStylus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    // 스타일러스는 캔버스가 받고, 손가락은 설정에 따라 Flutter 가 넘김에 쓴다.
    return UiKitView(
      viewType: PencilKitCanvas.viewType,
      creationParams: _geometry,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onCreated,
      gestureRecognizers: widget.editing
          ? {
              Factory<OneSequenceGestureRecognizer>(
                () => _StylusOnlyRecognizer(
                  allowTouch: () => widget.tools.fingerDraws,
                ),
              ),
            }
          : const {},
    );
  }
}

/// 플랫폼 뷰에 넘길 포인터를 고른다.
/// 스타일러스는 항상, 손가락은 손가락 그리기가 켜졌을 때만 캔버스로 간다.
class _StylusOnlyRecognizer extends OneSequenceGestureRecognizer {
  _StylusOnlyRecognizer({required this.allowTouch});

  final bool Function() allowTouch;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final stylus = event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
    if (!stylus && !allowTouch()) return;
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'pencilkit';
}
