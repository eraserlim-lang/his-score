import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/features/annotation/domain/annotation_tool_state.dart';
import 'package:his_score/features/annotation/domain/ink_models.dart';

/// 애플 펜슬 두 번 두드리기: 직전 도구로, 없으면 지우개로.
void main() {
  test('직전 도구가 없으면 지우개로 가고, 다시 두드리면 돌아온다', () {
    final t = AnnotationToolState();
    expect(t.tool, InkTool.pen);
    t.swapToPrevious();
    expect(t.tool, InkTool.eraser);
    t.swapToPrevious();
    expect(t.tool, InkTool.pen);
  });

  test('직전 도구로 돌아간다. 펜 종류까지', () {
    final t = AnnotationToolState()..setPreset(PenPreset.marker);
    t.setPreset(PenPreset.pencil);
    t.swapToPrevious();
    expect(t.tool, InkTool.pen);
    expect(t.preset, PenPreset.marker);
    t.swapToPrevious();
    expect(t.preset, PenPreset.pencil);
  });

  test('스탬프에서 두드리면 직전 펜으로', () {
    final t = AnnotationToolState()..setPreset(PenPreset.brush);
    t.setStamp('f1');
    expect(t.tool, InkTool.stamp);
    t.swapToPrevious();
    expect(t.tool, InkTool.pen);
    expect(t.preset, PenPreset.brush);
  });

  test('같은 도구를 다시 골라도 직전 도구가 지워지지 않는다', () {
    final t = AnnotationToolState()..setTool(InkTool.eraser);
    t.setTool(InkTool.eraser);
    t.swapToPrevious();
    expect(t.tool, InkTool.pen);
  });
}
