# R8 로 코드를 줄일 때 지켜야 하는 것들.

# Flutter 와 플러그인 엔진 진입점
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ML Kit 얼굴 인식: 네이티브에서 리플렉션으로 찾는다
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**

# sqlite3 / drift 네이티브 라이브러리 로더
-keep class eu.simonbinder.** { *; }

# 앱 자체 네이티브 브리지
-keep class com.eraser.his_score.** { *; }
