import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/db/score_dao.dart';
import '../../../core/db/setlist_dao.dart';
import '../../library/presentation/cover_image.dart';
import '../../library/presentation/tag_manager_sheet.dart';
import 'setlist_share_actions.dart';
import '../../../core/i18n/tr.dart';

/// 세트리스트 하나. 순서 바꾸기, 곡 추가/제거, 구간 지정.
///
/// 자리가 넉넉하면(태블릿) 두 칸으로 나눈다. 왼쪽은 세트에 든 곡, 오른쪽은
/// 전체 악보다. 오른쪽에서 누르면 왼쪽 끝에 바로 붙는다. 대화상자를 열었다
/// 닫았다 하지 않고 무엇이 들어갔는지 보면서 골라 담을 수 있다.
/// 폰처럼 좁으면 한 칸에 세트만 두고 곡 추가는 대화상자로 한다.
class SetlistDetailPage extends ConsumerStatefulWidget {
  const SetlistDetailPage({super.key, required this.setlistId});

  final String setlistId;

  @override
  ConsumerState<SetlistDetailPage> createState() => _SetlistDetailPageState();
}

class _SetlistDetailPageState extends ConsumerState<SetlistDetailPage> {
  /// 두 칸으로 나눌 최소 폭. 한 칸이 곡 이름과 단추를 담을 만해야 한다.
  static const _twoPaneWidth = 640.0;

  final _setScroll = ScrollController();

  String get setlistId => widget.setlistId;

  @override
  void dispose() {
    _setScroll.dispose();
    super.dispose();
  }

  /// 곡 하나를 세트 끝에 붙이고, 붙은 자리가 보이게 내린다.
  Future<void> _append(String scoreId) async {
    await ref.read(setlistDaoProvider).addScores(setlistId, [scoreId]);
    // 새 항목이 목록에 그려진 다음 프레임에 내려야 끝까지 닿는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_setScroll.hasClients) return;
      _setScroll.animateTo(
        _setScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final setlist = ref.watch(setlistProvider(setlistId)).value;
    final entries =
        ref.watch(setlistEntriesProvider(setlistId)).value ?? const [];

    if (setlist == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoPanes = constraints.maxWidth >= _twoPaneWidth;
        final setPane = _setPane(context, setlist, entries, twoPanes);

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.go('/setlists')),
            title: Text(setlist.name),
            actions: [
              IconButton(
                onPressed: () =>
                    _rename(context, ref, setlist.name, setlist.note),
                icon: const Icon(Icons.edit_outlined),
                tooltip: tr('이름과 메모'),
              ),
              // 두 칸일 때는 오른쪽 칸이 곧 곡 추가다.
              if (!twoPanes)
                IconButton(
                  onPressed: () => _addScores(context, ref),
                  icon: const Icon(Icons.playlist_add),
                  tooltip: tr('곡 추가'),
                ),
              IconButton(
                onPressed: () =>
                    shareSetlist(context, ref, setlistId, setlist.name),
                icon: const Icon(Icons.share_outlined),
                tooltip: tr('공유'),
              ),
            ],
          ),
          floatingActionButton: entries.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => context.push('/play/setlist/$setlistId'),
                  icon: const Icon(Icons.menu_book),
                  label: Text(tr('세트리스트 보기')),
                ),
          // 두 칸이면 연주하기 단추가 오른쪽 칸 위에 뜬다. 왼쪽 끝에 두어
          // 악보 목록의 추가 단추를 가리지 않게 한다.
          floatingActionButtonLocation: twoPanes
              ? FloatingActionButtonLocation.startFloat
              : FloatingActionButtonLocation.endFloat,
          body: twoPanes
              ? Row(
                  children: [
                    Expanded(child: setPane),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _LibraryPane(
                        entries: entries,
                        onAdd: _append,
                      ),
                    ),
                  ],
                )
              : setPane,
        );
      },
    );
  }

  /// 세트에 든 곡. 끌어서 순서를 바꾼다.
  Widget _setPane(
    BuildContext context,
    Setlist setlist,
    List<SetlistEntry> entries,
    bool twoPanes,
  ) {
    final dao = ref.read(setlistDaoProvider);
    final totalPages = entries.fold<int>(0, (sum, e) => sum + e.pageCount);

    return Column(
      children: [
        if (setlist.note != null && setlist.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                setlist.note!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
              ? Center(
                  child: Text(
                    twoPanes
                        ? tr('오른쪽 목록에서 곡을 눌러 담으세요')
                        : tr('오른쪽 위에서 곡을 추가하세요'),
                  ),
                )
              : ReorderableListView.builder(
                  scrollController: _setScroll,
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

/// 전체 악보. 누르면 세트 끝에 붙는다.
///
/// 이미 세트에 든 곡은 몇 번 들었는지 표시한다. 같은 곡을 두 번(예: 여는
/// 곡과 닫는 곡) 넣을 수도 있어 막지는 않는다.
class _LibraryPane extends ConsumerStatefulWidget {
  const _LibraryPane({required this.entries, required this.onAdd});

  final List<SetlistEntry> entries;
  final Future<void> Function(String scoreId) onAdd;

  @override
  ConsumerState<_LibraryPane> createState() => _LibraryPaneState();
}

class _LibraryPaneState extends ConsumerState<_LibraryPane> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scores =
        ref
            .watch(
              scoreListProvider(
                ScoreQuery(sort: ScoreSort.title, text: _query),
              ),
            )
            .value ??
        const <Score>[];
    final included = <String, int>{};
    for (final e in widget.entries) {
      included[e.score.id] = (included[e.score.id] ?? 0) + 1;
    }
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                tr('전체 악보'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              Text(
                tr('{0}곡', [scores.length]),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: tr('제목, 아티스트, 작곡가'),
              border: const OutlineInputBorder(),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: tr('지우기'),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    ),
            ),
          ),
        ),
        Expanded(
          child: scores.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? tr('악보가 없습니다') : tr('찾는 악보가 없습니다'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: scores.length,
                  itemBuilder: (context, i) {
                    final score = scores[i];
                    final times = included[score.id] ?? 0;
                    final inSet = times > 0;
                    return ListTile(
                      // 이미 세트에 든 곡은 고른 행처럼 칠하고 표지에 체크를
                      // 단다. 그래도 또 담을 수 있다.
                      selected: inSet,
                      selectedColor: scheme.onSecondaryContainer,
                      selectedTileColor: scheme.secondaryContainer.withValues(
                        alpha: 0.55,
                      ),
                      leading: SizedBox(
                        width: 36,
                        height: 48,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CoverImage(score: score),
                              ),
                            ),
                            if (inSet)
                              Positioned(
                                right: -6,
                                bottom: -6,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: scheme.primary,
                                  child: Icon(
                                    Icons.check,
                                    size: 14,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      title: Text(
                        score.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          if (score.artist != null) score.artist!,
                          tr('{0}쪽', [score.pageCount]),
                          if (times > 0) tr('세트에 {0}번', [times]),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton.filledTonal(
                        onPressed: () => widget.onAdd(score.id),
                        icon: const Icon(Icons.add),
                        tooltip: inSet ? tr('한 번 더 담기') : tr('세트에 담기'),
                      ),
                      onTap: () => widget.onAdd(score.id),
                    );
                  },
                ),
        ),
      ],
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
