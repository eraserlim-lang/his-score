import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'ink_models.dart';

/// 필기 모드에서 지금 손에 쥔 도구.
enum InkTool { pen, eraser, stamp, text, shape, select }

/// 필기 도구 상태. 뷰어 화면이 하나 들고 모든 페이지가 공유한다.
class AnnotationToolState extends ChangeNotifier {
  InkTool _tool = InkTool.pen;
  PenPreset _preset = PenPreset.pen;
  /// 악보 위 필기는 인쇄된 음표와 섞이지 않아야 한다. 빨강이 가장 눈에 띈다.
  Color _color = ViewerColors.inkDefault;
  double _width = 1.0;
  double _eraserRadius = 14;
  String _stampId = 'f1';
  ShapeKind _shape = ShapeKind.arrow;
  double _textSize = 28;
  bool _fingerDraws = false;
  bool _toolbarAtBottom = true;

  /// 스타일러스를 한 번이라도 봤으면 손가락은 자동으로 넘김 전용이 된다.
  bool _stylusSeen = false;

  InkTool get tool => _tool;
  PenPreset get preset => _preset;
  Color get color => _color;
  double get width => _width;
  double get eraserRadius => _eraserRadius;
  String get stampId => _stampId;
  ShapeKind get shape => _shape;
  double get textSize => _textSize;
  bool get toolbarAtBottom => _toolbarAtBottom;
  bool get stylusSeen => _stylusSeen;

  /// 손가락으로도 그릴지. 스타일러스가 없는 기기에서는 켜야 한다.
  bool get fingerDraws => _fingerDraws || !_stylusSeen;

  void setTool(InkTool tool) {
    if (tool == _tool) return;
    _tool = tool;
    notifyListeners();
  }

  void setPreset(PenPreset preset) {
    _preset = preset;
    _tool = InkTool.pen;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setWidth(double width) {
    _width = width.clamp(0.4, 4.0);
    notifyListeners();
  }

  void setEraserRadius(double radius) {
    _eraserRadius = radius.clamp(6, 60);
    notifyListeners();
  }

  void setStamp(String id) {
    _stampId = id;
    _tool = InkTool.stamp;
    notifyListeners();
  }

  void setShape(ShapeKind shape) {
    _shape = shape;
    _tool = InkTool.shape;
    notifyListeners();
  }

  void setTextSize(double size) {
    _textSize = size.clamp(10, 120);
    notifyListeners();
  }

  void setFingerDraws(bool value) {
    _fingerDraws = value;
    notifyListeners();
  }

  void toggleToolbarPosition() {
    _toolbarAtBottom = !_toolbarAtBottom;
    notifyListeners();
  }

  void noteStylus() {
    if (_stylusSeen) return;
    _stylusSeen = true;
    notifyListeners();
  }
}
