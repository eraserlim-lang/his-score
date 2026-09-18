import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/database.dart';
import '../../data/page_tools_dao.dart';
import '../../data/score_session.dart';

/// 페이지 위에 놓인 점프 버튼.
///
/// 보기 모드에서는 누르면 목적 페이지로 간다.
/// 편집 모드에서는 빈 곳을 눌러 새 버튼을 놓고, 버튼을 끌어 옮기고, X 로 지운다.
class JumpLayer extends ConsumerWidget {
  const JumpLayer({
    super.key,
    required this.session,
    required this.page,
    required this.editing,
    required this.onJump,
    required this.onPlace,
  });

  final ScoreSession session;
  final ViewPage page;
  final bool editing;

  /// 세션 페이지 인덱스로 이동.
  final ValueChanged<int> onJump;

  /// 편집 중 빈 곳을 눌렀을 때. 정규화 좌표를 넘긴다.
  final void Function(Offset normalized) onPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jumps = ref.watch(jumpButtonsProvider(page.scoreId)).value ?? const [];
    final mine = jumps.where((j) => j.fromPage == page.sourcePageNumber).toList();
    if (mine.isEmpty && !editing) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final crop = page.crop;

        Offset toWidget(double nx, double ny) => Offset(
              (nx - crop.left) / crop.width * size.width,
              (ny - crop.top) / crop.height * size.height,
            );
        Offset toNormalized(Offset w) => Offset(
              w.dx / size.width * crop.width + crop.left,
              w.dy / size.height * crop.height + crop.top,
            );

        return Stack(
          children: [
            if (editing)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => onPlace(toNormalized(d.localPosition)),
                ),
              ),
            for (final j in mine)
              Positioned(
                left: toWidget(j.x, j.y).dx - 22,
                top: toWidget(j.x, j.y).dy - 22,
                child: _JumpChip(
                  jump: j,
                  editing: editing,
                  onTap: () {
                    final index = session.pageIndexOf(page.scoreId, j.toPage);
                    if (index >= 0) onJump(index);
                  },
                  onDelete: () => ref.read(pageToolsDaoProvider).deleteJump(j.id),
                  onMoved: (delta) {
                    final moved = toNormalized(toWidget(j.x, j.y) + delta);
                    ref.read(pageToolsDaoProvider).moveJump(
                          j.id,
                          moved.dx.clamp(0, 1),
                          moved.dy.clamp(0, 1),
                        );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _JumpChip extends StatelessWidget {
  const _JumpChip({
    required this.jump,
    required this.editing,
    required this.onTap,
    required this.onDelete,
    required this.onMoved,
  });

  final JumpButton jump;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<Offset> onMoved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chip = Material(
      color: scheme.tertiaryContainer.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: editing ? null : onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              jump.label ?? '→${jump.toPage}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ),
      ),
    );

    if (!editing) return chip;

    Offset accumulated = Offset.zero;
    return GestureDetector(
      onPanUpdate: (d) => accumulated += d.delta,
      onPanEnd: (_) {
        if (accumulated != Offset.zero) onMoved(accumulated);
        accumulated = Offset.zero;
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          chip,
          Positioned(
            right: -6,
            top: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: scheme.error,
                child: Icon(Icons.close, size: 12, color: scheme.onError),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
