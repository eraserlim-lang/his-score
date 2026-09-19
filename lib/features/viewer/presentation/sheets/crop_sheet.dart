import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/database.dart';
import '../../../../core/db/score_dao.dart';
import '../../data/score_session.dart';
import '../widgets/score_page_view.dart';
import '../../../../core/i18n/tr.dart';

/// 여백 잘라내기와 기울기 보정.
///
/// 조정은 전부 페이지 위에서 손가락으로 한다. 변과 모서리를 끌어 여백을,
/// 두 손가락을 돌려 기울기를 맞추고, 벌려서 확대해 세밀하게 본다.
///
/// "모든 페이지" 는 곡 전체 크롭을, "이 페이지" 는 페이지 단독 크롭과 회전을 고친다.
/// 저장하면 호출한 쪽이 세션을 다시 열어야 화면에 반영된다.
Future<bool> showCropSheet(
  BuildContext context, {
  required ScoreSession session,
  required ViewPage current,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // 페이지 위에서 위아래로 끄는 손가락을 시트가 가로채면 안 된다.
    enableDrag: false,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _CropBody(session: session, current: current),
    ),
  );
  return saved == true;
}

class _CropBody extends ConsumerStatefulWidget {
  const _CropBody({required this.session, required this.current});

  final ScoreSession session;
  final ViewPage current;

  @override
  ConsumerState<_CropBody> createState() => _CropBodyState();
}

class _CropBodyState extends ConsumerState<_CropBody> {
  static const _maxTilt = 15.0;

  bool _allPages = true;
  late double _left, _top, _right, _bottom;

  /// 90° 단위 회전과 그 위에 얹는 미세 기울기(-15° ~ 15°).
  late double _quarter, _tilt;

  double get _rotation => (_quarter + _tilt) % 360;

  Score get _score => widget.session.scoreOf(widget.current);

  @override
  void initState() {
    super.initState();
    _loadFor(all: true);
  }

  void _loadFor({required bool all}) {
    final score = _score;
    final crop = widget.current.crop;
    if (all) {
      _left = score.cropLeft;
      _top = score.cropTop;
      _right = score.cropRight;
      _bottom = score.cropBottom;
      _quarter = 0;
      _tilt = 0;
    } else {
      _left = crop.left;
      _top = crop.top;
      _right = 1 - crop.right;
      _bottom = 1 - crop.bottom;
      final rotation = widget.current.rotation;
      _quarter = (rotation / 90).round() * 90.0;
      _tilt = (rotation - _quarter).clamp(-_maxTilt, _maxTilt);
    }
  }

  ViewPage get _preview => ViewPage(
        index: widget.current.index,
        scoreId: widget.current.scoreId,
        scorePageId: widget.current.scorePageId,
        docIndex: widget.current.docIndex,
        sourcePageNumber: widget.current.sourcePageNumber,
        crop: ScoreSession.cropRect(left: _left, top: _top, right: _right, bottom: _bottom),
        rotation: _rotation,
        sourceSize: widget.current.sourceSize,
      );

  Future<void> _save() async {
    final dao = ref.read(scoreDaoProvider);
    if (_allPages) {
      await dao.updateScore(
        _score.id,
        ScoresCompanion(
          cropLeft: Value(_left),
          cropTop: Value(_top),
          cropRight: Value(_right),
          cropBottom: Value(_bottom),
        ),
      );
    } else {
      await dao.updatePage(
        widget.current.scorePageId,
        ScorePagesCompanion(
          cropLeft: Value(_left),
          cropTop: Value(_top),
          cropRight: Value(_right),
          cropBottom: Value(_bottom),
          rotation: Value(_rotation),
        ),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _resetPage() async {
    await ref.read(scoreDaoProvider).updatePage(
          widget.current.scorePageId,
          const ScorePagesCompanion(
            cropLeft: Value(null),
            cropTop: Value(null),
            cropRight: Value(null),
            cropBottom: Value(null),
            rotation: Value(0),
          ),
        );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Text(tr('페이지 조정'), style: Theme.of(context).textTheme.titleLarge),
              Spacer(),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(tr('모든 페이지'))),
                  ButtonSegment(value: false, label: Text(tr('이 페이지'))),
                ],
                selected: {_allPages},
                onSelectionChanged: (s) => setState(() {
                  _allPages = s.first;
                  _loadFor(all: _allPages);
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _CropEditor(
              session: widget.session,
              page: widget.current,
              preview: _preview,
              left: _left,
              top: _top,
              right: _right,
              bottom: _bottom,
              tilt: _tilt,
              maxTilt: _maxTilt,
              tiltEnabled: !_allPages,
              onCropChanged: (l, t, r, b) => setState(() {
                _left = l;
                _top = t;
                _right = r;
                _bottom = b;
              }),
              onTiltChanged: (v) => setState(() => _tilt = v),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _allPages
                    ? tr('변과 모서리를 끌어 여백을 맞춥니다. 두 손가락을 벌려 확대합니다.')
                    : tr('변과 모서리를 끌어 여백을 맞춥니다. 두 손가락을 벌려 확대하고, 돌려서 기울기를 바로잡습니다.'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tr('왼쪽')} ${_percent(_left)} · ${tr('오른쪽')} ${_percent(_right)} · '
                      '${tr('위')} ${_percent(_top)} · ${tr('아래')} ${_percent(_bottom)}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  if (!_allPages) ...[
                    ActionChip(
                      avatar: const Icon(Icons.straighten, size: 18),
                      label: Text('${tr('기울기')} ${_tilt.toStringAsFixed(1)}°'),
                      tooltip: tr('기울기 0°로'),
                      onPressed: _tilt == 0 ? null : () => setState(() => _tilt = 0),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quarter = (_quarter + 90) % 360),
                      icon: const Icon(Icons.rotate_right),
                      tooltip: tr('90° 돌리기'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (!_allPages)
                    TextButton(onPressed: _resetPage, child: Text(tr('이 페이지 초기화')))
                  else
                    TextButton(
                      onPressed: () => setState(() {
                        _left = _top = _right = _bottom = 0;
                      }),
                      child: Text(tr('초기화')),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(tr('취소')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _save, child: Text(tr('저장'))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _percent(double value) => '${(value * 100).round()}%';
}

/// 페이지 위에서 손가락으로 여백과 기울기를 고치는 편집 영역.
///
/// 한 손가락: 변·모서리를 끌면 여백, 안쪽을 끌면 잘라낼 창 전체가 움직인다.
/// 확대한 뒤에는 안쪽 끌기가 화면 이동이 된다.
/// 두 손가락: 벌리면 확대, 돌리면 기울기. 먼저 뚜렷해진 쪽 하나만 따른다.
/// 확대하려다 기울기가 틀어지는 일을 막기 위해서다.
class _CropEditor extends StatefulWidget {
  const _CropEditor({
    required this.session,
    required this.page,
    required this.preview,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.tilt,
    required this.maxTilt,
    required this.tiltEnabled,
    required this.onCropChanged,
    required this.onTiltChanged,
  });

  final ScoreSession session;

  /// 고치기 전의 페이지. 잘라내지 않은 전체 모습을 밑그림으로 쓴다.
  final ViewPage page;

  /// 지금 값대로 자르고 돌린 페이지.
  final ViewPage preview;

  final double left, top, right, bottom;
  final double tilt;
  final double maxTilt;
  final bool tiltEnabled;
  final void Function(double left, double top, double right, double bottom) onCropChanged;
  final ValueChanged<double> onTiltChanged;

  @override
  State<_CropEditor> createState() => _CropEditorState();
}

enum _Grab { none, edges, move, pan }

enum _TwoFinger { undecided, zoom, tilt }

class _CropEditorState extends State<_CropEditor> {
  static const _maxMargin = 0.45;
  static const _maxScale = 5.0;
  static const _grabReach = 30.0;

  Size _area = Size.zero;
  Rect _pageBox = Rect.zero;

  // 보기 확대. 저장되는 값이 아니라 세밀하게 맞추기 위한 돋보기다.
  double _scale = 1;
  Offset _offset = Offset.zero;

  _Grab _grab = _Grab.none;
  bool _grabLeft = false, _grabTop = false, _grabRight = false, _grabBottom = false;
  Offset _startFocal = Offset.zero;
  Offset _lastFocal = Offset.zero;
  late double _startLeft, _startTop, _startRight, _startBottom;

  _TwoFinger _twoFinger = _TwoFinger.undecided;
  double _baseScale = 1, _baseSpan = 1, _baseTilt = 0, _baseRotation = 0;

  Offset get _center => _area.center(Offset.zero);

  Offset _toScreen(Offset p) => (p - _center) * _scale + _center + _offset;
  Offset _toPage(Offset q) => (q - _center - _offset) / _scale + _center;

  Rect get _cropBox => Rect.fromLTRB(
        _pageBox.left + _pageBox.width * widget.left,
        _pageBox.top + _pageBox.height * widget.top,
        _pageBox.right - _pageBox.width * widget.right,
        _pageBox.bottom - _pageBox.height * widget.bottom,
      );

  Rect get _cropOnScreen {
    final box = _cropBox;
    return Rect.fromPoints(_toScreen(box.topLeft), _toScreen(box.bottomRight));
  }

  void _onStart(ScaleStartDetails d) {
    _startFocal = _lastFocal = d.localFocalPoint;
    _twoFinger = _TwoFinger.undecided;
    _grab = _Grab.none;
    if (d.pointerCount != 1) return;

    _startLeft = widget.left;
    _startTop = widget.top;
    _startRight = widget.right;
    _startBottom = widget.bottom;

    final p = d.localFocalPoint;
    final r = _cropOnScreen;
    final inX = p.dx > r.left - _grabReach && p.dx < r.right + _grabReach;
    final inY = p.dy > r.top - _grabReach && p.dy < r.bottom + _grabReach;
    final dl = (p.dx - r.left).abs(), dr = (p.dx - r.right).abs();
    final dt = (p.dy - r.top).abs(), db = (p.dy - r.bottom).abs();

    _grabLeft = inY && dl < _grabReach && dl <= dr;
    _grabRight = inY && dr < _grabReach && dr < dl;
    _grabTop = inX && dt < _grabReach && dt <= db;
    _grabBottom = inX && db < _grabReach && db < dt;

    if (_grabLeft || _grabRight || _grabTop || _grabBottom) {
      _grab = _Grab.edges;
    } else if (_scale > 1) {
      _grab = _Grab.pan;
    } else if (r.contains(p)) {
      _grab = _Grab.move;
    }
    setState(() {});
  }

  void _onUpdate(ScaleUpdateDetails d) {
    final focal = d.localFocalPoint;
    final step = focal - _lastFocal;
    _lastFocal = focal;

    if (d.pointerCount == 1) {
      _dragOneFinger(focal, step);
    } else {
      _dragTwoFingers(d, focal, step);
    }
  }

  void _dragOneFinger(Offset focal, Offset step) {
    if (_grab == _Grab.none || _pageBox.isEmpty) return;
    if (_grab == _Grab.pan) {
      setState(() => _offset = _clampOffset(_offset + step, _scale));
      return;
    }

    // 손가락이 한계를 넘어갔다 돌아와도 변이 손끝에 붙어 있도록
    // 매 순간의 변화량이 아니라 처음 잡은 자리부터의 거리로 계산한다.
    final total = focal - _startFocal;
    final dx = total.dx / _scale / _pageBox.width;
    final dy = total.dy / _scale / _pageBox.height;

    var l = _startLeft, t = _startTop, r = _startRight, b = _startBottom;
    if (_grab == _Grab.move) {
      final mx = dx.clamp(
        math.max(-_startLeft, _startRight - _maxMargin),
        math.min(_maxMargin - _startLeft, _startRight),
      );
      final my = dy.clamp(
        math.max(-_startTop, _startBottom - _maxMargin),
        math.min(_maxMargin - _startTop, _startBottom),
      );
      l += mx;
      r -= mx;
      t += my;
      b -= my;
    } else {
      if (_grabLeft) l = (l + dx).clamp(0.0, _maxMargin);
      if (_grabRight) r = (r - dx).clamp(0.0, _maxMargin);
      if (_grabTop) t = (t + dy).clamp(0.0, _maxMargin);
      if (_grabBottom) b = (b - dy).clamp(0.0, _maxMargin);
    }
    widget.onCropChanged(l, t, r, b);
  }

  void _dragTwoFingers(ScaleUpdateDetails d, Offset focal, Offset step) {
    if (_twoFinger == _TwoFinger.undecided) {
      final zoomPull = (d.scale - 1).abs() / 0.06;
      final tiltPull = widget.tiltEnabled ? d.rotation.abs() / 0.05 : 0.0;
      if (math.max(zoomPull, tiltPull) < 1) return;
      _twoFinger = tiltPull > zoomPull ? _TwoFinger.tilt : _TwoFinger.zoom;
      // 정해지기까지 움직인 만큼은 버린다. 그러지 않으면 값이 튄다.
      _baseScale = _scale;
      _baseSpan = d.scale;
      _baseTilt = widget.tilt;
      _baseRotation = d.rotation;
      setState(() {});
    }

    if (_twoFinger == _TwoFinger.tilt) {
      final degrees = (d.rotation - _baseRotation) * 180 / math.pi;
      // 0.1° 단위로 끊어 손 떨림이 값에 그대로 실리지 않게 한다.
      final tilt = ((_baseTilt + degrees) * 10).round() / 10;
      widget.onTiltChanged(tilt.clamp(-widget.maxTilt, widget.maxTilt));
      return;
    }

    // 두 손가락 사이의 점이 가리키던 곳이 확대 뒤에도 그 손가락 밑에 있게 한다.
    final anchor = _toPage(focal - step);
    final scale = (_baseScale * d.scale / _baseSpan).clamp(1.0, _maxScale);
    final offset = focal - _center - (anchor - _center) * scale;
    setState(() {
      _scale = scale;
      _offset = _clampOffset(offset, scale);
    });
  }

  void _onEnd(ScaleEndDetails d) {
    setState(() {
      _grab = _Grab.none;
      _grabLeft = _grabTop = _grabRight = _grabBottom = false;
      _twoFinger = _TwoFinger.undecided;
      if (_scale < 1.03) {
        _scale = 1;
        _offset = Offset.zero;
      }
    });
  }

  Offset _clampOffset(Offset offset, double scale) {
    final mx = (scale - 1) * _area.width / 2;
    final my = (scale - 1) * _area.height / 2;
    return Offset(offset.dx.clamp(-mx, mx), offset.dy.clamp(-my, my));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _area = constraints.biggest;

        // 모서리 손잡이가 가장자리에 걸리지 않도록 둘레를 띄운다.
        const margin = 28.0;
        final room = Size(
          math.max(1, _area.width - margin * 2),
          math.max(1, _area.height - margin * 2),
        );
        final source = widget.page.sourceSize;
        final aspect = source.isEmpty ? 1 / math.sqrt2 : source.width / source.height;
        final fitted = room.width / room.height > aspect
            ? Size(room.height * aspect, room.height)
            : Size(room.width, room.width / aspect);
        _pageBox = Rect.fromCenter(
          center: _center,
          width: fitted.width,
          height: fitted.height,
        );

        final whole = ViewPage(
          index: widget.page.index,
          scoreId: widget.page.scoreId,
          scorePageId: widget.page.scorePageId,
          docIndex: widget.page.docIndex,
          sourcePageNumber: widget.page.sourcePageNumber,
          crop: const Rect.fromLTWH(0, 0, 1, 1),
          rotation: 0,
          sourceSize: widget.page.sourceSize,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _onStart,
              onScaleUpdate: _onUpdate,
              onScaleEnd: _onEnd,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform(
                    transform: Matrix4.identity()
                      ..translateByDouble(
                        _center.dx + _offset.dx,
                        _center.dy + _offset.dy,
                        0,
                        1,
                      )
                      ..scaleByDouble(_scale, _scale, 1, 1)
                      ..translateByDouble(-_center.dx, -_center.dy, 0, 1),
                    child: Stack(
                      children: [
                        // 잘려 나갈 부분은 어둡게, 남는 부분은 결과 그대로 보여준다.
                        Positioned.fromRect(
                          rect: _pageBox,
                          child: ScorePageView(session: widget.session, page: whole),
                        ),
                        Positioned.fromRect(
                          rect: _pageBox,
                          child: const ColoredBox(color: Color(0x99000000)),
                        ),
                        Positioned.fromRect(
                          rect: _cropBox,
                          child: ScorePageView(
                            session: widget.session,
                            page: widget.preview,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 손잡이는 확대해도 같은 크기로 남아야 잡기 쉽다.
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _CropFramePainter(
                        frame: _cropOnScreen,
                        color: scheme.primary,
                        activeLeft: _grabLeft || _grab == _Grab.move,
                        activeTop: _grabTop || _grab == _Grab.move,
                        activeRight: _grabRight || _grab == _Grab.move,
                        activeBottom: _grabBottom || _grab == _Grab.move,
                        showLevels: _twoFinger == _TwoFinger.tilt,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 잘라낼 창의 테두리와 손잡이. 기울기를 맞추는 동안에는 수평 기준선을 긋는다.
class _CropFramePainter extends CustomPainter {
  _CropFramePainter({
    required this.frame,
    required this.color,
    required this.activeLeft,
    required this.activeTop,
    required this.activeRight,
    required this.activeBottom,
    required this.showLevels,
  });

  final Rect frame;
  final Color color;
  final bool activeLeft, activeTop, activeRight, activeBottom;
  final bool showLevels;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    if (showLevels) {
      // 오선이 이 선들과 나란해지면 바로 선 것이다.
      final level = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 1;
      const lines = 8;
      for (var i = 1; i < lines; i++) {
        final y = frame.top + frame.height * i / lines;
        canvas.drawLine(Offset(frame.left, y), Offset(frame.right, y), level);
      }
    }

    canvas.drawRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color,
    );

    Paint grip(bool active) => Paint()
      ..color = color
      ..strokeWidth = active ? 7 : 4.5
      ..strokeCap = StrokeCap.round;

    // 변 가운데 손잡이.
    final reachX = math.min(22.0, frame.width / 6);
    final reachY = math.min(22.0, frame.height / 6);
    final c = frame.center;
    canvas.drawLine(Offset(frame.left, c.dy - reachY), Offset(frame.left, c.dy + reachY), grip(activeLeft));
    canvas.drawLine(Offset(frame.right, c.dy - reachY), Offset(frame.right, c.dy + reachY), grip(activeRight));
    canvas.drawLine(Offset(c.dx - reachX, frame.top), Offset(c.dx + reachX, frame.top), grip(activeTop));
    canvas.drawLine(Offset(c.dx - reachX, frame.bottom), Offset(c.dx + reachX, frame.bottom), grip(activeBottom));

    // 모서리 꺾쇠.
    void corner(Offset at, double sx, double sy, bool active) {
      final paint = grip(active);
      canvas.drawLine(at, at + Offset(reachX * sx, 0), paint);
      canvas.drawLine(at, at + Offset(0, reachY * sy), paint);
    }

    corner(frame.topLeft, 1, 1, activeLeft && activeTop);
    corner(frame.topRight, -1, 1, activeRight && activeTop);
    corner(frame.bottomLeft, 1, -1, activeLeft && activeBottom);
    corner(frame.bottomRight, -1, -1, activeRight && activeBottom);
  }

  @override
  bool shouldRepaint(_CropFramePainter old) =>
      old.frame != frame ||
      old.color != color ||
      old.activeLeft != activeLeft ||
      old.activeTop != activeTop ||
      old.activeRight != activeRight ||
      old.activeBottom != activeBottom ||
      old.showLevels != showLevels;
}
