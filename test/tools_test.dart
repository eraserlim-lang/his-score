import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/features/tools/data/audio_engine.dart';
import 'package:his_score/features/tools/domain/metronome.dart';
import 'package:his_score/features/tools/domain/pitch.dart';

void main() {
  group('음 이름', () {
    test('440Hz 는 A4, 0 센트', () {
      final r = PitchReading.fromFrequency(440);
      expect(r.label, 'A4');
      expect(r.cents, closeTo(0, 1e-9));
    });

    test('261.63Hz 는 C4', () {
      expect(PitchReading.fromFrequency(261.63).label, 'C4');
    });

    test('살짝 높으면 + 센트', () {
      final r = PitchReading.fromFrequency(445);
      expect(r.midi, 69);
      expect(r.cents, closeTo(19.6, 0.2));
    });

    test('기준음을 442 로 바꾸면 442Hz 가 0 센트', () {
      expect(PitchReading.fromFrequency(442, a4: 442).cents, closeTo(0, 1e-9));
    });

    test('MIDI 60 은 중앙 C 주파수', () {
      expect(PitchReading.frequencyOf(60), closeTo(261.63, 0.01));
    });
  });

  group('YIN 주파수 검출', () {
    Float32List tone(double hz, {int n = 4096, int sr = 44100, double amp = 0.5}) {
      final out = Float32List(n);
      for (var i = 0; i < n; i++) {
        final t = i / sr;
        // 기본음 + 배음 둘. 실제 악기처럼 만든다.
        out[i] = amp *
            (math.sin(2 * math.pi * hz * t) +
                0.4 * math.sin(2 * math.pi * hz * 2 * t) +
                0.2 * math.sin(2 * math.pi * hz * 3 * t));
      }
      return out;
    }

    final yin = YinDetector();

    test('A4 를 1Hz 안으로 맞춘다', () {
      expect(yin.detect(tone(440)), closeTo(440, 1));
    });

    test('낮은 E2(82.4Hz) 도 잡는다', () {
      expect(yin.detect(tone(82.41)), closeTo(82.41, 0.6));
    });

    test('배음이 있어도 옥타브를 틀리지 않는다', () {
      final hz = yin.detect(tone(196))!;
      expect(hz, closeTo(196, 1));
    });

    test('무음은 null', () {
      expect(yin.detect(Float32List(4096)), isNull);
    });

    test('PCM 바이트를 실수로 바꾼다', () {
      final bytes = Uint8List.fromList([0, 0, 0xFF, 0x7F, 0x00, 0x80]);
      final f = pcm16BytesToFloat(bytes);
      expect(f[0], 0);
      expect(f[1], closeTo(1, 0.001));
      expect(f[2], closeTo(-1, 0.001));
    });
  });

  group('메트로놈 루프', () {
    test('한 마디 길이가 bpm 과 박자에 맞는다', () {
      final wav = MetronomeController.buildBarLoop(
        bpm: 120,
        beatsPerBar: 4,
        subdivision: 1,
        accentFirst: true,
      );
      // 120bpm 4박 = 2초 = 88200 샘플 = 176400 바이트 + 44 헤더
      expect(wav.length, 44 + 88200 * 2);
      final data = ByteData.sublistView(wav);
      expect(data.getUint32(24, Endian.little), 44100);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    });

    test('첫 박 강세는 다른 박보다 크다', () {
      final wav = MetronomeController.buildBarLoop(
        bpm: 60,
        beatsPerBar: 2,
        subdivision: 1,
        accentFirst: true,
      );
      final data = ByteData.sublistView(wav);
      int peak(int fromSample) {
        var m = 0;
        for (var i = 0; i < 1500; i++) {
          m = math.max(m, data.getInt16(44 + (fromSample + i) * 2, Endian.little).abs());
        }
        return m;
      }

      expect(peak(0), greaterThan(peak(44100)));
    });

    test('분할 클릭이 박 사이에 들어간다', () {
      final wav = MetronomeController.buildBarLoop(
        bpm: 60,
        beatsPerBar: 1,
        subdivision: 2,
        accentFirst: false,
      );
      final data = ByteData.sublistView(wav);
      var m = 0;
      for (var i = 0; i < 1000; i++) {
        m = math.max(m, data.getInt16(44 + (22050 + i) * 2, Endian.little).abs());
      }
      expect(m, greaterThan(1000));
    });

    test('빠르기말이 구간에 맞는다', () {
      final m = MetronomeController();
      m.setBpm(60);
      expect(m.tempoName, 'Larghetto');
      m.setBpm(120);
      expect(m.tempoName, 'Allegro');
      m.setBpm(500);
      expect(m.bpm, MetronomeController.maxBpm);
    });
  });

  group('합성', () {
    test('클릭은 짧고 앞이 크며 뒤로 갈수록 꺼진다', () {
      final c = synthClick(accent: true);
      expect(c.length, lessThan(2000));
      final head = c.take(200).map((v) => v.abs()).reduce(math.max);
      final tail = c.skip(c.length - 200).map((v) => v.abs()).reduce(math.max);
      expect(head, greaterThan(tail * 5));
    });

    test('피아노 음은 시작이 부드럽고 서서히 꺼진다', () {
      final n = synthPianoNote(440);
      expect(n[0].abs(), lessThan(500));
      final mid = n.skip(2000).take(500).map((v) => v.abs()).reduce(math.max);
      final end = n.skip(n.length - 500).map((v) => v.abs()).reduce(math.max);
      expect(mid, greaterThan(end));
    });
  });
}
