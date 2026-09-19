import 'package:flutter/material.dart';

import '../../../../core/db/tables.dart';
import '../../data/face_turn_service.dart';
import '../../domain/viewer_controller.dart';
import '../../../../core/i18n/tr.dart';

/// 하단 도구 막대. 레이아웃 전환과 자동 스크롤을 담는다.
class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.state,
    required this.controller,
    required this.isLandscape,
    required this.onPageMenu,
    required this.onSync,
    this.faceGesture,
  });

  final ViewerState state;
  final ViewerController controller;
  final bool isLandscape;
  final ValueChanged<String> onPageMenu;
  final VoidCallback onSync;

  /// 얼굴 제스처 서비스. 지원하지 않는 플랫폼이면 null.
  final FaceTurnService? faceGesture;

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
                  tooltip: state.autoScrolling ? tr('자동 스크롤 정지') : tr('자동 스크롤 시작'),
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
              PopupMenuButton<String>(
                tooltip: tr('페이지 도구'),
                icon: const Icon(Icons.auto_stories_outlined),
                onSelected: onPageMenu,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'bookmarks',
                    child: ListTile(leading: Icon(Icons.bookmark_border), title: Text(tr('북마크'))),
                  ),
                  PopupMenuItem(
                    value: 'crop',
                    child: ListTile(leading: Icon(Icons.crop), title: Text(tr('여백·기울기 조정'))),
                  ),
                  PopupMenuItem(
                    value: 'order',
                    child: ListTile(leading: Icon(Icons.reorder), title: Text(tr('페이지 순서 편집'))),
                  ),
                  PopupMenuItem(
                    value: 'jumps',
                    child: ListTile(leading: Icon(Icons.call_missed_outgoing), title: Text(tr('점프 버튼 편집'))),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: ListTile(leading: Icon(Icons.ios_share), title: Text(tr('내보내기 · 인쇄'))),
                  ),
                  const PopupMenuDivider(),
                  if (state.layout == PageLayout.dual) ...[
                    CheckedPopupMenuItem(
                      value: 'dualStepOne',
                      checked: state.dualStepOne,
                      child: Text(tr('한 장씩 밀어 넘기기')),
                    ),
                    // 펼침면 맞추기는 두 장씩 넘길 때만 뜻이 있다.
                    if (!state.dualStepOne)
                      CheckedPopupMenuItem(
                        value: 'startOnRight',
                        checked: state.startOnRight,
                        child: Text(tr('첫 장을 오른쪽에')),
                      ),
                  ],
                  if (state.isPaged) ...[
                    CheckedPopupMenuItem(
                      value: 'anim_slide',
                      checked: state.animation == TurnAnimation.slide,
                      child: Text(tr('넘김: 밀기')),
                    ),
                    CheckedPopupMenuItem(
                      value: 'anim_stack',
                      checked: state.animation == TurnAnimation.stack,
                      child: Text(tr('넘김: 쌓기')),
                    ),
                    CheckedPopupMenuItem(
                      value: 'anim_curl',
                      checked: state.animation == TurnAnimation.curl,
                      child: Text(tr('넘김: 넘기기')),
                    ),
                  ],
                ],
              ),
              if (faceGesture != null)
                ListenableBuilder(
                  listenable: faceGesture!,
                  builder: (context, _) => IconButton(
                    onPressed: () => faceGesture!.running ? faceGesture!.stop() : faceGesture!.start(),
                    isSelected: faceGesture!.running,
                    tooltip: faceGesture!.running
                        ? (faceGesture!.faceVisible ? tr('윙크 넘김 켜짐 (얼굴 인식 중)') : tr('윙크 넘김 켜짐 (얼굴을 찾는 중)'))
                        : tr('윙크로 넘기기'),
                    icon: Icon(
                      faceGesture!.running
                          ? (faceGesture!.faceVisible ? Icons.face : Icons.face_retouching_off)
                          : Icons.face_outlined,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onSync,
                tooltip: tr('기기 동기화 / 리모컨'),
                icon: const Icon(Icons.devices_other_outlined),
              ),
              IconButton(
                onPressed: () => controller.setAnnotating(true),
                tooltip: tr('필기'),
                icon: const Icon(Icons.draw_outlined),
              ),
              IconButton(
                onPressed: () => controller.setPerformanceMode(true),
                tooltip: tr('연주 모드'),
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
      tooltip: tr('보기 방식'),
      initialValue: state.layout,
      onSelected: controller.setLayout,
      icon: Icon(_iconFor(state.layout)),
      itemBuilder: (context) => [
        _item(PageLayout.single, Icons.crop_portrait, tr('1페이지'), true),
        _item(PageLayout.scroll, Icons.swap_vert, tr('세로 스크롤'), true),
        // 반페이지는 다음 줄을 미리 보여주는 것이 목적이라 세로에서만 뜻이 있다.
        _item(PageLayout.half, Icons.splitscreen, tr('반페이지'), !isLandscape,
            note: tr('세로 화면 전용')),
        _item(PageLayout.dual, Icons.import_contacts, tr('2페이지'), isLandscape,
            note: tr('가로 화면 전용')),
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
            tr('{0}분', [minutes.toStringAsFixed(1)]),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
