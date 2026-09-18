import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/setlist_share.dart';

/// 세트리스트 공유 메뉴. 텍스트 / 순서만 / 악보 포함.
Future<void> shareSetlist(BuildContext context, WidgetRef ref, String setlistId, String name) async {
  final kind = await showModalBottomSheet<SetlistShareKind>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.notes),
            title: const Text('곡 목록 텍스트'),
            subtitle: const Text('메신저나 메모에 붙여 넣기'),
            onTap: () => Navigator.pop(context, SetlistShareKind.text),
          ),
          ListTile(
            leading: const Icon(Icons.format_list_numbered),
            title: const Text('세트리스트만'),
            subtitle: const Text('순서와 구간만. 받는 쪽에 같은 곡이 있어야 합니다'),
            onTap: () => Navigator.pop(context, SetlistShareKind.setlistOnly),
          ),
          ListTile(
            leading: const Icon(Icons.folder_zip_outlined),
            title: const Text('악보 포함'),
            subtitle: const Text('PDF 를 함께 묶습니다. 필기와 태그는 빠집니다'),
            onTap: () => Navigator.pop(context, SetlistShareKind.withScores),
          ),
        ],
      ),
    ),
  );
  if (kind == null || !context.mounted) return;

  final share = await ref.read(setlistShareProvider.future);
  final safe = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  try {
    switch (kind) {
      case SetlistShareKind.text:
        await SharePlus.instance.share(ShareParams(text: await share.asText(setlistId), subject: name));
      case SetlistShareKind.setlistOnly:
        final bytes = await share.asSetlistFile(setlistId);
        final file = '$safe.${SetlistShare.extension}';
        await SharePlus.instance.share(
          ShareParams(files: [XFile.fromData(bytes, name: file, mimeType: 'application/json')], subject: name, fileNameOverrides: [file]),
        );
      case SetlistShareKind.withScores:
        final bytes = await share.asZip(setlistId);
        final file = '$safe.zip';
        await SharePlus.instance.share(
          ShareParams(files: [XFile.fromData(bytes, name: file, mimeType: 'application/zip')], subject: name, fileNameOverrides: [file]),
        );
    }
  } on Object catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('공유 실패: $e')));
    }
  }
}

/// 세트리스트 파일(.hisetlist / .zip) 가져오기.
Future<void> importSetlistFile(BuildContext context, WidgetRef ref) async {
  final picked = await FilePicker.pickFile(
    dialogTitle: '세트리스트 파일',
    type: FileType.custom,
    allowedExtensions: [SetlistShare.extension, 'zip', 'json'],
  );
  final path = picked?.path;
  if (path == null || !context.mounted) return;
  try {
    final share = await ref.read(setlistShareProvider.future);
    await share.import(File(path));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('세트리스트를 가져왔습니다')));
    }
  } on Object catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('가져오기 실패: $e')));
    }
  }
}
