import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database.dart';
import '../../../core/layout/center_sheet.dart';
import '../../../core/layout/floating_window.dart';
import '../domain/keyboard.dart';
import '../domain/metronome.dart';
import '../domain/music_player.dart';
import '../domain/pitch.dart';
import '../domain/recorder.dart';
import '../domain/tuner.dart';
import '../../../core/i18n/tr.dart';

/// 음악 도구 종류.
enum MusicTool {
  metronome('메트로놈', Icons.av_timer, Icons.timer),
  keyboard('건반', Icons.piano_outlined, Icons.piano),
  tuner('튜너', Icons.graphic_eq, Icons.equalizer),
  recorder('녹음기', Icons.mic_none, Icons.mic),
  player('플레이어', Icons.music_note_outlined, Icons.music_note);

  const MusicTool(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;

  /// 도구가 돌고 있을 때의 아이콘. 비어 있던 모양이 채워진다.
  final IconData activeIcon;
}

/// 떠 있는 도구 창. 도구마다 하나만 띄운다.
///
/// 예전에는 누를 때마다 새 창을 띄워 같은 메트로놈이 두 개씩 떴다. 이제는
/// 이미 떠 있으면 누를 때 닫는다. 창이 떠 있는 도구는 아래 막대에서
/// 돌고 있는 것으로 보인다.
final openToolWindows = ValueNotifier<Map<MusicTool, VoidCallback>>(const {});

Widget _toolBody(MusicTool tool, String? scoreId) => switch (tool) {
  MusicTool.metronome => const MetronomePanel(),
  MusicTool.keyboard => const KeyboardPanel(),
  MusicTool.tuner => const TunerPanel(),
  MusicTool.recorder => RecorderPanel(scoreId: scoreId),
  MusicTool.player => const PlayerPanel(),
};

/// 도구 하나를 연다. 닫아도 메트로놈과 재생은 계속된다.
///
/// 건반만 바닥 시트로 둔다. 건반은 화면 아래 폭을 다 써야 짚을 만하고,
/// 손이 가는 자리도 아래쪽이다. 나머지는 가운데 판으로 연다.
Future<void> showMusicTool(
  BuildContext context,
  MusicTool tool, {
  String? scoreId,
}) {
  // 닫은 뒤에도 창을 띄워야 하므로 부르는 쪽 context 를 들고 있는다.
  final host = context;

  Widget body(BuildContext inner) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              tr(tool.label),
              style: Theme.of(inner).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: tr('별도 창으로 띄우기'),
            icon: const Icon(Icons.open_in_new),
            onPressed: () {
              Navigator.pop(inner);
              openMusicToolWindow(host, tool, scoreId: scoreId);
            },
          ),
        ],
      ),
      _toolBody(tool, scoreId),
    ],
  );

  if (tool != MusicTool.keyboard) {
    return showCenterSheet<void>(
      context,
      maxWidth: 480,
      child: Builder(builder: body),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    // 넓은 화면에서 기본 640pt 로 묶이면 건반이 좁아진다. 화면을 그대로 쓴다.
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (sheetContext) => Padding(
      // 건반은 좌우 끝까지 쓰는 편이 짚기 좋다.
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: body(sheetContext),
    ),
  );
}

/// 도구를 악보 위에 떠 있는 창으로 연다. 악보를 보면서 쓸 수 있다.
void openMusicToolWindow(
  BuildContext context,
  MusicTool tool, {
  String? scoreId,
}) {
  final opened = openToolWindows.value[tool];
  if (opened != null) {
    opened();
    return;
  }
  final close = showFloatingWindow(
    onClosed: () {
      openToolWindows.value = {...openToolWindows.value}..remove(tool);
    },
    context: context,
    title: tr(tool.label),
    // 건반은 옆으로 넓어야 짚을 만하고, 메트로놈은 조절할 것이 많아 높다.
    // 처음 열릴 때 내용이 잘리면 안 된다.
    initialSize: switch (tool) {
      MusicTool.keyboard => const Size(640, 300),
      MusicTool.metronome => const Size(480, 600),
      MusicTool.tuner => const Size(420, 440),
      _ => const Size(430, 400),
    },
    builder: (context, close) => _toolBody(tool, scoreId),
  );
  openToolWindows.value = {...openToolWindows.value, tool: close};
}

/// 음악 도구 버튼 묶음. 악보 보기 아래 막대의 왼쪽에 가로로 늘어놓는다.
///
/// 예전에는 화면 왼쪽 가운데에 세로 판으로 떠 있어 악보 왼쪽 가장자리를
/// 가렸다. 아래 막대로 내려 악보를 비운다. 막대가 좁으면(폰 세로) 다섯 개를
/// 다 늘어놓을 자리가 없어 버튼 하나로 접고 메뉴로 연다.
class MusicToolButtons extends ConsumerWidget {
  const MusicToolButtons({super.key, this.scoreId, this.collapsed = false});

  final String? scoreId;

  /// 버튼 하나로 접을지.
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metronome = ref.watch(metronomeProvider);
    final player = ref.watch(musicPlayerProvider);
    final recorder = ref.watch(recorderProvider);
    final tuner = ref.watch(tunerProvider);
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: openToolWindows,
      builder: (context, windows, _) {
        // 소리를 내거나 듣고 있으면, 또는 창이 떠 있으면 돌고 있는 것이다.
        // 창을 닫아도 메트로놈과 재생은 계속되니 둘 다 본다.
        bool active(MusicTool t) =>
            windows.containsKey(t) ||
            switch (t) {
              MusicTool.metronome => metronome.running,
              MusicTool.player => player.hasTrack,
              MusicTool.recorder => recorder.recording,
              MusicTool.tuner => tuner.listening,
              MusicTool.keyboard => false,
            };

        if (collapsed) {
          final any = MusicTool.values.any(active);
          return PopupMenuButton<MusicTool>(
            tooltip: tr('음악 도구'),
            // 켜져 있는 도구가 있으면 접힌 버튼도 선택된 모양으로 둔다.
            icon: Icon(
              any ? Icons.music_note : Icons.music_note_outlined,
              color: any ? scheme.primary : null,
            ),
            onSelected: (t) =>
                openMusicToolWindow(context, t, scoreId: scoreId),
            itemBuilder: (context) => [
              for (final t in MusicTool.values)
                PopupMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      Icon(
                        active(t) ? t.activeIcon : t.icon,
                        size: 22,
                        color: active(t) ? scheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text(tr(t.label)),
                    ],
                  ),
                ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in MusicTool.values)
              // 도구는 악보를 보면서 쓰는 것이라 바로 떠 있는 창으로 연다.
              // 길게 누르면 예전처럼 판으로 연다.
              GestureDetector(
                onLongPress: () => showMusicTool(context, t, scoreId: scoreId),
                child: IconButton(
                  tooltip: tr(t.label),
                  isSelected: active(t),
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  // 돌고 있는 도구는 색 바탕을 깔아 한눈에 갈리게 한다.
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? scheme.primaryContainer
                          : null,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? scheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                  onPressed: () =>
                      openMusicToolWindow(context, t, scoreId: scoreId),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- 메트로놈

class MetronomePanel extends ConsumerWidget {
  const MetronomePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(metronomeProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 150,
          child: CustomPaint(
            size: const Size(double.infinity, 150),
            painter: _PendulumPainter(
              position: m.pendulum,
              beat: m.beat,
              beats: m.beatsPerBar,
              running: m.running,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: () => m.nudge(-1),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 8),
            _BpmField(metronome: m),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => m.nudge(1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Slider(
          value: m.bpm.toDouble(),
          min: MetronomeController.minBpm.toDouble(),
          max: MetronomeController.maxBpm.toDouble(),
          onChanged: (v) => m.setBpm(v.round()),
        ),
        _Labeled(
          label: tr('박자'),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final n in [2, 3, 4, 5, 6, 7])
                _ToggleButton(
                  label: '$n',
                  selected: m.beatsPerBar == n,
                  onTap: () => m.setBeatsPerBar(n),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _Labeled(
          label: tr('분할'),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (n, l) in [(1, '♩'), (2, '♫'), (3, '3'), (4, '4')])
                _ToggleButton(
                  label: l,
                  selected: m.subdivision == n,
                  onTap: () => m.setSubdivision(n),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // TAP 은 손가락으로 박자를 두드리는 버튼이라 크게. 좁은 창에서는
        // 아래로 내려가도록 Wrap 으로 둔다. Row 는 넘쳐서 잘렸다.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ToggleButton(
              label: tr('첫 박 강세'),
              selected: m.accentFirst,
              onTap: () => m.setAccentFirst(!m.accentFirst),
            ),
            _ToggleButton(
              label: tr('무음'),
              icon: m.silent ? Icons.volume_off : Icons.volume_up,
              selected: m.silent,
              onTap: () => m.setSilent(!m.silent),
            ),
            SizedBox(
              height: 56,
              width: 120,
              child: FilledButton.tonal(
                onPressed: m.tap,
                style: FilledButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('TAP'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.volume_down, size: 18),
            Expanded(
              child: Slider(value: m.volume, onChanged: m.setVolume),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: m.toggle,
            icon: Icon(m.running ? Icons.stop : Icons.play_arrow),
            label: Text(m.running ? tr('정지') : tr('시작')),
          ),
        ),
      ],
    );
  }
}

/// 템포 숫자. 누르면 그 자리에서 바로 고친다. 대화상자는 손이 멀었다.
class _BpmField extends StatefulWidget {
  const _BpmField({required this.metronome});

  final MetronomeController metronome;

  @override
  State<_BpmField> createState() => _BpmFieldState();
}

class _BpmFieldState extends State<_BpmField> {
  bool _editing = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _begin() {
    _controller.text = '${widget.metronome.bpm}';
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    setState(() => _editing = true);
  }

  void _commit() {
    final n = int.tryParse(_controller.text.trim());
    if (n != null) widget.metronome.setBpm(n);
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metronome;
    final big = Theme.of(context).textTheme.displaySmall;

    if (_editing) {
      return SizedBox(
        width: 120,
        child: TextField(
          controller: _controller,
          autofocus: true,
          textAlign: TextAlign.center,
          style: big,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(isDense: true),
          onSubmitted: (_) => _commit(),
          onTapOutside: (_) => _commit(),
        ),
      );
    }

    return InkWell(
      onTap: _begin,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text('${m.bpm}', style: big),
            Text(m.tempoName, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

/// 이름표를 앞에 두고 내용을 옆에 놓는다.
class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// 고르는 버튼. 골라도 크기가 변하지 않는다.
///
/// ChoiceChip 은 고르면 체크 표시가 끼어들어 폭이 늘고, 옆 버튼들이 밀려
/// 줄이 흔들린다. 여기서는 색과 테두리만 바꾼다. 테두리는 모양 안쪽에
/// 그려져 배치에 영향이 없다.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Material(
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? scheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendulumPainter extends CustomPainter {
  _PendulumPainter({
    required this.position,
    required this.beat,
    required this.beats,
    required this.running,
    required this.color,
  });

  final double position;
  final int beat;
  final int beats;
  final bool running;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height - 16);
    final len = size.height - 40;
    final angle = position * 0.5;
    final tip = pivot + Offset(len * -angle.clamp(-1, 1), -len * 0.95);
    final paint = Paint()
      ..color = color.withValues(alpha: running ? 1 : 0.35)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, tip, paint);
    canvas.drawCircle(tip, 10, paint..style = PaintingStyle.fill);

    // 박 불빛
    final dotW = 18.0;
    final totalW = beats * dotW + (beats - 1) * 8;
    var x = (size.width - totalW) / 2 + dotW / 2;
    for (var i = 0; i < beats; i++) {
      final on = running && i == beat;
      canvas.drawCircle(
        Offset(x, 12),
        on ? 8 : 5,
        Paint()..color = on ? color : color.withValues(alpha: 0.25),
      );
      x += dotW + 8;
    }
  }

  @override
  bool shouldRepaint(_PendulumPainter old) =>
      old.position != position ||
      old.beat != beat ||
      old.running != running ||
      old.beats != beats;
}

// ---------------------------------------------------------------- 건반

class KeyboardPanel extends ConsumerWidget {
  const KeyboardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = ref.watch(keyboardProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => k.shiftOctave(-1),
              icon: const Icon(Icons.chevron_left),
              tooltip: tr('한 옥타브 아래'),
            ),
            Text(
              PitchReading.fromFrequency(
                PitchReading.frequencyOf(k.lowest),
              ).label,
            ),
            IconButton(
              onPressed: () => k.shiftOctave(1),
              icon: const Icon(Icons.chevron_right),
              tooltip: tr('한 옥타브 위'),
            ),
            const Spacer(),
            Text(tr('크기')),
            for (final n in [1, 2, 3])
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _ToggleButton(
                  label: tr('{0}옥타브', [n]),
                  selected: k.octaves == n,
                  onTap: () => k.setOctaves(n),
                ),
              ),
          ],
        ),
        // 건반은 높을수록 짚기 쉽다. 화면 높이의 3분의 1 정도를 준다.
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * 0.34).clamp(
            170.0,
            340.0,
          ),
          child: PianoKeyboard(controller: k),
        ),
      ],
    );
  }
}

/// 피아노 건반. 흰 건반을 깔고 검은 건반을 위에 얹는다.
///
/// 손가락을 건반 위로 미끄러뜨리면 지나가는 건반이 차례로 울린다(글리산도).
/// 건반마다 따로 받으면 처음 짚은 건반만 울리므로, 건반 전체에서 포인터를
/// 받아 지금 어느 건반 위인지 직접 셈한다. 손가락 여러 개도 각각 따라간다.
class PianoKeyboard extends StatefulWidget {
  const PianoKeyboard({super.key, required this.controller});

  final KeyboardController controller;

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  /// 포인터마다 지금 누르고 있는 건반.
  final _under = <int, int>{};

  // 마지막 배치. 포인터 자리를 건반으로 바꿀 때 쓴다.
  late List<int> _whites;
  late List<int> _blacks;
  double _whiteW = 1;
  double _blackW = 1;
  double _blackH = 1;

  static bool _isBlack(int midi) => const {1, 3, 6, 8, 10}.contains(midi % 12);

  /// 검은 건반의 중심 x. 같은 옥타브의 흰 건반 개수를 세어 자리를 잡는다.
  double _blackCenter(int midi) {
    var whitesBefore = 0;
    for (var m = widget.controller.lowest; m < midi; m++) {
      if (!_isBlack(m)) whitesBefore++;
    }
    // 바로 앞 흰 건반의 오른쪽 경계. 실제 피아노처럼 C♯/F♯는 살짝 왼쪽, D♯/A♯는 살짝 오른쪽.
    return whitesBefore * _whiteW + _tweak(midi) * _whiteW;
  }

  static double _tweak(int midi) => switch (midi % 12) {
    1 || 6 => -0.08,
    3 || 10 => 0.08,
    _ => 0,
  };

  /// 이 자리에 있는 건반. 검은 건반이 흰 건반 위에 있으니 먼저 본다.
  int? _keyAt(Offset p) {
    if (p.dy < 0 || p.dx < 0) return null;
    if (p.dy < _blackH) {
      for (final m in _blacks) {
        if ((p.dx - _blackCenter(m)).abs() <= _blackW / 2) return m;
      }
    }
    final i = (p.dx / _whiteW).floor();
    if (i < 0 || i >= _whites.length) return null;
    return _whites[i];
  }

  void _track(int pointer, Offset position) {
    final midi = _keyAt(position);
    final before = _under[pointer];
    if (midi == before) return;
    if (before != null) widget.controller.release(before);
    if (midi != null) {
      _under[pointer] = midi;
      widget.controller.press(midi);
    } else {
      _under.remove(pointer);
    }
  }

  void _lift(int pointer) {
    final midi = _under.remove(pointer);
    if (midi != null) widget.controller.release(midi);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final lowest = controller.lowest;
    final count = controller.octaves * 12 + 1;
    _whites = [
      for (var m = lowest; m < lowest + count; m++)
        if (!_isBlack(m)) m,
    ];
    _blacks = [
      for (var m = lowest; m < lowest + count; m++)
        if (_isBlack(m)) m,
    ];

    return LayoutBuilder(
      builder: (context, c) {
        _whiteW = c.maxWidth / _whites.length;
        _blackW = _whiteW * 0.62;
        _blackH = c.maxHeight * 0.6;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _track(e.pointer, e.localPosition),
          onPointerMove: (e) => _track(e.pointer, e.localPosition),
          onPointerUp: (e) => _lift(e.pointer),
          onPointerCancel: (e) => _lift(e.pointer),
          child: Stack(
            children: [
              Row(
                children: [
                  for (final m in _whites)
                    Expanded(
                      child: _Key(
                        black: false,
                        pressed: controller.pressed.contains(m),
                        label: m % 12 == 0 ? 'C${m ~/ 12 - 1}' : null,
                      ),
                    ),
                ],
              ),
              for (final m in _blacks)
                Positioned(
                  left: _blackCenter(m) - _blackW / 2,
                  top: 0,
                  width: _blackW,
                  height: _blackH,
                  child: _Key(
                    black: true,
                    pressed: controller.pressed.contains(m),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 건반 한 개의 모양. 입력은 건반 전체가 받는다.
class _Key extends StatelessWidget {
  const _Key({required this.black, required this.pressed, this.label});

  final bool black;
  final bool pressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final base = black ? const Color(0xFF222222) : Colors.white;
    final down = black ? const Color(0xFF555555) : const Color(0xFFDDE7F5);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: black ? 0 : 1),
      decoration: BoxDecoration(
        color: pressed ? down : base,
        border: Border.all(color: Colors.black54, width: 0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 6),
      child: label == null
          ? null
          : Text(
              label!,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
    );
  }
}

// ---------------------------------------------------------------- 튜너

class TunerPanel extends ConsumerStatefulWidget {
  const TunerPanel({super.key});

  @override
  ConsumerState<TunerPanel> createState() => _TunerPanelState();
}

class _TunerPanelState extends ConsumerState<TunerPanel> {
  /// dispose 에서는 ref 를 쓸 수 없어 미리 잡아 둔다.
  late final _tuner = ref.read(tunerProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tuner.start());
  }

  @override
  void dispose() {
    // 판을 닫으면 마이크를 놓는다. 기준음은 남겨 둔다.
    _tuner.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tunerProvider);
    final r = t.reading;
    final displayed = r == null
        ? null
        : PitchReading.fromFrequency(r.frequency, a4: t.a4);
    final transposed = displayed == null
        ? null
        : PitchReading(
            frequency: displayed.frequency,
            midi: displayed.midi + t.transpose,
            cents: displayed.cents,
          );
    final cents = transposed?.cents ?? 0;
    final inTune = transposed != null && cents.abs() < 5;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (t.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(t.error!, style: TextStyle(color: scheme.error)),
          ),

        // 바늘은 읽은 값으로 바로 튀지 않고 이전 자리에서 미끄러져 간다.
        // 음정 검출은 프레임마다 조금씩 흔들려서 그대로 그리면 떨린다.
        TweenAnimationBuilder<double>(
          tween: Tween(end: cents.clamp(-50.0, 50.0)),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => SizedBox(
            height: 132,
            child: CustomPaint(
              size: const Size(double.infinity, 132),
              painter: _TunerGaugePainter(
                cents: transposed == null ? null : value,
                color: inTune ? Colors.green : scheme.primary,
              ),
            ),
          ),
        ),
        Text(
          transposed?.label ?? '—',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: inTune ? Colors.green : null,
          ),
        ),
        Text(
          transposed == null
              ? tr('소리를 내 보세요')
              : '${transposed.frequency.toStringAsFixed(1)} Hz · ${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(0)}¢',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),

        // 조옮김 악기(B♭ 클라리넷 등)는 읽은 음을 그 악기 기준으로 보여 준다.
        Row(
          children: [
            Text(tr('조옮김'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: t.transpose,
              onChanged: (v) {
                if (v != null) t.setTranspose(v);
              },
              items: [
                for (final semi in [0, -2, -9, -7])
                  DropdownMenuItem(
                    value: semi,
                    child: Text(_transposeName(semi)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(tr('기준음'), style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final midi in [57, 60, 62, 64, 65, 67, 69, 71, 72])
              _ToggleButton(
                label: PitchReading.fromFrequency(
                  PitchReading.frequencyOf(midi),
                ).label,
                selected: t.pipeMidi == midi,
                onTap: () => t.togglePipe(midi),
              ),
          ],
        ),
      ],
    );
  }
}

String _transposeName(int semi) => switch (semi) {
  -2 => 'B♭',
  -9 => 'E♭',
  -7 => 'F',
  _ => 'C',
};

class _TunerGaugePainter extends CustomPainter {
  _TunerGaugePainter({required this.cents, required this.color});
  final double? cents;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseline = size.height - 20;
    final half = size.width * 0.42;
    final axis = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(cx - half, baseline),
      Offset(cx + half, baseline),
      axis,
    );
    for (var c = -50; c <= 50; c += 10) {
      final x = cx + c / 50 * half;
      final h = c == 0 ? 18.0 : (c % 25 == 0 ? 12.0 : 7.0);
      canvas.drawLine(Offset(x, baseline), Offset(x, baseline - h), axis);
    }
    final v = cents;
    if (v == null) return;
    final x = cx + (v.clamp(-50, 50) / 50) * half;
    final needle = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, baseline + 4), Offset(x, 10), needle);
  }

  @override
  bool shouldRepaint(_TunerGaugePainter old) =>
      old.cents != cents || old.color != color;
}

// ---------------------------------------------------------------- 녹음기

class RecorderPanel extends ConsumerWidget {
  const RecorderPanel({super.key, this.scoreId});

  final String? scoreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(recorderProvider)..contextScoreId = scoreId;
    final list = ref.watch(recordingsProvider).value ?? const <Recording>[];
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        children: [
          if (r.error != null)
            Text(r.error!, style: TextStyle(color: scheme.error)),
          Row(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: r.recording ? scheme.error : null,
                ),
                onPressed: r.recording ? r.stop : r.start,
                icon: Icon(
                  r.recording ? Icons.stop : Icons.fiber_manual_record,
                ),
                label: Text(
                  r.recording ? tr('정지 {0}', [_fmt(r.elapsed)]) : tr('녹음'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: r.recording ? r.amplitude : 0,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text(tr('녹음이 없습니다')))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final rec = list[i];
                      final playing = r.playingId == rec.id;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: IconButton.filledTonal(
                              onPressed: () => r.play(rec),
                              icon: Icon(
                                playing && !r.isPaused
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                            ),
                            title: Text(
                              rec.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _fmt(Duration(milliseconds: rec.durationMs)),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                switch (v) {
                                  case 'share':
                                    await SharePlus.instance.share(
                                      ShareParams(
                                        files: [XFile(r.fileOf(rec).path)],
                                        subject: rec.title,
                                      ),
                                    );
                                  case 'rename':
                                    final name = await _ask(context, rec.title);
                                    if (name != null) await r.rename(rec, name);
                                  case 'delete':
                                    await r.delete(rec);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'share',
                                  child: Text(tr('공유 / 내보내기')),
                                ),
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text(tr('이름 바꾸기')),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(tr('지우기')),
                                ),
                              ],
                            ),
                          ),
                          if (playing)
                            Slider(
                              value: r.playPosition.inMilliseconds
                                  .toDouble()
                                  .clamp(
                                    0.0,
                                    r.playLength.inMilliseconds
                                        .toDouble()
                                        .clamp(1.0, double.infinity),
                                  ),
                              max: r.playLength.inMilliseconds.toDouble().clamp(
                                1.0,
                                double.infinity,
                              ),
                              onChanged: (v) =>
                                  r.seek(Duration(milliseconds: v.round())),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<String?> _ask(BuildContext context, String initial) async {
    final c = TextEditingController(text: initial);
    final v = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('이름')),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('취소')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: Text(tr('확인')),
          ),
        ],
      ),
    );
    return v == null || v.isEmpty ? null : v;
  }

  static String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------- 플레이어

class PlayerPanel extends ConsumerWidget {
  const PlayerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(musicPlayerProvider);
    final length = p.length.inMilliseconds.toDouble();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        children: [
          if (p.current != null) ...[
            Text(
              p.current!.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Slider(
              value: p.position.inMilliseconds.toDouble().clamp(
                0,
                length < 1 ? 1 : length,
              ),
              max: length < 1 ? 1 : length,
              onChanged: (v) => p.seek(Duration(milliseconds: v.round())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () =>
                      p.seek(p.position - const Duration(seconds: 10)),
                  icon: const Icon(Icons.replay_10),
                ),
                IconButton.filled(
                  onPressed: p.togglePause,
                  icon: Icon(p.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  onPressed: () =>
                      p.seek(p.position + const Duration(seconds: 10)),
                  icon: const Icon(Icons.forward_10),
                ),
                IconButton(onPressed: p.stop, icon: const Icon(Icons.stop)),
                IconButton(
                  onPressed: () => p.setLoop(!p.loop),
                  isSelected: p.loop,
                  icon: const Icon(Icons.repeat),
                  tooltip: tr('반복'),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.volume_down, size: 18),
                Expanded(
                  child: Slider(value: p.volume, onChanged: p.setVolume),
                ),
              ],
            ),
            const Divider(),
          ],
          Row(
            children: [
              Text(tr('음원'), style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final n = await p.pickAndAdd();
                  if (context.mounted && n > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('{0}개를 추가했습니다', [n]))),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(tr('음원 추가')),
              ),
            ],
          ),
          Expanded(
            child: p.tracks.isEmpty
                ? Center(child: Text(tr('MP3, WAV, FLAC, OGG 파일을 추가하세요')))
                : ListView.builder(
                    itemCount: p.tracks.length,
                    itemBuilder: (context, i) {
                      final t = p.tracks[i];
                      final cur = p.current?.path == t.path;
                      return ListTile(
                        leading: Icon(
                          cur ? Icons.equalizer : Icons.audiotrack_outlined,
                        ),
                        title: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: cur,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => p.remove(t),
                        ),
                        onTap: () => p.play(t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
