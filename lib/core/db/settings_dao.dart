import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'tables.dart';

part 'settings_dao.g.dart';

/// 키-값 전역 설정.
///
/// 비밀이 아닌 값만 둔다. OAuth 토큰은 [flutter_secure_storage] 로 따로 보관한다.
@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> get(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watch(String key) =>
      (select(appSettings)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((r) => r?.value);

  Future<void> set(String key, String? value) {
    if (value == null) {
      return (delete(appSettings)..where((t) => t.key.equals(key))).go();
    }
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setJson(String key, Map<String, dynamic>? value) =>
      set(key, value == null ? null : jsonEncode(value));

  Future<Map<String, String>> all() async {
    final rows = await select(appSettings).get();
    return {for (final r in rows) r.key: r.value};
  }
}

/// 설정 키 모음. 오타를 막기 위해 한곳에 둔다.
abstract final class SettingKeys {
  static const googleClientId = 'cloud.google.clientId';
  static const dropboxClientId = 'cloud.dropbox.clientId';
  static const watchFolder = 'import.watchFolder';
  static const watchFolderSeen = 'import.watchFolder.seen';
  static const pedalNext = 'pedal.next';
  static const pedalPrevious = 'pedal.previous';
  static const faceGesture = 'turn.faceGesture';
  static const syncRole = 'sync.role';
  static const deviceName = 'sync.deviceName';
  static const locale = 'ui.locale';
  static const themeMode = 'ui.themeMode';
  static const tapZoneWidth = 'viewer.tapZoneWidth';
}

final settingsDaoProvider =
    Provider<SettingsDao>((ref) => SettingsDao(ref.watch(appDatabaseProvider)));

final settingProvider = StreamProvider.family<String?, String>(
  (ref, key) => ref.watch(settingsDaoProvider).watch(key),
);
