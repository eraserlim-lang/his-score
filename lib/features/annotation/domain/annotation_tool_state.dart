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

  /// 도구 막대에 내놓는 빠른 색 여섯 칸. 길게 눌러 다른 색으로 바꾼다.
  /// 쓰는 색은 사람마다 달라서(운지는 파랑, 주의는 빨강 식으로) 고정하면
  /// 매번 넓은 팔레트를 열어야 한다.
  List<Color> _palette = List.of(ViewerColors.inkColors);
  double _width = 1.0;
  double _eraserRadius = 14;
  String _stampId = 'f1';

  /// 새로 찍는 스탬프를 네모 상자로 두를지.
  bool _stampBoxed = false;
  ShapeKind _shape = ShapeKind.arrow;
  double _textSize = 28;
  bool _fingerDraws = false;
  bool _toolbarAtBottom = true;

  /// 스타일러스를 한 번이라도 봤으면 손가락은 자동으로 넘김 전용이 된다.
  bool _stylusSeen = false;

  InkTool get tool => _tool;
  PenPreset get preset => _preset;
  Color get color => _color;
  List<Color> get palette => List.unmodifiable(_palette);
  double get width => _width;
  double get eraserRadius => _eraserRadius;
  String get stampId => _stampId;
  bool get stampBoxed => _stampBoxed;
  ShapeKind get shape => _shape;
  double get textSize => _textSize;
  bool get toolbarAtBottom => _toolbarAtBottom;
  bool get stylusSeen => _stylusSeen;

  /// 손가락으로도 그릴지. 스타일러스가 없는 기기에서는 켜야 한다.
  bool get fingerDraws => _fingerDraws || !_stylusSeen;

  /// 펜슬 두 번 두드리기로 돌아갈 도구. 도구를 바꿀 때마다 직전 것을 적어 둔다.
  (InkTool, PenPreset)? _previous;

  void _remember() => _previous = (_tool, _preset);

  void setTool(InkTool tool) {
    if (tool == _tool) return;
    _remember();
    _tool = tool;
    notifyListeners();
  }

  /// 애플 펜슬을 두 번 두드렸을 때. 직전 도구로 돌아가고, 직전 도구가
  /// 없으면 지우개로 간다. 지우개였는데 직전 도구가 없으면 펜으로 온다.
  /// 되풀이하면 두 도구 사이를 오간다.
  void swapToPrevious() {
    final now = (_tool, _preset);
    final prev = _previous;
    if (prev != null && prev != now) {
      _tool = prev.$1;
      _preset = prev.$2;
    } else if (_tool != InkTool.eraser) {
      _tool = InkTool.eraser;
    } else {
      _tool = InkTool.pen;
    }
    _previous = now;
    notifyListeners();
  }

  void setPreset(PenPreset preset) {
    if (_tool == InkTool.pen && _preset == preset) return;
    _remember();
    _preset = preset;
    _tool = InkTool.pen;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  /// 빠른 색 한 칸을 다른 색으로 갈아 끼운다. 그 칸을 쓰고 있었으면
  /// 지금 색도 함께 옮겨 간다. 안 그러면 방금 고른 색이 사라져 보인다.
  void setPaletteColor(int index, Color color) {
    if (index < 0 || index >= _palette.length) return;
    final replacing = _palette[index] == _color;
    _palette = List.of(_palette)..[index] = color;
    if (replacing) _color = color;
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
    if (_tool != InkTool.stamp) _remember();
    _tool = InkTool.stamp;
    notifyListeners();
  }

  void setStampBoxed(bool value) {
    if (value == _stampBoxed) return;
    _stampBoxed = value;
    notifyListeners();
  }

  void setShape(ShapeKind shape) {
    _shape = shape;
    if (_tool != InkTool.shape) _remember();
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
