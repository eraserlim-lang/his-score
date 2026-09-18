import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';

/// 악보 목록. Phase 2 에서 그리드/리스트, 정렬, 검색, 태그 필터를 채운다.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = Breakpoints.of(context).gridColumns;
    return Scaffold(
      appBar: AppBar(
        title: const Text('악보'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            tooltip: '검색',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
            tooltip: '정렬과 보기',
          ),
        ],
      ),
      body: Center(
        child: Text('악보 목록 (열 $columns개)'),
      ),
    );
  }
}
