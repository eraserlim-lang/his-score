import 'package:flutter/widgets.dart';

/// 페이지를 빠르게 훑는 중이라고 아래에 알린다.
///
/// 슬라이더로 수십 쪽을 훑으면 스쳐 가는 쪽마다 제 모습을 다 갖추려 든다.
/// 페이지는 화면 해상도로 굽고(iPad 에서 한 장 30MB), iOS 는 쪽마다 PencilKit
/// 네이티브 뷰를 새로 띄운다. 굽는 일꾼은 하나뿐이라 줄이 밀리고, 화면은
/// 손가락을 따라오다 멈춘다. 훑는 동안은 페이지를 거칠게 굽고 무거운 층은
/// 떼어 둔다. 손을 놓으면 제 모습으로 돌아온다.
class PagePreviewScope extends InheritedWidget {
  const PagePreviewScope({
    super.key,
    required this.preview,
    required super.child,
  });

  final bool preview;

  /// 훑는 중인지. 표지가 없으면 아니다.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PagePreviewScope>()?.preview ??
      false;

  @override
  bool updateShouldNotify(PagePreviewScope oldWidget) =>
      oldWidget.preview != preview;
}
