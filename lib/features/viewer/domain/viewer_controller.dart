import 'package:flutter/foundation.dart';

import '../../../core/db/tables.dart';

/// 페이지 이동 명령.
///
/// 탭, 스와이프, 블루투스 페달, 얼굴 제스처, 원격 기기가 모두 이 명령으로
/// 수렴한다. 입력 장치가 늘어도 뷰어는 이 목록만 알면 된다.
enum TurnCommand { next, previous, first, last }

@immutable
class ViewerState {
  const ViewerState({
    required this.pageCount,
    this.layout = PageLayout.single,
    this.animation = TurnAnimation.slide,
    this.pageIndex = 0,
    this.startOnRight = false,
    this.dualStepOne = true,
    this.performanceMode = false,
    this.autoScrolling = false,
    this.autoScrollSeconds = 180,
    this.annotating = false,
    this.editingJumps = false,
  });

  final int pageCount;
  final PageLayout layout;
  final TurnAnimation animation;

  /// 현재 보고 있는 0-based 페이지. 2페이지 보기에서는 왼쪽 페이지다.
  final int pageIndex;

  /// 2페이지 보기에서 첫 페이지를 오른쪽에 두는지. 펼침면을 맞출 때 쓴다.
  /// 두 장씩 넘길 때만 뜻이 있다.
  final bool startOnRight;

  /// 2페이지 보기에서 한 장씩 밀어 넘기는지.
  /// 참이면 (1,2) (2,3) (3,4), 거짓이면 (1,2) (3,4) 로 넘어간다.
  final bool dualStepOne;

  /// 연주 중 오조작을 막는 모드. 화면을 눌러도 메뉴가 뜨지 않는다.
  final bool performanceMode;

  final bool autoScrolling;

  /// 악보 전체를 자동으로 훑는 데 걸리는 시간(초).
  final double autoScrollSeconds;

  /// 필기 모드. 켜지면 탭 영역이 꺼지고 페이지 위 필기 층이 입력을 받는다.
  final bool annotating;

  /// 점프 버튼 편집 모드. 빈 곳을 눌러 버튼을 놓는다.
  final bool editingJumps;

  /// 탭 영역을 꺼야 하는 상태.
  bool get overlayEditing => annotating || editingJumps;

  bool get isStrip => layout == PageLayout.scroll || layout == PageLayout.half;
  bool get isPaged => !isStrip;

  int get spreadStep => layout == PageLayout.dual && !dualStepOne ? 2 : 1;

  /// 한 장씩 미는 2페이지 보기. 페이지를 한 줄로 이어 붙여 반 화면씩 밀기
  /// 때문에 묶음이 통째로 갈리는 것을 전제로 한 넘김 효과는 쓸 수 없다.
  bool get slidesOnePage => layout == PageLayout.dual && dualStepOne;

  bool get canGoNext => pageIndex + spreadStep < pageCount;
  bool get canGoPrevious => pageIndex > 0;

  ViewerState copyWith({
    int? pageCount,
    PageLayout? layout,
    TurnAnimation? animation,
    int? pageIndex,
    bool? startOnRight,
    bool? dualStepOne,
    bool? performanceMode,
    bool? autoScrolling,
    double? autoScrollSeconds,
    bool? annotating,
    bool? editingJumps,
  }) {
    return ViewerState(
      pageCount: pageCount ?? this.pageCount,
      layout: layout ?? this.layout,
      animation: animation ?? this.animation,
      pageIndex: pageIndex ?? this.pageIndex,
      startOnRight: startOnRight ?? this.startOnRight,
      dualStepOne: dualStepOne ?? this.dualStepOne,
      performanceMode: performanceMode ?? this.performanceMode,
      autoScrolling: autoScrolling ?? this.autoScrolling,
      autoScrollSeconds: autoScrollSeconds ?? this.autoScrollSeconds,
      annotating: annotating ?? this.annotating,
      editingJumps: editingJumps ?? this.editingJumps,
    );
  }
}

/// 뷰어의 상태와 이동 명령을 담당한다.
///
/// 악보 보기 화면과 수명이 같으므로 provider 로 올리지 않고 화면이 소유한다.
/// 실제 스크롤은 화면 쪽 위젯이 [ViewerState.pageIndex] 변화를 보고 따라간다.
class ViewerController extends ChangeNotifier {
  ViewerController(ViewerState initial) : _state = initial;

  ViewerState _state;
  ViewerState get state => _state;

  /// 페이지가 바뀐 순간 호출된다. 미리 굽기와 마지막 위치 저장에 쓴다.
  ValueChanged<int>? onPageChanged;

  void _set(ViewerState next) {
    if (identical(next, _state)) return;
    final pageMoved = next.pageIndex != _state.pageIndex;
    _state = next;
    notifyListeners();
    if (pageMoved) onPageChanged?.call(next.pageIndex);
  }

  /// 화면 쪽에서 스크롤로 페이지가 바뀌었을 때 되돌려 알린다.
  /// 여기서 다시 스크롤을 지시하면 무한 반복이 되므로 상태만 바꾼다.
  void reportPageChanged(int index) {
    if (_state.pageCount == 0) return;
    final clamped = index.clamp(0, _state.pageCount - 1);
    if (clamped == _state.pageIndex) return;
    _set(_state.copyWith(pageIndex: clamped));
  }

  void handle(TurnCommand command) {
    switch (command) {
      case TurnCommand.next:
        goToPage(_state.pageIndex + _state.spreadStep);
      case TurnCommand.previous:
        goToPage(_state.pageIndex - _state.spreadStep);
      case TurnCommand.first:
        goToPage(0);
      case TurnCommand.last:
        goToPage(_state.pageCount - 1);
    }
  }

  void goToPage(int index) {
    if (_state.pageCount == 0) return;
    final clamped = index.clamp(0, _state.pageCount - 1);
    if (clamped == _state.pageIndex) return;
    _set(_state.copyWith(pageIndex: clamped));
  }

  /// 세션을 다시 열어 페이지 수가 달라졌을 때 맞춰 준다.
  ///
  /// 화면을 그리는 도중에 불릴 수 있어 [onPageChanged] 는 부르지 않는다.
  /// 미리 굽기와 자리 기록은 화면 쪽이 프레임이 끝난 뒤에 따로 한다.
  void resize(int pageCount, int pageIndex) {
    final clamped = pageIndex.clamp(0, (pageCount - 1).clamp(0, 1 << 30));
    if (pageCount == _state.pageCount && clamped == _state.pageIndex) return;
    _state = _state.copyWith(pageCount: pageCount, pageIndex: clamped);
    notifyListeners();
  }

  void setLayout(PageLayout layout) {
    if (layout == _state.layout) return;
    // 스크롤 계열에서 벗어나면 자동 스크롤은 의미가 없다.
    _set(
      _state.copyWith(
        layout: layout,
        autoScrolling: false,
        animation: _animationFor(layout, _state.animation),
      ),
    );
  }

  /// 레이아웃이 감당할 수 없는 애니메이션이 남지 않게 맞춰 준다.
  TurnAnimation _animationFor(PageLayout layout, TurnAnimation current) {
    return switch (layout) {
      PageLayout.scroll || PageLayout.half => TurnAnimation.scroll,
      PageLayout.single || PageLayout.dual =>
        current == TurnAnimation.scroll ? TurnAnimation.slide : current,
    };
  }

  void setAnimation(TurnAnimation animation) {
    if (_state.isStrip) return;
    _set(_state.copyWith(animation: animation));
  }

  void setStartOnRight(bool value) =>
      _set(_state.copyWith(startOnRight: value));

  void setDualStepOne(bool value) =>
      _set(_state.copyWith(dualStepOne: value));

  void setPerformanceMode(bool value) =>
      _set(_state.copyWith(performanceMode: value));

  void setAutoScrolling(bool value) {
    if (!_state.isStrip && value) return;
    if (value == _state.autoScrolling) return;
    _set(_state.copyWith(autoScrolling: value));
  }

  void toggleAutoScrolling() => setAutoScrolling(!_state.autoScrolling);

  void setAutoScrollSeconds(double seconds) =>
      _set(_state.copyWith(autoScrollSeconds: seconds.clamp(10, 3600)));

  void setAnnotating(bool value) {
    if (value == _state.annotating) return;
    // 필기 중에는 자동 스크롤이 손을 방해한다.
    _set(_state.copyWith(annotating: value, autoScrolling: false, editingJumps: false));
  }

  void setEditingJumps(bool value) {
    if (value == _state.editingJumps) return;
    _set(_state.copyWith(editingJumps: value, autoScrolling: false, annotating: false));
  }
}
