import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/settings_dao.dart';
import '../../importer/data/watch_folder_service.dart';

/// 설정.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
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
