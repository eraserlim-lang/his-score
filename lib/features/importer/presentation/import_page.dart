import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'import_actions.dart';

/// 가져오기 허브.
///
/// Phase 1 은 파일 선택만 동작한다. 카메라, 클라우드, IMSLP 는 Phase 5 에서
/// 같은 자리에 채운다.
class ImportPage extends ConsumerWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('가져오기')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _Source(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF 파일',
            subtitle: '기기에 있는 PDF 악보를 가져옵니다',
            onTap: () => importPdfFiles(context, ref),
          ),
          _Source(
            icon: Icons.photo_camera_outlined,
            title: '종이 악보 촬영',
            subtitle: '카메라로 찍거나 사진에서 고릅니다',
            enabled: false,
          ),
          _Source(
            icon: Icons.cloud_outlined,
            title: '클라우드',
            subtitle: 'Google Drive, Dropbox, iCloud',
            enabled: false,
          ),
          _Source(
            icon: Icons.public,
            title: '무료 클래식 악보',
            subtitle: 'IMSLP 에서 검색해 내려받습니다',
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: enabled
            ? const Icon(Icons.chevron_right)
            : const Text('준비 중', style: TextStyle(fontSize: 11)),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
