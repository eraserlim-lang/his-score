import 'package:flutter/material.dart';

/// HIScore 의 색과 타이포. 악보가 주인공이므로 UI 는 채도를 낮게 둔다.
abstract final class AppTheme {
  static const seed = Color(0xFF3B6EA8);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

/// 악보 보기 화면 전용 색. 테마와 무관하게 고정한다.
abstract final class ViewerColors {
  /// 악보 뒤 배경. 눈부심을 줄이되 흰 종이와 구분되게 한다.
  static const canvas = Color(0xFF2A2C31);
  static const canvasLight = Color(0xFFE8E9EC);

  /// 필기 기본 6색. Piascore 와 같은 구성에 가독성을 맞췄다.
  static const inkColors = <Color>[
    Color(0xFF1A1A1A), // 검정
    Color(0xFFD32F2F), // 빨강
    Color(0xFF1976D2), // 파랑
    Color(0xFF388E3C), // 초록
    Color(0xFFF9A825), // 노랑
    Color(0xFF7B1FA2), // 보라
  ];
}
