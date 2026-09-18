import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:record/record.dart';

import '../data/audio_engine.dart';
import 'pitch.dart';

/// 크로매틱 튜너.
///
/// 마이크 스트림을 받아 YIN 으로 주파수를 잡고, 기준음(피치 파이프)도 낸다.
/// 마이크 권한이 없으면 [error] 에 이유를 남긴다.
class TunerController extends ChangeNotifier {
  static const sampleRate = 44100;
  static const windowSize = 4096;

  final _recorder = AudioRecorder();
  final _engine = AudioEngine.instance;
  final _detector = YinDetector(sampleRate: sampleRate);

  StreamSubscription<Uint8List>? _sub;
  final _window = Float32List(windowSize);
  int _filled = 0;

  bool _listening = false;
  String? _error;
  PitchReading? _reading;
  double _a4 = 440;
  int _transpose = 0;

  /// 잡음으로 튀지 않게 몇 프레임을 부드럽게 섞는다.
  double? _smoothedHz;

  // 기준음
  AudioSource? _pipe;
  SoundHandle? _pipeHandle;
  int? _pipeMidi;

  bool get listening => _listening;
  String? get error => _error;
  PitchReading? get reading => _reading;
  double get a4 => _a4;
  int get transpose => _transpose;
  int? get pipeMidi => _pipeMidi;

  /// 이조 악기용. 클라리넷(B♭)은 -2, 알토 색소폰(E♭)은 -9 처럼 쓴다.
  void setTranspose(int semitones) {
    _transpose = semitones.clamp(-12, 12);
    notifyListeners();
  }

  void setA4(double hz) {
    _a4 = hz.clamp(415, 466);
    final midi = _pipeMidi;
    if (midi != null && _pipe != null) {
      _engine.setFrequency(_pipe!, PitchReading.frequencyOf(midi, a4: _a4));
    }
    notifyListeners();
  }

  Future<void> start() async {
    if (_listening) return;
    _error = null;
    try {
      if (!await _recorder.hasPermission()) {
        _error = '마이크 권한이 없습니다';
        notifyListeners();
        return;
      }
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
      _sub = stream.listen(_onChunk);
      _listening = true;
    } on Object catch (e) {
      _error = '마이크를 열 수 없습니다: $e';
    }
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_listening) return;
    await _sub?.cancel();
    _sub = null;
    await _recorder.stop();
    _listening = false;
    _reading = null;
    _smoothedHz = null;
    _filled = 0;
    notifyListeners();
  }

  void _onChunk(Uint8List bytes) {
    final samples = pcm16BytesToFloat(bytes);
    var i = 0;
    while (i < samples.length) {
      final room = windowSize - _filled;
      final take = samples.length - i < room ? samples.length - i : room;
      _window.setRange(_filled, _filled + take, samples, i);
      _filled += take;
      i += take;
      if (_filled == windowSize) {
        _analyze();
        // 절반씩 겹쳐 가며 다음 창을 채운다. 반응이 두 배 빨라진다.
        _window.setRange(0, windowSize ~/ 2, _window, windowSize ~/ 2);
        _filled = windowSize ~/ 2;
      }
    }
  }

  void _analyze() {
    final hz = _detector.detect(_window);
    if (hz == null) {
      if (_reading != null) {
        _reading = null;
        _smoothedHz = null;
        notifyListeners();
      }
      return;
    }
    final prev = _smoothedHz;
    // 갑자기 옥타브가 튀면 새 값으로, 아니면 살짝 섞는다.
    _smoothedHz = prev == null || (hz / prev - 1).abs() > 0.06 ? hz : prev * 0.6 + hz * 0.4;
    _reading = PitchReading.fromFrequency(_smoothedHz!, a4: _a4);
    notifyListeners();
  }

  /// 기준음 켜기/끄기. 같은 음을 다시 누르면 꺼진다.
  Future<void> togglePipe(int midi) async {
    if (_pipeMidi == midi) {
      await stopPipe();
      return;
    }
    if (!await _engine.ensureReady()) return;
    _pipe ??= await _engine.sine();
    _engine.setFrequency(_pipe!, PitchReading.frequencyOf(midi, a4: _a4));
    _pipeHandle ??= _engine.play(_pipe!, volume: 0.5, looping: true);
    _pipeMidi = midi;
    notifyListeners();
  }

  Future<void> stopPipe() async {
    final h = _pipeHandle;
    _pipeHandle = null;
    _pipeMidi = null;
    if (h != null) await _engine.stop(h);
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    stopPipe();
    _recorder.dispose();
    super.dispose();
  }
}

final tunerProvider = ChangeNotifierProvider<TunerController>((ref) {
  final c = TunerController();
  ref.onDispose(c.dispose);
  return c;
});
