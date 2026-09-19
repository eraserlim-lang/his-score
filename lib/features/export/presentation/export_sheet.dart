import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database.dart';
import '../../../core/layout/center_sheet.dart';
import '../data/score_exporter.dart';
import '../../../core/i18n/tr.dart';

/// 곡 내보내기. 필기 포함 여부, 페이지 구간, 저장/공유/인쇄.
Future<void> showExportSheet(BuildContext context, {required Score score, required int visiblePageCount}) {
  return showCenterSheet<void>(
    context,
    child: _ExportBody(score: score, pageCount: visiblePageCount),
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
            dialogTitle: tr('PDF 저장'),
          );
          if (uri != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('저장했습니다'))));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('내보내기 실패: {0}', [e]))));
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
        Text(tr('내보내기'), style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(tr('새로 만들기')), icon: Icon(Icons.auto_awesome)),
            ButtonSegment(value: true, label: Text(tr('원본 그대로')), icon: Icon(Icons.description_outlined)),
          ],
          selected: {_original},
          onSelectionChanged: (s) => setState(() => _original = s.first),
        ),
        if (!_original) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('필기와 스탬프 포함')),
            value: _withInk,
            onChanged: (v) => setState(() => _withInk = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('페이지 편집 반영')),
            subtitle: Text(tr('순서, 숨김, 여백 잘라내기')),
            value: _applyEdits,
            onChanged: (v) => setState(() => _applyEdits = v),
          ),
          if (widget.pageCount > 1 && _applyEdits) ...[
            Text(tr('{0}쪽 ~ {1}쪽', [_range.start.round() + 1, _range.end.round() + 1])),
            RangeSlider(
              values: _range,
              max: last,
              divisions: widget.pageCount - 1,
              onChanged: (v) => setState(() => _range = v),
            ),
          ],
        ] else
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(tr('가져온 PDF 파일을 그대로 보냅니다. 필기와 편집은 들어가지 않습니다.')),
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
                label: Text(tr('저장')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(_Target.share),
                icon: const Icon(Icons.share_outlined),
                label: Text(tr('공유')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _run(_Target.print),
                icon: const Icon(Icons.print_outlined),
                label: Text(tr('인쇄')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 지금 보고 있는 한 쪽만 내보낸다.
///
/// 곡 전체 내보내기와 달리 구간을 고를 것이 없다. 한 쪽을 그림으로 떼어
/// 메신저에 붙이거나 PDF 한 장으로 넘기는 일이 잦아 따로 두었다.
Future<void> showPageSaveSheet(
  BuildContext context, {
  required Score score,

  /// 곡 안에서 몇 번째 쪽인지(0-based, 보이는 순서 기준).
  required int pageIndex,
}) {
  return showCenterSheet<void>(
    context,
    maxWidth: 460,
    child: _PageSaveBody(score: score, pageIndex: pageIndex),
  );
}

enum _PageFormat { pdf, png }

class _PageSaveBody extends ConsumerStatefulWidget {
  const _PageSaveBody({required this.score, required this.pageIndex});

  final Score score;
  final int pageIndex;

  @override
  ConsumerState<_PageSaveBody> createState() => _PageSaveBodyState();
}

class _PageSaveBodyState extends ConsumerState<_PageSaveBody> {
  bool _withInk = true;
  _PageFormat _format = _PageFormat.pdf;
  bool _busy = false;

  bool get _isPdf => _format == _PageFormat.pdf;
  String get _mime => _isPdf ? 'application/pdf' : 'image/png';

  String get _fileName {
    final safe = widget.score.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final ink = _withInk ? ' (필기)' : '';
    return '$safe p${widget.pageIndex + 1}$ink.${_isPdf ? 'pdf' : 'png'}';
  }

  Future<Uint8List?> _bytes() async {
    final exporter = await ref.read(scoreExporterProvider.future);
    final options = ExportOptions(
      withInk: _withInk,
      firstPage: widget.pageIndex,
      lastPage: widget.pageIndex,
    );
    return _isPdf
        ? await exporter.build(widget.score, options)
        : await exporter.pageImage(widget.score, options);
  }

  Future<void> _run(_Target target) async {
    setState(() => _busy = true);
    try {
      final bytes = await _bytes();
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('이 쪽을 굽지 못했습니다'))));
        return;
      }
      switch (target) {
        case _Target.save:
          final uri = await FilePicker.saveFile(
            fileName: _fileName,
            bytes: bytes,
            mimeType: _mime,
            dialogTitle: tr('이 페이지 저장'),
          );
          if (uri != null && mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(tr('저장했습니다'))));
          }
        case _Target.share:
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile.fromData(bytes, name: _fileName, mimeType: _mime)],
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('내보내기 실패: {0}', [e]))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('이 페이지 저장'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          tr('{0}쪽', [widget.pageIndex + 1]),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<_PageFormat>(
          segments: [
            ButtonSegment(
              value: _PageFormat.pdf,
              label: const Text('PDF'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            ButtonSegment(
              value: _PageFormat.png,
              label: Text(tr('이미지')),
              icon: const Icon(Icons.image_outlined),
            ),
          ],
          selected: {_format},
          onSelectionChanged: (s) => setState(() => _format = s.first),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('필기와 스탬프 포함')),
          value: _withInk,
          onChanged: (v) => setState(() => _withInk = v),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _run(_Target.save),
                icon: const Icon(Icons.download),
                label: Text(tr('저장')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _busy ? null : () => _run(_Target.share),
                icon: const Icon(Icons.ios_share),
                label: Text(tr('공유')),
              ),
            ),
            if (_isPdf) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _busy ? null : () => _run(_Target.print),
                icon: const Icon(Icons.print_outlined),
                tooltip: tr('인쇄'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
