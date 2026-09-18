import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/storage/app_paths.dart';

/// 표지 이미지. 파일이 없으면 자리표시자를 그린다.
class CoverImage extends ConsumerWidget {
  const CoverImage({super.key, required this.score, this.fit = BoxFit.cover});

  final Score score;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paths = ref.watch(appPathsProvider).value;
    final cover = score.coverPath;

    if (paths == null || cover == null) return const _Placeholder();

    final file = paths.resolve(cover);
    return Image.file(
      file,
      fit: fit,
      alignment: Alignment.topCenter,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.description_outlined, size: 32)),
    );
  }
}
