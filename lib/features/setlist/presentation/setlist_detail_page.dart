import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/score_dao.dart';
import '../../../core/db/setlist_dao.dart';
import '../../library/presentation/cover_image.dart';
import '../../library/presentation/tag_manager_sheet.dart';
import 'setlist_share_actions.dart';
import '../../../core/i18n/tr.dart';

/// 세트리스트 하나. 순서 바꾸기, 곡 추가/제거, 구간 지정.
class SetlistDetailPage extends ConsumerWidget {
  const SetlistDetailPage({super.key, required this.setlistId});

  final String setlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setlist = ref.watch(setlistProvider(setlistId)).value;
    final entries =
        ref.watch(setlistEntriesProvider(setlistId)).value ?? const [];
    final dao = ref.read(setlistDaoProvider);

    if (setlist == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalPages = entries.fold<int>(0, (sum, e) => sum + e.pageCount);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/setlists')),
        title: Text(setlist.name),
        actions: [
          IconButton(
            onPressed: () => _rename(context, ref, setlist.name, setlist.note),
            icon: const Icon(Icons.edit_outlined),
            tooltip: tr('이름과 메모'),
          ),
          IconButton(
            onPressed: () => _addScores(context, ref),
            icon: const Icon(Icons.playlist_add),
            tooltip: tr('곡 추가'),
          ),
          IconButton(
            onPressed: () => shareSetlist(context, ref, setlistId, setlist.name),
            icon: const Icon(Icons.share_outlined),
            tooltip: tr('공유'),
          ),
        ],
      ),
      floatingActionButton: entries.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/play/setlist/$setlistId'),
              icon: const Icon(Icons.play_arrow),
              label: Text(tr('연주하기')),
            ),
      body: Column(
        children: [
          if (setlist.note != null && setlist.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(setlist.note!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr('{0}곡 · 총 {1}쪽', [entries.length, totalPages]),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text(tr('오른쪽 위에서 곡을 추가하세요')))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: entries.length,
                    buildDefaultDragHandles: false,
                    onReorderItem: (fromIndex, toIndex) {
                      final ids = entries.map((e) => e.item.id).toList();
                      final moved = ids.removeAt(fromIndex);
                      ids.insert(toIndex, moved);
                      dao.reorder(setlistId, ids);
                    },
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      return _EntryTile(
                        key: ValueKey(entry.item.id),
                        index: i,
                        entry: entry,
                        onRemove: () => dao.removeItem(entry.item.id),
                        onRange: () => _editRange(context, ref, entry),
                        onOpen: () => context.push(
                          '/play/setlist/$setlistId?page=${_startIndexOf(entries, i)}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// i 번째 곡이 세션에서 시작하는 페이지 인덱스.
  int _startIndexOf(List<SetlistEntry> entries, int i) =>
      entries.take(i).fold(0, (sum, e) => sum + e.pageCount);

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String name,
    String? note,
  ) async {
    final nameCtl = TextEditingController(text: name);
    final noteCtl = TextEditingController(text: note ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('세트리스트 정보')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: InputDecoration(labelText: tr('이름')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtl,
              decoration: InputDecoration(labelText: tr('메모')),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('취소')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('저장')),
          ),
        ],
      ),
    );
    if (ok == true && nameCtl.text.trim().isNotEmpty) {
      await ref.read(setlistDaoProvider).rename(
            setlistId,
            nameCtl.text.trim(),
            note: noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
          );
    }
  }

  Future<void> _addScores(BuildContext context, WidgetRef ref) async {
    final scores = await ref
        .read(scoreDaoProvider)
        .watchScores(const ScoreQuery(sort: ScoreSort.title))
        .first;
    if (!context.mounted) return;
    final chosen = await showScoreCheckDialog(
      context,
      title: tr('추가할 곡'),
      scores: scores,
    );
    if (chosen == null || chosen.isEmpty) return;
    final ordered = scores.where((s) => chosen.contains(s.id)).map((s) => s.id);
    await ref.read(setlistDaoProvider).addScores(setlistId, ordered.toList());
  }

  Future<void> _editRange(
    BuildContext context,
    WidgetRef ref,
    SetlistEntry entry,
  ) async {
    final result = await showDialog<(int?, int?)>(
      context: context,
      builder: (context) => _RangeDialog(entry: entry),
    );
    if (result == null) return;
    await ref.read(setlistDaoProvider).setPageRange(
          entry.item.id,
          result.$1,
          result.$2,
        );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    super.key,
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onRange,
    required this.onOpen,
  });

  final int index;
  final SetlistEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onRange;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final rangeText = item.startPage == null && item.endPage == null
        ? tr('{0}쪽 전체', [entry.score.pageCount])
        : tr('{0}~{1}쪽', [(item.startPage ?? 0) + 1, (item.endPage ?? entry.score.pageCount - 1) + 1]);

    return ListTile(
      leading: ReorderableDragStartListener(
        index: index,
        child: Icon(Icons.drag_handle),
      ),
      title: Text(entry.score.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [if (entry.score.artist != null) entry.score.artist!, rangeText]
            .join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 44,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CoverImage(score: entry.score),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'range' => onRange(),
              'remove' => onRemove(),
              _ => null,
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'range', child: Text(tr('페이지 구간'))),
              PopupMenuItem(value: 'remove', child: Text(tr('빼기'))),
            ],
          ),
        ],
      ),
      onTap: onOpen,
    );
  }
}

class _RangeDialog extends StatefulWidget {
  const _RangeDialog({required this.entry});

  final SetlistEntry entry;

  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  late RangeValues _range;
  late bool _whole;

  @override
  void initState() {
    super.initState();
    final item = widget.entry.item;
    final last = widget.entry.score.pageCount - 1;
    _whole = item.startPage == null && item.endPage == null;
    _range = RangeValues(
      (item.startPage ?? 0).toDouble(),
      (item.endPage ?? last).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = (widget.entry.score.pageCount - 1).toDouble();
    return AlertDialog(
      title: Text(tr('연주할 페이지 구간')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: Text(tr('곡 전체')),
            value: _whole,
            onChanged: (v) => setState(() => _whole = v),
          ),
          if (!_whole) ...[
            Text(tr('{0}쪽 ~ {1}쪽', [_range.start.round() + 1, _range.end.round() + 1])),
            RangeSlider(
              values: _range,
              min: 0,
              max: last,
              divisions: last > 0 ? last.toInt() : null,
              onChanged: (v) => setState(() => _range = v),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('취소')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _whole
                ? (null, null)
                : (_range.start.round(), _range.end.round()),
          ),
          child: Text(tr('저장')),
        ),
      ],
    );
  }
}
