import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 악보 보기. Phase 1 의 핵심 화면.
class ViewerPage extends ConsumerWidget {
  const ViewerPage({super.key, required this.scoreId, this.initialPage});

  final String scoreId;
  final int? initialPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('악보 $scoreId')),
      body: Center(child: Text('페이지 ${initialPage ?? 1}')),
    );
  }
}
