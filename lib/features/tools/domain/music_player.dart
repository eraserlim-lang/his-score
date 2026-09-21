import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path/path.dart' as p;

import '../../../core/storage/app_paths.dart';
import '../data/audio_engine.dart';
import '../../../core/i18n/tr.dart';

/// 연주하며 들을 반주 음원.
class PlayerTrack {
  const PlayerTrack({required this.path, required this.title});
  final String path;
  final String title;
}

/// 뮤직 플레이어. 앱 폴더에 넣어 둔 음원을 반복 재생한다.
///
/// MP3, WAV, FLAC, OGG 를 읽는다. M4A(AAC) 는 엔진이 지원하지 않아 걸러낸다.
class MusicPlayerController extends ChangeNotifier {
  MusicPlayerController(this._paths);

  final AppPaths _paths;
  final _engine = AudioEngine.instance;

  static const supported = ['mp3', 'wav', 'flac', 'ogg'];

  List<PlayerTrack> _tracks = const [];
  PlayerTrack? _current;
  AudioSource? _source;
  SoundHandle? _handle;
  bool _loop = false;
  double _volume = 0.8;
  Timer? _clock;

  List<PlayerTrack> get tracks => _tracks;
  PlayerTrack? get current => _current;
  bool get loop => _loop;
  double get volume => _volume;
  bool get isPlaying => _handle != null && !_engine.getPause(_handle!);
  bool get hasTrack => _handle != null;

  Duration get position => _handle == null ? Duration.zero : _engine.position(_handle!);
  Duration get length => _source == null ? Duration.zero : _engine.length(_source!);

  Directory get _dir => Directory(p.join(_paths.docsRoot.path, 'audio'));

  Future<void> refresh() async {
    if (!_dir.existsSync()) await _dir.create(recursive: true);
    final files = await _dir
        .list()
        .where((e) => e is File && supported.contains(p.extension(e.path).replaceFirst('.', '').toLowerCase()))
        .cast<File>()
        .toList();
    files.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
    _tracks = [for (final f in files) PlayerTrack(path: f.path, title: p.basenameWithoutExtension(f.path))];
    notifyListeners();
  }

  /// 파일 선택 창에서 골라 앱 폴더로 복사한다.
  Future<int> pickAndAdd() async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: tr('반주 음원 선택'),
      type: FileType.custom,
      allowedExtensions: supported,
    );
    var added = 0;
    for (final f in picked) {
      final path = f.path;
      if (path == null) continue;
      if (!_dir.existsSync()) await _dir.create(recursive: true);
      await File(path).copy(p.join(_dir.path, p.basename(path)));
      added++;
    }
    await refresh();
    return added;
  }

  Future<void> remove(PlayerTrack t) async {
    if (_current?.path == t.path) await stop();
    final f = File(t.path);
    if (await f.exists()) await f.delete();
    await refresh();
  }

  Future<void> play(PlayerTrack t) async {
    if (!await _engine.ensureReady()) return;
    await stop();
    _source = await _engine.loadFile(t.path);
    _handle = _engine.play(_source!, volume: _volume, looping: _loop);
    _current = t;
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final h = _handle;
      if (h == null) return;
      if (!_loop && position >= length - const Duration(milliseconds: 200)) {
        stop();
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void togglePause() {
    final h = _handle;
    if (h == null) return;
    _engine.setPause(h, !_engine.getPause(h));
    notifyListeners();
  }

  void seek(Duration t) {
    final h = _handle;
    if (h != null) _engine.seek(h, t);
    notifyListeners();
  }

  void setLoop(bool v) {
    _loop = v;
    final h = _handle;
    if (h != null) _engine.setLooping(h, v);
    notifyListeners();
  }

  void setVolume(double v) {
    _volume = v.clamp(0, 1);
    final h = _handle;
    if (h != null) _engine.setVolume(h, _volume);
    notifyListeners();
  }

  Future<void> stop() async {
    _clock?.cancel();
    final h = _handle;
    final s = _source;
    _handle = null;
    _source = null;
    _current = null;
    if (h != null) await _engine.stop(h);
    if (s != null) await _engine.dispose(s);
    notifyListeners();
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
    super.dispose();
  }
}

final musicPlayerProvider = ChangeNotifierProvider<MusicPlayerController>((ref) {
  final paths = ref.watch(appPathsProvider).value;
  final c = MusicPlayerController(paths ?? AppPaths(Directory.systemTemp));
  if (paths != null) c.refresh();
  // ChangeNotifierProvider 가 알아서 dispose 한다. 여기서 또 부르면 두 번이다.
  return c;
});
