import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/database.dart';
import '../../../core/db/tables.dart';
import '../../../core/storage/app_paths.dart';
import '../data/audio_engine.dart';
import '../../../core/i18n/tr.dart';

part 'recorder.g.dart';

@DriftAccessor(tables: [Recordings])
class RecordingDao extends DatabaseAccessor<AppDatabase> with _$RecordingDaoMixin {
  RecordingDao(super.db);

  Stream<List<Recording>> watchAll() => (select(recordings)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<void> insert(RecordingsCompanion r) => into(recordings).insert(r);

  Future<void> rename(String id, String title) =>
      (update(recordings)..where((t) => t.id.equals(id)))
          .write(RecordingsCompanion(title: Value(title)));

  Future<Recording?> find(String id) =>
      (select(recordings)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> remove(String id) =>
      (delete(recordings)..where((t) => t.id.equals(id))).go();
}

final recordingDaoProvider =
    Provider<RecordingDao>((ref) => RecordingDao(ref.watch(appDatabaseProvider)));

final recordingsProvider =
    StreamProvider<List<Recording>>((ref) => ref.watch(recordingDaoProvider).watchAll());

/// 녹음기. 녹음, 재생, 삭제.
///
/// 파일은 WAV 로 남긴다. 모든 플랫폼에서 같은 형식이라 옮겨도 그대로 들린다.
class RecorderController extends ChangeNotifier {
  RecorderController(this._dao, this._paths);

  final RecordingDao _dao;
  final AppPaths _paths;
  final _recorder = AudioRecorder();
  final _engine = AudioEngine.instance;
  static const _uuid = Uuid();

  bool _recording = false;
  DateTime? _startedAt;
  String? _error;
  double _amplitude = 0;
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _clock;

  /// 지금 곡 안에서 녹음 중이면 곡 id 를 붙여 둔다.
  String? contextScoreId;

  // 재생
  String? _playingId;
  AudioSource? _playSource;
  SoundHandle? _playHandle;
  Timer? _playClock;

  bool get recording => _recording;
  String? get error => _error;
  double get amplitude => _amplitude;
  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);
  String? get playingId => _playingId;

  Duration get playPosition {
    final h = _playHandle;
    return h == null ? Duration.zero : _engine.position(h);
  }

  Duration get playLength {
    final s = _playSource;
    return s == null ? Duration.zero : _engine.length(s);
  }

  Future<void> start() async {
    if (_recording) return;
    _error = null;
    try {
      if (!await _recorder.hasPermission()) {
        _error = tr('마이크 권한이 없습니다');
        notifyListeners();
        return;
      }
      await stopPlayback();
      final file = File(p.join(_paths.recordingsDir.path, '${_uuid.v4()}.wav'));
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, numChannels: 1),
        path: file.path,
      );
      _recording = true;
      _startedAt = DateTime.now();
      _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 120)).listen((a) {
        // dBFS(-160~0) 를 0~1 로.
        _amplitude = ((a.current + 50) / 50).clamp(0.0, 1.0);
        notifyListeners();
      });
      _clock = Timer.periodic(const Duration(milliseconds: 250), (_) => notifyListeners());
    } on Object catch (e) {
      _error = tr('녹음을 시작할 수 없습니다: {0}', [e]);
    }
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_recording) return;
    _clock?.cancel();
    await _ampSub?.cancel();
    final path = await _recorder.stop();
    final duration = elapsed;
    _recording = false;
    _startedAt = null;
    _amplitude = 0;
    notifyListeners();
    if (path == null) return;

    final file = File(path);
    if (!await file.exists()) return;
    await _dao.insert(
      RecordingsCompanion.insert(
        id: _uuid.v4(),
        scoreId: Value(contextScoreId),
        title: tr('녹음 {0}', [_label(DateTime.now())]),
        filePath: _paths.relativeOf(file),
        durationMs: Value(duration.inMilliseconds),
      ),
    );
  }

  Future<void> play(Recording r) async {
    if (_playingId == r.id) {
      final h = _playHandle;
      if (h != null) {
        _engine.setPause(h, !_engine.getPause(h));
        notifyListeners();
      }
      return;
    }
    await stopPlayback();
    if (!await _engine.ensureReady()) return;
    final file = _paths.resolve(r.filePath);
    if (!await file.exists()) {
      _error = tr('파일이 없습니다');
      notifyListeners();
      return;
    }
    _playSource = await _engine.loadFile(file.path);
    _playHandle = _engine.play(_playSource!);
    _playingId = r.id;
    _playClock = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final h = _playHandle;
      if (h == null) return;
      if (_engine.position(h) >= playLength - const Duration(milliseconds: 150)) {
        stopPlayback();
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  bool get isPaused {
    final h = _playHandle;
    return h != null && _engine.getPause(h);
  }

  void seek(Duration t) {
    final h = _playHandle;
    if (h != null) _engine.seek(h, t);
  }

  Future<void> stopPlayback() async {
    _playClock?.cancel();
    final h = _playHandle;
    final s = _playSource;
    _playHandle = null;
    _playSource = null;
    _playingId = null;
    if (h != null) await _engine.stop(h);
    if (s != null) await _engine.dispose(s);
    notifyListeners();
  }

  Future<void> delete(Recording r) async {
    if (_playingId == r.id) await stopPlayback();
    await _dao.remove(r.id);
    final file = _paths.resolve(r.filePath);
    if (await file.exists()) await file.delete();
  }

  Future<void> rename(Recording r, String title) => _dao.rename(r.id, title);

  File fileOf(Recording r) => _paths.resolve(r.filePath);

  static String _label(DateTime t) =>
      '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _clock?.cancel();
    _playClock?.cancel();
    _ampSub?.cancel();
    stopPlayback();
    _recorder.dispose();
    super.dispose();
  }
}

final recorderProvider = ChangeNotifierProvider<RecorderController>((ref) {
  final paths = ref.watch(appPathsProvider).value;
  // 경로가 아직 없으면 임시로 systemTemp 를 쓰고, 준비되면 provider 가 다시 만든다.
  final c = RecorderController(
    ref.watch(recordingDaoProvider),
    paths ?? AppPaths(Directory.systemTemp),
  );
  ref.onDispose(c.dispose);
  return c;
});
