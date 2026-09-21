import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../data/audio_engine.dart';

/// 메트로놈.
///
/// 타이머로 매 박마다 소리를 내면 화면이 바쁠 때 흔들린다. 대신 한 마디
/// 분량의 클릭을 미리 구워 오디오 스레드에서 반복 재생한다. 박은 항상
/// 샘플 단위로 정확하다. 화면의 추와 불빛은 시작 시각 기준으로 계산한다.
class MetronomeController extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  MetronomeController({TickerProvider? vsync}) : _vsync = vsync;

  final TickerProvider? _vsync;
  final _engine = AudioEngine.instance;

  int _bpm = 100;
  int _beatsPerBar = 4;

  /// 1 이면 박마다, 2 면 8분음표, 3 이면 셋잇단.
  int _subdivision = 1;
  bool _accentFirst = true;
  bool _silent = false;
  double _volume = 0.9;
  bool _running = false;

  AudioSource? _loop;
  SoundHandle? _handle;
  Ticker? _ticker;
  Stopwatch? _clock;

  /// 지금 어느 박인지(0-based). 화면용.
  int _beat = 0;

  /// 추가 왼쪽(-1)에서 오른쪽(1)으로 오가는 위치. 화면용.
  double _pendulum = 0;

  int get bpm => _bpm;
  int get beatsPerBar => _beatsPerBar;
  int get subdivision => _subdivision;
  bool get accentFirst => _accentFirst;
  bool get silent => _silent;
  double get volume => _volume;
  bool get running => _running;
  int get beat => _beat;
  double get pendulum => _pendulum;

  static const minBpm = 20;
  static const maxBpm = 300;

  /// 이탈리아어 빠르기말. 재미로 붙이지만 학생들이 좋아한다.
  String get tempoName {
    if (_bpm < 40) return 'Grave';
    if (_bpm < 60) return 'Largo';
    if (_bpm < 66) return 'Larghetto';
    if (_bpm < 76) return 'Adagio';
    if (_bpm < 108) return 'Andante';
    if (_bpm < 120) return 'Moderato';
    if (_bpm < 156) return 'Allegro';
    if (_bpm < 176) return 'Vivace';
    if (_bpm < 200) return 'Presto';
    return 'Prestissimo';
  }

  void setBpm(int value) {
    final v = value.clamp(minBpm, maxBpm);
    if (v == _bpm) return;
    _bpm = v;
    notifyListeners();
    _rebuildIfRunning();
  }

  void nudge(int delta) => setBpm(_bpm + delta);

  void setBeatsPerBar(int value) {
    _beatsPerBar = value.clamp(1, 12);
    notifyListeners();
    _rebuildIfRunning();
  }

  void setSubdivision(int value) {
    _subdivision = value.clamp(1, 4);
    notifyListeners();
    _rebuildIfRunning();
  }

  void setAccentFirst(bool value) {
    _accentFirst = value;
    notifyListeners();
    _rebuildIfRunning();
  }

  /// 무음 모드. 소리 없이 추와 불빛만 움직인다. 연주 중 녹음할 때 쓴다.
  void setSilent(bool value) {
    _silent = value;
    final h = _handle;
    if (h != null) _engine.setVolume(h, value ? 0 : _volume);
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0, 1);
    final h = _handle;
    if (h != null && !_silent) _engine.setVolume(h, _volume);
    notifyListeners();
  }

  /// 탭 템포. 최근 탭 간격의 평균으로 bpm 을 잡는다.
  final _taps = <DateTime>[];
  void tap() {
    final now = DateTime.now();
    if (_taps.isNotEmpty && now.difference(_taps.last).inMilliseconds > 2000) {
      _taps.clear();
    }
    _taps.add(now);
    if (_taps.length > 6) _taps.removeAt(0);
    if (_taps.length >= 2) {
      final total = _taps.last.difference(_taps.first).inMilliseconds;
      final avg = total / (_taps.length - 1);
      setBpm((60000 / avg).round());
    }
  }

  Future<void> toggle() => _running ? stop() : start();

  Future<void> start() async {
    if (_running) return;
    if (!await _engine.ensureReady()) return;
    _running = true;
    notifyListeners();
    await _rebuild();
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _ticker?.stop();
    final h = _handle;
    _handle = null;
    if (h != null) await _engine.stop(h);
    final loop = _loop;
    _loop = null;
    if (loop != null) await _engine.dispose(loop);
    _beat = 0;
    _pendulum = 0;
    notifyListeners();
  }

  Future<void> _rebuildIfRunning() async {
    if (_running) await _rebuild();
  }

  /// 한 마디 분량 루프를 새로 굽고 처음부터 튼다.
  Future<void> _rebuild() async {
    final old = _handle;
    final oldLoop = _loop;
    final wav = buildBarLoop(
      bpm: _bpm,
      beatsPerBar: _beatsPerBar,
      subdivision: _subdivision,
      accentFirst: _accentFirst,
    );
    final loop = await _engine.loadWav('metronome-$_bpm-$_beatsPerBar-$_subdivision', wav);
    if (!_running) {
      await _engine.dispose(loop);
      return;
    }
    _loop = loop;
    _handle = _engine.play(loop, volume: _silent ? 0 : _volume, looping: true);
    _clock = Stopwatch()..start();
    if (old != null) await _engine.stop(old);
    if (oldLoop != null) await _engine.dispose(oldLoop);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.dispose();
    final vsync = _vsync;
    if (vsync == null) return;
    _ticker = vsync.createTicker((_) {
      final clock = _clock;
      if (clock == null) return;
      final beatMs = 60000 / _bpm;
      final elapsed = clock.elapsedMilliseconds;
      final beatIndex = (elapsed / beatMs).floor();
      final phase = (elapsed % beatMs) / beatMs;
      final newBeat = beatIndex % _beatsPerBar;
      // 추는 한 박에 한 방향으로 간다. 짝수 박은 왼→오, 홀수 박은 오→왼.
      final dir = beatIndex.isEven ? 1 : -1;
      _pendulum = dir * (phase * 2 - 1);
      _beat = newBeat;
      notifyListeners();
    })
      ..start();
  }

  /// 한 마디의 클릭을 PCM 으로 굽는다. 순수 함수라 테스트할 수 있다.
  static Uint8List buildBarLoop({
    required int bpm,
    required int beatsPerBar,
    required int subdivision,
    required bool accentFirst,
    int sampleRate = 44100,
  }) {
    final samplesPerBeat = sampleRate * 60 / bpm;
    final total = (samplesPerBeat * beatsPerBar).round();
    final out = Int16List(total);
    final accent = synthClick(accent: true, sampleRate: sampleRate);
    final normal = synthClick(accent: false, sampleRate: sampleRate);
    final sub = synthClick(accent: false, sampleRate: sampleRate);

    for (var b = 0; b < beatsPerBar; b++) {
      for (var s = 0; s < subdivision; s++) {
        final at = (samplesPerBeat * (b + s / subdivision)).round();
        final Int16List click;
        final double gain;
        if (s != 0) {
          click = sub;
          gain = 0.45;
        } else if (b == 0 && accentFirst) {
          click = accent;
          gain = 1;
        } else {
          click = normal;
          gain = 1;
        }
        for (var i = 0; i < click.length && at + i < total; i++) {
          out[at + i] = (out[at + i] + click[i] * gain).round().clamp(-32768, 32767);
        }
      }
    }
    return pcm16ToWav(out, sampleRate: sampleRate);
  }

  /// dispose 에 들어온 뒤로는 알리지 않는다. 멈추면서 알리면 이미 떠난
  /// 듣는 쪽을 부르게 되고, 멈추기가 비동기라 dispose 가 끝난 뒤에도 알림이
  /// 늦게 도착한다.
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    _ticker?.dispose();
    super.dispose();
  }
}

/// 앱 전체에서 하나. 시트를 닫아도 계속 친다.
final metronomeProvider = ChangeNotifierProvider<MetronomeController>((ref) {
  final c = MetronomeController(vsync: _AppTicker());
  // ChangeNotifierProvider 가 알아서 dispose 한다. 여기서 또 부르면 두 번이다.
  return c;
});

/// 위젯 밖에서 티커를 만들기 위한 최소 구현.
class _AppTicker implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
