import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 앱 문자열 번역.
///
/// 소스 코드의 한국어 문자열이 곧 키다. `tr('악보')` 는 현재 언어가 한국어면
/// 그대로, 영어면 assets/i18n/en.json 에서 찾은 값을 준다. 없으면 한국어로 둔다.
/// 자리표시자는 `{0}`, `{1}` 순서로 넣는다.
///
/// ARB 방식 대신 이렇게 한 이유: 코드에서 문자열을 그대로 읽을 수 있고,
/// 번역이 빠진 문장이 있어도 화면이 비지 않는다.
String tr(String key, [List<Object?> args = const []]) {
  var text = AppLocale.lookup(key);
  for (var i = 0; i < args.length; i++) {
    text = text.replaceAll('{$i}', '${args[i]}');
  }
  return text;
}

/// 현재 언어. 바뀌면 MaterialApp 이 다시 그려진다.
abstract final class AppLocale {
  static const supported = [Locale('ko'), Locale('en'), Locale('ja')];

  /// null 이면 시스템 언어를 따른다.
  static final override = ValueNotifier<Locale?>(null);

  static Locale get current {
    final o = override.value;
    if (o != null) return o;
    final system = PlatformDispatcher.instance.locale;
    return supported.firstWhere(
      (l) => l.languageCode == system.languageCode,
      orElse: () => const Locale('ko'),
    );
  }

  static final _tables = <String, Map<String, String>>{};

  /// 앱 시작 때 번역 표를 전부 읽어 둔다. 몇십 KB 라 부담이 없다.
  static Future<void> load() async {
    for (final locale in supported) {
      if (locale.languageCode == 'ko') continue;
      try {
        final raw = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
        final map = (jsonDecode(raw) as Map<String, dynamic>).cast<String, String>();
        _tables[locale.languageCode] = map;
      } on Object catch (e) {
        debugPrint('번역 표를 읽지 못했습니다 ${locale.languageCode}: $e');
      }
    }
  }

  /// 테스트나 동적 등록용.
  static void register(String languageCode, Map<String, String> table) =>
      _tables[languageCode] = table;

  static String lookup(String key) {
    final code = current.languageCode;
    if (code == 'ko') return key;
    return _tables[code]?[key] ?? key;
  }

  static String labelOf(Locale? l) => switch (l?.languageCode) {
        null => tr('시스템 언어'),
        'ko' => '한국어',
        'en' => 'English',
        'ja' => '日本語',
        _ => l.toString(),
      };
}
