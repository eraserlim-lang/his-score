import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud_providers.dart';
import '../data/watch_folder_service.dart';
import 'capture_page.dart';
import 'cloud_browser_page.dart';
import 'imslp_page.dart';
import 'import_actions.dart';

/// 가져오기 허브.
class ImportPage extends ConsumerWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(cloudProvidersProvider).value ?? const <CloudProvider>[];
    final isApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    final watch = WatchFolderService.supported ? ref.watch(watchFolderServiceProvider).value : null;

    return Scaffold(
      appBar: AppBar(title: const Text('가져오기')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _Source(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF 파일',
            subtitle: isApple ? '파일 앱, iCloud Drive 에서 고릅니다' : '기기에 있는 PDF 악보를 가져옵니다',
            onTap: () => importPdfFiles(context, ref),
          ),
          _Source(
            icon: Icons.photo_camera_outlined,
            title: '종이 악보 촬영',
            subtitle: '카메라로 찍거나 사진에서 골라 한 곡으로 묶습니다',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CapturePage())),
          ),
          for (final p in providers)
            _Source(
              icon: Icons.cloud_outlined,
              title: p.label,
              subtitle: p.isConfigured ? '폴더를 탐색해 PDF 를 내려받습니다' : '설정에서 클라이언트 ID 를 넣으면 연결됩니다',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CloudBrowserPage(provider: p)),
              ),
            ),
          _Source(
            icon: Icons.public,
            title: '무료 클래식 악보',
            subtitle: 'IMSLP 에서 검색해 내려받습니다',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImslpPage())),
          ),
          if (WatchFolderService.supported)
            _Source(
              icon: Icons.folder_special_outlined,
              title: '감시 폴더',
              subtitle: watch == null
                  ? '설정에서 폴더를 지정하면 PDF 가 들어올 때 자동으로 가져옵니다'
                  : '설정에서 지정한 폴더를 지금 다시 확인합니다',
              onTap: watch == null
                  ? null
                  : () async {
                      final n = await watch.scanNow();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(n == 0 ? '새 파일이 없습니다' : '$n개를 가져왔습니다')),
                        );
                      }
                    },
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
