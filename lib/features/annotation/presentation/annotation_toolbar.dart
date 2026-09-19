import 'package:flutter/material.dart';

import '../../../core/db/tables.dart';
import '../../../core/layout/center_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../data/page_ink_store.dart';
import '../domain/annotation_tool_state.dart';
import '../domain/ink_models.dart';
import '../domain/stamps.dart';
import 'ink_painter.dart';
import '../../../core/i18n/tr.dart';

/// 필기 도구 막대.
///
/// 위나 아래에 붙일 수 있다. 오른손잡이가 아래 막대를 손목으로 가리는 일이
/// 잦아서 위로 옮기는 사람이 많다.
class AnnotationToolbar extends StatelessWidget {
  const AnnotationToolbar({
    super.key,
    required this.tools,
    required this.pageController,
    required this.onClose,
    required this.onClearAll,
  });

  final AnnotationToolState tools;
  final PageInkController? pageController;
  final VoidCallback onClose;

  /// 곡 전체의 필기를 지운다. 확인은 호출한 쪽이 한다.
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([tools, ?pageController]),
      builder: (context, _) {
        return Material(
          color: scheme.surface.withValues(alpha: 0.96),
          elevation: 4,
          child: SafeArea(
            top: !tools.toolbarAtBottom,
            bottom: tools.toolbarAtBottom,
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: [
                  IconButton(
                    onPressed: tools.toggleToolbarPosition,
                    icon: Icon(
                      tools.toolbarAtBottom
                          ? Icons.vertical_align_top
                          : Icons.vertical_align_bottom,
                    ),
                    tooltip: tools.toolbarAtBottom
                        ? tr('위로 옮기기')
                        : tr('아래로 옮기기'),
                  ),
                  const VerticalDivider(indent: 12, endIndent: 12),
                  for (final preset in PenPreset.values)
                    // Builder 로 감싸야 팝업을 이 버튼 자리에 띄울 수 있다.
                    Builder(
                      builder: (buttonContext) => _ToolButton(
                        icon: _presetIcon(preset),
                        label: tr(preset.label),
                        selected:
                            tools.tool == InkTool.pen && tools.preset == preset,
                        onTap: () => tools.setPreset(preset),
                        onLongPress: () => _showPenOptions(buttonContext),
                      ),
                    ),
                  _ToolButton(
                    icon: Icons.auto_fix_normal,
                    label: tr('지우개'),
                    selected: tools.tool == InkTool.eraser,
                    onTap: () => tools.setTool(InkTool.eraser),
                    onLongPress: () => _showEraser(context),
                  ),
                  const VerticalDivider(indent: 12, endIndent: 12),
                  _ToolButton(
                    icon: Icons.music_note,
                    label: tr('스탬프'),
                    selected: tools.tool == InkTool.stamp,
                    onTap: () => _showStamps(context),
                  ),
                  _ToolButton(
                    icon: Icons.text_fields,
                    label: tr('텍스트'),
                    selected: tools.tool == InkTool.text,
                    onTap: () => tools.setTool(InkTool.text),
                    onLongPress: () => _showTextSize(context),
                  ),
                  _ToolButton(
                    icon: Icons.timeline,
                    label: tr('도형'),
                    selected: tools.tool == InkTool.shape,
                    onTap: () => _showShapes(context),
                  ),
                  _ToolButton(
                    icon: Icons.open_with,
                    label: tr('선택'),
                    selected: tools.tool == InkTool.select,
                    onTap: () => tools.setTool(InkTool.select),
                  ),
                  const VerticalDivider(indent: 12, endIndent: 12),
                  for (final (i, color) in tools.palette.indexed)
                    _ColorDot(
                      color: color,
                      selected: tools.color == color,
                      onTap: () => tools.setColor(color),
                      onLongPress: () => _pickPaletteColor(context, i),
                    ),
                  const VerticalDivider(indent: 12, endIndent: 12),
                  IconButton(
                    onPressed: pageController?.canUndo == true
                        ? pageController!.undo
                        : null,
                    icon: const Icon(Icons.undo),
                    tooltip: tr('실행 취소'),
                  ),
                  IconButton(
                    onPressed: pageController?.canRedo == true
                        ? pageController!.redo
                        : null,
                    icon: const Icon(Icons.redo),
                    tooltip: tr('다시 실행'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: tr('지우기'),
                    icon: Icon(Icons.delete_sweep_outlined),
                    onSelected: (v) {
                      if (v == 'page') {
                        pageController?.clear();
                      } else {
                        onClearAll();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'page',
                        child: Text(tr('이 페이지 필기 지우기')),
                      ),
                      PopupMenuItem(
                        value: 'all',
                        child: Text(tr('전체 페이지 필기 지우기')),
                      ),
                    ],
                  ),
                  if (tools.stylusSeen)
                    IconButton(
                      onPressed: () => tools.setFingerDraws(!tools.fingerDraws),
                      isSelected: tools.fingerDraws,
                      icon: const Icon(Icons.touch_app_outlined),
                      tooltip: tools.fingerDraws
                          ? tr('손가락: 그리기')
                          : tr('손가락: 페이지 넘김'),
                    ),
                  const VerticalDivider(indent: 12, endIndent: 12),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    tooltip: tr('필기 끝내기'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _presetIcon(PenPreset p) => switch (p) {
    PenPreset.pen => Icons.edit,
    PenPreset.marker => Icons.border_color,
    PenPreset.pencil => Icons.create_outlined,
    PenPreset.brush => Icons.brush,
  };

  /// 펜 옵션을 화면 가운데 판으로 띄운다.
  ///
  /// 버튼 옆에 띄우면 막대가 아래에 있을 때 손이 판을 가리고, 좁은 화면에서는
  /// 팔레트가 잘렸다. 가운데는 어느 막대 자리에서도 같게 보인다.
  Future<void> _showPenOptions(BuildContext context) {
    return showCenterSheet<void>(
      context,
      maxWidth: 380,
      child: _PenOptions(tools: tools),
    );
  }

  /// 빠른 색 한 칸을 길게 눌렀을 때. 넓은 팔레트에서 새 색을 고른다.
  Future<void> _pickPaletteColor(BuildContext context, int index) async {
    final picked = await showCenterSheet<Color>(
      context,
      maxWidth: 360,
      child: _PalettePicker(current: tools.palette[index]),
    );
    if (picked != null) tools.setPaletteColor(index, picked);
  }

  void _showEraser(BuildContext context) {
    showCenterSheet<void>(
      context,
      maxWidth: 360,
      child: _SliderSheet(
        title: tr('지우개 크기'),
        listenable: tools,
        value: () => tools.eraserRadius,
        min: 6,
        max: 60,
        onChanged: tools.setEraserRadius,
        preview: (v) => SizedBox(
          height: 130,
          child: Center(
            child: Container(
              width: v * 2,
              height: v * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTextSize(BuildContext context) {
    showCenterSheet<void>(
      context,
      maxWidth: 360,
      child: _SliderSheet(
        title: tr('글자 크기'),
        listenable: tools,
        value: () => tools.textSize,
        min: 10,
        max: 120,
        onChanged: tools.setTextSize,
        preview: (v) => SizedBox(
          height: 130,
          child: Center(
            child: Text(
              'rit.',
              style: TextStyle(fontSize: v * 0.6, color: tools.color),
            ),
          ),
        ),
      ),
    );
  }

  void _showStamps(BuildContext context) {
    showCenterSheet<void>(
      context,
      maxWidth: 560,
      // 목록이 안에서 스스로 스크롤한다.
      fill: true,
      scrollable: false,
      child: Builder(
        builder: (sheetContext) => StampPalette(
          selected: tools.stampId,
          color: tools.color,
          onSelected: (id) {
            tools.setStamp(id);
            Navigator.pop(sheetContext);
          },
        ),
      ),
    );
  }

  void _showShapes(BuildContext context) {
    showCenterSheet<void>(
      context,
      maxWidth: 360,
      child: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final kind in ShapeKind.values)
              ListTile(
                leading: SizedBox(
                  width: 40,
                  height: 28,
                  child: CustomPaint(painter: _ShapePreview(kind, tools.color)),
                ),
                title: Text(tr(kind.label)),
                selected: tools.shape == kind,
                onTap: () {
                  tools.setShape(kind);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// 빠른 색 한 칸에 넣을 색을 고른다.
class _PalettePicker extends StatelessWidget {
  const _PalettePicker({required this.current});

  final Color current;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('색 바꾸기'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          tr('고른 색이 이 칸에 들어갑니다.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final color in ViewerColors.inkPalette)
              _ColorDot(
                color: color,
                selected: color == current,
                onTap: () => Navigator.pop(context, color),
              ),
          ],
        ),
      ],
    );
  }
}

/// 펜 옵션 팝업 속 내용. 굵기와 색을 한자리에서 고친다.
class _PenOptions extends StatelessWidget {
  const _PenOptions({required this.tools});

  final AnnotationToolState tools;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tools,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('펜 굵기'), style: Theme.of(context).textTheme.labelLarge),
              CustomPaint(
                size: const Size(double.infinity, 36),
                painter: _WidthPreview(tools.preset, tools.color, tools.width),
              ),
              Slider(
                value: tools.width,
                min: 0.4,
                max: 4,
                onChanged: tools.setWidth,
              ),
              const SizedBox(height: 4),
              Text(tr('색'), style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in ViewerColors.inkPalette)
                    _ColorDot(
                      color: color,
                      selected: tools.color == color,
                      onTap: () => tools.setColor(color),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: onLongPress == null ? label : tr('{0} (길게 눌러 설정)', [label]),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 1),
          decoration: BoxDecoration(
            color: selected ? scheme.secondaryContainer : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 22,
            color: selected ? scheme.onSecondaryContainer : null,
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  /// 주면 길게 눌러 이 칸의 색을 바꿀 수 있다.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              width: selected ? 3 : 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderSheet extends StatelessWidget {
  const _SliderSheet({
    required this.title,
    required this.listenable,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.preview,
  });

  final String title;
  final Listenable listenable;
  final double Function() value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Widget Function(double) preview;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final v = value();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                preview(v),
                Slider(value: v, min: min, max: max, onChanged: onChanged),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WidthPreview extends CustomPainter {
  _WidthPreview(this.preset, this.color, this.width);
  final PenPreset preset;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Stroke(
      id: 'preview',
      tool: StrokeTool.pen,
      color: color,
      width: width,
      preset: preset,
      points: [
        for (var i = 0; i <= 20; i++)
          InkPoint(
            i / 20,
            0.5 + 0.3 * (i.isEven ? 1 : -1) * (i % 3 == 0 ? 1 : 0.4),
            (i / 20),
          ),
      ],
    );
    InkPainter.paintStroke(
      canvas,
      stroke,
      InkTransform(
        size: size,
        crop: const Rect.fromLTRB(0, 0, 1, 1),
        // 200px 상자를 실제 페이지 폭의 5분의 1쯤으로 본다.
        scaleOverride: 1,
      ),
    );
  }

  @override
  bool shouldRepaint(_WidthPreview old) =>
      old.width != width || old.color != color || old.preset != preset;
}

class _ShapePreview extends CustomPainter {
  _ShapePreview(this.kind, this.color);
  final ShapeKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    InkPainter.paintStroke(
      canvas,
      Stroke(
        id: 'p',
        tool: StrokeTool.shape,
        color: color,
        width: 1,
        shape: kind,
        points: const [InkPoint(0.1, 0.2), InkPoint(0.9, 0.8)],
      ),
      InkTransform(
        size: size,
        crop: const Rect.fromLTRB(0, 0, 1, 1),
        scaleOverride: 1,
      ),
    );
  }

  @override
  bool shouldRepaint(_ShapePreview old) =>
      old.kind != kind || old.color != color;
}

/// 스탬프 고르기.
class StampPalette extends StatelessWidget {
  const StampPalette({
    super.key,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final group in stampGroups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              tr(group.title),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final stamp in group.stamps)
                Tooltip(
                  message: tr(stamp.label),
                  child: InkWell(
                    onTap: () => onSelected(stamp.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 64,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: stamp.id == selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: stamp.id == selected ? 2 : 1,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _StampPreview(stamp.id, color),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StampPreview extends CustomPainter {
  _StampPreview(this.id, this.color);
  final String id;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    InkPainter.paintPlaced(
      canvas,
      PlacedAnnotation(
        id: 'p',
        kind: PlacedKind.stamp,
        value: id,
        x: 0.5,
        y: 0.5,
        color: color,
        fontSize: 26,
      ),
      InkTransform(
        size: size,
        crop: const Rect.fromLTRB(0, 0, 1, 1),
        scaleOverride: 1,
      ),
      // 칸 밖으로 삐져나오지 않게 글자를 줄인다. 양옆에 숨 쉴 자리를 둔다.
      maxWidth: size.width - 8,
    );
  }

  @override
  bool shouldRepaint(_StampPreview old) => old.id != id || old.color != color;
}
