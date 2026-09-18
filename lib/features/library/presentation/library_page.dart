import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/db/score_dao.dart';
import '../../../core/db/setlist_dao.dart';
import '../../../core/db/tag_dao.dart';
import '../../../core/layout/breakpoints.dart';
import '../../importer/data/score_importer.dart';
import '../../importer/presentation/import_actions.dart';
import '../../setlist/presentation/setlist_picker.dart';
import 'cover_image.dart';
import 'score_info_sheet.dart';
import 'tag_manager_sheet.dart';
import '../../../core/i18n/tr.dart';

/// 조회 조건. 화면을 떠나도 유지되도록 화면 밖에 둔다.
class LibraryQueryNotifier extends Notifier<ScoreQuery> {
  @override
  ScoreQuery build() => const ScoreQuery();

  void setSort(ScoreSort sort) => state = state.copyWith(sort: sort);
  void setText(String text) => state = state.copyWith(text: text);

  void toggleTag(String tagId) {
    final next = {...state.tagIds};
    if (!next.remove(tagId)) next.add(tagId);
    state = state.copyWith(tagIds: next);
  }

  void clearTags() => state = state.copyWith(tagIds: const {});
}

final libraryQueryProvider =
    NotifierProvider<LibraryQueryNotifier, ScoreQuery>(LibraryQueryNotifier.new);

class _GridModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

final _gridModeProvider = NotifierProvider<_GridModeNotifier, bool>(
  _GridModeNotifier.new,
);

/// 악보 목록.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  /// 다중 선택 중인 곡 id. 비어 있으면 일반 모드다.
  final _selected = <String>{};
  bool _searching = false;
  final _search = TextEditingController();

  bool get _selecting => _selected.isNotEmpty;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _clearSelection() => setState(_selected.clear);

  Future<void> _deleteSelected(List<Score> scores) async {
    final targets = scores.where((s) => _selected.contains(s.id)).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('{0}곡을 지울까요?', [targets.length])),
        content: Text(tr('파일과 필기가 함께 지워지며 되돌릴 수 없습니다.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('취소')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('지우기')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final importer = await ref.read(scoreImporterProvider.future);
    await importer.deleteScores(targets);
    _clearSelection();
  }

  Future<void> _tagSelected() async {
    final tags = await ref.read(tagDaoProvider).all();
    if (!mounted) return;
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => _PickTagDialog(tags: tags),
    );
    if (chosen == null) return;

    final dao = ref.read(tagDaoProvider);
    final tag = await dao.findOrCreate(chosen);
    await dao.attachMany(_selected, tag.id);
    _clearSelection();
  }

  Future<void> _addSelectedToSetlist() async {
    final setlistId = await pickSetlist(context, ref);
    if (setlistId == null) return;
    await ref.read(setlistDaoProvider).addScores(setlistId, _selected.toList());
    _clearSelection();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('세트리스트에 추가했습니다'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(libraryQueryProvider);
    final grid = ref.watch(_gridModeProvider);
    final scoresAsync = ref.watch(scoreListProvider(query));
    final tags = ref.watch(allTagsProvider).value ?? const <Tag>[];
    final counts = ref.watch(tagCountsProvider).value ?? const {};

    return Scaffold(
      appBar: _selecting
          ? AppBar(
              leading: IconButton(
                onPressed: _clearSelection,
                icon: const Icon(Icons.close),
              ),
              title: Text(tr('{0}곡 선택', [_selected.length])),
              actions: [
                IconButton(
                  onPressed: _tagSelected,
                  icon: const Icon(Icons.tag),
                  tooltip: tr('태그 붙이기'),
                ),
                IconButton(
                  onPressed: _addSelectedToSetlist,
                  icon: const Icon(Icons.playlist_add),
                  tooltip: tr('세트리스트에 추가'),
                ),
                IconButton(
                  onPressed: () =>
                      _deleteSelected(scoresAsync.value ?? []),
                  icon: Icon(Icons.delete_outline),
                  tooltip: tr('지우기'),
                ),
              ],
            )
          : AppBar(
              title: _searching
                  ? TextField(
                      controller: _search,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: tr('제목, 아티스트, 작곡가'),
                        border: InputBorder.none,
                      ),
                      onChanged: ref.read(libraryQueryProvider.notifier).setText,
                    )
                  : Text(tr('악보')),
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() => _searching = !_searching);
                    if (!_searching) {
                      _search.clear();
                      ref.read(libraryQueryProvider.notifier).setText('');
                    }
                  },
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  tooltip: tr('검색'),
                ),
                IconButton(
                  onPressed: ref.read(_gridModeProvider.notifier).toggle,
                  icon: Icon(grid ? Icons.view_list : Icons.grid_view),
                  tooltip: grid ? tr('목록으로 보기') : tr('격자로 보기'),
                ),
                PopupMenuButton<ScoreSort>(
                  tooltip: tr('정렬'),
                  initialValue: query.sort,
                  icon: Icon(Icons.sort),
                  onSelected: ref.read(libraryQueryProvider.notifier).setSort,
                  itemBuilder: (context) => [
                    PopupMenuItem(value: ScoreSort.recent, child: Text(tr('최근 본 순'))),
                    PopupMenuItem(value: ScoreSort.title, child: Text(tr('제목 순'))),
                    PopupMenuItem(value: ScoreSort.artist, child: Text(tr('아티스트 순'))),
                    PopupMenuItem(value: ScoreSort.added, child: Text(tr('추가한 순'))),
                  ],
                ),
              ],
              bottom: tags.isEmpty
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: _TagBar(
                        tags: tags,
                        counts: counts,
                        selected: query.tagIds,
                        onToggle:
                            ref.read(libraryQueryProvider.notifier).toggleTag,
                        onClear: ref.read(libraryQueryProvider.notifier).clearTags,
                        onManage: () => showTagManagerSheet(context),
                      ),
                    ),
            ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton.extended(
              onPressed: () => importPdfFiles(context, ref),
              icon: const Icon(Icons.add),
              label: Text(tr('악보 추가')),
            ),
      body: scoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(tr('목록을 불러오지 못했습니다\n{0}', [e]))),
        data: (scores) {
          if (scores.isEmpty) {
            return _EmptyState(
              hasFilter: query.text.trim().isNotEmpty || query.tagIds.isNotEmpty,
            );
          }
          if (grid) {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Breakpoints.of(context).gridColumns,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: scores.length,
              itemBuilder: (context, i) => _ScoreCard(
                score: scores[i],
                selected: _selected.contains(scores[i].id),
                selecting: _selecting,
                onTap: () => _open(scores[i]),
                onLongPress: () => _toggle(scores[i].id),
                onInfo: () => showScoreInfoSheet(context, scores[i].id),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: scores.length,
            itemBuilder: (context, i) => _ScoreTile(
              score: scores[i],
              selected: _selected.contains(scores[i].id),
              selecting: _selecting,
              onTap: () => _open(scores[i]),
              onLongPress: () => _toggle(scores[i].id),
              onInfo: () => showScoreInfoSheet(context, scores[i].id),
            ),
          );
        },
      ),
    );
  }

  void _open(Score score) {
    if (_selecting) {
      _toggle(score.id);
    } else {
      context.push('/score/${score.id}');
    }
  }
}

class _TagBar extends StatelessWidget {
  const _TagBar({
    required this.tags,
    required this.counts,
    required this.selected,
    required this.onToggle,
    required this.onClear,
    required this.onManage,
  });

  final List<Tag> tags;
  final Map<String, int> counts;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          if (selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(tr('전체')),
                avatar: const Icon(Icons.clear, size: 16),
                onPressed: onClear,
              ),
            ),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text('${tag.name} ${counts[tag.id] ?? 0}'),
                selected: selected.contains(tag.id),
                onSelected: (_) => onToggle(tag.id),
              ),
            ),
          IconButton(
            onPressed: onManage,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: tr('태그 관리'),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
    required this.onInfo,
  });

  final Score score;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final subtitle = score.artist ?? score.composer;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CoverImage(score: score),
                  if (selecting)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        color: selected ? scheme.primary : Colors.white,
                      ),
                    )
                  else
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: onInfo,
                        icon: const Icon(Icons.info_outline, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white70,
                        ),
                        tooltip: tr('정보'),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    subtitle == null
                        ? tr('{0}쪽', [score.pageCount])
                        : tr('{0} · {1}쪽', [subtitle, score.pageCount]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.score,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
    required this.onInfo,
  });

  final Score score;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: SizedBox(
        width: 40,
        height: 54,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CoverImage(score: score),
        ),
      ),
      title: Text(score.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (score.artist != null) score.artist!,
          if (score.composer != null) score.composer!,
          tr('{0}쪽', [score.pageCount]),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: selecting
          ? Icon(selected ? Icons.check_circle : Icons.circle_outlined)
          : IconButton(
              onPressed: onInfo,
              icon: const Icon(Icons.info_outline),
              tooltip: tr('정보'),
            ),
    );
  }
}

class _PickTagDialog extends StatefulWidget {
  const _PickTagDialog({required this.tags});

  final List<Tag> tags;

  @override
  State<_PickTagDialog> createState() => _PickTagDialogState();
}

class _PickTagDialogState extends State<_PickTagDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('태그 붙이기')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: tr('새 태그 또는 기존 태그 이름')),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          if (widget.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                for (final t in widget.tags)
                  ActionChip(
                    label: Text(t.name),
                    onPressed: () => Navigator.pop(context, t.name),
                  ),
              ],
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
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(tr('붙이기')),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.library_music_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter ? tr('조건에 맞는 악보가 없습니다') : tr('아직 악보가 없습니다'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 4),
            Text(
              tr('PDF 악보를 추가해 보세요'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
