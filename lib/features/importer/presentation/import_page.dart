import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 가져오기 허브. Phase 1 은 파일 선택, Phase 5 에서 카메라/클라우드/IMSLP 를 붙인다.
class ImportPage extends ConsumerWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('가져오기')),
      body: const Center(child: Text('가져오기')),
    );
  }
}
