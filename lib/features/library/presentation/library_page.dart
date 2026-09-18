import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/db/score_dao.dart';
import '../../../core/layout/breakpoints.dart';
import '../../importer/presentation/import_actions.dart';

/// 정렬 기준. 화면을 떠나도 유지되도록 화면 밖에 둔다.
class _SortNotifier extends Notifier<ScoreSort> {
  @override
  ScoreSort build() => ScoreSort.recent;
  void set(ScoreSort value) => state = value;
}

class _QueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final _sortProvider = NotifierProvider<_SortNotifier, ScoreSort>(_SortNotifier.new);
final _queryProvider = NotifierProvider<_QueryNotifier, String>(_QueryNotifier.new);

/// 악보 목록.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(_sortProvider);
    final query = ref.watch(_queryProvider);
    final scoresAsync =
        ref.watch(scoreListProvider((sort: sort, query: query)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('악보'),
        actions: [
          PopupMenuButton<ScoreSort>(
            tooltip: '정렬',
            initialValue: sort,
            icon: const Icon(Icons.sort),
            onSelected: (v) => ref.read(_sortProvider.notifier).set(v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: ScoreSort.recent, child: Text('최근 본 순')),
              PopupMenuItem(value: ScoreSort.title, child: Text('제목 순')),
              PopupMenuItem(value: ScoreSort.artist, child: Text('아티스트 순')),
              PopupMenuItem(value: ScoreSort.added, child: Text('추가한 순')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '제목, 아티스트, 작곡가 검색',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => ref.read(_queryProvider.notifier).set(v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => importPdfFiles(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('악보 추가'),
      ),
      body: scoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('목록을 불러오지 못했습니다\n$e')),
        data: (scores) {
          if (scores.isEmpty) {
            return _EmptyState(hasQuery: query.trim().isNotEmpty);
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Breakpoints.of(context).gridColumns,
              childAspectRatio: 0.62,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: scores.length,
            itemBuilder: (context, i) => _ScoreCard(score: scores[i]),
          );
        },
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});

  final Score score;

  @override
  Widget build(BuildContext context) {
    final subtitle = score.artist ?? score.composer;

    return Card(
      child: InkWell(
        onTap: () => context.push('/score/${score.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.description_outlined, size: 32),
                ),
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
                        ? '${score.pageCount}쪽'
                        : '$subtitle · ${score.pageCount}쪽',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off : Icons.library_music_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery ? '검색 결과가 없습니다' : '아직 악보가 없습니다',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 4),
            Text(
              'PDF 악보를 추가해 보세요',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
