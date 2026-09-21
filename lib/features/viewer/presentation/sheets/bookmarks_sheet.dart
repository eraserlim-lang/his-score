import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/database.dart';
import '../../data/page_tools_dao.dart';
import '../../data/score_session.dart';
import '../../../../core/layout/center_sheet.dart';
import '../../../../core/i18n/tr.dart';

/// 북마크 목록. 현재 페이지 추가, 이름 바꾸기, 지우기.
///
/// 악보 하나를 보면 그 악보의 북마크, 세트리스트를 보면 그 세트의 북마크다.
/// 둘은 따로 모인다. 세트에서 단 북마크는 같은 곡을 따로 열어도 보이지 않는다.
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

  /// 세트리스트를 보는 중이면 그 세트의 북마크, 아니면 지금 곡의 북마크.
  BookmarkScope get _scope => session.key.isSetlist
      ? BookmarkScope.setlist(session.key.id)
      : BookmarkScope.score(current.scoreId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = _scope;
    final raw = ref.watch(bookmarksProvider(scope)).value ?? const [];
    final dao = ref.read(pageToolsDaoProvider);
    final scheme = Theme.of(context).colorScheme;

    // 화면에 나오는 차례로 늘어놓는다. 세트에서는 연주 순서가 곧 이 차례다.
    // 세트에 없는 쪽(구간 밖)은 갈 수 없으니 뒤로 보낸다.
    int indexOf(Bookmark b) => session.pageIndexOf(b.scoreId, b.page);
    final bookmarks = [...raw]
      ..sort((x, y) {
        final ix = indexOf(x), iy = indexOf(y);
        if (ix < 0 && iy < 0) return 0;
        if (ix < 0) return 1;
        if (iy < 0) return -1;
        return ix.compareTo(iy);
      });

    String? titleOf(String scoreId) {
      for (final s in session.scores) {
        if (s.id == scoreId) return s.title;
      }
      return null;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('북마크'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      scope.isSetlist ? tr('이 세트리스트의 북마크') : tr('이 악보의 북마크'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _add(context, dao),
                icon: const Icon(Icons.add),
                label: Text(tr('현재 페이지')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: bookmarks.isEmpty
              ? Center(child: Text(tr('북마크가 없습니다')))
              : ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, i) {
                    final b = bookmarks[i];
                    final index = indexOf(b);
                    final reachable = index >= 0;
                    final isHere =
                        b.scoreId == current.scoreId &&
                        b.page == current.sourcePageNumber;
                    // 세트에서는 어느 곡인지가 쪽 번호보다 먼저다.
                    final where = scope.isSetlist
                        ? '${titleOf(b.scoreId) ?? ''} · ${tr('{0}쪽', [b.page])}'
                        : tr('{0}쪽', [b.page]);
                    return Dismissible(
                      key: ValueKey(b.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: scheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline),
                      ),
                      onDismissed: (_) => dao.deleteBookmark(b.id),
                      child: ListTile(
                        enabled: reachable,
                        contentPadding: EdgeInsets.only(
                          left: 20.0 + b.depth * 16,
                          right: 8,
                        ),
                        leading: Icon(
                          isHere ? Icons.bookmark : Icons.bookmark_border,
                          color: isHere ? scheme.primary : null,
                        ),
                        title: Text(
                          b.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          reachable ? where : '$where · ${tr('이 보기에 없는 쪽')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _rename(context, dao, b.id, b.label),
                        ),
                        onTap: reachable
                            ? () {
                                Navigator.pop(context);
                                onJump(index);
                              }
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, PageToolsDao dao) async {
    final label = await _askLabel(
      context,
      tr('북마크 이름'),
      tr('{0}쪽', [current.sourcePageNumber]),
    );
    if (label == null) return;
    await dao.addBookmark(
      current.scoreId,
      current.sourcePageNumber,
      label,
      setlistId: session.key.isSetlist ? session.key.id : null,
    );
  }

  Future<void> _rename(
    BuildContext context,
    PageToolsDao dao,
    String id,
    String initial,
  ) async {
    final label = await _askLabel(context, tr('이름 바꾸기'), initial);
    if (label == null) return;
    await dao.renameBookmark(id, label);
  }

  Future<String?> _askLabel(
    BuildContext context,
    String title,
    String initial,
  ) async {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('취소')),
          ),
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
