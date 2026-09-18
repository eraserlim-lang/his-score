import 'dart:math' as math;
import 'dart:typed_data';

/// 음 이름과 센트 오차.
class PitchReading {
  const PitchReading({required this.frequency, required this.midi, required this.cents});

  final double frequency;

  /// 가장 가까운 MIDI 번호.
  final int midi;

  /// 그 음에서 벗어난 정도. -50 ~ +50.
  final double cents;

  static const _names = ['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'];

  String get noteName => _names[midi % 12];
  int get octave => midi ~/ 12 - 1;
  String get label => '$noteName$octave';

  /// 기준음 a4 에 맞춘 주파수에서 MIDI 와 센트를 구한다.
  static PitchReading fromFrequency(double hz, {double a4 = 440}) {
    final exact = 69 + 12 * (math.log(hz / a4) / math.ln2);
    final midi = exact.round();
    return PitchReading(frequency: hz, midi: midi, cents: (exact - midi) * 100);
  }

  static double frequencyOf(int midi, {double a4 = 440}) =>
      a4 * math.pow(2, (midi - 69) / 12);
}

/// YIN 알고리즘으로 기본 주파수를 찾는다.
///
/// 자기상관보다 배음에 덜 속는다. 악기 튜너에 흔히 쓰는 방법이다.
/// 신호가 너무 작거나 확신이 없으면 null 을 준다.
class YinDetector {
  YinDetector({
    this.sampleRate = 44100,
    this.threshold = 0.12,
    this.minFrequency = 27.5,
    this.maxFrequency = 4200,
  });

  final int sampleRate;
  final double threshold;
  final double minFrequency;
  final double maxFrequency;

  double? detect(Float32List buffer) {
    final n = buffer.length;
    if (n < 512) return null;

    // 너무 조용하면 잡음만 잡는다.
    var energy = 0.0;
    for (final v in buffer) {
      energy += v * v;
    }
    if (energy / n < 1e-5) return null;

    final maxTau = math.min(n ~/ 2, (sampleRate / minFrequency).floor());
    final minTau = math.max(2, (sampleRate / maxFrequency).floor());

    // 차분 함수.
    final d = Float64List(maxTau);
    for (var tau = 1; tau < maxTau; tau++) {
      var sum = 0.0;
      for (var i = 0; i < n - maxTau; i++) {
        final delta = buffer[i] - buffer[i + tau];
        sum += delta * delta;
      }
      d[tau] = sum;
    }

    // 누적 평균 정규화.
    final cmnd = Float64List(maxTau);
    cmnd[0] = 1;
    var running = 0.0;
    for (var tau = 1; tau < maxTau; tau++) {
      running += d[tau];
      cmnd[tau] = running == 0 ? 1 : d[tau] * tau / running;
    }

    // 문턱 아래로 처음 내려가는 골짜기.
    var tau = minTau;
    while (tau < maxTau) {
      if (cmnd[tau] < threshold) {
        while (tau + 1 < maxTau && cmnd[tau + 1] < cmnd[tau]) {
          tau++;
        }
        break;
      }
      tau++;
    }
    if (tau >= maxTau || cmnd[tau] >= threshold) return null;

    // 포물선 보간으로 정수 tau 사이를 메운다.
    var refined = tau.toDouble();
    if (tau > 0 && tau < maxTau - 1) {
      final a = cmnd[tau - 1], b = cmnd[tau], c = cmnd[tau + 1];
      final denom = 2 * (a - 2 * b + c);
      if (denom.abs() > 1e-12) refined = tau + (a - c) / denom;
    }
    return sampleRate / refined;
  }
}

/// 16비트 PCM 바이트를 -1~1 실수로.
Float32List pcm16BytesToFloat(Uint8List bytes, {int channels = 1}) {
  final count = bytes.length ~/ 2 ~/ channels;
  final data = ByteData.sublistView(bytes);
  final out = Float32List(count);
  for (var i = 0; i < count; i++) {
    out[i] = data.getInt16(i * 2 * channels, Endian.little) / 32768;
  }
  return out;
}
