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
    StampDef('dsharp', '더블샤프', glyph: '𝄪'),
    StampDef('dflat', '더블플랫', glyph: '𝄫'),
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
    StampDef('rest', '쉼표', glyph: '𝄽'),
  ]),
  StampGroup('구조', [
    StampDef('segno', '세뇨', glyph: '𝄋'),
    StampDef('coda', '코다', glyph: '𝄌'),
    StampDef('ds', 'D.S.', glyph: 'D.S.'),
    StampDef('dc', 'D.C.', glyph: 'D.C.'),
    StampDef('fine', 'Fine', glyph: 'Fine', italic: true),
    StampDef('repeat', '반복', glyph: '𝄆𝄇'),
    StampDef('check', '체크', glyph: '✓'),
    StampDef('star', '별', glyph: '★'),
    StampDef('circle', '동그라미'),
    StampDef('x', '엑스', glyph: '✕'),
    StampDef('eye', '주의', glyph: '👓'),
    StampDef('breathe', '호흡', glyph: '∨'),
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
