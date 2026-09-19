import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_dao.dart';
import '../../../core/i18n/tr.dart';
import '../../backup/presentation/backup_tiles.dart';
import '../../importer/data/watch_folder_service.dart';
import '../../sync/presentation/sync_sheet.dart';
import '../../viewer/domain/turn_input.dart';
import '../../viewer/domain/viewer_controller.dart';

/// 눌러서 고르는 설정 한 줄.
///
/// 점 세 개만 눌러야 했더니 손가락으로는 잘 안 맞았다. 줄 어디를 눌러도
/// 열리게 하고, 지금 고른 값을 오른쪽에 적어 펼치지 않고도 알 수 있게 한다.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onSelected,
    this.subtitle,
  });

  final IconData icon;
  final String title;

  /// 오른쪽에 적을 지금 상태.
  final String value;

  final String? subtitle;
  final List<PopupMenuEntry<T>> Function(BuildContext context) items;
  final ValueChanged<T> onSelected;

  Future<void> _open(BuildContext context) async {
    final tile = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (tile == null || overlay == null) return;

    final corner = tile.localToGlobal(Offset.zero, ancestor: overlay);
    final selected = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        corner.dx + tile.size.width,
        corner.dy + tile.size.height,
        overlay.size.width - corner.dx - tile.size.width,
        0,
      ),
      items: items(context),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: () => _open(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.primary),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// 설정.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('설정'))),
      body: ListView(
        children: [
          _SectionHeader(tr('화면')),
          const _LanguageTile(),
          const _ThemeTile(),
          _SectionHeader(tr('페이지 넘김')),
          const _PedalTile(),
          ListTile(
            leading: const Icon(Icons.devices_other_outlined),
            title: Text(tr('기기 동기화')),
            subtitle: Text(tr('리드 / 팔로우 역할과 연결 상태')),
            onTap: () => showSyncSheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_remote),
            title: Text(tr('리모컨 모드')),
            subtitle: Text(tr('이 기기로 다른 기기의 페이지를 넘깁니다')),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemotePage())),
          ),
          _SectionHeader(tr('가져오기')),
          if (WatchFolderService.supported) const _WatchFolderTile(),
          _SectionHeader(tr('클라우드 연결')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              tr('Google Cloud Console 과 Dropbox App Console 에서 만든 OAuth 클라이언트 ID 를 넣습니다. 데스크톱은 http://127.0.0.1 로, 모바일은 hiscore://oauth 로 되돌아오도록 등록하세요. 비밀 키는 필요 없습니다.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _TextSettingTile(
            settingKey: SettingKeys.googleClientId,
            title: tr('Google Drive 클라이언트 ID'),
            hint: 'xxxx.apps.googleusercontent.com',
          ),
          _TextSettingTile(
            settingKey: SettingKeys.dropboxClientId,
            title: tr('Dropbox 앱 키'),
            hint: 'App key',
          ),
          _SectionHeader(tr('백업')),
          const BackupTiles(),
          _SectionHeader(tr('정보')),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('HIScore'),
            subtitle: Text(tr('모든 기기에서 쓰는 악보 뷰어')),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

class _WatchFolderTile extends ConsumerWidget {
  const _WatchFolderTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(settingProvider(SettingKeys.watchFolder)).value;
    return ListTile(
      leading: const Icon(Icons.folder_special_outlined),
      title: Text(tr('감시 폴더')),
      subtitle: Text(folder ?? tr('지정하지 않음. PDF 가 들어오면 자동으로 가져옵니다.')),
      trailing: folder == null
          ? null
          : IconButton(
              icon: const Icon(Icons.clear),
              tooltip: tr('해제'),
              onPressed: () async {
                final service = await ref.read(watchFolderServiceProvider.future);
                await service.setFolder(null);
              },
            ),
      onTap: () async {
        final picked = await FilePicker.getDirectoryPath(dialogTitle: tr('감시할 폴더'));
        if (picked == null) return;
        final service = await ref.read(watchFolderServiceProvider.future);
        await service.setFolder(picked);
      },
    );
  }
}

class _TextSettingTile extends ConsumerWidget {
  const _TextSettingTile({
    required this.settingKey,
    required this.title,
    required this.hint,
  });

  final String settingKey;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(settingProvider(settingKey)).value;
    return ListTile(
      leading: const Icon(Icons.key_outlined),
      title: Text(title),
      subtitle: Text(value == null || value.isEmpty ? tr('설정 안 됨') : value),
      onTap: () async {
        final controller = TextEditingController(text: value ?? '');
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: hint),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('취소'))),
              FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(tr('저장'))),
            ],
          ),
        );
        if (result == null) return;
        await ref.read(settingsDaoProvider).set(settingKey, result.isEmpty ? null : result);
        // 제공자 목록이 새 ID 를 쓰도록 다시 만든다.
        ref.invalidate(settingProvider(settingKey));
      },
    );
  }
}

/// 블루투스 페달 학습. 페달을 밟으면 어떤 키가 오는지 잡아 매핑에 넣는다.
class _PedalTile extends ConsumerWidget {
  const _PedalTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = ref.watch(settingProvider(SettingKeys.pedalNext)).value;
    final mapping = PedalMapping.decode(raw);
    return _ChoiceTile<String>(
      icon: Icons.keyboard_alt_outlined,
      title: tr('페달 / 키보드 매핑'),
      value: tr('다음 {0} · 이전 {1}', [mapping.next.length, mapping.previous.length]),
      onSelected: (v) async {
        if (v == 'reset') {
          await ref.read(settingsDaoProvider).set(SettingKeys.pedalNext, null);
          return;
        }
        final cmd = v == 'next' ? TurnCommand.next : TurnCommand.previous;
        final key = await _learn(context, cmd);
        if (key == null) return;
        final updated = cmd == TurnCommand.next
            ? mapping.withLearned(nextKey: key.keyId)
            : mapping.withLearned(previousKey: key.keyId);
        await ref.read(settingsDaoProvider).set(SettingKeys.pedalNext, updated.encode());
      },
      items: (context) => [
        PopupMenuItem(value: 'next', child: Text(tr('"다음" 페달 학습'))),
        PopupMenuItem(value: 'previous', child: Text(tr('"이전" 페달 학습'))),
        PopupMenuItem(value: 'reset', child: Text(tr('기본값으로'))),
      ],
    );
  }

  Future<LogicalKeyboardKey?> _learn(BuildContext context, TurnCommand cmd) {
    LogicalKeyboardKey? captured;
    bool handler(KeyEvent e) {
      if (e is KeyDownEvent) {
        captured = e.logicalKey;
        Navigator.of(context).pop();
        return true;
      }
      return false;
    }

    HardwareKeyboard.instance.addHandler(handler);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cmd == TurnCommand.next ? tr('"다음" 페달을 밟으세요') : tr('"이전" 페달을 밟으세요')),
        content: Text(tr('키보드 키를 눌러도 됩니다.')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('취소')))],
      ),
    ).then((_) {
      HardwareKeyboard.instance.removeHandler(handler);
      return captured;
    });
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(settingProvider(SettingKeys.locale)).value;
    return _ChoiceTile<String>(
      icon: Icons.language,
      title: tr('언어'),
      value: AppLocale.labelOf(saved == null ? null : Locale(saved)),
      onSelected: (v) async {
        await ref.read(settingsDaoProvider).set(SettingKeys.locale, v == 'system' ? null : v);
        AppLocale.override.value = v == 'system' ? null : Locale(v);
      },
      items: (context) => [
        PopupMenuItem(value: 'system', child: Text(AppLocale.labelOf(null))),
        for (final l in AppLocale.supported)
          PopupMenuItem(value: l.languageCode, child: Text(AppLocale.labelOf(l))),
      ],
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(settingProvider(SettingKeys.themeMode)).value ?? 'system';
    String label(String v) => switch (v) {
          'light' => tr('밝게'),
          'dark' => tr('어둡게'),
          _ => tr('시스템 설정'),
        };
    return _ChoiceTile<String>(
      icon: Icons.brightness_6_outlined,
      title: tr('테마'),
      value: label(saved),
      onSelected: (v) =>
          ref.read(settingsDaoProvider).set(SettingKeys.themeMode, v == 'system' ? null : v),
      items: (context) => [
        for (final v in ['system', 'light', 'dark'])
          PopupMenuItem(value: v, child: Text(label(v))),
      ],
    );
  }
}
