import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database.dart';
import '../data/score_exporter.dart';

/// 곡 내보내기. 필기 포함 여부, 페이지 구간, 저장/공유/인쇄.
Future<void> showExportSheet(BuildContext context, {required Score score, required int visiblePageCount}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: _ExportBody(score: score, pageCount: visiblePageCount),
    ),
  );
}

enum _Target { save, share, print }

class _ExportBody extends ConsumerStatefulWidget {
  const _ExportBody({required this.score, required this.pageCount});

  final Score score;
  final int pageCount;

  @override
  ConsumerState<_ExportBody> createState() => _ExportBodyState();
}

class _ExportBodyState extends ConsumerState<_ExportBody> {
  bool _withInk = true;
  bool _applyEdits = true;
  bool _original = false;
  late RangeValues _range = RangeValues(0, (widget.pageCount - 1).toDouble());
  bool _busy = false;
  double? _progress;

  String get _fileName {
    final safe = widget.score.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return _original ? '$safe.pdf' : '$safe${_withInk ? ' (필기)' : ''}.pdf';
  }

  Future<Uint8List> _bytes() async {
    final exporter = await ref.read(scoreExporterProvider.future);
    if (_original) return exporter.originalBytes(widget.score);
    return exporter.build(
      widget.score,
      ExportOptions(
        withInk: _withInk,
        applyPageEdits: _applyEdits,
        firstPage: _range.start.round(),
        lastPage: _range.end.round(),
      ),
      onProgress: (done, total) {
        if (mounted) setState(() => _progress = done / total);
      },
    );
  }

  Future<void> _run(_Target target) async {
    setState(() {
      _busy = true;
      _progress = null;
    });
    try {
      final bytes = await _bytes();
      if (!mounted) return;
      switch (target) {
        case _Target.save:
          final uri = await FilePicker.saveFile(
            fileName: _fileName,
            bytes: bytes,
            mimeType: 'application/pdf',
            dialogTitle: 'PDF 저장',
          );
          if (uri != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장했습니다')));
          }
        case _Target.share:
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile.fromData(bytes, name: _fileName, mimeType: 'application/pdf')],
              subject: widget.score.title,
              fileNameOverrides: [_fileName],
            ),
          );
        case _Target.print:
          await Printing.layoutPdf(onLayout: (_) async => bytes, name: _fileName);
      }
      if (mounted) Navigator.pop(context);
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('내보내기 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = (widget.pageCount - 1).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('내보내기', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('새로 만들기'), icon: Icon(Icons.auto_awesome)),
            ButtonSegment(value: true, label: Text('원본 그대로'), icon: Icon(Icons.description_outlined)),
          ],
          selected: {_original},
          onSelectionChanged: (s) => setState(() => _original = s.first),
        ),
        if (!_original) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('필기와 스탬프 포함'),
            value: _withInk,
            onChanged: (v) => setState(() => _withInk = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('페이지 편집 반영'),
            subtitle: const Text('순서, 숨김, 여백 잘라내기'),
            value: _applyEdits,
            onChanged: (v) => setState(() => _applyEdits = v),
          ),
          if (widget.pageCount > 1 && _applyEdits) ...[
            Text('${_range.start.round() + 1}쪽 ~ ${_range.end.round() + 1}쪽'),
            RangeSlider(
              values: _range,
              max: last,
              divisions: widget.pageCount - 1,
              onChanged: (v) => setState(() => _range = v),
            ),
          ],
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('가져온 PDF 파일을 그대로 보냅니다. 필기와 편집은 들어가지 않습니다.'),
          ),
        if (_busy) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(_Target.save),
                icon: const Icon(Icons.save_alt),
                label: const Text('저장'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(_Target.share),
                icon: const Icon(Icons.share_outlined),
                label: const Text('공유'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _run(_Target.print),
                icon: const Icon(Icons.print_outlined),
                label: const Text('인쇄'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
