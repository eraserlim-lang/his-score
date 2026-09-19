/// 스탬프 한 종.
///
/// [glyph] 가 있으면 글자로 그리고, 없으면 [StampPainter] 가 직접 그린다.
/// 폰트에 따라 안 나오는 기호가 있어 자주 쓰는 것은 손으로 그린다.
class StampDef {
  const StampDef(this.id, this.label, {this.glyph, this.italic = false});

  final String id;
  final String label;
  final String? glyph;
  final bool italic;
}

class StampGroup {
  const StampGroup(this.title, this.stamps);
  final String title;
  final List<StampDef> stamps;
}

/// 악보에서 자주 쓰는 기호 전부. 유료 구분 없이 전부 연다.
const stampGroups = <StampGroup>[
  StampGroup('운지', [
    StampDef('f1', '1', glyph: '1'),
    StampDef('f2', '2', glyph: '2'),
    StampDef('f3', '3', glyph: '3'),
    StampDef('f4', '4', glyph: '4'),
    StampDef('f5', '5', glyph: '5'),
    StampDef('f0', '0', glyph: '0'),
    StampDef('thumb', '엄지', glyph: 'p'),
    StampDef('idx', '검지', glyph: 'i'),
    StampDef('mid', '중지', glyph: 'm'),
    StampDef('ring', '약지', glyph: 'a'),
  ]),
  StampGroup('셈여림', [
    StampDef('ppp', 'ppp', glyph: 'ppp', italic: true),
    StampDef('pp', 'pp', glyph: 'pp', italic: true),
    StampDef('p', 'p', glyph: 'p', italic: true),
    StampDef('mp', 'mp', glyph: 'mp', italic: true),
    StampDef('mf', 'mf', glyph: 'mf', italic: true),
    StampDef('f', 'f', glyph: 'f', italic: true),
    StampDef('ff', 'ff', glyph: 'ff', italic: true),
    StampDef('fff', 'fff', glyph: 'fff', italic: true),
    StampDef('sfz', 'sfz', glyph: 'sfz', italic: true),
    StampDef('fp', 'fp', glyph: 'fp', italic: true),
    StampDef('cresc', 'cresc.', glyph: 'cresc.', italic: true),
    StampDef('dim', 'dim.', glyph: 'dim.', italic: true),
  ]),
  StampGroup('임시표', [
    StampDef('sharp', '샤프', glyph: '♯'),
    StampDef('flat', '플랫', glyph: '♭'),
    StampDef('natural', '내추럴', glyph: '♮'),
    // 𝄪 𝄫 는 대부분의 시스템 폰트에 없어 ? 로 나왔다. 하나는 직접 그리고
    // 하나는 있는 글자를 겹쳐 쓴다.
    StampDef('dsharp', '더블샤프'),
    StampDef('dflat', '더블플랫', glyph: '♭♭'),
  ]),
  StampGroup('아티큘레이션', [
    StampDef('accent', '악센트'),
    StampDef('staccato', '스타카토'),
    StampDef('tenuto', '테누토'),
    StampDef('marcato', '마르카토'),
    StampDef('fermata', '페르마타'),
    StampDef('breath', '숨표'),
    StampDef('caesura', '체주라'),
    StampDef('trill', '트릴', glyph: 'tr'),
    StampDef('mordent', '모르덴트'),
    StampDef('turn', '턴'),
  ]),
  StampGroup('활·페달', [
    StampDef('downbow', '내림활'),
    StampDef('upbow', '올림활'),
    StampDef('pedal', '페달', glyph: 'Ped.', italic: true),
    StampDef('pedalup', '페달 떼기', glyph: '✱'),
  ]),
  StampGroup('음표', [
    StampDef('whole', '온음표'),
    StampDef('half', '2분음표'),
    StampDef('quarter', '4분음표', glyph: '♩'),
    StampDef('eighth', '8분음표', glyph: '♪'),
    StampDef('beamed', '8분음표 둘', glyph: '♫'),
    StampDef('rest', '쉼표'),
  ]),
  StampGroup('구조', [
    // 𝄋 𝄌 𝄆𝄇 도 폰트에 없어 직접 그린다.
    StampDef('segno', '세뇨'),
    StampDef('coda', '코다'),
    StampDef('ds', 'D.S.', glyph: 'D.S.'),
    StampDef('dc', 'D.C.', glyph: 'D.C.'),
    StampDef('fine', 'Fine', glyph: 'Fine', italic: true),
    StampDef('repeat', '반복'),
    StampDef('check', '체크', glyph: '✓'),
    StampDef('star', '별', glyph: '★'),
    StampDef('circle', '동그라미'),
    StampDef('x', '엑스', glyph: '✕'),
    // 👓 는 이모지라 악보 위에서 혼자 튀었다. 안경을 직접 그린다.
    StampDef('eye', '주의'),
    StampDef('breathe', '호흡', glyph: '∨'),
  ]),
  // 대중음악 악보에 적는 곡 구성 표시. 반복 구간을 부를 이름이 있어야
  // 연습할 때 "브릿지부터" 같은 말이 통한다.
  StampGroup('송폼', [
    StampDef('intro', 'Intro', glyph: 'Intro'),
    StampDef('verse', 'Verse', glyph: 'Verse'),
    StampDef('prechorus', 'Pre', glyph: 'Pre'),
    StampDef('chorus', 'Chorus', glyph: 'Chorus'),
    StampDef('hook', 'Hook', glyph: 'Hook'),
    StampDef('bridge', 'Bridge', glyph: 'Bridge'),
    StampDef('interlude', '간주', glyph: 'Inter.'),
    StampDef('solo', 'Solo', glyph: 'Solo'),
    StampDef('outro', 'Outro', glyph: 'Outro'),
    StampDef('ending', 'Ending', glyph: 'Ending'),
    StampDef('tag', 'Tag', glyph: 'Tag'),
    StampDef('vamp', 'Vamp', glyph: 'Vamp'),
    StampDef('secA', 'A 파트', glyph: 'A'),
    StampDef('secB', 'B 파트', glyph: 'B'),
    StampDef('secC', 'C 파트', glyph: 'C'),
    StampDef('first', '1번 괄호', glyph: '1.'),
    StampDef('second', '2번 괄호', glyph: '2.'),
  ]),
];

StampDef? findStamp(String id) {
  for (final g in stampGroups) {
    for (final s in g.stamps) {
      if (s.id == id) return s;
    }
  }
  return null;
}
