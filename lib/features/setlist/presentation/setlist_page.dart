import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/score_dao.dart';
import '../../../core/db/setlist_dao.dart';
import '../../library/presentation/tag_manager_sheet.dart';
import '../../viewer/domain/open_tabs.dart';
import 'setlist_share_actions.dart';
import '../../../core/i18n/tr.dart';

/// 세트리스트 목록.
class SetlistPage extends ConsumerWidget {
  const SetlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setlists = ref.watch(setlistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('세트리스트')),
        actions: [
          IconButton(
            onPressed: () => importSetlistFile(context, ref),
            icon: const Icon(Icons.file_open_outlined),
            tooltip: tr('세트리스트 파일 가져오기'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createSetlist(context, ref),
        icon: const Icon(Icons.add),
        label: Text(tr('새 세트리스트')),
      ),
      body: setlists.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.queue_music,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(tr('세트리스트가 없습니다'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(tr('공연이나 연습 순서대로 곡을 묶어 두세요'),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final entry = list[i];
              return Dismissible(
                key: ValueKey(entry.setlist.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline),
                ),
                confirmDismiss: (_) => _confirmDelete(context, entry.setlist.name),
                onDismissed: (_) {
                  ref.read(setlistDaoProvider).deleteSetlist(entry.setlist.id);
                  ref.read(openTabsProvider.notifier).closeIds([entry.setlist.id]);
                },
                child: ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(entry.setlist.name),
                  subtitle: Text(tr('{0}곡', [entry.itemCount])),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      final dao = ref.read(setlistDaoProvider);
                      switch (v) {
                        case 'play':
                          context.push('/play/setlist/${entry.setlist.id}');
                        case 'share':
                          await shareSetlist(context, ref, entry.setlist.id, entry.setlist.name);
                        case 'duplicate':
                          await dao.duplicate(entry.setlist.id);
                        case 'delete':
                          if (await _confirmDelete(context, entry.setlist.name)) {
                            await dao.deleteSetlist(entry.setlist.id);
                            ref
                                .read(openTabsProvider.notifier)
                                .closeIds([entry.setlist.id]);
                          }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'play',
                        enabled: entry.itemCount > 0,
                        child: Text(tr('세트리스트 보기')),
                      ),
                      PopupMenuItem(value: 'share', child: Text(tr('공유'))),
                      PopupMenuItem(value: 'duplicate', child: Text(tr('복제'))),
                      PopupMenuItem(value: 'delete', child: Text(tr('지우기'))),
                    ],
                  ),
                  onTap: () => context.go('/setlists/${entry.setlist.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('"{0}" 을 지울까요?', [name])),
        content: Text(tr('곡 파일은 그대로 남습니다.')),
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
    return ok == true;
  }
}

/// 이름을 받고 곡을 골라 세트리스트를 만든다. 만든 id 를 돌려준다.
Future<String?> createSetlist(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('새 세트리스트')),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: tr('이름')),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('취소')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(tr('다음')),
        ),
      ],
    ),
  );
  if (name == null || name.trim().isEmpty || !context.mounted) return null;

  final scores = await ref
      .read(scoreDaoProvider)
      .watchScores(const ScoreQuery(sort: ScoreSort.title))
      .first;
  if (!context.mounted) return null;

  final chosen = await showScoreCheckDialog(
    context,
    title: tr('"{0}" 에 넣을 곡', [name.trim()]),
    scores: scores,
  );
  if (chosen == null) return null;

  // 체크 목록은 제목순이라 그 순서대로 넣는다. 나중에 드래그로 바꾼다.
  final ordered = scores.where((s) => chosen.contains(s.id)).map((s) => s.id);
  return ref.read(setlistDaoProvider).create(name.trim(), ordered.toList());
}
