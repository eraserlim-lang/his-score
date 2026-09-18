import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_dao.dart';
import '../../importer/data/watch_folder_service.dart';
import '../../sync/presentation/sync_sheet.dart';
import '../../viewer/domain/turn_input.dart';
import '../../viewer/domain/viewer_controller.dart';

/// 설정.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const _SectionHeader('페이지 넘김'),
          const _PedalTile(),
          ListTile(
            leading: const Icon(Icons.devices_other_outlined),
            title: const Text('기기 동기화'),
            subtitle: const Text('리드 / 팔로우 역할과 연결 상태'),
            onTap: () => showSyncSheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_remote),
            title: const Text('리모컨 모드'),
            subtitle: const Text('이 기기로 다른 기기의 페이지를 넘깁니다'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemotePage())),
          ),
          const _SectionHeader('가져오기'),
          if (WatchFolderService.supported) const _WatchFolderTile(),
          const _SectionHeader('클라우드 연결'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Google Cloud Console 과 Dropbox App Console 에서 만든 OAuth 클라이언트 ID 를 넣습니다. '
              '데스크톱은 http://127.0.0.1 로, 모바일은 hiscore://oauth 로 되돌아오도록 등록하세요. 비밀 키는 필요 없습니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const _TextSettingTile(
            settingKey: SettingKeys.googleClientId,
            title: 'Google Drive 클라이언트 ID',
            hint: 'xxxx.apps.googleusercontent.com',
          ),
          const _TextSettingTile(
            settingKey: SettingKeys.dropboxClientId,
            title: 'Dropbox 앱 키',
            hint: 'App key',
          ),
          const _SectionHeader('정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('HIScore'),
            subtitle: Text('모든 기기에서 쓰는 악보 뷰어'),
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
      title: const Text('감시 폴더'),
      subtitle: Text(folder ?? '지정하지 않음. PDF 가 들어오면 자동으로 가져옵니다.'),
      trailing: folder == null
          ? null
          : IconButton(
              icon: const Icon(Icons.clear),
              tooltip: '해제',
              onPressed: () async {
                final service = await ref.read(watchFolderServiceProvider.future);
                await service.setFolder(null);
              },
            ),
      onTap: () async {
        final picked = await FilePicker.getDirectoryPath(dialogTitle: '감시할 폴더');
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
      subtitle: Text(value == null || value.isEmpty ? '설정 안 됨' : value),
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
              FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('저장')),
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
    return ListTile(
      leading: const Icon(Icons.keyboard_alt_outlined),
      title: const Text('페달 / 키보드 매핑'),
      subtitle: Text('다음 ${mapping.next.length}개 키, 이전 ${mapping.previous.length}개 키'),
      trailing: PopupMenuButton<String>(
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
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'next', child: Text('"다음" 페달 학습')),
          PopupMenuItem(value: 'previous', child: Text('"이전" 페달 학습')),
          PopupMenuItem(value: 'reset', child: Text('기본값으로')),
        ],
      ),
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
        title: Text(cmd == TurnCommand.next ? '"다음" 페달을 밟으세요' : '"이전" 페달을 밟으세요'),
        content: const Text('키보드 키를 눌러도 됩니다.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소'))],
      ),
    ).then((_) {
      HardwareKeyboard.instance.removeHandler(handler);
      return captured;
    });
  }
}
