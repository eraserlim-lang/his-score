import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/score_dao.dart';
import '../../../core/db/tag_dao.dart';

/// 태그 이름 바꾸기, 지우기, 태그에 속한 곡 편집.
Future<void> showTagManagerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const FractionallySizedBox(
      heightFactor: 0.8,
      child: _TagManager(),
    ),
  );
}

class _TagManager extends ConsumerWidget {
  const _TagManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(allTagsProvider).value ?? const <Tag>[];
    final counts = ref.watch(tagCountsProvider).value ?? const {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('태그 관리', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('새 태그'),
              ),
            ],
          ),
        ),
        Expanded(
          child: tags.isEmpty
              ? const Center(child: Text('태그가 없습니다'))
              : ListView.builder(
                  itemCount: tags.length,
                  itemBuilder: (context, i) {
                    final tag = tags[i];
                    return ListTile(
                      leading: const Icon(Icons.tag),
                      title: Text(tag.name),
                      subtitle: Text('${counts[tag.id] ?? 0}곡'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) => switch (v) {
                          'rename' => _rename(context, ref, tag),
                          'scores' => _editScores(context, ref, tag),
                          'delete' => _delete(context, ref, tag),
                          _ => null,
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'scores', child: Text('곡 고르기')),
                          PopupMenuItem(value: 'rename', child: Text('이름 바꾸기')),
                          PopupMenuItem(value: 'delete', child: Text('지우기')),
                        ],
                      ),
                      onTap: () => _editScores(context, ref, tag),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _askName(context, '새 태그', '');
    if (name == null || name.trim().isEmpty) return;
    await ref.read(tagDaoProvider).findOrCreate(name);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Tag tag) async {
    final name = await _askName(context, '이름 바꾸기', tag.name);
    if (name == null || name.trim().isEmpty) return;
    await ref.read(tagDaoProvider).rename(tag.id, name);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Tag tag) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${tag.name}" 태그를 지울까요?'),
        content: const Text('곡은 그대로 남고 태그만 떨어집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(tagDaoProvider).deleteTag(tag.id);
  }

  Future<void> _editScores(BuildContext context, WidgetRef ref, Tag tag) async {
    final dao = ref.read(tagDaoProvider);
    final current = await dao.scoreIdsOfTag(tag.id);
    final scores = await ref
        .read(scoreDaoProvider)
        .watchScores(const ScoreQuery(sort: ScoreSort.title))
        .first;
    if (!context.mounted) return;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _ScoreCheckDialog(
        title: '"${tag.name}" 에 넣을 곡',
        scores: scores,
        initial: current,
      ),
    );
    if (result != null) await dao.setScoresOfTag(tag.id, result);
  }

  Future<String?> _askName(BuildContext context, String title, String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '태그 이름'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

/// 곡 체크 목록. 태그 편집과 세트리스트 만들기에서 함께 쓴다.
class _ScoreCheckDialog extends StatefulWidget {
  const _ScoreCheckDialog({
    required this.title,
    required this.scores,
    required this.initial,
  });

  final String title;
  final List<Score> scores;
  final Set<String> initial;

  @override
  State<_ScoreCheckDialog> createState() => _ScoreCheckDialogState();
}

class _ScoreCheckDialogState extends State<_ScoreCheckDialog> {
  late final Set<String> _selected = {...widget.initial};
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.scores
        .where((s) => s.title.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        height: 460,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '제목으로 찾기',
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final s = visible[i];
                  return CheckboxListTile(
                    dense: true,
                    value: _selected.contains(s.id),
                    title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: s.artist == null ? null : Text(s.artist!),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(s.id);
                      } else {
                        _selected.remove(s.id);
                      }
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('저장 (${_selected.length})'),
        ),
      ],
    );
  }
}

/// 다른 화면에서도 같은 체크 목록을 쓸 수 있게 연다.
Future<Set<String>?> showScoreCheckDialog(
  BuildContext context, {
  required String title,
  required List<Score> scores,
  Set<String> initial = const {},
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (context) =>
        _ScoreCheckDialog(title: title, scores: scores, initial: initial),
  );
}
