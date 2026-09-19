import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/page_tools_dao.dart';
import '../../data/score_session.dart';
import '../../../../core/layout/center_sheet.dart';
import '../../../../core/i18n/tr.dart';

/// 북마크 목록. 현재 페이지 추가, PDF 목차 가져오기, 이름 바꾸기, 지우기.
///
/// 세트리스트를 보는 중이면 지금 페이지가 속한 곡의 북마크만 다룬다.
Future<void> showBookmarksSheet(
  BuildContext context, {
  required ScoreSession session,
  required ViewPage current,
  required ValueChanged<int> onJump,
}) {
  return showCenterSheet<void>(
    context,
    maxWidth: 520,
    // 목록이 안에서 스스로 스크롤한다.
    fill: true,
    scrollable: false,
    child: _BookmarksBody(session: session, current: current, onJump: onJump),
  );
}

class _BookmarksBody extends ConsumerWidget {
  const _BookmarksBody({
    required this.session,
    required this.current,
    required this.onJump,
  });

  final ScoreSession session;
  final ViewPage current;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreId = current.scoreId;
    final bookmarks = ref.watch(bookmarksProvider(scoreId)).value ?? const [];
    final dao = ref.read(pageToolsDaoProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(tr('북마크'), style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final n = await dao.importOutline(
                    scoreId,
                    session.documentFor(current),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(n == 0 ? tr('PDF 에 목차가 없습니다') : tr('목차 {0}개를 가져왔습니다', [n])),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: Text(tr('목차 가져오기')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _add(context, dao, scoreId),
                icon: const Icon(Icons.add),
                label: Text(tr('현재 페이지')),
              ),
            ],
          ),
        ),
        Expanded(
          child: bookmarks.isEmpty
              ? Center(child: Text(tr('북마크가 없습니다')))
              : ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, i) {
                    final b = bookmarks[i];
                    final isHere = b.page == current.sourcePageNumber;
                    return Dismissible(
                      key: ValueKey(b.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline),
                      ),
                      onDismissed: (_) => dao.deleteBookmark(b.id),
                      child: ListTile(
                        contentPadding: EdgeInsets.only(left: 20.0 + b.depth * 16, right: 8),
                        leading: Icon(
                          isHere ? Icons.bookmark : Icons.bookmark_border,
                          color: isHere ? Theme.of(context).colorScheme.primary : null,
                        ),
                        title: Text(b.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(tr('{0}쪽', [b.page])),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _rename(context, dao, b.id, b.label),
                        ),
                        onTap: () {
                          final index = session.pageIndexOf(scoreId, b.page);
                          if (index < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr('숨긴 페이지라 갈 수 없습니다'))),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          onJump(index);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, PageToolsDao dao, String scoreId) async {
    final label = await _askLabel(context, tr('북마크 이름'), tr('{0}쪽', [current.sourcePageNumber]));
    if (label == null) return;
    await dao.addBookmark(scoreId, current.sourcePageNumber, label);
  }

  Future<void> _rename(BuildContext context, PageToolsDao dao, String id, String initial) async {
    final label = await _askLabel(context, tr('이름 바꾸기'), initial);
    if (label == null) return;
    await dao.renameBookmark(id, label);
  }

  Future<String?> _askLabel(BuildContext context, String title, String initial) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('취소'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(tr('확인')),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return null;
    return result.trim();
  }
}
