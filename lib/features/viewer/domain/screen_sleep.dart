import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/db/settings_dao.dart';
import '../data/face_turn_service.dart';

/// 악보를 보는 동안 화면을 언제 끌지.
enum ScreenSleepMode {
  /// 손이 닿은 뒤 정한 시간이 지나면 기기 설정대로 꺼지게 둔다.
  timed,

  /// 얼굴이 보이는 동안에는 켜 둔다. 전면 카메라를 쓴다.
  watching,

  /// 악보를 보는 동안에는 끄지 않는다.
  never,
}

/// 화면 자동 꺼짐 설정.
@immutable
class ScreenSleep {
  const ScreenSleep(this.mode, {this.minutes = 5});

  final ScreenSleepMode mode;

  /// [ScreenSleepMode.timed] 에서 손이 닿은 뒤 화면을 붙잡아 둘 시간(분).
  final int minutes;

  static const defaults = ScreenSleep(ScreenSleepMode.timed);

  /// 고를 수 있는 시간. 연주 한 곡이 대개 3~5분이다.
  static const minuteChoices = [1, 3, 5, 10, 30];

  /// 얼굴이 사라진 뒤 이만큼 더 붙잡고 있다가 놓는다. 고개를 잠깐 돌리거나
  /// 인식이 한두 번 흔들렸다고 바로 꺼지면 오히려 성가시다.
  static const watchGrace = Duration(seconds: 90);

  String encode() => switch (mode) {
    ScreenSleepMode.never => 'always',
    ScreenSleepMode.watching => 'auto',
    ScreenSleepMode.timed => 'min:$minutes',
  };

  static ScreenSleep decode(String? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    if (raw == 'always') return const ScreenSleep(ScreenSleepMode.never);
    if (raw == 'auto') return const ScreenSleep(ScreenSleepMode.watching);
    if (raw.startsWith('min:')) {
      final n = int.tryParse(raw.substring(4));
      if (n != null && n > 0) {
        return ScreenSleep(ScreenSleepMode.timed, minutes: n);
      }
    }
    return defaults;
  }

  @override
  bool operator ==(Object other) =>
      other is ScreenSleep && other.mode == mode && other.minutes == minutes;

  @override
  int get hashCode => Object.hash(mode, minutes);
}

/// 지금 설정. 설정 화면에서 바꾸면 보고 있는 악보에 곧바로 반영된다.
final screenSleepProvider = Provider<ScreenSleep>((ref) {
  final raw = ref.watch(settingProvider(SettingKeys.screenSleep)).value;
  return ScreenSleep.decode(raw);
});

/// 악보를 보는 동안 화면을 붙잡아 두는 일을 맡는다.
///
/// 세 가지 방식이 타이머 하나로 모인다. 붙잡은 뒤 타이머가 울리면 놓고,
/// 손이 닿거나 얼굴이 보이면 다시 붙잡으며 타이머를 새로 건다.
/// [ScreenSleepMode.never] 는 타이머를 걸지 않아 놓을 일이 없다.
class ScreenAwake {
  ScreenAwake(this._face);

  final FaceTurnService _face;

  ScreenSleep _setting = ScreenSleep.defaults;
  Timer? _timer;
  bool _held = false;
  bool _listening = false;
  bool _disposed = false;

  ScreenSleep get setting => _setting;

  /// 설정을 적용한다. 화면이 열릴 때와 설정이 바뀔 때 부른다.
  void apply(ScreenSleep setting) {
    if (_disposed) return;
    _setting = setting;

    final wantsFace = setting.mode == ScreenSleepMode.watching;
    if (wantsFace && !_listening) {
      _listening = true;
      _face.addListener(_onFace);
      unawaited(_face.setPresence(true));
    } else if (!wantsFace && _listening) {
      _listening = false;
      _face.removeListener(_onFace);
      unawaited(_face.setPresence(false));
    }

    _hold();
    _arm();
  }

  /// 손이 닿았다. 보고 있다는 가장 분명한 신호다.
  void touch() {
    if (_disposed) return;
    _hold();
    _arm();
  }

  void _onFace() {
    if (_disposed || _setting.mode != ScreenSleepMode.watching) return;
    if (!_face.faceVisible) return;
    _hold();
    _arm();
  }

  /// 다음에 화면을 놓을 시각을 정한다. 놓지 않는 방식이면 걸지 않는다.
  void _arm() {
    _timer?.cancel();
    final after = switch (_setting.mode) {
      ScreenSleepMode.never => null,
      ScreenSleepMode.watching => ScreenSleep.watchGrace,
      ScreenSleepMode.timed => Duration(minutes: _setting.minutes),
    };
    if (after == null) return;
    _timer = Timer(after, _release);
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
    _timer?.cancel();
    if (_listening) {
      _listening = false;
      _face.removeListener(_onFace);
      unawaited(_face.setPresence(false));
    }
    _release();
  }
}
