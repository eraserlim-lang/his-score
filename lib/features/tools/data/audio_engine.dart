import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// 앱 전체가 함께 쓰는 오디오 엔진.
///
/// 메트로놈, 건반, 튜너의 기준음, 녹음 재생, 뮤직 플레이어가 전부
/// 이 하나를 통해 소리를 낸다. 엔진은 처음 필요할 때 켠다.
class AudioEngine {
  AudioEngine._();
  static final instance = AudioEngine._();

  SoLoud get _soloud => SoLoud.instance;
  bool get isReady => _soloud.isInitialized;

  Future<bool> ensureReady() async {
    if (_soloud.isInitialized) return true;
    try {
      await _soloud.init(channels: Channels.stereo, sampleRate: 44100);
      return true;
    } on Object catch (e) {
      debugPrint('오디오 엔진 초기화 실패: $e');
      return false;
    }
  }

  Future<AudioSource> loadWav(String name, Uint8List wav) =>
      _soloud.loadMem(name, wav, mode: LoadMode.memory);

  Future<AudioSource> loadFile(String path) =>
      _soloud.loadFile(path, mode: LoadMode.disk);

  Future<AudioSource> sine() => _soloud.loadWaveform(WaveForm.sin, false, 0.25, 0);

  SoundHandle play(AudioSource s, {double volume = 1, bool looping = false}) =>
      _soloud.play(s, volume: volume, looping: looping);

  Future<void> stop(SoundHandle h) => _soloud.stop(h);
  void setVolume(SoundHandle h, double v) => _soloud.setVolume(h, v);
  void setPause(SoundHandle h, bool p) => _soloud.setPause(h, p);
  bool getPause(SoundHandle h) => _soloud.getPause(h);
  void seek(SoundHandle h, Duration t) => _soloud.seek(h, t);
  Duration position(SoundHandle h) => _soloud.getPosition(h);
  Duration length(AudioSource s) => _soloud.getLength(s);
  void setLooping(SoundHandle h, bool v) => _soloud.setLooping(h, v);
  void setFrequency(AudioSource s, double hz) => _soloud.setWaveformFreq(s, hz);
  Future<void> dispose(AudioSource s) => _soloud.disposeSource(s);
}

/// PCM 을 WAV 바이트로 싼다. SoLoud 가 메모리에서 바로 읽는다.
Uint8List pcm16ToWav(Int16List samples, {int sampleRate = 44100, int channels = 1}) {
  final dataBytes = samples.length * 2;
  final bytes = ByteData(44 + dataBytes);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  bytes.setUint32(4, 36 + dataBytes, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, channels, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * channels * 2, Endian.little);
  bytes.setUint16(32, channels * 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  str(36, 'data');
  bytes.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    bytes.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

/// 짧고 또렷한 클릭. 나무 메트로놈의 "딱" 소리를 흉내 낸다.
///
/// [accent] 는 첫 박에 쓰는 높고 큰 소리다.
Int16List synthClick({required bool accent, int sampleRate = 44100}) {
  final length = (sampleRate * 0.035).round();
  final out = Int16List(length);
  final freq = accent ? 1760.0 : 1175.0;
  final amp = accent ? 0.95 : 0.7;
  for (var i = 0; i < length; i++) {
    final t = i / sampleRate;
    // 빠르게 꺼지는 사인파에 약간의 배음. 지속음이 아니라 타격음이어야 한다.
    final env = math.exp(-t * 180);
    final v = math.sin(2 * math.pi * freq * t) * 0.8 +
        math.sin(2 * math.pi * freq * 2.7 * t) * 0.2;
    out[i] = (v * env * amp * 32767).round().clamp(-32768, 32767);
  }
  return out;
}

/// 피아노 비슷한 한 음. 배음 몇 개에 감쇠 포락선을 씌운다.
Int16List synthPianoNote(double freq, {double seconds = 1.6, int sampleRate = 22050}) {
  final length = (sampleRate * seconds).round();
  final out = Int16List(length);
  const partials = [1.0, 0.5, 0.25, 0.12, 0.06];
  for (var i = 0; i < length; i++) {
    final t = i / sampleRate;
    // 높은 음일수록 빨리 꺼지는 것이 실제 피아노와 비슷하다.
    final decay = 2.2 + freq / 400;
    final env = math.exp(-t * decay) * (1 - math.exp(-t * 400));
    var v = 0.0;
    for (var k = 0; k < partials.length; k++) {
      v += math.sin(2 * math.pi * freq * (k + 1) * t) * partials[k] * math.exp(-t * k * 1.5);
    }
    out[i] = (v / 1.9 * env * 0.85 * 32767).round().clamp(-32768, 32767);
  }
  return out;
}
