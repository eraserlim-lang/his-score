import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/db/database.dart';
import '../../../core/db/score_dao.dart';
import '../../../core/db/tag_dao.dart';
import '../../../core/storage/app_paths.dart';
import '../../importer/data/score_importer.dart';
import 'cover_image.dart';

/// 악보 정보 화면. 제목, 아티스트, 작곡가, 태그, 표지를 고친다.
Future<void> showScoreInfoSheet(BuildContext context, String scoreId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _ScoreInfoBody(scoreId: scoreId, scrollController: controller),
    ),
  );
}

class _ScoreInfoBody extends ConsumerStatefulWidget {
  const _ScoreInfoBody({required this.scoreId, required this.scrollController});

  final String scoreId;
  final ScrollController scrollController;

  @override
  ConsumerState<_ScoreInfoBody> createState() => _ScoreInfoBodyState();
}

class _ScoreInfoBodyState extends ConsumerState<_ScoreInfoBody> {
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _composer = TextEditingController();
  final _genre = TextEditingController();
  final _tagInput = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _composer.dispose();
    _genre.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  void _seed(Score score) {
    if (_seeded) return;
    _seeded = true;
    _title.text = score.title;
    _artist.text = score.artist ?? '';
    _composer.text = score.composer ?? '';
    _genre.text = score.genre ?? '';
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('제목은 비울 수 없습니다')));
      return;
    }
    await ref.read(scoreDaoProvider).updateScore(
          widget.scoreId,
          ScoresCompanion(
            title: Value(title),
            artist: Value(_nullIfEmpty(_artist.text)),
            composer: Value(_nullIfEmpty(_composer.text)),
            genre: Value(_nullIfEmpty(_genre.text)),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  static String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _addTag(String name) async {
    if (name.trim().isEmpty) return;
    final dao = ref.read(tagDaoProvider);
    final tag = await dao.findOrCreate(name);
    await dao.attach(widget.scoreId, tag.id);
    _tagInput.clear();
  }

  Future<void> _changeCover(Score score) async {
    final choice = await showModalBottomSheet<_CoverChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_stories_outlined),
              title: const Text('악보 페이지에서 고르기'),
              onTap: () => Navigator.pop(context, _CoverChoice.page),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('사진에서 고르기'),
              onTap: () => Navigator.pop(context, _CoverChoice.photo),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final covers = await ref.read(coverGeneratorProvider.future);
    final paths = await ref.read(appPathsProvider.future);
    String? newCover;

    switch (choice) {
      case _CoverChoice.photo:
        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (picked == null) return;
        newCover = await covers.fromImageFile(score.id, File(picked.path));
      case _CoverChoice.page:
        if (!mounted) return;
        final page = await _pickPage(score);
        if (page == null) return;
        final doc = await PdfDocument.openFile(
          paths.resolve(score.filePath).path,
          passwordProvider:
              score.pdfPassword == null ? null : () => score.pdfPassword,
          firstAttemptByEmptyPassword: score.pdfPassword == null,
        );
        try {
          newCover = await covers.fromPage(score.id, doc, page);
        } finally {
          doc.dispose();
        }
    }

    await covers.deleteCover(score.coverPath);
    await ref.read(scoreDaoProvider).updateScore(
          score.id,
          ScoresCompanion(coverPath: Value(newCover)),
        );
  }

  Future<int?> _pickPage(Score score) {
    return showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('표지로 쓸 페이지'),
        children: [
          SizedBox(
            width: 300,
            height: 300,
            child: GridView.count(
              crossAxisCount: 4,
              children: [
                for (var i = 1; i <= score.pageCount; i++)
                  InkWell(
                    onTap: () => Navigator.pop(context, i),
                    child: Center(child: Text('$i')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreAsync = ref.watch(scoreProvider(widget.scoreId));
    final tagsAsync = ref.watch(tagsOfScoreProvider(widget.scoreId));
    final allTags = ref.watch(allTagsProvider).value ?? const <Tag>[];

    final score = scoreAsync.value;
    if (score == null) return const Center(child: CircularProgressIndicator());
    _seed(score);

    final tags = tagsAsync.value ?? const <Tag>[];
    final attached = tags.map((t) => t.id).toSet();

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _changeCover(score),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 96,
                height: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CoverImage(score: score),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: '제목'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _artist,
                    decoration: const InputDecoration(labelText: '아티스트'),
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _composer,
                decoration: const InputDecoration(labelText: '작곡가'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _genre,
                decoration: const InputDecoration(labelText: '장르'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('태그', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in tags)
              InputChip(
                label: Text(tag.name),
                onDeleted: () =>
                    ref.read(tagDaoProvider).detach(score.id, tag.id),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Autocomplete<Tag>(
          optionsBuilder: (value) {
            final q = value.text.trim().toLowerCase();
            if (q.isEmpty) return const Iterable<Tag>.empty();
            return allTags.where(
              (t) => !attached.contains(t.id) && t.name.toLowerCase().contains(q),
            );
          },
          displayStringForOption: (t) => t.name,
          onSelected: (t) => ref.read(tagDaoProvider).attach(score.id, t.id),
          fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
            controller: controller,
            focusNode: focus,
            decoration: const InputDecoration(
              labelText: '태그 추가',
              hintText: '입력 후 Enter',
              prefixIcon: Icon(Icons.tag),
            ),
            onSubmitted: (v) async {
              await _addTag(v);
              controller.clear();
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${score.pageCount}쪽 · ${_formatSize(score.fileSize)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _save, child: const Text('저장')),
          ],
        ),
      ],
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

enum _CoverChoice { page, photo }
