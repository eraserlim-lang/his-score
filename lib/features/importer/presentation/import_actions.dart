import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/score_importer.dart';
import '../../../core/i18n/tr.dart';

/// 파일 선택 창을 띄워 PDF 를 가져오고 결과를 알린다.
///
/// 목록 화면과 가져오기 화면이 같은 동작을 쓰므로 한 곳에 둔다.
Future<void> importPdfFiles(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final importer = await ref.read(scoreImporterProvider.future);

  final result = await importer.pickAndImport(
    onPasswordNeeded: (fileName) =>
        context.mounted ? _askPassword(context, fileName) : Future.value(),
  );

  if (result == null) return; // 사용자가 취소했다
  if (!context.mounted) return;

  final parts = <String>[
    if (result.imported.isNotEmpty) tr('{0}개 추가', [result.imported.length]),
    if (result.hasFailures) tr('{0}개 실패', [result.failures.length]),
  ];

  messenger.showSnackBar(
    SnackBar(
      content: Text(parts.isEmpty ? tr('가져온 악보가 없습니다') : parts.join(', ')),
      action: result.hasFailures
          ? SnackBarAction(
              label: tr('자세히'),
              onPressed: () => _showFailures(context, result.failures),
            )
          : null,
    ),
  );
}

Future<String?> _askPassword(BuildContext context, String fileName) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('암호가 걸린 악보')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fileName, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: tr('암호')),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('건너뛰기')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(tr('열기')),
        ),
      ],
    ),
  );
}

void _showFailures(BuildContext context, Map<String, String> failures) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('가져오지 못한 파일')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in failures.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      entry.value,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('닫기')),
        ),
      ],
    ),
  );
}
