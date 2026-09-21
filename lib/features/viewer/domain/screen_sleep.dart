import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/settings_dao.dart';

/// 악보를 보는 동안 화면을 언제 끌지.
enum ScreenSleepMode {
  /// 기기 설정(자동 잠금)을 그대로 따른다. 앱은 화면을 붙잡지 않는다.
  system,

  /// 악보를 보는 동안에는 끄지 않는다.
  never,
}

/// 화면 자동 꺼짐 설정.
///
/// 예전에는 "손이 닿은 뒤 n분" 과 "보고 있으면 켜 둠" 도 있었다. 앞의 것은
/// 기기의 자동 잠금과 하는 일이 겹쳐 두 설정이 서로 헷갈렸고, 뒤의 것은
/// 전면 카메라를 연주 내내 돌려 배터리와 발열 부담이 컸다. 둘 다 걷어내고
/// 기기에 맡기거나 아예 끄지 않거나 둘 중 하나로 둔다.
@immutable
class ScreenSleep {
  const ScreenSleep(this.mode);

  final ScreenSleepMode mode;

  static const defaults = ScreenSleep(ScreenSleepMode.system);

  String encode() => switch (mode) {
    ScreenSleepMode.never => 'always',
    ScreenSleepMode.system => 'system',
  };

  /// 예전 값('min:5', 'auto')은 모두 시스템 설정으로 넘어간다.
  static ScreenSleep decode(String? raw) {
    if (raw == 'always') return const ScreenSleep(ScreenSleepMode.never);
    return defaults;
  }

  @override
  bool operator ==(Object other) => other is ScreenSleep && other.mode == mode;

  @override
  int get hashCode => mode.hashCode;
}

/// 지금 설정. 설정 화면에서 바꾸면 보고 있는 악보에 곧바로 반영된다.
final screenSleepProvider = Provider<ScreenSleep>((ref) {
  final raw = ref.watch(settingProvider(SettingKeys.screenSleep)).value;
  return ScreenSleep.decode(raw);
});

/// 악보를 보는 동안 화면을 붙잡아 두는 일을 맡는다.
///
/// [ScreenSleepMode.never] 면 붙잡고, 아니면 놓아 기기 설정에 맡긴다.
class ScreenAwake {
  ScreenSleep _setting = ScreenSleep.defaults;
  bool _held = false;
  bool _disposed = false;

  ScreenSleep get setting => _setting;

  /// 설정을 적용한다. 화면이 열릴 때와 설정이 바뀔 때 부른다.
  void apply(ScreenSleep setting) {
    if (_disposed) return;
    _setting = setting;
    if (setting.mode == ScreenSleepMode.never) {
      _hold();
    } else {
      _release();
    }
  }

  void _hold() {
    if (_held) return;
    _held = true;
    _set(true);
  }

  void _release() {
    if (!_held) return;
    _held = false;
    _set(false);
  }

  void _set(bool on) {
    // 지원하지 않는 자리(데스크톱 일부)에서는 조용히 넘어간다.
    unawaited(
      WakelockPlus.toggle(enable: on).catchError((Object e) {
        debugPrint('화면 꺼짐 설정 실패: $e');
      }),
    );
  }

  void dispose() {
    _disposed = true;
    _release();
  }
}
