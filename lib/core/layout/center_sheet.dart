import 'package:flutter/material.dart';

/// 화면 가운데에 띄우는 판.
///
/// 바닥 시트는 아이패드에서 화면 아래쪽 끝에만 붙어 손이 멀고, 넓은 화면에서는
/// 가운데가 비어 어색하다. 건반처럼 아래에 붙어야 뜻이 있는 것만 시트로 두고
/// 나머지는 이 판으로 연다.
Future<T?> showCenterSheet<T>(
  BuildContext context, {
  required Widget child,
  double maxWidth = 560,

  /// 세로 크기를 화면에 맞춰 늘릴지. 목록처럼 안에서 스스로 스크롤하는
  /// 내용은 켜야 높이가 정해진다.
  bool fill = false,

  /// 내용이 길면 이 판이 스크롤할지. 안에서 스크롤하는 내용은 꺼야 한다.
  bool scrollable = true,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      final screen = MediaQuery.sizeOf(context);
      final maxHeight = screen.height * 0.86;

      return Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            minHeight: fill ? maxHeight : 0,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: scrollable ? SingleChildScrollView(child: child) : child,
          ),
        ),
      );
    },
  );
}
