import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/database.dart';
import '../../../../core/db/score_dao.dart';
import '../../data/score_session.dart';
import '../widgets/score_page_view.dart';

/// 여백 잘라내기와 기울기 보정.
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
    showDragHandle: true,
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
  bool _allPages = true;
  late double _left, _top, _right, _bottom, _rotation;

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
      _rotation = 0;
    } else {
      _left = crop.left;
      _top = crop.top;
      _right = 1 - crop.right;
      _bottom = 1 - crop.bottom;
      _rotation = widget.current.rotation;
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('페이지 조정', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('모든 페이지')),
                  ButtonSegment(value: false, label: Text('이 페이지')),
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: ScorePageView(session: widget.session, page: _preview),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              _edge('왼쪽', _left, (v) => setState(() => _left = v)),
              _edge('오른쪽', _right, (v) => setState(() => _right = v)),
              _edge('위', _top, (v) => setState(() => _top = v)),
              _edge('아래', _bottom, (v) => setState(() => _bottom = v)),
              if (!_allPages)
                Row(
                  children: [
                    const SizedBox(width: 56, child: Text('기울기')),
                    Expanded(
                      child: Slider(
                        value: _rotation,
                        min: -15,
                        max: 15,
                        divisions: 300,
                        label: '${_rotation.toStringAsFixed(1)}°',
                        onChanged: (v) => setState(() => _rotation = v),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _rotation = (_rotation + 90) % 360),
                      icon: const Icon(Icons.rotate_right),
                      tooltip: '90° 돌리기',
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (!_allPages)
                    TextButton(onPressed: _resetPage, child: const Text('이 페이지 초기화'))
                  else
                    TextButton(
                      onPressed: () => setState(() {
                        _left = _top = _right = _bottom = 0;
                      }),
                      child: const Text('초기화'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _save, child: const Text('저장')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _edge(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            max: 0.45,
            label: '${(value * 100).round()}%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 40, child: Text('${(value * 100).round()}%', textAlign: TextAlign.end)),
      ],
    );
  }
}
