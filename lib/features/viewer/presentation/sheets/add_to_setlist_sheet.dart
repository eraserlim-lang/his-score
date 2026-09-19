import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/database.dart';
import '../../../../core/db/setlist_dao.dart';
import '../../../../core/i18n/tr.dart';
import '../../../../core/layout/center_sheet.dart';

/// 보고 있는 곡을 세트리스트에 넣는다.
///
/// 곡 전체를 넣는 것이 보통이지만, 앙코르나 발췌처럼 한 쪽만 세트에 거는
/// 일도 있어 "이 페이지만" 을 고를 수 있게 했다.
Future<void> showAddToSetlistSheet(
  BuildContext context, {
  required Score score,

  /// 곡 안에서 몇 번째 쪽을 보고 있는지(0-based, 보이는 순서 기준).
  required int pageIndex,
}) {
  return showCenterSheet<void>(
    context,
    maxWidth: 460,
    scrollable: false,
    child: _AddToSetlistBody(score: score, pageIndex: pageIndex),
  );
}

class _AddToSetlistBody extends ConsumerStatefulWidget {
  const _AddToSetlistBody({required this.score, required this.pageIndex});

  final Score score;
  final int pageIndex;

  @override
  ConsumerState<_AddToSetlistBody> createState() => _AddToSetlistBodyState();
}

class _AddToSetlistBodyState extends ConsumerState<_AddToSetlistBody> {
  /// 보고 있는 쪽에서 부르는 기능이라 그 쪽만 담는 것을 먼저 고른다.
  /// 스위치를 못 보고 지나치면 곡이 통째로 들어가 세트가 엉킨다.
  bool _thisPageOnly = true;
  bool _busy = false;

  Future<void> _add(String setlistId, String setlistName) async {
    setState(() => _busy = true);
    try {
      await ref.read(setlistDaoProvider).addScore(
            setlistId,
            widget.score.id,
            startPage: _thisPageOnly ? widget.pageIndex : null,
            endPage: _thisPageOnly ? widget.pageIndex : null,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('{0} 에 넣었습니다', [setlistName]))),
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('넣지 못했습니다: {0}', [e]))));
    }
  }

  Future<void> _createAndAdd() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: widget.score.title),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;

    setState(() => _busy = true);
    final dao = ref.read(setlistDaoProvider);
    try {
      final id = await dao.create(name.trim(), const []);
      await dao.addScore(
        id,
        widget.score.id,
        startPage: _thisPageOnly ? widget.pageIndex : null,
        endPage: _thisPageOnly ? widget.pageIndex : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('{0} 에 넣었습니다', [name.trim()]))),
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('넣지 못했습니다: {0}', [e]))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final setlists = ref.watch(setlistsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('세트리스트에 넣기'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          widget.score.title,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: true,
              label: Text(tr('{0}쪽만', [widget.pageIndex + 1])),
              icon: const Icon(Icons.insert_page_break_outlined),
            ),
            ButtonSegment(
              value: false,
              label: Text(tr('곡 전체')),
              icon: const Icon(Icons.library_music_outlined),
            ),
          ],
          selected: {_thisPageOnly},
          onSelectionChanged:
              _busy ? null : (v) => setState(() => _thisPageOnly = v.first),
        ),
        const SizedBox(height: 8),
        const Divider(height: 8),
        Flexible(
          child: setlists.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('세트리스트를 불러오지 못했습니다')),
            ),
            data: (rows) => rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(tr('아직 세트리스트가 없습니다')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      return ListTile(
                        leading: const Icon(Icons.queue_music),
                        title: Text(row.setlist.name),
                        subtitle: Text(tr('{0}곡', [row.itemCount])),
                        onTap: _busy
                            ? null
                            : () => _add(row.setlist.id, row.setlist.name),
                      );
                    },
                  ),
          ),
        ),
        const Divider(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _busy ? null : _createAndAdd,
            icon: const Icon(Icons.add),
            label: Text(tr('새 세트리스트')),
          ),
        ),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('새 세트리스트')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: tr('이름')),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('취소')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(tr('만들기')),
        ),
      ],
    );
  }
}
