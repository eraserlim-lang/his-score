import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../viewer/data/score_session.dart';
import '../data/backup_service.dart';
import '../../../core/i18n/tr.dart';

/// 설정 화면의 백업/복원 항목.
class BackupTiles extends ConsumerWidget {
  const BackupTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: Text(tr('전체 백업')),
          subtitle: Text(tr('악보, 필기, 태그, 세트리스트, 녹음을 한 파일로')),
          onTap: () => _backup(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: Text(tr('백업에서 복원')),
          subtitle: Text(tr('지금 있는 것을 모두 지우고 백업으로 되돌립니다')),
          onTap: () => _restore(context, ref),
        ),
      ],
    );
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final service = await ref.read(backupServiceProvider.future);
    if (!context.mounted) return;
    final stage = ValueNotifier<String>(tr('준비 중'));
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: ValueListenableBuilder<String>(
          valueListenable: stage,
          builder: (context, v, _) => Row(
            children: [const CircularProgressIndicator(), const SizedBox(width: 16), Expanded(child: Text(v))],
          ),
        ),
      ),
    );
    try {
      final bytes = await service.createBackup(onStage: (s) => stage.value = s);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await dialog;
      if (!context.mounted) return;
      final name = tr('HIScore-백업-{0}.zip', [_stamp()]);
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: Text(tr('파일로 저장')),
                subtitle: Text('${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB'),
                onTap: () => Navigator.pop(context, 'save'),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(tr('공유 / 다른 기기로 보내기')),
                onTap: () => Navigator.pop(context, 'share'),
              ),
            ],
          ),
        ),
      );
      if (choice == 'save') {
        await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: 'application/zip', dialogTitle: tr('백업 저장'));
      } else if (choice == 'share') {
        await SharePlus.instance.share(
          ShareParams(files: [XFile.fromData(bytes, name: name, mimeType: 'application/zip')], fileNameOverrides: [name]),
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        Navigator.of(context).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('백업 실패: {0}', [e]))));
      }
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['zip']);
    final path = picked?.path;
    if (path == null || !context.mounted) return;
    final service = await ref.read(backupServiceProvider.future);
    final bytes = await File(path).readAsBytes();

    BackupSummary summary;
    try {
      summary = await service.inspect(bytes);
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('백업 파일을 읽을 수 없습니다: {0}', [e]))));
      }
      return;
    }
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('복원할까요?')),
        content: Text(
          tr('백업 시각: {0}\n악보 {1}곡, 세트리스트 {2}개, 필기 {3}획, 파일 {4}개\n\n지금 앱에 있는 모든 것이 지워지고 이 백업으로 바뀝니다.', [summary.createdAt?.toLocal().toString().substring(0, 16) ?? '알 수 없음', summary.scores, summary.setlists, summary.strokes, summary.files]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('취소'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('복원'))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await service.restore(bytes);
      // 열려 있던 세션 캐시를 전부 버린다.
      ref.invalidate(scoreSessionProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('복원했습니다'))));
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('복원 실패: {0}', [e]))));
      }
    }
  }

  static String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}-${two(n.hour)}${two(n.minute)}';
  }
}
