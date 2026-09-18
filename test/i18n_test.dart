import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/i18n/tr.dart';

/// 번역 표와 tr() 의 규칙.
void main() {
  final en = (jsonDecode(File('assets/i18n/en.json').readAsStringSync()) as Map).cast<String, String>();
  final ja = (jsonDecode(File('assets/i18n/ja.json').readAsStringSync()) as Map).cast<String, String>();

  setUp(() {
    AppLocale.register('en', en);
    AppLocale.register('ja', ja);
    AppLocale.override.value = null;
  });

  test('한국어는 키 그대로', () {
    AppLocale.override.value = const Locale('ko');
    expect(tr('악보'), '악보');
    expect(tr('{0}곡', [3]), '3곡');
  });

  test('영어와 일본어로 바뀌고 자리표시자가 채워진다', () {
    AppLocale.override.value = const Locale('en');
    expect(tr('악보'), 'Scores');
    expect(tr('{0}곡 · 총 {1}쪽', [2, 15]), '2 songs · 15 pages');

    AppLocale.override.value = const Locale('ja');
    expect(tr('설정'), '設定');
    expect(tr('{0}쪽', [7]), '7ページ');
  });

  test('번역이 없는 문장은 한국어로 남는다', () {
    AppLocale.override.value = const Locale('en');
    expect(tr('번역표에 없는 문장'), '번역표에 없는 문장');
  });

  test('영어와 일본어 표의 키가 같다', () {
    expect(en.keys.toSet(), ja.keys.toSet());
  });

  test('자리표시자 개수가 원문과 번역에서 같다', () {
    final re = RegExp(r'\{\d\}');
    for (final table in [en, ja]) {
      for (final entry in table.entries) {
        final a = re.allMatches(entry.key).map((m) => m.group(0)).toSet();
        final b = re.allMatches(entry.value).map((m) => m.group(0)).toSet();
        expect(b, a, reason: '"${entry.key}" → "${entry.value}"');
      }
    }
  });

  test('코드가 쓰는 모든 키에 번역이 있다', () {
    // tr('...') 리터럴을 전부 긁어 표와 대조한다. 보간 자리표시자는 그대로 비교한다.
    final missing = <String>{};
    final re = RegExp(r"tr\('((?:[^'\\]|\\.)*)'");
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();
      for (final m in re.allMatches(src)) {
        final key = m.group(1)!.replaceAll(r"\'", "'").replaceAll(r'\n', '\n').replaceAll(r'\"', '"');
        if (!en.containsKey(key)) missing.add(key);
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });
}
