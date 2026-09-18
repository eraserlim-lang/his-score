import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/settings_dao.dart';
import 'score_importer.dart';

/// 데스크톱 감시 폴더.
///
/// 지정한 폴더에 PDF 가 들어오면 자동으로 가져온다. iTunes 파일 공유 대신
/// Dropbox 나 iCloud 가 동기화하는 로컬 폴더를 가리키면 된다.
/// 어떤 파일을 이미 가져왔는지는 "경로 + 수정 시각" 으로 기억한다.
class WatchFolderService {
  WatchFolderService(this._settings, this._importer);

  final SettingsDao _settings;
  final ScoreImporter _importer;

  StreamSubscription<FileSystemEvent>? _sub;
  Timer? _debounce;
  String? _folder;

  static bool get supported =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// 마지막 스캔 결과. 화면에 보여주기 위한 것이다.
  final lastImported = ValueNotifier<int>(0);

  Future<void> start() async {
    if (!supported) return;
    _folder = await _settings.get(SettingKeys.watchFolder);
    await _restart();
  }

  Future<void> setFolder(String? folder) async {
    _folder = folder;
    await _settings.set(SettingKeys.watchFolder, folder);
    await _restart();
  }

  Future<void> _restart() async {
    await _sub?.cancel();
    _sub = null;
    final folder = _folder;
    if (folder == null || !Directory(folder).existsSync()) return;

    await scanNow();
    _sub = Directory(folder).watch().listen((_) {
      // 복사가 끝나기 전에 읽으면 깨진 PDF 를 만난다. 잠시 기다린다.
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 2), scanNow);
    });
  }

  /// 아직 안 들여온 PDF 를 전부 들여온다. 들여온 개수를 돌려준다.
  Future<int> scanNow() async {
    final folder = _folder;
    if (folder == null) return 0;
    final dir = Directory(folder);
    if (!dir.existsSync()) return 0;

    final seenRaw = await _settings.get(SettingKeys.watchFolderSeen);
    final seen = seenRaw == null
        ? <String, String>{}
        : (jsonDecode(seenRaw) as Map).cast<String, String>();

    var imported = 0;
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.pdf')) continue;
      final stamp = (await entity.lastModified()).toIso8601String();
      final key = p.normalize(entity.path);
      if (seen[key] == stamp) continue;

      try {
        final id = await _importer.importFile(entity);
        if (id != null) imported++;
        seen[key] = stamp;
      } on Object catch (e) {
        debugPrint('감시 폴더 가져오기 실패 ${entity.path}: $e');
      }
    }

    await _settings.set(SettingKeys.watchFolderSeen, jsonEncode(seen));
    if (imported > 0) lastImported.value += imported;
    return imported;
  }

  Future<void> dispose() async {
    _debounce?.cancel();
    await _sub?.cancel();
  }
}

final watchFolderServiceProvider = FutureProvider<WatchFolderService>((ref) async {
  final importer = await ref.watch(scoreImporterProvider.future);
  final service = WatchFolderService(ref.watch(settingsDaoProvider), importer);
  ref.onDispose(service.dispose);
  await service.start();
  return service;
});
