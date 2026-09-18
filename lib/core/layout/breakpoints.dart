import 'package:flutter/widgets.dart';

/// 화면 폭에 따른 3단 레이아웃 구분.
///
/// 폰은 1단(목록 또는 상세), 태블릿은 2단(목록 + 상세),
/// 데스크톱은 사이드바가 붙은 3단으로 간다.
enum FormFactor { compact, medium, expanded }

abstract final class Breakpoints {
  static const medium = 600.0;
  static const expanded = 1000.0;

  static FormFactor of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expanded) return FormFactor.expanded;
    if (width >= medium) return FormFactor.medium;
    return FormFactor.compact;
  }
}

extension FormFactorX on FormFactor {
  bool get isCompact => this == FormFactor.compact;
  bool get isExpanded => this == FormFactor.expanded;

  /// 목록과 상세를 한 화면에 같이 보여줄 수 있는지.
  bool get showsTwoPanes => this != FormFactor.compact;

  /// 카탈로그 그리드의 열 수.
  int get gridColumns => switch (this) {
        FormFactor.compact => 2,
        FormFactor.medium => 4,
        FormFactor.expanded => 6,
      };
}
