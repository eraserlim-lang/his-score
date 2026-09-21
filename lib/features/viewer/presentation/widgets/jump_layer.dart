import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.onEditRequested,
  });

  final ScoreSession session;
  final ViewPage page;
  final bool editing;

  /// 세션 페이지 인덱스로 이동.
  final ValueChanged<int> onJump;

  /// 편집 중 빈 곳을 눌렀을 때. 정규화 좌표를 넘긴다.
  final void Function(Offset normalized) onPlace;

  /// 보기 중 버튼을 길게 눌렀을 때. 편집 모드로 들어간다.
  final VoidCallback? onEditRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jumps =
        ref.watch(jumpButtonsProvider(page.scoreId)).value ?? const [];
    final mine = jumps
        .where((j) => j.fromPage == page.sourcePageNumber)
        .toList();
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
                  onEditRequested: onEditRequested,
                  onDelete: () =>
                      ref.read(pageToolsDaoProvider).deleteJump(j.id),
                  onMoved: (delta) {
                    final moved = toNormalized(toWidget(j.x, j.y) + delta);
                    ref
                        .read(pageToolsDaoProvider)
                        .moveJump(
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

class _JumpChip extends StatefulWidget {
  const _JumpChip({
    required this.jump,
    required this.editing,
    required this.onTap,
    required this.onDelete,
    required this.onMoved,
    this.onEditRequested,
  });

  final JumpButton jump;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback? onEditRequested;
  final VoidCallback onDelete;
  final ValueChanged<Offset> onMoved;

  @override
  State<_JumpChip> createState() => _JumpChipState();
}

class _JumpChipState extends State<_JumpChip> {
  /// 끄는 동안 움직인 만큼. 버튼이 손가락을 따라오게 그린다.
  Offset _drag = Offset.zero;
  bool _dragging = false;

  @override
  void didUpdateWidget(_JumpChip old) {
    super.didUpdateWidget(old);
    // 옮긴 자리가 저장돼 돌아오면 그때 끈 만큼을 거둔다. 먼저 거두면 저장이
    // 오기 전 한 프레임 동안 버튼이 옛 자리로 튀었다 돌아간다.
    if (!_dragging &&
        (old.jump.x != widget.jump.x || old.jump.y != widget.jump.y)) {
      _drag = Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chip = Material(
      color: scheme.tertiaryContainer.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: _dragging ? 8 : 2,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            widget.jump.label ?? '→${widget.jump.toPage}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onTertiaryContainer,
            ),
          ),
        ),
      ),
    );

    if (!widget.editing) {
      return RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          JumpTapRecognizer:
              GestureRecognizerFactoryWithHandlers<JumpTapRecognizer>(
                JumpTapRecognizer.new,
                (r) {
                  r.onTap = widget.onTap;
                  r.onLongPress = widget.onEditRequested == null
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          widget.onEditRequested!();
                        };
                },
              ),
        },
        child: chip,
      );
    }

    return Transform.translate(
      offset: _drag,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: {
              JumpDragRecognizer:
                  GestureRecognizerFactoryWithHandlers<JumpDragRecognizer>(
                    JumpDragRecognizer.new,
                    (r) {
                      r.onStart = () => setState(() => _dragging = true);
                      r.onUpdate = (delta) => setState(() => _drag += delta);
                      r.onEnd = () {
                        setState(() => _dragging = false);
                        if (_drag != Offset.zero) widget.onMoved(_drag);
                      };
                    },
                  ),
            },
            child: AnimatedScale(
              scale: _dragging ? 1.15 : 1,
              duration: const Duration(milliseconds: 120),
              child: chip,
            ),
          ),
          if (!_dragging)
            Positioned(
              right: -6,
              top: -6,
              child: GestureDetector(
                onTap: widget.onDelete,
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

/// 편집 중 점프 버튼 끌기. 조금만 움직여도 먼저 나서서 이긴다.
///
/// 편집 중에도 페이지는 옆으로 밀어 넘길 수 있다. 보통의 끌기 인식기로는
/// 가로 끌기에서 페이지 넘김이 먼저 이겨, 버튼을 옆으로 옮기려 하면 장이
/// 넘어갔다. 넘김이 나서는 거리보다 짧게 움직였을 때 먼저 이겼다고 선언한다.
/// 움직이지 않고 손을 떼면 물러나 X(지우기) 누름을 막지 않는다.
class JumpDragRecognizer extends OneSequenceGestureRecognizer {
  VoidCallback? onStart;
  ValueChanged<Offset>? onUpdate;
  VoidCallback? onEnd;

  /// 이만큼 움직이면 끌기로 본다. 넘김이 나서는 kTouchSlop(18)보다 짧다.
  static const _slop = 4.0;

  Offset? _origin;
  Offset? _last;
  bool _accepted = false;
  bool _started = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _origin = _last = event.position;
    _accepted = _started = false;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      final origin = _origin!;
      if (!_started) {
        if ((event.position - origin).distance < _slop) return;
        if (!_accepted) resolve(GestureDisposition.accepted);
        _started = true;
        onStart?.call();
        // 나서기 전까지 움직인 만큼도 따라간다.
        onUpdate?.call(event.position - origin);
      } else {
        onUpdate?.call(event.position - _last!);
      }
      _last = event.position;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_started) {
        onEnd?.call();
      } else if (!_accepted) {
        resolve(GestureDisposition.rejected);
      }
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    _accepted = true;
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'jump drag';
}

/// 점프 버튼의 누름. 손을 떼는 순간 겨룸에서 먼저 이겼다고 선언한다.
///
/// 페이지 위에는 넘김 탭 영역이 반투명으로 덮여 있다. 보통의 탭 인식기끼리
/// 겨루면 아무도 먼저 나서지 않다가 손을 뗀 뒤 먼저 줄 선 쪽이 이기는데,
/// 그게 위에 덮인 탭 영역이라 점프 버튼을 누르면 페이지만 넘어갔다.
/// 손을 뗄 때 먼저 나서면 탭 영역은 지고 점프만 일어난다.
///
/// 누른 채 조금이라도 끌면 물러난다. 버튼 위에서 시작한 넘김 끌기를 막지 않는다.
///
/// 길게 누르면 [onLongPress]. 페이지를 길게 누르면 뜨는 페이지 메뉴보다
/// 조금 먼저(0.4초) 나서서, 버튼 위에서는 페이지 메뉴 대신 이쪽이 뜬다.
class JumpTapRecognizer extends OneSequenceGestureRecognizer {
  VoidCallback? onTap;
  VoidCallback? onLongPress;

  /// 페이지 길게 누르기(0.5초)보다 짧아야 먼저 이긴다.
  static const longPressDelay = Duration(milliseconds: 400);

  Offset? _origin;
  bool _up = false;
  bool _accepted = false;
  bool _fired = false;
  bool _long = false;
  Timer? _longTimer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _origin = event.position;
    _up = _accepted = _fired = _long = false;
    _longTimer?.cancel();
    if (onLongPress != null) {
      _longTimer = Timer(longPressDelay, () {
        if (_up) return;
        _long = true;
        if (!_accepted) resolve(GestureDisposition.accepted);
        onLongPress?.call();
      });
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      final origin = _origin;
      if (!_long &&
          origin != null &&
          (event.position - origin).distance > kTouchSlop) {
        _longTimer?.cancel();
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
      }
    } else if (event is PointerUpEvent) {
      _up = true;
      _longTimer?.cancel();
      if (_long) {
        // 길게 누른 뒤 뗀 것은 누름이 아니다.
      } else if (_accepted) {
        _fire();
      } else {
        resolve(GestureDisposition.accepted);
      }
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      _longTimer?.cancel();
      resolve(GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    _accepted = true;
    // 겨룰 상대가 없으면 누르는 순간 이긴다. 그때는 손을 뗄 때까지 기다린다.
    if (_up && !_long) _fire();
  }

  @override
  void rejectGesture(int pointer) {
    _longTimer?.cancel();
    super.rejectGesture(pointer);
  }

  @override
  void dispose() {
    _longTimer?.cancel();
    super.dispose();
  }

  void _fire() {
    if (_fired) return;
    _fired = true;
    onTap?.call();
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'jump tap';
}
