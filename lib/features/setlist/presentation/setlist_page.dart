import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 세트리스트. Phase 2 에서 생성/편집/복제/공유를 채운다.
class SetlistPage extends ConsumerWidget {
  const SetlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('세트리스트')),
      body: const Center(child: Text('세트리스트')),
    );
  }
}
