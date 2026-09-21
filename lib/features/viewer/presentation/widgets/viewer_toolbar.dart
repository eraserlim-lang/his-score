import 'package:flutter/material.dart';

import '../../../../core/db/tables.dart';
import '../../data/face_turn_service.dart';
import '../../domain/viewer_controller.dart';
import '../../../../core/i18n/tr.dart';

/// 하단 도구 막대.
///
/// 왼쪽 끝에 음악 도구, 가운데에 자동 스크롤, 오른쪽에 페이지와 보기 도구를
/// 둔다. 보기 방식은 가장 오른쪽 끝이다.
class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.state,
    required this.controller,
    required this.isLandscape,
    required this.onPageMenu,
    required this.onSync,
    required this.onSettings,
    this.faceGesture,
    this.leading,
    this.leadingButtons = 0,
  });

  final ViewerState state;
  final ViewerController controller;
  final bool isLandscape;
  final ValueChanged<String> onPageMenu;
  final VoidCallback onSync;

  /// 악보를 닫지 않고 설정을 연다. 화면 꺼짐이나 페달을 연주 중에 바꾼다.
  final VoidCallback onSettings;

  /// 얼굴 제스처 서비스. 지원하지 않는 플랫폼이면 null.
  final FaceTurnService? faceGesture;

  /// 막대 왼쪽 끝에 놓을 것(음악 도구). 자리가 모자라면 접힌 모양을 청한다.
  final Widget Function(bool collapsed)? leading;

  /// [leading] 을 다 펼쳤을 때의 버튼 수. 넘치는지 가늠할 때 쓴다.
  final int leadingButtons;

  /// 막대 아이콘 크기. 막대 높이(56) 안에서 선택된 도구의 색 바탕이 막대
  /// 밖으로 넘치지 않는 가장 큰 값이다. 연주 중에 한눈에 찾아 누르기 쉽다.
  static const _iconSize = 36.0;

  /// 버튼 하나의 폭(아이콘 + 양옆 여백 8). 막대가 넘치는지 가늠할 때 쓴다.
  static const _button = _iconSize + 16;

  /// 자동 스크롤 속도 막대가 쓸 만하려면 이만큼은 있어야 한다.
  static const _minSpeedSlider = 160.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // 오른쪽 버튼 수: 보기 방식, 페이지 도구, 북마크, 필기, 윙크, 동기화,
    // 연주 모드, 설정.
    final trailing = 7 + (faceGesture != null ? 1 : 0);

    return Material(
      color: scheme.surface.withValues(alpha: 0.95),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 음악 도구 다섯 개를 다 늘어놓아도 넘치지 않는지 본다.
              // 세로 스크롤 보기는 속도 막대 자리까지 남아야 한다.
              final needed =
                  16 +
                  _button * (trailing + leadingButtons) +
                  (state.isStrip ? _button + _minSpeedSlider : 0);
              final collapsed = constraints.maxWidth < needed;
              // 막대 안의 모든 아이콘(메뉴 단추 포함)이 이 크기를 따른다.
              // 펼쳐지는 메뉴는 다른 층이라 영향받지 않는다.
              return IconTheme.merge(
                data: const IconThemeData(size: _iconSize),
                child: _row(context, collapsed),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, bool collapsed) {
    return Row(
      children: [
        const SizedBox(width: 8),
        ?leading?.call(collapsed),
        if (state.isStrip)
          IconButton(
            onPressed: controller.toggleAutoScrolling,
            tooltip: state.autoScrolling ? tr('자동 스크롤 정지') : tr('자동 스크롤 시작'),
            isSelected: state.autoScrolling,
            icon: Icon(state.autoScrolling ? Icons.pause : Icons.play_arrow),
          ),
        if (state.isStrip)
          Expanded(
            child: _SpeedSlider(state: state, controller: controller),
          )
        else
          const Spacer(),
        // 오른쪽 순서: 보기 방식, 페이지 도구, 북마크, 필기, 윙크 넘기기,
        // 기기 동기화, 연주 모드, 설정.
        _LayoutButton(
          state: state,
          controller: controller,
          isLandscape: isLandscape,
        ),
        PopupMenuButton<String>(
          tooltip: tr('페이지 도구'),
          // 페이지 도구에서 가장 자주 여는 것이 여백·기울기 조정이다.
          icon: const Icon(Icons.crop),
          onSelected: onPageMenu,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'crop',
              child: ListTile(
                leading: Icon(Icons.crop),
                title: Text(tr('여백·기울기 조정')),
              ),
            ),
            PopupMenuItem(
              value: 'order',
              child: ListTile(
                leading: Icon(Icons.reorder),
                title: Text(tr('페이지 순서 편집')),
              ),
            ),
            PopupMenuItem(
              value: 'jumps',
              child: ListTile(
                leading: Icon(Icons.call_missed_outgoing),
                title: Text(tr('점프 버튼 편집')),
              ),
            ),
            PopupMenuItem(
              value: 'savePage',
              child: ListTile(
                leading: Icon(Icons.file_download_outlined),
                title: Text(tr('이 페이지 저장')),
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.ios_share),
                title: Text(tr('내보내기 · 인쇄')),
              ),
            ),
          ],
        ),
        // 북마크는 자주 쓴다. 메뉴 속에 묻어 두지 않고 막대에 내놓는다.
        IconButton(
          tooltip: tr('북마크'),
          icon: const Icon(Icons.bookmark_border),
          onPressed: () => onPageMenu('bookmarks'),
        ),
        IconButton(
          onPressed: () => controller.setAnnotating(true),
          tooltip: tr('필기'),
          icon: const Icon(Icons.draw_outlined),
        ),
        if (faceGesture != null)
          ListenableBuilder(
            listenable: faceGesture!,
            builder: (context, _) => IconButton(
              onPressed: () =>
                  faceGesture!.setGestures(!faceGesture!.gesturesOn),
              isSelected: faceGesture!.gesturesOn,
              tooltip: faceGesture!.gesturesOn
                  ? (faceGesture!.faceVisible
                        ? tr('윙크 넘김 켜짐 (얼굴 인식 중)')
                        : tr('윙크 넘김 켜짐 (얼굴을 찾는 중)'))
                  : tr('윙크로 넘기기'),
              icon: Icon(
                faceGesture!.gesturesOn
                    ? (faceGesture!.faceVisible
                          ? Icons.face
                          : Icons.face_retouching_off)
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
          onPressed: () => controller.setPerformanceMode(true),
          tooltip: tr('연주 모드'),
          // 플레이어(음표)와 같은 아이콘이라 헷갈렸다. 연주 모드는 막대를
          // 걷고 악보만 크게 보이는 것이라 전체 화면으로 나타낸다.
          icon: const Icon(Icons.fullscreen),
        ),
        IconButton(
          onPressed: onSettings,
          tooltip: tr('설정'),
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// 보기 방식 메뉴.
///
/// 몇 장을 어떻게 펼쳐 볼지와 어떻게 넘길지는 한 가지 이야기다. 페이지 도구에
/// 흩어 두면 넘김 효과를 바꾸러 악보 편집 메뉴를 뒤지게 된다. 한 곳에 모은다.
class _LayoutButton extends StatelessWidget {
  const _LayoutButton({
    required this.state,
    required this.controller,
    required this.isLandscape,
  });

  final ViewerState state;
  final ViewerController controller;
  final bool isLandscape;

  void _select(String value) {
    switch (value) {
      case 'single':
        controller.setLayout(PageLayout.single);
      case 'scroll':
        controller.setLayout(PageLayout.scroll);
      case 'half':
        controller.setLayout(PageLayout.half);
      case 'dual':
        controller.setLayout(PageLayout.dual);
      case 'dualStepOne':
        controller.setDualStepOne(!state.dualStepOne);
      case 'startOnRight':
        controller.setStartOnRight(!state.startOnRight);
      case 'anim_slide':
        controller.setAnimation(TurnAnimation.slide);
      case 'anim_stack':
        controller.setAnimation(TurnAnimation.stack);
      case 'anim_curl':
        controller.setAnimation(TurnAnimation.curl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tr('보기 방식'),
      onSelected: _select,
      icon: Icon(_iconFor(state.layout)),
      itemBuilder: (context) => [
        _header(context, tr('보기 방식')),
        _item(
          'single',
          Icons.crop_portrait,
          tr('1페이지'),
          true,
          checked: state.layout == PageLayout.single,
        ),
        _item(
          'scroll',
          Icons.swap_vert,
          tr('세로 스크롤'),
          true,
          checked: state.layout == PageLayout.scroll,
        ),
        // 반페이지는 다음 줄을 미리 보여주는 것이 목적이라 세로에서만 뜻이 있다.
        _item(
          'half',
          Icons.splitscreen,
          tr('반페이지'),
          !isLandscape,
          checked: state.layout == PageLayout.half,
          note: tr('세로 화면 전용'),
        ),
        _item(
          'dual',
          Icons.import_contacts,
          tr('2페이지'),
          isLandscape,
          checked: state.layout == PageLayout.dual,
          note: tr('가로 화면 전용'),
        ),

        if (state.layout == PageLayout.dual) ...[
          const PopupMenuDivider(),
          _header(context, tr('펼침면')),
          CheckedPopupMenuItem(
            value: 'dualStepOne',
            checked: state.dualStepOne,
            child: Text(tr('한 장씩 밀어 넘기기')),
          ),
          // 한 장씩 밀 때도 뜻이 있다. 맨 앞에 빈 자리를 두어 지금 쪽이
          // 왼쪽이 아니라 오른쪽에 서게 한다.
          CheckedPopupMenuItem(
            value: 'startOnRight',
            checked: state.startOnRight,
            child: Text(tr('첫 장을 오른쪽에')),
          ),
        ],

        if (state.isPaged) ...[
          const PopupMenuDivider(),
          _header(context, tr('넘김')),
          CheckedPopupMenuItem(
            value: 'anim_slide',
            checked: state.animation == TurnAnimation.slide,
            child: Text(tr('밀기')),
          ),
          // 한 장씩 미는 2페이지 보기는 페이지를 한 줄로 이어 붙여 민다.
          // 묶음이 통째로 갈리는 것을 전제로 만든 쌓기와 넘기기는 그 띠와
          // 맞지 않아 내놓지 않는다.
          if (!state.slidesOnePage) ...[
            CheckedPopupMenuItem(
              value: 'anim_stack',
              checked: state.animation == TurnAnimation.stack,
              child: Text(tr('쌓기')),
            ),
            CheckedPopupMenuItem(
              value: 'anim_curl',
              checked: state.animation == TurnAnimation.curl,
              child: Text(tr('넘기기')),
            ),
          ],
        ],
      ],
    );
  }

  /// 고를 수 없는 이름표. 묶음이 세 덩이라 무엇을 고르는지 밝혀 둔다.
  PopupMenuItem<String> _header(BuildContext context, String label) {
    return PopupMenuItem(
      enabled: false,
      height: 32,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(
    String value,
    IconData icon,
    String label,
    bool enabled, {
    required bool checked,
    String? note,
  }) {
    return PopupMenuItem(
      value: value,
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
          if (checked) ...[const Spacer(), const Icon(Icons.check, size: 18)],
        ],
      ),
    );
  }

  IconData _iconFor(PageLayout layout) => switch (layout) {
    // 빈 사각형(crop_portrait)은 1페이지로 읽히지 않았다. 귀접힌 종이 한 장.
    PageLayout.single => Icons.insert_drive_file_outlined,
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
