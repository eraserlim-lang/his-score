import 'package:flutter/material.dart';

import '../../../../core/db/tables.dart';
import '../../domain/viewer_controller.dart';

/// 하단 도구 막대. 레이아웃 전환과 자동 스크롤을 담는다.
class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.state,
    required this.controller,
    required this.isLandscape,
  });

  final ViewerState state;
  final ViewerController controller;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.95),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 8),
              _LayoutButton(
                state: state,
                controller: controller,
                isLandscape: isLandscape,
              ),
              if (state.isStrip)
                IconButton(
                  onPressed: controller.toggleAutoScrolling,
                  tooltip: state.autoScrolling ? '자동 스크롤 정지' : '자동 스크롤 시작',
                  isSelected: state.autoScrolling,
                  icon: Icon(
                    state.autoScrolling ? Icons.pause : Icons.play_arrow,
                  ),
                ),
              if (state.isStrip)
                Expanded(
                  child: _SpeedSlider(state: state, controller: controller),
                )
              else
                const Spacer(),
              IconButton(
                onPressed: () => controller.setPerformanceMode(true),
                tooltip: '연주 모드',
                icon: const Icon(Icons.music_note_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutButton extends StatelessWidget {
  const _LayoutButton({
    required this.state,
    required this.controller,
    required this.isLandscape,
  });

  final ViewerState state;
  final ViewerController controller;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PageLayout>(
      tooltip: '보기 방식',
      initialValue: state.layout,
      onSelected: controller.setLayout,
      icon: Icon(_iconFor(state.layout)),
      itemBuilder: (context) => [
        _item(PageLayout.single, Icons.crop_portrait, '1페이지', true),
        _item(PageLayout.scroll, Icons.swap_vert, '세로 스크롤', true),
        // 반페이지는 다음 줄을 미리 보여주는 것이 목적이라 세로에서만 뜻이 있다.
        _item(PageLayout.half, Icons.splitscreen, '반페이지', !isLandscape,
            note: '세로 화면 전용'),
        _item(PageLayout.dual, Icons.import_contacts, '2페이지', isLandscape,
            note: '가로 화면 전용'),
      ],
    );
  }

  PopupMenuItem<PageLayout> _item(
    PageLayout layout,
    IconData icon,
    String label,
    bool enabled, {
    String? note,
  }) {
    return PopupMenuItem(
      value: layout,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          if (!enabled && note != null) ...[
            const SizedBox(width: 8),
            Text(note, style: const TextStyle(fontSize: 11)),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(PageLayout layout) => switch (layout) {
        PageLayout.single => Icons.crop_portrait,
        PageLayout.scroll => Icons.swap_vert,
        PageLayout.half => Icons.splitscreen,
        PageLayout.dual => Icons.import_contacts,
      };
}

class _SpeedSlider extends StatelessWidget {
  const _SpeedSlider({required this.state, required this.controller});

  final ViewerState state;
  final ViewerController controller;

  @override
  Widget build(BuildContext context) {
    final minutes = state.autoScrollSeconds / 60;
    return Row(
      children: [
        const Icon(Icons.speed, size: 18),
        Expanded(
          child: Slider(
            // 느릴수록 오른쪽이면 헷갈리므로 오른쪽이 빠르게 뒤집는다.
            value: -state.autoScrollSeconds,
            min: -1800,
            max: -20,
            onChanged: (v) => controller.setAutoScrollSeconds(-v),
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '${minutes.toStringAsFixed(1)}분',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
