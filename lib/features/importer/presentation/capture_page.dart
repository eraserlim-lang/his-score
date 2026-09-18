import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/layout/breakpoints.dart';
import '../../viewer/presentation/pages/page_order_page.dart' show ReorderableGridView;
import '../data/image_to_pdf.dart';
import '../data/score_importer.dart';
import '../../../core/i18n/tr.dart';

/// 종이 악보 촬영.
///
/// 카메라로 찍거나 앨범에서 여러 장을 골라 순서를 잡고 한 곡으로 묶는다.
/// 결과는 PDF 로 만들어 다른 악보와 똑같이 다룬다.
class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({super.key});

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  final _pages = <CapturedPage>[];
  final _title = TextEditingController();
  bool _enhance = true;
  bool _busy = false;
  final _picker = ImagePicker();

  bool get _hasCamera =>
      !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final shot = await _picker.pickImage(source: ImageSource.camera, imageQuality: 92);
    if (shot == null) return;
    setState(() => _pages.add(CapturedPage(file: File(shot.path))));
  }

  Future<void> _pickFromAlbum() async {
    final shots = await _picker.pickMultiImage(imageQuality: 92);
    if (shots.isEmpty) return;
    setState(() => _pages.addAll(shots.map((s) => CapturedPage(file: File(s.path)))));
  }

  Future<void> _save() async {
    if (_pages.isEmpty) return;
    setState(() => _busy = true);
    try {
      final pdf = await ImageToPdf.build(
        pages: _pages,
        outDir: Directory.systemTemp,
        enhance: _enhance,
      );
      final importer = await ref.read(scoreImporterProvider.future);
      final id = await importer.importFile(
        pdf,
        title: _title.text.trim().isEmpty ? tr('촬영 {0}', [_dateLabel()]) : _title.text.trim(),
        deleteSource: true,
      );
      if (!mounted) return;
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('저장하지 못했습니다'))));
        return;
      }
      Navigator.pop(context, id);
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('PDF 를 만들지 못했습니다: {0}', [e]))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _dateLabel() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('종이 악보 촬영')),
        actions: [
          FilledButton(
            onPressed: _pages.isEmpty || _busy ? null : _save,
            child: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(tr('저장 ({0}장)', [_pages.length])),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _title,
              decoration: InputDecoration(labelText: tr('제목'), hintText: tr('비우면 날짜로 저장')),
            ),
          ),
          SwitchListTile(
            title: Text(tr('흑백 보정')),
            subtitle: Text(tr('누런 배경과 그림자를 지워 오선을 또렷하게')),
            value: _enhance,
            onChanged: (v) => setState(() => _enhance = v),
          ),
          Expanded(
            child: _pages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(tr('아래 버튼으로 페이지를 담으세요')),
                      ],
                    ),
                  )
                : ReorderableGridView(
                    columns: Breakpoints.of(context).gridColumns,
                    itemCount: _pages.length,
                    onReorder: (from, to) => setState(() {
                      final moved = _pages.removeAt(from);
                      _pages.insert(to, moved);
                    }),
                    itemBuilder: (context, i) => _CaptureTile(
                      key: ValueKey(_pages[i]),
                      index: i,
                      page: _pages[i],
                      onRotate: () => setState(() => _pages[i] = _pages[i].rotated()),
                      onRemove: () => setState(() => _pages.removeAt(i)),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (_hasCamera)
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _busy ? null : _takePhoto,
                        icon: const Icon(Icons.photo_camera),
                        label: Text(tr('촬영')),
                      ),
                    ),
                  if (_hasCamera) const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _busy ? null : _pickFromAlbum,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(tr('앨범에서 고르기')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile({
    super.key,
    required this.index,
    required this.page,
    required this.onRotate,
    required this.onRemove,
  });

  final int index;
  final CapturedPage page;
  final VoidCallback onRotate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RotatedBox(
                  quarterTurns: page.rotation ~/ 90,
                  child: Image.file(page.file, fit: BoxFit.cover),
                ),
                Positioned(
                  left: 4,
                  top: 4,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(iconSize: 18, onPressed: onRotate, icon: const Icon(Icons.rotate_right), tooltip: tr('돌리기')),
              IconButton(iconSize: 18, onPressed: onRemove, icon: const Icon(Icons.close), tooltip: tr('빼기')),
            ],
          ),
        ],
      ),
    );
  }
}
