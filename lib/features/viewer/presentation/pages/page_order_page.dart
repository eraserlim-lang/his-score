import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/database.dart';
import '../../../../core/db/score_dao.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../data/page_render_cache.dart';
import '../../data/score_session.dart';
import '../../../../core/i18n/tr.dart';

/// 페이지 순서 편집. 숨기기, 드래그 이동, 복제, 빈 페이지 추가.
///
/// 원본 PDF 는 손대지 않는다. 표시 순서와 숨김만 DB 에 남긴다.
/// 저장하면 true 를 돌려주고 호출한 쪽이 세션을 다시 연다.
class PageOrderPage extends ConsumerStatefulWidget {
  const PageOrderPage({super.key, required this.session, required this.scoreId});

  final ScoreSession session;
  final String scoreId;

  @override
  ConsumerState<PageOrderPage> createState() => _PageOrderPageState();
}

class _Entry {
  _Entry({required this.id, required this.sourceIndex, required this.hidden, this.original});
  final String id;
  final int sourceIndex;
  bool hidden;

  /// DB 에서 온 행이면 그대로 두고, 복제/추가로 생긴 항목은 null.
  final ScorePage? original;

  bool get isBlank => sourceIndex < 0;
}

class _PageOrderPageState extends ConsumerState<PageOrderPage> {
  static const _uuid = Uuid();
  List<_Entry>? _entries;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await ref.read(scoreDaoProvider).allPages(widget.scoreId);
    if (!mounted) return;
    setState(() {
      _entries = [
        for (final r in rows)
          _Entry(id: r.id, sourceIndex: r.sourceIndex, hidden: r.hidden, original: r),
      ];
    });
  }

  Future<void> _save() async {
    final entries = _entries!;
    await ref.read(scoreDaoProvider).replacePages(widget.scoreId, [
      for (var i = 0; i < entries.length; i++)
        ScorePagesCompanion.insert(
          id: entries[i].id,
          scoreId: widget.scoreId,
          sourceIndex: entries[i].sourceIndex,
          displayOrder: i,
          hidden: Value(entries[i].hidden),
          rotation: Value(entries[i].original?.rotation ?? 0),
          cropLeft: Value(entries[i].original?.cropLeft),
          cropTop: Value(entries[i].original?.cropTop),
          cropRight: Value(entries[i].original?.cropRight),
          cropBottom: Value(entries[i].original?.cropBottom),
        ),
    ]);
    if (mounted) Navigator.pop(context, true);
  }

  void _mutate(void Function(List<_Entry>) fn) {
    setState(() {
      fn(_entries!);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final docIndex = widget.session.scores.indexWhere((s) => s.id == widget.scoreId);
    final cache = widget.session.caches[docIndex < 0 ? 0 : docIndex];

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
          title: Text(tr('페이지 순서')),
          actions: [
            TextButton.icon(
              onPressed: () => _mutate((e) => e.add(
                    _Entry(id: _uuid.v4(), sourceIndex: -1, hidden: false),
                  )),
              icon: const Icon(Icons.note_add_outlined),
              label: Text(tr('빈 페이지')),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _dirty ? _save : null, child: Text(tr('저장'))),
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
                      tr('길게 눌러 끌면 순서가 바뀝니다. 눈 아이콘으로 숨기고, + 로 복제합니다.'),
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
                          cache: cache,
                          onToggleHidden: () => _mutate((_) => entry.hidden = !entry.hidden),
                          onDuplicate: () => _mutate((e) => e.insert(
                                i + 1,
                                _Entry(id: _uuid.v4(), sourceIndex: entry.sourceIndex, hidden: false),
                              )),
                          onRemove: entry.original == null
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
    required this.onToggleHidden,
    required this.onDuplicate,
    this.onRemove,
  });

  final int index;
  final _Entry entry;
  final PageRenderCache cache;
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
                  const Center(child: Icon(Icons.visibility_off, size: 32)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                iconSize: 18,
                onPressed: onToggleHidden,
                icon: Icon(entry.hidden ? Icons.visibility : Icons.visibility_off_outlined),
                tooltip: entry.hidden ? tr('보이기') : tr('숨기기'),
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
