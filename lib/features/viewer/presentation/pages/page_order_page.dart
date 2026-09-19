import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/database.dart';
import '../../../../core/db/score_dao.dart';
import '../../../../core/db/setlist_dao.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../data/page_render_cache.dart';
import '../../data/score_session.dart';
import '../../domain/page_order_plan.dart';
import '../../../../core/i18n/tr.dart';

/// 페이지 순서 편집. 숨기기, 드래그 이동, 복제, 빈 페이지 추가.
///
/// 곡 하나를 열었으면 그 곡의 페이지만 다룬다. 세트리스트를 열었으면
/// 세트에 든 모든 곡의 페이지를 한 줄로 늘어놓고 곡을 넘나들며 옮길 수 있다.
///
/// 원본 PDF 는 손대지 않는다. 표시 순서와 숨김만 DB 에 남긴다.
/// 저장하면 true 를 돌려주고 호출한 쪽이 세션을 다시 연다.
class PageOrderPage extends ConsumerStatefulWidget {
  const PageOrderPage({super.key, required this.session, this.scoreId});

  final ScoreSession session;

  /// 다룰 곡. null 이면 세션에 든 모든 곡을 한 줄로 놓고 고친다.
  final String? scoreId;

  /// 세트 전체를 한 줄로 고치는 중인지.
  bool get wholeSet => scoreId == null;

  @override
  ConsumerState<PageOrderPage> createState() => _PageOrderPageState();
}

class _Entry implements OrderedPage {
  _Entry({
    required this.id,
    required this.scoreId,
    required this.docIndex,
    required this.sourceIndex,
    required this.hidden,
    this.original,
    this.added = false,
    this.excludeOnly = false,
  });

  /// DB 에서 온 행을 그대로 옮겨 담는다. 이 화면이 건드리지 않는 페이지다.
  factory _Entry.fromRow(ScorePage row, int docIndex) => _Entry(
        id: row.id,
        scoreId: row.scoreId,
        docIndex: docIndex,
        sourceIndex: row.sourceIndex,
        hidden: row.hidden,
        original: row,
      );

  @override
  final String id;

  @override
  final String scoreId;

  /// 세션이 든 문서 목록 안의 위치. 미리보기를 굽는 캐시를 고를 때 쓴다.
  final int docIndex;

  final int sourceIndex;
  bool hidden;

  /// DB 에서 온 행. 회전과 크롭을 물려받는다. 복제/추가로 생긴 항목은 null.
  final ScorePage? original;

  /// 이 화면에서 새로 만든 행. 원본 행 자리를 차지하지 않는다.
  @override
  final bool added;

  /// 세트 전체를 고치는 중이라 [hidden] 이 "세트에서 뺌" 만 뜻하는 행.
  /// 곡에서는 그대로 보인다.
  final bool excludeOnly;

  bool get isBlank => sourceIndex < 0;

  /// DB 에 남길 숨김 값.
  @override
  bool get savedHidden => excludeOnly ? false : hidden;

  @override
  bool get excludedFromSet => hidden;

  ScorePagesCompanion companion(int order) => ScorePagesCompanion.insert(
        id: id,
        scoreId: scoreId,
        sourceIndex: sourceIndex,
        displayOrder: order,
        hidden: Value(savedHidden),
        rotation: Value(original?.rotation ?? 0),
        cropLeft: Value(original?.cropLeft),
        cropTop: Value(original?.cropTop),
        cropRight: Value(original?.cropRight),
        cropBottom: Value(original?.cropBottom),
      );
}

class _PageOrderPageState extends ConsumerState<PageOrderPage> {
  static const _uuid = Uuid();

  List<_Entry>? _entries;

  /// 곡별 전체 페이지 행. 이 화면이 다루지 않는 페이지의 자리를 지키는 데 쓴다.
  final _full = <String, List<ScorePage>>{};

  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 곡 id 를 세션의 문서 번호로. 같은 곡이 두 번 들었으면 앞의 것을 쓴다.
  int _docIndexOf(String scoreId) {
    final i = widget.session.scores.indexWhere((s) => s.id == scoreId);
    return i < 0 ? 0 : i;
  }

  Future<void> _load() async {
    final dao = ref.read(scoreDaoProvider);
    final scoreIds = widget.wholeSet
        ? <String>{for (final s in widget.session.scores) s.id}.toList()
        : [widget.scoreId!];

    for (final id in scoreIds) {
      _full[id] = await dao.allPages(id);
    }

    final entries = <_Entry>[];
    if (widget.wholeSet) {
      // 세트에 실제로 들어 있는 페이지만, 세트 순서 그대로 늘어놓는다.
      final rows = {
        for (final id in scoreIds) id: {for (final r in _full[id]!) r.id: r},
      };
      final seen = <String>{};
      for (final page in widget.session.pages) {
        final row = rows[page.scoreId]?[page.scorePageId];
        // 같은 페이지가 세트에 두 번 들었으면 뒤엣것은 새 행으로 만든다.
        final duplicated = !seen.add(page.scorePageId);
        entries.add(
          _Entry(
            id: duplicated ? _uuid.v4() : page.scorePageId,
            scoreId: page.scoreId,
            docIndex: page.docIndex,
            sourceIndex: row?.sourceIndex ??
                (page.isBlank ? -1 : page.sourcePageNumber - 1),
            hidden: false,
            original: row,
            added: duplicated || row == null,
            excludeOnly: true,
          ),
        );
      }
    } else {
      final docIndex = _docIndexOf(widget.scoreId!);
      for (final r in _full[widget.scoreId!]!) {
        entries.add(_Entry.fromRow(r, docIndex));
      }
    }

    if (!mounted) return;
    setState(() => _entries = entries);
  }

  /// 곡별 전체 페이지를 편집 항목 모양으로 바꾼다.
  /// 이 화면이 다루지 않는 페이지의 자리를 지키는 데 쓴다.
  Map<String, List<_Entry>> _carriedOver() => {
        for (final score in _full.entries)
          score.key: [
            for (final r in score.value) _Entry.fromRow(r, _docIndexOf(score.key)),
          ],
      };

  Future<void> _save() async {
    if (_saving) return;
    final entries = _entries!;
    final rebuilt = rebuildScorePages(entries, _carriedOver());

    List<SetlistItemDraft>? drafts;
    if (widget.wholeSet) {
      drafts = draftSetlistItems(entries, rebuilt);
      if (drafts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('세트에 남은 페이지가 없습니다'))),
        );
        return;
      }
    }

    setState(() => _saving = true);
    final scoreDao = ref.read(scoreDaoProvider);
    for (final score in rebuilt.entries) {
      await scoreDao.replacePages(score.key, [
        for (var i = 0; i < score.value.length; i++) score.value[i].companion(i),
      ]);
    }
    if (drafts != null) {
      await ref
          .read(setlistDaoProvider)
          .replaceItems(widget.session.key.id, drafts);
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _mutate(void Function(List<_Entry>) fn) {
    setState(() {
      fn(_entries!);
      _dirty = true;
    });
  }

  /// 빈 페이지는 목록 끝에 붙인다. 세트에서는 마지막 곡에 딸린다.
  void _addBlank() {
    _mutate((entries) {
      final last = entries.isEmpty ? null : entries.last;
      entries.add(
        _Entry(
          id: _uuid.v4(),
          scoreId: last?.scoreId ??
              widget.scoreId ??
              widget.session.primaryScore.id,
          docIndex: last?.docIndex ?? 0,
          sourceIndex: -1,
          hidden: false,
          added: true,
          excludeOnly: widget.wholeSet,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('저장하지 않고 나갈까요?')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('계속 편집'))),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('나가기'))),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context, false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.wholeSet ? tr('세트 페이지 순서') : tr('페이지 순서')),
          actions: [
            TextButton.icon(
              onPressed: entries == null ? null : _addBlank,
              icon: const Icon(Icons.note_add_outlined),
              label: Text(tr('빈 페이지')),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _dirty && !_saving ? _save : null,
              child: Text(tr('저장')),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: entries == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      widget.wholeSet
                          ? tr('길게 눌러 끌면 곡을 넘나들며 순서가 바뀝니다. 빼기 아이콘으로 세트에서 빼고, + 로 복제합니다.')
                          : tr('길게 눌러 끌면 순서가 바뀝니다. 눈 아이콘으로 숨기고, + 로 복제합니다.'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: ReorderableGridView(
                      columns: Breakpoints.of(context).gridColumns,
                      itemCount: entries.length,
                      onReorder: (from, to) => _mutate((e) {
                        final moved = e.removeAt(from);
                        e.insert(to, moved);
                      }),
                      itemBuilder: (context, i) {
                        final entry = entries[i];
                        return _PageTile(
                          key: ValueKey(entry.id),
                          index: i,
                          entry: entry,
                          cache: widget.session.caches[
                              entry.docIndex.clamp(0, widget.session.caches.length - 1)],
                          // 세트 전체를 고칠 때는 곡이 바뀌는 자리를 알려 준다.
                          label: widget.wholeSet
                              ? widget.session.scores[_docIndexOf(entry.scoreId)].title
                              : null,
                          fromSet: widget.wholeSet,
                          onToggleHidden: () => _mutate((_) => entry.hidden = !entry.hidden),
                          onDuplicate: () => _mutate((e) => e.insert(
                                i + 1,
                                _Entry(
                                  id: _uuid.v4(),
                                  scoreId: entry.scoreId,
                                  docIndex: entry.docIndex,
                                  sourceIndex: entry.sourceIndex,
                                  hidden: false,
                                  original: entry.original,
                                  added: true,
                                  excludeOnly: widget.wholeSet,
                                ),
                              )),
                          onRemove: entry.added
                              ? () => _mutate((e) => e.removeAt(i))
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    super.key,
    required this.index,
    required this.entry,
    required this.cache,
    required this.fromSet,
    required this.onToggleHidden,
    required this.onDuplicate,
    this.label,
    this.onRemove,
  });

  final int index;
  final _Entry entry;
  final PageRenderCache cache;

  /// 타일 아래에 붙일 곡 이름. 세트 전체를 고칠 때만 준다.
  final String? label;

  /// 숨기기가 "세트에서 빼기" 를 뜻하는지.
  final bool fromSet;

  final VoidCallback onToggleHidden;
  final VoidCallback onDuplicate;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: entry.hidden ? 0.3 : 1,
                  child: entry.isBlank
                      ? ColoredBox(
                          color: Colors.white,
                          child: Center(child: Text(tr('빈 페이지'), style: TextStyle(color: Colors.black38))),
                        )
                      : _Thumb(cache: cache, pageNumber: entry.sourceIndex + 1),
                ),
                if (entry.hidden)
                  Center(
                    child: Icon(
                      fromSet ? Icons.playlist_remove : Icons.visibility_off,
                      size: 32,
                    ),
                  ),
                Positioned(
                  left: 4,
                  top: 4,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: scheme.primaryContainer,
                    child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                iconSize: 18,
                onPressed: onToggleHidden,
                icon: Icon(
                  fromSet
                      ? (entry.hidden ? Icons.playlist_add : Icons.playlist_remove)
                      : (entry.hidden ? Icons.visibility : Icons.visibility_off_outlined),
                ),
                tooltip: fromSet
                    ? (entry.hidden ? tr('세트에 넣기') : tr('세트에서 빼기'))
                    : (entry.hidden ? tr('보이기') : tr('숨기기')),
              ),
              IconButton(
                iconSize: 18,
                onPressed: onDuplicate,
                icon: const Icon(Icons.add_box_outlined),
                tooltip: tr('복제'),
              ),
              if (onRemove != null)
                IconButton(
                  iconSize: 18,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                  tooltip: tr('빼기'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatefulWidget {
  const _Thumb({required this.cache, required this.pageNumber});
  final PageRenderCache cache;
  final int pageNumber;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    final key = PageRenderKey.forWidth(widget.pageNumber, 256);
    _image = widget.cache.peek(key);
    if (_image == null) {
      widget.cache.render(key).then((img) {
        if (mounted) setState(() => _image = img);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const ColoredBox(color: Colors.white);
    return RawImage(image: image, fit: BoxFit.cover, alignment: Alignment.topCenter);
  }
}

/// 드래그로 순서를 바꾸는 격자. Flutter 기본 위젯에는 없어 짧게 만든다.
class ReorderableGridView extends StatelessWidget {
  const ReorderableGridView({
    super.key,
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
  });

  final int columns;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.62,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        final child = itemBuilder(context, i);
        return DragTarget<int>(
          onWillAcceptWithDetails: (d) => d.data != i,
          onAcceptWithDetails: (d) => onReorder(d.data, i),
          builder: (context, candidates, _) => LongPressDraggable<int>(
            data: i,
            feedback: Opacity(
              opacity: 0.85,
              child: SizedBox(width: 120, height: 190, child: child),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: child),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: candidates.isNotEmpty
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
