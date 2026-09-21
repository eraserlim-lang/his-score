import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../data/audio_engine.dart';
import 'pitch.dart';

/// 가상 건반의 소리.
///
/// 음마다 짧은 피아노 음을 미리 구워 두고 누를 때 한 번 재생한다.
/// 동시에 여러 음을 눌러도 각각 소리가 난다.
class KeyboardController extends ChangeNotifier {
  final _engine = AudioEngine.instance;
  final _notes = <int, AudioSource>{};

  /// 화면 왼쪽 끝의 MIDI 번호. 기본은 C3(48).
  int _lowest = 48;

  /// 보여줄 옥타브 수.
  int _octaves = 2;

  bool _ready = false;
  final _pressed = <int>{};

  int get lowest => _lowest;
  int get octaves => _octaves;
  Set<int> get pressed => _pressed;

  void shiftOctave(int delta) {
    _lowest = (_lowest + delta * 12).clamp(24, 84);
    notifyListeners();
  }

  void setOctaves(int n) {
    _octaves = n.clamp(1, 4);
    notifyListeners();
  }

  Future<void> _ensure() async {
    if (_ready) return;
    _ready = await _engine.ensureReady();
  }

  Future<void> press(int midi) async {
    await _ensure();
    if (!_ready) return;
    _pressed.add(midi);
    notifyListeners();

    var source = _notes[midi];
    if (source == null) {
      final pcm = synthPianoNote(PitchReading.frequencyOf(midi));
      source = await _engine.loadWav('key-$midi', pcm16ToWav(pcm, sampleRate: 22050));
      _notes[midi] = source;
    }
    _engine.play(source, volume: 0.8);
  }

  void release(int midi) {
    if (_pressed.remove(midi)) notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _notes.values) {
      _engine.dispose(s);
    }
    super.dispose();
  }
}

final keyboardProvider = ChangeNotifierProvider<KeyboardController>((ref) {
  final c = KeyboardController();
  // ChangeNotifierProvider 가 알아서 dispose 한다. 여기서 또 부르면 두 번이다.
  return c;
});
