import 'package:drift/drift.dart';

/// 페이지 넘김 레이아웃.
enum PageLayout { single, scroll, half, dual }

/// 페이지 넘김 애니메이션.
enum TurnAnimation { slide, scroll, stack, curl }

/// 필기 도구 종류.
enum StrokeTool { pen, marker, pencil, brush, shape, eraser }

/// 필기 데이터의 원본 형식. iOS 는 PencilKit 이 자체 포맷을 쓰므로 구분한다.
enum InkFormat { vector, pencilKit }

/// 악보 한 곡. PDF 파일 하나 또는 이미지 묶음 하나에 대응한다.
class Scores extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get composer => text().nullable()();
  TextColumn get genre => text().nullable()();

  /// 앱 문서 폴더 기준 상대 경로.
  TextColumn get filePath => text()();
  TextColumn get fileHash => text().nullable()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();

  /// 암호가 걸린 PDF 의 암호. 열람 편의를 위해 보관한다.
  TextColumn get pdfPassword => text().nullable()();

  /// 표지 이미지 상대 경로. 없으면 1페이지를 축소해 쓴다.
  TextColumn get coverPath => text().nullable()();

  /// 곡별 기본 보기 설정. 없으면 전역 설정을 따른다.
  IntColumn get layout => intEnum<PageLayout>().nullable()();
  IntColumn get turnAnimation => intEnum<TurnAnimation>().nullable()();

  /// 2페이지 보기에서 1페이지를 오른쪽에 둘지 여부.
  BoolColumn get startOnRight => boolean().withDefault(const Constant(false))();

  /// 전체 페이지 공통 여백 크롭 비율 (0.0 ~ 0.45).
  RealColumn get cropLeft => real().withDefault(const Constant(0))();
  RealColumn get cropTop => real().withDefault(const Constant(0))();
  RealColumn get cropRight => real().withDefault(const Constant(0))();
  RealColumn get cropBottom => real().withDefault(const Constant(0))();

  /// 자동 스크롤 1회 재생 시간(초). null 이면 전역 기본값.
  IntColumn get autoScrollSeconds => integer().nullable()();

  IntColumn get lastPage => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 페이지 단위 편집 정보. 원본 PDF 는 건드리지 않고 여기에만 기록한다.
class ScorePages extends Table {
  TextColumn get id => text()();
  TextColumn get scoreId =>
      text().references(Scores, #id, onDelete: KeyAction.cascade)();

  /// 원본 파일 안에서의 0-based 페이지 번호.
  IntColumn get sourceIndex => integer()();

  /// 사용자가 재배열한 뒤의 표시 순서.
  IntColumn get displayOrder => integer()();

  /// 숨긴 페이지는 뷰어와 내보내기에서 제외한다.
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  /// 페이지 단독 회전 각도(도 단위, 0/90/180/270 외 미세 보정 포함).
  RealColumn get rotation => real().withDefault(const Constant(0))();

  /// 페이지 단독 크롭. 곡 전체 크롭보다 우선한다.
  RealColumn get cropLeft => real().nullable()();
  RealColumn get cropTop => real().nullable()();
  RealColumn get cropRight => real().nullable()();
  RealColumn get cropBottom => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {scoreId, displayOrder},
      ];
}

/// 북마크. PDF 목차를 가져오면 여기에 채운다.
class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get scoreId =>
      text().references(Scores, #id, onDelete: KeyAction.cascade)();
  IntColumn get page => integer()();
  TextColumn get label => text()();

  /// 목차 계층. 최상위는 0.
  IntColumn get depth => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 반복 기호용 점프 버튼. 특정 페이지 위 좌표에 놓고 누르면 목적 페이지로 간다.
class JumpButtons extends Table {
  TextColumn get id => text()();
  TextColumn get scoreId =>
      text().references(Scores, #id, onDelete: KeyAction.cascade)();

  /// 버튼이 놓인 페이지와 그 페이지 안의 상대 좌표(0.0 ~ 1.0).
  IntColumn get fromPage => integer()();
  RealColumn get x => real()();
  RealColumn get y => real()();
  IntColumn get toPage => integer()();
  TextColumn get label => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 태그. 폴더 대용으로 쓰며 한 곡에 여러 개 붙는다.
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();
  IntColumn get color => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ScoreTags extends Table {
  TextColumn get scoreId =>
      text().references(Scores, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {scoreId, tagId};
}

/// 세트리스트. 태그와 달리 순서를 가진다.
class Setlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get performedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 세트리스트 항목. 곡 전체가 아니라 일부 페이지 구간만 넣을 수 있다.
class SetlistItems extends Table {
  TextColumn get id => text()();
  TextColumn get setlistId =>
      text().references(Setlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get scoreId =>
      text().references(Scores, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();

  /// null 이면 곡 전체. 값이 있으면 해당 페이지 구간만 이어 붙인다.
  IntColumn get startPage => integer().nullable()();
  IntColumn get endPage => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 필기 한 획 또는 한 개체(스탬프, 텍스트, 도형).
///
/// 원본 PDF 에 굽지 않고 여기에만 보관한다. 내보낼 때만 합성한다.
/// iOS 는 PencilKit 이 페이지 단위 PKDrawing 을 통째로 주므로
/// [format] 이 pencilKit 인 행은 페이지당 하나만 존재한다.
class InkStrokes extends Table {
  TextColumn get id => text()();
  TextColumn get scoreId =>
      text().references(Scores, #id, onDelete: KeyAction.cascade)();
  IntColumn get page => integer()();

  IntColumn get format => intEnum<InkFormat>()
      .withDefault(Constant(InkFormat.vector.index))();
  IntColumn get tool => intEnum<StrokeTool>()
      .withDefault(Constant(StrokeTool.pen.index))();

  IntColumn get color => integer().withDefault(const Constant(0xFF000000))();
  RealColumn get width => real().withDefault(const Constant(2))();

  /// 도구의 세부 종류. 펜이면 프리셋 이름, 도형이면 도형 이름.
  TextColumn get subtype => text().nullable()();

  /// vector: 점 배열(x, y, 압력)을 원본 페이지 기준 0~1 비율로 직렬화한 바이트.
  /// pencilKit: PKDrawing 의 dataRepresentation 바이트 그대로.
  BlobColumn get data => blob()();

  /// 실행 취소 순서와 그리기 순서를 함께 결정한다.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 스탬프, 텍스트 같은 배치형 주석. 획과 달리 좌표와 내용이 따로 있다.
class Annotations extends Table {
  TextColumn get id => text()();
  TextColumn get scoreId =>
      text().references(Scores, #id, onDelete: KeyAction.cascade)();
  IntColumn get page => integer()();

  /// 'stamp' | 'text'
  TextColumn get kind => text()();

  /// 스탬프 식별자 또는 텍스트 내용.
  TextColumn get value => text()();

  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get scale => real().withDefault(const Constant(1))();
  RealColumn get rotation => real().withDefault(const Constant(0))();
  IntColumn get color => integer().withDefault(const Constant(0xFF000000))();
  RealColumn get fontSize => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 녹음 파일.
class Recordings extends Table {
  TextColumn get id => text()();
  TextColumn get scoreId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get filePath => text()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 키-값 전역 설정.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
