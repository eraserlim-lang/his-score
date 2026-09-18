// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ScoresTable extends Scores with TableInfo<$ScoresTable, Score> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _composerMeta = const VerificationMeta(
    'composer',
  );
  @override
  late final GeneratedColumn<String> composer = GeneratedColumn<String>(
    'composer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pdfPasswordMeta = const VerificationMeta(
    'pdfPassword',
  );
  @override
  late final GeneratedColumn<String> pdfPassword = GeneratedColumn<String>(
    'pdf_password',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PageLayout?, int> layout =
      GeneratedColumn<int>(
        'layout',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<PageLayout?>($ScoresTable.$converterlayoutn);
  @override
  late final GeneratedColumnWithTypeConverter<TurnAnimation?, int>
  turnAnimation = GeneratedColumn<int>(
    'turn_animation',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<TurnAnimation?>($ScoresTable.$converterturnAnimationn);
  static const VerificationMeta _startOnRightMeta = const VerificationMeta(
    'startOnRight',
  );
  @override
  late final GeneratedColumn<bool> startOnRight = GeneratedColumn<bool>(
    'start_on_right',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("start_on_right" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cropLeftMeta = const VerificationMeta(
    'cropLeft',
  );
  @override
  late final GeneratedColumn<double> cropLeft = GeneratedColumn<double>(
    'crop_left',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cropTopMeta = const VerificationMeta(
    'cropTop',
  );
  @override
  late final GeneratedColumn<double> cropTop = GeneratedColumn<double>(
    'crop_top',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cropRightMeta = const VerificationMeta(
    'cropRight',
  );
  @override
  late final GeneratedColumn<double> cropRight = GeneratedColumn<double>(
    'crop_right',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cropBottomMeta = const VerificationMeta(
    'cropBottom',
  );
  @override
  late final GeneratedColumn<double> cropBottom = GeneratedColumn<double>(
    'crop_bottom',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _autoScrollSecondsMeta = const VerificationMeta(
    'autoScrollSeconds',
  );
  @override
  late final GeneratedColumn<int> autoScrollSeconds = GeneratedColumn<int>(
    'auto_scroll_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPageMeta = const VerificationMeta(
    'lastPage',
  );
  @override
  late final GeneratedColumn<int> lastPage = GeneratedColumn<int>(
    'last_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artist,
    composer,
    genre,
    filePath,
    fileHash,
    fileSize,
    pageCount,
    pdfPassword,
    coverPath,
    layout,
    turnAnimation,
    startOnRight,
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
    autoScrollSeconds,
    lastPage,
    lastOpenedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<Score> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('composer')) {
      context.handle(
        _composerMeta,
        composer.isAcceptableOrUnknown(data['composer']!, _composerMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('pdf_password')) {
      context.handle(
        _pdfPasswordMeta,
        pdfPassword.isAcceptableOrUnknown(
          data['pdf_password']!,
          _pdfPasswordMeta,
        ),
      );
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('start_on_right')) {
      context.handle(
        _startOnRightMeta,
        startOnRight.isAcceptableOrUnknown(
          data['start_on_right']!,
          _startOnRightMeta,
        ),
      );
    }
    if (data.containsKey('crop_left')) {
      context.handle(
        _cropLeftMeta,
        cropLeft.isAcceptableOrUnknown(data['crop_left']!, _cropLeftMeta),
      );
    }
    if (data.containsKey('crop_top')) {
      context.handle(
        _cropTopMeta,
        cropTop.isAcceptableOrUnknown(data['crop_top']!, _cropTopMeta),
      );
    }
    if (data.containsKey('crop_right')) {
      context.handle(
        _cropRightMeta,
        cropRight.isAcceptableOrUnknown(data['crop_right']!, _cropRightMeta),
      );
    }
    if (data.containsKey('crop_bottom')) {
      context.handle(
        _cropBottomMeta,
        cropBottom.isAcceptableOrUnknown(data['crop_bottom']!, _cropBottomMeta),
      );
    }
    if (data.containsKey('auto_scroll_seconds')) {
      context.handle(
        _autoScrollSecondsMeta,
        autoScrollSeconds.isAcceptableOrUnknown(
          data['auto_scroll_seconds']!,
          _autoScrollSecondsMeta,
        ),
      );
    }
    if (data.containsKey('last_page')) {
      context.handle(
        _lastPageMeta,
        lastPage.isAcceptableOrUnknown(data['last_page']!, _lastPageMeta),
      );
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Score map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Score(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      composer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composer'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      pdfPassword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_password'],
      ),
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      layout: $ScoresTable.$converterlayoutn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}layout'],
        ),
      ),
      turnAnimation: $ScoresTable.$converterturnAnimationn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}turn_animation'],
        ),
      ),
      startOnRight: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}start_on_right'],
      )!,
      cropLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_left'],
      )!,
      cropTop: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_top'],
      )!,
      cropRight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_right'],
      )!,
      cropBottom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_bottom'],
      )!,
      autoScrollSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_scroll_seconds'],
      ),
      lastPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_page'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ScoresTable createAlias(String alias) {
    return $ScoresTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PageLayout, int, int> $converterlayout =
      const EnumIndexConverter<PageLayout>(PageLayout.values);
  static JsonTypeConverter2<PageLayout?, int?, int?> $converterlayoutn =
      JsonTypeConverter2.asNullable($converterlayout);
  static JsonTypeConverter2<TurnAnimation, int, int> $converterturnAnimation =
      const EnumIndexConverter<TurnAnimation>(TurnAnimation.values);
  static JsonTypeConverter2<TurnAnimation?, int?, int?>
  $converterturnAnimationn = JsonTypeConverter2.asNullable(
    $converterturnAnimation,
  );
}

class Score extends DataClass implements Insertable<Score> {
  final String id;
  final String title;
  final String? artist;
  final String? composer;
  final String? genre;

  /// 앱 문서 폴더 기준 상대 경로.
  final String filePath;
  final String? fileHash;
  final int fileSize;
  final int pageCount;

  /// 암호가 걸린 PDF 의 암호. 열람 편의를 위해 보관한다.
  final String? pdfPassword;

  /// 표지 이미지 상대 경로. 없으면 1페이지를 축소해 쓴다.
  final String? coverPath;

  /// 곡별 기본 보기 설정. 없으면 전역 설정을 따른다.
  final PageLayout? layout;
  final TurnAnimation? turnAnimation;

  /// 2페이지 보기에서 1페이지를 오른쪽에 둘지 여부.
  final bool startOnRight;

  /// 전체 페이지 공통 여백 크롭 비율 (0.0 ~ 0.45).
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  /// 자동 스크롤 1회 재생 시간(초). null 이면 전역 기본값.
  final int? autoScrollSeconds;
  final int lastPage;
  final DateTime? lastOpenedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Score({
    required this.id,
    required this.title,
    this.artist,
    this.composer,
    this.genre,
    required this.filePath,
    this.fileHash,
    required this.fileSize,
    required this.pageCount,
    this.pdfPassword,
    this.coverPath,
    this.layout,
    this.turnAnimation,
    required this.startOnRight,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    this.autoScrollSeconds,
    required this.lastPage,
    this.lastOpenedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || composer != null) {
      map['composer'] = Variable<String>(composer);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || fileHash != null) {
      map['file_hash'] = Variable<String>(fileHash);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['page_count'] = Variable<int>(pageCount);
    if (!nullToAbsent || pdfPassword != null) {
      map['pdf_password'] = Variable<String>(pdfPassword);
    }
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || layout != null) {
      map['layout'] = Variable<int>(
        $ScoresTable.$converterlayoutn.toSql(layout),
      );
    }
    if (!nullToAbsent || turnAnimation != null) {
      map['turn_animation'] = Variable<int>(
        $ScoresTable.$converterturnAnimationn.toSql(turnAnimation),
      );
    }
    map['start_on_right'] = Variable<bool>(startOnRight);
    map['crop_left'] = Variable<double>(cropLeft);
    map['crop_top'] = Variable<double>(cropTop);
    map['crop_right'] = Variable<double>(cropRight);
    map['crop_bottom'] = Variable<double>(cropBottom);
    if (!nullToAbsent || autoScrollSeconds != null) {
      map['auto_scroll_seconds'] = Variable<int>(autoScrollSeconds);
    }
    map['last_page'] = Variable<int>(lastPage);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScoresCompanion toCompanion(bool nullToAbsent) {
    return ScoresCompanion(
      id: Value(id),
      title: Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      composer: composer == null && nullToAbsent
          ? const Value.absent()
          : Value(composer),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      filePath: Value(filePath),
      fileHash: fileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fileHash),
      fileSize: Value(fileSize),
      pageCount: Value(pageCount),
      pdfPassword: pdfPassword == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPassword),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      layout: layout == null && nullToAbsent
          ? const Value.absent()
          : Value(layout),
      turnAnimation: turnAnimation == null && nullToAbsent
          ? const Value.absent()
          : Value(turnAnimation),
      startOnRight: Value(startOnRight),
      cropLeft: Value(cropLeft),
      cropTop: Value(cropTop),
      cropRight: Value(cropRight),
      cropBottom: Value(cropBottom),
      autoScrollSeconds: autoScrollSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(autoScrollSeconds),
      lastPage: Value(lastPage),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Score.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Score(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      composer: serializer.fromJson<String?>(json['composer']),
      genre: serializer.fromJson<String?>(json['genre']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileHash: serializer.fromJson<String?>(json['fileHash']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      pdfPassword: serializer.fromJson<String?>(json['pdfPassword']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      layout: $ScoresTable.$converterlayoutn.fromJson(
        serializer.fromJson<int?>(json['layout']),
      ),
      turnAnimation: $ScoresTable.$converterturnAnimationn.fromJson(
        serializer.fromJson<int?>(json['turnAnimation']),
      ),
      startOnRight: serializer.fromJson<bool>(json['startOnRight']),
      cropLeft: serializer.fromJson<double>(json['cropLeft']),
      cropTop: serializer.fromJson<double>(json['cropTop']),
      cropRight: serializer.fromJson<double>(json['cropRight']),
      cropBottom: serializer.fromJson<double>(json['cropBottom']),
      autoScrollSeconds: serializer.fromJson<int?>(json['autoScrollSeconds']),
      lastPage: serializer.fromJson<int>(json['lastPage']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'composer': serializer.toJson<String?>(composer),
      'genre': serializer.toJson<String?>(genre),
      'filePath': serializer.toJson<String>(filePath),
      'fileHash': serializer.toJson<String?>(fileHash),
      'fileSize': serializer.toJson<int>(fileSize),
      'pageCount': serializer.toJson<int>(pageCount),
      'pdfPassword': serializer.toJson<String?>(pdfPassword),
      'coverPath': serializer.toJson<String?>(coverPath),
      'layout': serializer.toJson<int?>(
        $ScoresTable.$converterlayoutn.toJson(layout),
      ),
      'turnAnimation': serializer.toJson<int?>(
        $ScoresTable.$converterturnAnimationn.toJson(turnAnimation),
      ),
      'startOnRight': serializer.toJson<bool>(startOnRight),
      'cropLeft': serializer.toJson<double>(cropLeft),
      'cropTop': serializer.toJson<double>(cropTop),
      'cropRight': serializer.toJson<double>(cropRight),
      'cropBottom': serializer.toJson<double>(cropBottom),
      'autoScrollSeconds': serializer.toJson<int?>(autoScrollSeconds),
      'lastPage': serializer.toJson<int>(lastPage),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Score copyWith({
    String? id,
    String? title,
    Value<String?> artist = const Value.absent(),
    Value<String?> composer = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    String? filePath,
    Value<String?> fileHash = const Value.absent(),
    int? fileSize,
    int? pageCount,
    Value<String?> pdfPassword = const Value.absent(),
    Value<String?> coverPath = const Value.absent(),
    Value<PageLayout?> layout = const Value.absent(),
    Value<TurnAnimation?> turnAnimation = const Value.absent(),
    bool? startOnRight,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
    Value<int?> autoScrollSeconds = const Value.absent(),
    int? lastPage,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Score(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist.present ? artist.value : this.artist,
    composer: composer.present ? composer.value : this.composer,
    genre: genre.present ? genre.value : this.genre,
    filePath: filePath ?? this.filePath,
    fileHash: fileHash.present ? fileHash.value : this.fileHash,
    fileSize: fileSize ?? this.fileSize,
    pageCount: pageCount ?? this.pageCount,
    pdfPassword: pdfPassword.present ? pdfPassword.value : this.pdfPassword,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    layout: layout.present ? layout.value : this.layout,
    turnAnimation: turnAnimation.present
        ? turnAnimation.value
        : this.turnAnimation,
    startOnRight: startOnRight ?? this.startOnRight,
    cropLeft: cropLeft ?? this.cropLeft,
    cropTop: cropTop ?? this.cropTop,
    cropRight: cropRight ?? this.cropRight,
    cropBottom: cropBottom ?? this.cropBottom,
    autoScrollSeconds: autoScrollSeconds.present
        ? autoScrollSeconds.value
        : this.autoScrollSeconds,
    lastPage: lastPage ?? this.lastPage,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Score copyWithCompanion(ScoresCompanion data) {
    return Score(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      composer: data.composer.present ? data.composer.value : this.composer,
      genre: data.genre.present ? data.genre.value : this.genre,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      pdfPassword: data.pdfPassword.present
          ? data.pdfPassword.value
          : this.pdfPassword,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      layout: data.layout.present ? data.layout.value : this.layout,
      turnAnimation: data.turnAnimation.present
          ? data.turnAnimation.value
          : this.turnAnimation,
      startOnRight: data.startOnRight.present
          ? data.startOnRight.value
          : this.startOnRight,
      cropLeft: data.cropLeft.present ? data.cropLeft.value : this.cropLeft,
      cropTop: data.cropTop.present ? data.cropTop.value : this.cropTop,
      cropRight: data.cropRight.present ? data.cropRight.value : this.cropRight,
      cropBottom: data.cropBottom.present
          ? data.cropBottom.value
          : this.cropBottom,
      autoScrollSeconds: data.autoScrollSeconds.present
          ? data.autoScrollSeconds.value
          : this.autoScrollSeconds,
      lastPage: data.lastPage.present ? data.lastPage.value : this.lastPage,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Score(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('composer: $composer, ')
          ..write('genre: $genre, ')
          ..write('filePath: $filePath, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('pageCount: $pageCount, ')
          ..write('pdfPassword: $pdfPassword, ')
          ..write('coverPath: $coverPath, ')
          ..write('layout: $layout, ')
          ..write('turnAnimation: $turnAnimation, ')
          ..write('startOnRight: $startOnRight, ')
          ..write('cropLeft: $cropLeft, ')
          ..write('cropTop: $cropTop, ')
          ..write('cropRight: $cropRight, ')
          ..write('cropBottom: $cropBottom, ')
          ..write('autoScrollSeconds: $autoScrollSeconds, ')
          ..write('lastPage: $lastPage, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    artist,
    composer,
    genre,
    filePath,
    fileHash,
    fileSize,
    pageCount,
    pdfPassword,
    coverPath,
    layout,
    turnAnimation,
    startOnRight,
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
    autoScrollSeconds,
    lastPage,
    lastOpenedAt,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Score &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.composer == this.composer &&
          other.genre == this.genre &&
          other.filePath == this.filePath &&
          other.fileHash == this.fileHash &&
          other.fileSize == this.fileSize &&
          other.pageCount == this.pageCount &&
          other.pdfPassword == this.pdfPassword &&
          other.coverPath == this.coverPath &&
          other.layout == this.layout &&
          other.turnAnimation == this.turnAnimation &&
          other.startOnRight == this.startOnRight &&
          other.cropLeft == this.cropLeft &&
          other.cropTop == this.cropTop &&
          other.cropRight == this.cropRight &&
          other.cropBottom == this.cropBottom &&
          other.autoScrollSeconds == this.autoScrollSeconds &&
          other.lastPage == this.lastPage &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScoresCompanion extends UpdateCompanion<Score> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> artist;
  final Value<String?> composer;
  final Value<String?> genre;
  final Value<String> filePath;
  final Value<String?> fileHash;
  final Value<int> fileSize;
  final Value<int> pageCount;
  final Value<String?> pdfPassword;
  final Value<String?> coverPath;
  final Value<PageLayout?> layout;
  final Value<TurnAnimation?> turnAnimation;
  final Value<bool> startOnRight;
  final Value<double> cropLeft;
  final Value<double> cropTop;
  final Value<double> cropRight;
  final Value<double> cropBottom;
  final Value<int?> autoScrollSeconds;
  final Value<int> lastPage;
  final Value<DateTime?> lastOpenedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ScoresCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.composer = const Value.absent(),
    this.genre = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.pdfPassword = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.layout = const Value.absent(),
    this.turnAnimation = const Value.absent(),
    this.startOnRight = const Value.absent(),
    this.cropLeft = const Value.absent(),
    this.cropTop = const Value.absent(),
    this.cropRight = const Value.absent(),
    this.cropBottom = const Value.absent(),
    this.autoScrollSeconds = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoresCompanion.insert({
    required String id,
    required String title,
    this.artist = const Value.absent(),
    this.composer = const Value.absent(),
    this.genre = const Value.absent(),
    required String filePath,
    this.fileHash = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.pdfPassword = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.layout = const Value.absent(),
    this.turnAnimation = const Value.absent(),
    this.startOnRight = const Value.absent(),
    this.cropLeft = const Value.absent(),
    this.cropTop = const Value.absent(),
    this.cropRight = const Value.absent(),
    this.cropBottom = const Value.absent(),
    this.autoScrollSeconds = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       filePath = Value(filePath);
  static Insertable<Score> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? composer,
    Expression<String>? genre,
    Expression<String>? filePath,
    Expression<String>? fileHash,
    Expression<int>? fileSize,
    Expression<int>? pageCount,
    Expression<String>? pdfPassword,
    Expression<String>? coverPath,
    Expression<int>? layout,
    Expression<int>? turnAnimation,
    Expression<bool>? startOnRight,
    Expression<double>? cropLeft,
    Expression<double>? cropTop,
    Expression<double>? cropRight,
    Expression<double>? cropBottom,
    Expression<int>? autoScrollSeconds,
    Expression<int>? lastPage,
    Expression<DateTime>? lastOpenedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (composer != null) 'composer': composer,
      if (genre != null) 'genre': genre,
      if (filePath != null) 'file_path': filePath,
      if (fileHash != null) 'file_hash': fileHash,
      if (fileSize != null) 'file_size': fileSize,
      if (pageCount != null) 'page_count': pageCount,
      if (pdfPassword != null) 'pdf_password': pdfPassword,
      if (coverPath != null) 'cover_path': coverPath,
      if (layout != null) 'layout': layout,
      if (turnAnimation != null) 'turn_animation': turnAnimation,
      if (startOnRight != null) 'start_on_right': startOnRight,
      if (cropLeft != null) 'crop_left': cropLeft,
      if (cropTop != null) 'crop_top': cropTop,
      if (cropRight != null) 'crop_right': cropRight,
      if (cropBottom != null) 'crop_bottom': cropBottom,
      if (autoScrollSeconds != null) 'auto_scroll_seconds': autoScrollSeconds,
      if (lastPage != null) 'last_page': lastPage,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoresCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? artist,
    Value<String?>? composer,
    Value<String?>? genre,
    Value<String>? filePath,
    Value<String?>? fileHash,
    Value<int>? fileSize,
    Value<int>? pageCount,
    Value<String?>? pdfPassword,
    Value<String?>? coverPath,
    Value<PageLayout?>? layout,
    Value<TurnAnimation?>? turnAnimation,
    Value<bool>? startOnRight,
    Value<double>? cropLeft,
    Value<double>? cropTop,
    Value<double>? cropRight,
    Value<double>? cropBottom,
    Value<int?>? autoScrollSeconds,
    Value<int>? lastPage,
    Value<DateTime?>? lastOpenedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ScoresCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      composer: composer ?? this.composer,
      genre: genre ?? this.genre,
      filePath: filePath ?? this.filePath,
      fileHash: fileHash ?? this.fileHash,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      pdfPassword: pdfPassword ?? this.pdfPassword,
      coverPath: coverPath ?? this.coverPath,
      layout: layout ?? this.layout,
      turnAnimation: turnAnimation ?? this.turnAnimation,
      startOnRight: startOnRight ?? this.startOnRight,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      autoScrollSeconds: autoScrollSeconds ?? this.autoScrollSeconds,
      lastPage: lastPage ?? this.lastPage,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (composer.present) {
      map['composer'] = Variable<String>(composer.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (pdfPassword.present) {
      map['pdf_password'] = Variable<String>(pdfPassword.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (layout.present) {
      map['layout'] = Variable<int>(
        $ScoresTable.$converterlayoutn.toSql(layout.value),
      );
    }
    if (turnAnimation.present) {
      map['turn_animation'] = Variable<int>(
        $ScoresTable.$converterturnAnimationn.toSql(turnAnimation.value),
      );
    }
    if (startOnRight.present) {
      map['start_on_right'] = Variable<bool>(startOnRight.value);
    }
    if (cropLeft.present) {
      map['crop_left'] = Variable<double>(cropLeft.value);
    }
    if (cropTop.present) {
      map['crop_top'] = Variable<double>(cropTop.value);
    }
    if (cropRight.present) {
      map['crop_right'] = Variable<double>(cropRight.value);
    }
    if (cropBottom.present) {
      map['crop_bottom'] = Variable<double>(cropBottom.value);
    }
    if (autoScrollSeconds.present) {
      map['auto_scroll_seconds'] = Variable<int>(autoScrollSeconds.value);
    }
    if (lastPage.present) {
      map['last_page'] = Variable<int>(lastPage.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoresCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('composer: $composer, ')
          ..write('genre: $genre, ')
          ..write('filePath: $filePath, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('pageCount: $pageCount, ')
          ..write('pdfPassword: $pdfPassword, ')
          ..write('coverPath: $coverPath, ')
          ..write('layout: $layout, ')
          ..write('turnAnimation: $turnAnimation, ')
          ..write('startOnRight: $startOnRight, ')
          ..write('cropLeft: $cropLeft, ')
          ..write('cropTop: $cropTop, ')
          ..write('cropRight: $cropRight, ')
          ..write('cropBottom: $cropBottom, ')
          ..write('autoScrollSeconds: $autoScrollSeconds, ')
          ..write('lastPage: $lastPage, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScorePagesTable extends ScorePages
    with TableInfo<$ScorePagesTable, ScorePage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScorePagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceIndexMeta = const VerificationMeta(
    'sourceIndex',
  );
  @override
  late final GeneratedColumn<int> sourceIndex = GeneratedColumn<int>(
    'source_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cropLeftMeta = const VerificationMeta(
    'cropLeft',
  );
  @override
  late final GeneratedColumn<double> cropLeft = GeneratedColumn<double>(
    'crop_left',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropTopMeta = const VerificationMeta(
    'cropTop',
  );
  @override
  late final GeneratedColumn<double> cropTop = GeneratedColumn<double>(
    'crop_top',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropRightMeta = const VerificationMeta(
    'cropRight',
  );
  @override
  late final GeneratedColumn<double> cropRight = GeneratedColumn<double>(
    'crop_right',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropBottomMeta = const VerificationMeta(
    'cropBottom',
  );
  @override
  late final GeneratedColumn<double> cropBottom = GeneratedColumn<double>(
    'crop_bottom',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scoreId,
    sourceIndex,
    displayOrder,
    hidden,
    rotation,
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'score_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScorePage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('source_index')) {
      context.handle(
        _sourceIndexMeta,
        sourceIndex.isAcceptableOrUnknown(
          data['source_index']!,
          _sourceIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceIndexMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('crop_left')) {
      context.handle(
        _cropLeftMeta,
        cropLeft.isAcceptableOrUnknown(data['crop_left']!, _cropLeftMeta),
      );
    }
    if (data.containsKey('crop_top')) {
      context.handle(
        _cropTopMeta,
        cropTop.isAcceptableOrUnknown(data['crop_top']!, _cropTopMeta),
      );
    }
    if (data.containsKey('crop_right')) {
      context.handle(
        _cropRightMeta,
        cropRight.isAcceptableOrUnknown(data['crop_right']!, _cropRightMeta),
      );
    }
    if (data.containsKey('crop_bottom')) {
      context.handle(
        _cropBottomMeta,
        cropBottom.isAcceptableOrUnknown(data['crop_bottom']!, _cropBottomMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {scoreId, displayOrder},
  ];
  @override
  ScorePage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScorePage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      sourceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_index'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
      cropLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_left'],
      ),
      cropTop: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_top'],
      ),
      cropRight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_right'],
      ),
      cropBottom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}crop_bottom'],
      ),
    );
  }

  @override
  $ScorePagesTable createAlias(String alias) {
    return $ScorePagesTable(attachedDatabase, alias);
  }
}

class ScorePage extends DataClass implements Insertable<ScorePage> {
  final String id;
  final String scoreId;

  /// 원본 파일 안에서의 0-based 페이지 번호.
  final int sourceIndex;

  /// 사용자가 재배열한 뒤의 표시 순서.
  final int displayOrder;

  /// 숨긴 페이지는 뷰어와 내보내기에서 제외한다.
  final bool hidden;

  /// 페이지 단독 회전 각도(도 단위, 0/90/180/270 외 미세 보정 포함).
  final double rotation;

  /// 페이지 단독 크롭. 곡 전체 크롭보다 우선한다.
  final double? cropLeft;
  final double? cropTop;
  final double? cropRight;
  final double? cropBottom;
  const ScorePage({
    required this.id,
    required this.scoreId,
    required this.sourceIndex,
    required this.displayOrder,
    required this.hidden,
    required this.rotation,
    this.cropLeft,
    this.cropTop,
    this.cropRight,
    this.cropBottom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['score_id'] = Variable<String>(scoreId);
    map['source_index'] = Variable<int>(sourceIndex);
    map['display_order'] = Variable<int>(displayOrder);
    map['hidden'] = Variable<bool>(hidden);
    map['rotation'] = Variable<double>(rotation);
    if (!nullToAbsent || cropLeft != null) {
      map['crop_left'] = Variable<double>(cropLeft);
    }
    if (!nullToAbsent || cropTop != null) {
      map['crop_top'] = Variable<double>(cropTop);
    }
    if (!nullToAbsent || cropRight != null) {
      map['crop_right'] = Variable<double>(cropRight);
    }
    if (!nullToAbsent || cropBottom != null) {
      map['crop_bottom'] = Variable<double>(cropBottom);
    }
    return map;
  }

  ScorePagesCompanion toCompanion(bool nullToAbsent) {
    return ScorePagesCompanion(
      id: Value(id),
      scoreId: Value(scoreId),
      sourceIndex: Value(sourceIndex),
      displayOrder: Value(displayOrder),
      hidden: Value(hidden),
      rotation: Value(rotation),
      cropLeft: cropLeft == null && nullToAbsent
          ? const Value.absent()
          : Value(cropLeft),
      cropTop: cropTop == null && nullToAbsent
          ? const Value.absent()
          : Value(cropTop),
      cropRight: cropRight == null && nullToAbsent
          ? const Value.absent()
          : Value(cropRight),
      cropBottom: cropBottom == null && nullToAbsent
          ? const Value.absent()
          : Value(cropBottom),
    );
  }

  factory ScorePage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScorePage(
      id: serializer.fromJson<String>(json['id']),
      scoreId: serializer.fromJson<String>(json['scoreId']),
      sourceIndex: serializer.fromJson<int>(json['sourceIndex']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      rotation: serializer.fromJson<double>(json['rotation']),
      cropLeft: serializer.fromJson<double?>(json['cropLeft']),
      cropTop: serializer.fromJson<double?>(json['cropTop']),
      cropRight: serializer.fromJson<double?>(json['cropRight']),
      cropBottom: serializer.fromJson<double?>(json['cropBottom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scoreId': serializer.toJson<String>(scoreId),
      'sourceIndex': serializer.toJson<int>(sourceIndex),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'hidden': serializer.toJson<bool>(hidden),
      'rotation': serializer.toJson<double>(rotation),
      'cropLeft': serializer.toJson<double?>(cropLeft),
      'cropTop': serializer.toJson<double?>(cropTop),
      'cropRight': serializer.toJson<double?>(cropRight),
      'cropBottom': serializer.toJson<double?>(cropBottom),
    };
  }

  ScorePage copyWith({
    String? id,
    String? scoreId,
    int? sourceIndex,
    int? displayOrder,
    bool? hidden,
    double? rotation,
    Value<double?> cropLeft = const Value.absent(),
    Value<double?> cropTop = const Value.absent(),
    Value<double?> cropRight = const Value.absent(),
    Value<double?> cropBottom = const Value.absent(),
  }) => ScorePage(
    id: id ?? this.id,
    scoreId: scoreId ?? this.scoreId,
    sourceIndex: sourceIndex ?? this.sourceIndex,
    displayOrder: displayOrder ?? this.displayOrder,
    hidden: hidden ?? this.hidden,
    rotation: rotation ?? this.rotation,
    cropLeft: cropLeft.present ? cropLeft.value : this.cropLeft,
    cropTop: cropTop.present ? cropTop.value : this.cropTop,
    cropRight: cropRight.present ? cropRight.value : this.cropRight,
    cropBottom: cropBottom.present ? cropBottom.value : this.cropBottom,
  );
  ScorePage copyWithCompanion(ScorePagesCompanion data) {
    return ScorePage(
      id: data.id.present ? data.id.value : this.id,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      sourceIndex: data.sourceIndex.present
          ? data.sourceIndex.value
          : this.sourceIndex,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      cropLeft: data.cropLeft.present ? data.cropLeft.value : this.cropLeft,
      cropTop: data.cropTop.present ? data.cropTop.value : this.cropTop,
      cropRight: data.cropRight.present ? data.cropRight.value : this.cropRight,
      cropBottom: data.cropBottom.present
          ? data.cropBottom.value
          : this.cropBottom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScorePage(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('sourceIndex: $sourceIndex, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('hidden: $hidden, ')
          ..write('rotation: $rotation, ')
          ..write('cropLeft: $cropLeft, ')
          ..write('cropTop: $cropTop, ')
          ..write('cropRight: $cropRight, ')
          ..write('cropBottom: $cropBottom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scoreId,
    sourceIndex,
    displayOrder,
    hidden,
    rotation,
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScorePage &&
          other.id == this.id &&
          other.scoreId == this.scoreId &&
          other.sourceIndex == this.sourceIndex &&
          other.displayOrder == this.displayOrder &&
          other.hidden == this.hidden &&
          other.rotation == this.rotation &&
          other.cropLeft == this.cropLeft &&
          other.cropTop == this.cropTop &&
          other.cropRight == this.cropRight &&
          other.cropBottom == this.cropBottom);
}

class ScorePagesCompanion extends UpdateCompanion<ScorePage> {
  final Value<String> id;
  final Value<String> scoreId;
  final Value<int> sourceIndex;
  final Value<int> displayOrder;
  final Value<bool> hidden;
  final Value<double> rotation;
  final Value<double?> cropLeft;
  final Value<double?> cropTop;
  final Value<double?> cropRight;
  final Value<double?> cropBottom;
  final Value<int> rowid;
  const ScorePagesCompanion({
    this.id = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.sourceIndex = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.hidden = const Value.absent(),
    this.rotation = const Value.absent(),
    this.cropLeft = const Value.absent(),
    this.cropTop = const Value.absent(),
    this.cropRight = const Value.absent(),
    this.cropBottom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScorePagesCompanion.insert({
    required String id,
    required String scoreId,
    required int sourceIndex,
    required int displayOrder,
    this.hidden = const Value.absent(),
    this.rotation = const Value.absent(),
    this.cropLeft = const Value.absent(),
    this.cropTop = const Value.absent(),
    this.cropRight = const Value.absent(),
    this.cropBottom = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scoreId = Value(scoreId),
       sourceIndex = Value(sourceIndex),
       displayOrder = Value(displayOrder);
  static Insertable<ScorePage> custom({
    Expression<String>? id,
    Expression<String>? scoreId,
    Expression<int>? sourceIndex,
    Expression<int>? displayOrder,
    Expression<bool>? hidden,
    Expression<double>? rotation,
    Expression<double>? cropLeft,
    Expression<double>? cropTop,
    Expression<double>? cropRight,
    Expression<double>? cropBottom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scoreId != null) 'score_id': scoreId,
      if (sourceIndex != null) 'source_index': sourceIndex,
      if (displayOrder != null) 'display_order': displayOrder,
      if (hidden != null) 'hidden': hidden,
      if (rotation != null) 'rotation': rotation,
      if (cropLeft != null) 'crop_left': cropLeft,
      if (cropTop != null) 'crop_top': cropTop,
      if (cropRight != null) 'crop_right': cropRight,
      if (cropBottom != null) 'crop_bottom': cropBottom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScorePagesCompanion copyWith({
    Value<String>? id,
    Value<String>? scoreId,
    Value<int>? sourceIndex,
    Value<int>? displayOrder,
    Value<bool>? hidden,
    Value<double>? rotation,
    Value<double?>? cropLeft,
    Value<double?>? cropTop,
    Value<double?>? cropRight,
    Value<double?>? cropBottom,
    Value<int>? rowid,
  }) {
    return ScorePagesCompanion(
      id: id ?? this.id,
      scoreId: scoreId ?? this.scoreId,
      sourceIndex: sourceIndex ?? this.sourceIndex,
      displayOrder: displayOrder ?? this.displayOrder,
      hidden: hidden ?? this.hidden,
      rotation: rotation ?? this.rotation,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (sourceIndex.present) {
      map['source_index'] = Variable<int>(sourceIndex.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (cropLeft.present) {
      map['crop_left'] = Variable<double>(cropLeft.value);
    }
    if (cropTop.present) {
      map['crop_top'] = Variable<double>(cropTop.value);
    }
    if (cropRight.present) {
      map['crop_right'] = Variable<double>(cropRight.value);
    }
    if (cropBottom.present) {
      map['crop_bottom'] = Variable<double>(cropBottom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScorePagesCompanion(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('sourceIndex: $sourceIndex, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('hidden: $hidden, ')
          ..write('rotation: $rotation, ')
          ..write('cropLeft: $cropLeft, ')
          ..write('cropTop: $cropTop, ')
          ..write('cropRight: $cropRight, ')
          ..write('cropBottom: $cropBottom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _depthMeta = const VerificationMeta('depth');
  @override
  late final GeneratedColumn<int> depth = GeneratedColumn<int>(
    'depth',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scoreId,
    page,
    label,
    depth,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('depth')) {
      context.handle(
        _depthMeta,
        depth.isAcceptableOrUnknown(data['depth']!, _depthMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      depth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}depth'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String id;
  final String scoreId;
  final int page;
  final String label;

  /// 목차 계층. 최상위는 0.
  final int depth;
  final int sortOrder;
  const Bookmark({
    required this.id,
    required this.scoreId,
    required this.page,
    required this.label,
    required this.depth,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['score_id'] = Variable<String>(scoreId);
    map['page'] = Variable<int>(page);
    map['label'] = Variable<String>(label);
    map['depth'] = Variable<int>(depth);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      scoreId: Value(scoreId),
      page: Value(page),
      label: Value(label),
      depth: Value(depth),
      sortOrder: Value(sortOrder),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<String>(json['id']),
      scoreId: serializer.fromJson<String>(json['scoreId']),
      page: serializer.fromJson<int>(json['page']),
      label: serializer.fromJson<String>(json['label']),
      depth: serializer.fromJson<int>(json['depth']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scoreId': serializer.toJson<String>(scoreId),
      'page': serializer.toJson<int>(page),
      'label': serializer.toJson<String>(label),
      'depth': serializer.toJson<int>(depth),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Bookmark copyWith({
    String? id,
    String? scoreId,
    int? page,
    String? label,
    int? depth,
    int? sortOrder,
  }) => Bookmark(
    id: id ?? this.id,
    scoreId: scoreId ?? this.scoreId,
    page: page ?? this.page,
    label: label ?? this.label,
    depth: depth ?? this.depth,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      page: data.page.present ? data.page.value : this.page,
      label: data.label.present ? data.label.value : this.label,
      depth: data.depth.present ? data.depth.value : this.depth,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('page: $page, ')
          ..write('label: $label, ')
          ..write('depth: $depth, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scoreId, page, label, depth, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.scoreId == this.scoreId &&
          other.page == this.page &&
          other.label == this.label &&
          other.depth == this.depth &&
          other.sortOrder == this.sortOrder);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<String> scoreId;
  final Value<int> page;
  final Value<String> label;
  final Value<int> depth;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.page = const Value.absent(),
    this.label = const Value.absent(),
    this.depth = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String scoreId,
    required int page,
    required String label,
    this.depth = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scoreId = Value(scoreId),
       page = Value(page),
       label = Value(label);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<String>? scoreId,
    Expression<int>? page,
    Expression<String>? label,
    Expression<int>? depth,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scoreId != null) 'score_id': scoreId,
      if (page != null) 'page': page,
      if (label != null) 'label': label,
      if (depth != null) 'depth': depth,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? scoreId,
    Value<int>? page,
    Value<String>? label,
    Value<int>? depth,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      scoreId: scoreId ?? this.scoreId,
      page: page ?? this.page,
      label: label ?? this.label,
      depth: depth ?? this.depth,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (depth.present) {
      map['depth'] = Variable<int>(depth.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('page: $page, ')
          ..write('label: $label, ')
          ..write('depth: $depth, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JumpButtonsTable extends JumpButtons
    with TableInfo<$JumpButtonsTable, JumpButton> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JumpButtonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fromPageMeta = const VerificationMeta(
    'fromPage',
  );
  @override
  late final GeneratedColumn<int> fromPage = GeneratedColumn<int>(
    'from_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toPageMeta = const VerificationMeta('toPage');
  @override
  late final GeneratedColumn<int> toPage = GeneratedColumn<int>(
    'to_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scoreId,
    fromPage,
    x,
    y,
    toPage,
    label,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jump_buttons';
  @override
  VerificationContext validateIntegrity(
    Insertable<JumpButton> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('from_page')) {
      context.handle(
        _fromPageMeta,
        fromPage.isAcceptableOrUnknown(data['from_page']!, _fromPageMeta),
      );
    } else if (isInserting) {
      context.missing(_fromPageMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('to_page')) {
      context.handle(
        _toPageMeta,
        toPage.isAcceptableOrUnknown(data['to_page']!, _toPageMeta),
      );
    } else if (isInserting) {
      context.missing(_toPageMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JumpButton map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JumpButton(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      fromPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_page'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      toPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_page'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
    );
  }

  @override
  $JumpButtonsTable createAlias(String alias) {
    return $JumpButtonsTable(attachedDatabase, alias);
  }
}

class JumpButton extends DataClass implements Insertable<JumpButton> {
  final String id;
  final String scoreId;

  /// 버튼이 놓인 페이지와 그 페이지 안의 상대 좌표(0.0 ~ 1.0).
  final int fromPage;
  final double x;
  final double y;
  final int toPage;
  final String? label;
  const JumpButton({
    required this.id,
    required this.scoreId,
    required this.fromPage,
    required this.x,
    required this.y,
    required this.toPage,
    this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['score_id'] = Variable<String>(scoreId);
    map['from_page'] = Variable<int>(fromPage);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['to_page'] = Variable<int>(toPage);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  JumpButtonsCompanion toCompanion(bool nullToAbsent) {
    return JumpButtonsCompanion(
      id: Value(id),
      scoreId: Value(scoreId),
      fromPage: Value(fromPage),
      x: Value(x),
      y: Value(y),
      toPage: Value(toPage),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
    );
  }

  factory JumpButton.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JumpButton(
      id: serializer.fromJson<String>(json['id']),
      scoreId: serializer.fromJson<String>(json['scoreId']),
      fromPage: serializer.fromJson<int>(json['fromPage']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      toPage: serializer.fromJson<int>(json['toPage']),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scoreId': serializer.toJson<String>(scoreId),
      'fromPage': serializer.toJson<int>(fromPage),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'toPage': serializer.toJson<int>(toPage),
      'label': serializer.toJson<String?>(label),
    };
  }

  JumpButton copyWith({
    String? id,
    String? scoreId,
    int? fromPage,
    double? x,
    double? y,
    int? toPage,
    Value<String?> label = const Value.absent(),
  }) => JumpButton(
    id: id ?? this.id,
    scoreId: scoreId ?? this.scoreId,
    fromPage: fromPage ?? this.fromPage,
    x: x ?? this.x,
    y: y ?? this.y,
    toPage: toPage ?? this.toPage,
    label: label.present ? label.value : this.label,
  );
  JumpButton copyWithCompanion(JumpButtonsCompanion data) {
    return JumpButton(
      id: data.id.present ? data.id.value : this.id,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      fromPage: data.fromPage.present ? data.fromPage.value : this.fromPage,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      toPage: data.toPage.present ? data.toPage.value : this.toPage,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JumpButton(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('fromPage: $fromPage, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('toPage: $toPage, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scoreId, fromPage, x, y, toPage, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JumpButton &&
          other.id == this.id &&
          other.scoreId == this.scoreId &&
          other.fromPage == this.fromPage &&
          other.x == this.x &&
          other.y == this.y &&
          other.toPage == this.toPage &&
          other.label == this.label);
}

class JumpButtonsCompanion extends UpdateCompanion<JumpButton> {
  final Value<String> id;
  final Value<String> scoreId;
  final Value<int> fromPage;
  final Value<double> x;
  final Value<double> y;
  final Value<int> toPage;
  final Value<String?> label;
  final Value<int> rowid;
  const JumpButtonsCompanion({
    this.id = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.fromPage = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.toPage = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JumpButtonsCompanion.insert({
    required String id,
    required String scoreId,
    required int fromPage,
    required double x,
    required double y,
    required int toPage,
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scoreId = Value(scoreId),
       fromPage = Value(fromPage),
       x = Value(x),
       y = Value(y),
       toPage = Value(toPage);
  static Insertable<JumpButton> custom({
    Expression<String>? id,
    Expression<String>? scoreId,
    Expression<int>? fromPage,
    Expression<double>? x,
    Expression<double>? y,
    Expression<int>? toPage,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scoreId != null) 'score_id': scoreId,
      if (fromPage != null) 'from_page': fromPage,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (toPage != null) 'to_page': toPage,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JumpButtonsCompanion copyWith({
    Value<String>? id,
    Value<String>? scoreId,
    Value<int>? fromPage,
    Value<double>? x,
    Value<double>? y,
    Value<int>? toPage,
    Value<String?>? label,
    Value<int>? rowid,
  }) {
    return JumpButtonsCompanion(
      id: id ?? this.id,
      scoreId: scoreId ?? this.scoreId,
      fromPage: fromPage ?? this.fromPage,
      x: x ?? this.x,
      y: y ?? this.y,
      toPage: toPage ?? this.toPage,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (fromPage.present) {
      map['from_page'] = Variable<int>(fromPage.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (toPage.present) {
      map['to_page'] = Variable<int>(toPage.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JumpButtonsCompanion(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('fromPage: $fromPage, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('toPage: $toPage, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final int? color;
  final int sortOrder;
  final DateTime createdAt;
  const Tag({
    required this.id,
    required this.name,
    this.color,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int?>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int?>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    Value<int?> color = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<int?> color;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int?>? color,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScoreTagsTable extends ScoreTags
    with TableInfo<$ScoreTagsTable, ScoreTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoreTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [scoreId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'score_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoreTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scoreId, tagId};
  @override
  ScoreTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoreTag(
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $ScoreTagsTable createAlias(String alias) {
    return $ScoreTagsTable(attachedDatabase, alias);
  }
}

class ScoreTag extends DataClass implements Insertable<ScoreTag> {
  final String scoreId;
  final String tagId;
  const ScoreTag({required this.scoreId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['score_id'] = Variable<String>(scoreId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  ScoreTagsCompanion toCompanion(bool nullToAbsent) {
    return ScoreTagsCompanion(scoreId: Value(scoreId), tagId: Value(tagId));
  }

  factory ScoreTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoreTag(
      scoreId: serializer.fromJson<String>(json['scoreId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scoreId': serializer.toJson<String>(scoreId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  ScoreTag copyWith({String? scoreId, String? tagId}) =>
      ScoreTag(scoreId: scoreId ?? this.scoreId, tagId: tagId ?? this.tagId);
  ScoreTag copyWithCompanion(ScoreTagsCompanion data) {
    return ScoreTag(
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoreTag(')
          ..write('scoreId: $scoreId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scoreId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoreTag &&
          other.scoreId == this.scoreId &&
          other.tagId == this.tagId);
}

class ScoreTagsCompanion extends UpdateCompanion<ScoreTag> {
  final Value<String> scoreId;
  final Value<String> tagId;
  final Value<int> rowid;
  const ScoreTagsCompanion({
    this.scoreId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoreTagsCompanion.insert({
    required String scoreId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : scoreId = Value(scoreId),
       tagId = Value(tagId);
  static Insertable<ScoreTag> custom({
    Expression<String>? scoreId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scoreId != null) 'score_id': scoreId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoreTagsCompanion copyWith({
    Value<String>? scoreId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return ScoreTagsCompanion(
      scoreId: scoreId ?? this.scoreId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoreTagsCompanion(')
          ..write('scoreId: $scoreId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetlistsTable extends Setlists with TableInfo<$SetlistsTable, Setlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetlistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _performedAtMeta = const VerificationMeta(
    'performedAt',
  );
  @override
  late final GeneratedColumn<DateTime> performedAt = GeneratedColumn<DateTime>(
    'performed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    note,
    performedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setlist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('performed_at')) {
      context.handle(
        _performedAtMeta,
        performedAt.isAcceptableOrUnknown(
          data['performed_at']!,
          _performedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      performedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}performed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SetlistsTable createAlias(String alias) {
    return $SetlistsTable(attachedDatabase, alias);
  }
}

class Setlist extends DataClass implements Insertable<Setlist> {
  final String id;
  final String name;
  final String? note;
  final DateTime? performedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Setlist({
    required this.id,
    required this.name,
    this.note,
    this.performedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || performedAt != null) {
      map['performed_at'] = Variable<DateTime>(performedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SetlistsCompanion toCompanion(bool nullToAbsent) {
    return SetlistsCompanion(
      id: Value(id),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      performedAt: performedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(performedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setlist(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      performedAt: serializer.fromJson<DateTime?>(json['performedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
      'performedAt': serializer.toJson<DateTime?>(performedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setlist copyWith({
    String? id,
    String? name,
    Value<String?> note = const Value.absent(),
    Value<DateTime?> performedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Setlist(
    id: id ?? this.id,
    name: name ?? this.name,
    note: note.present ? note.value : this.note,
    performedAt: performedAt.present ? performedAt.value : this.performedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Setlist copyWithCompanion(SetlistsCompanion data) {
    return Setlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      performedAt: data.performedAt.present
          ? data.performedAt.value
          : this.performedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('performedAt: $performedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, note, performedAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.note == this.note &&
          other.performedAt == this.performedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SetlistsCompanion extends UpdateCompanion<Setlist> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> note;
  final Value<DateTime?> performedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SetlistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetlistsCompanion.insert({
    required String id,
    required String name,
    this.note = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Setlist> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? note,
    Expression<DateTime>? performedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (performedAt != null) 'performed_at': performedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetlistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? note,
    Value<DateTime?>? performedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SetlistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      performedAt: performedAt ?? this.performedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (performedAt.present) {
      map['performed_at'] = Variable<DateTime>(performedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetlistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('performedAt: $performedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetlistItemsTable extends SetlistItems
    with TableInfo<$SetlistItemsTable, SetlistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetlistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setlistIdMeta = const VerificationMeta(
    'setlistId',
  );
  @override
  late final GeneratedColumn<String> setlistId = GeneratedColumn<String>(
    'setlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES setlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPageMeta = const VerificationMeta(
    'startPage',
  );
  @override
  late final GeneratedColumn<int> startPage = GeneratedColumn<int>(
    'start_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endPageMeta = const VerificationMeta(
    'endPage',
  );
  @override
  late final GeneratedColumn<int> endPage = GeneratedColumn<int>(
    'end_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    setlistId,
    scoreId,
    sortOrder,
    startPage,
    endPage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setlist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetlistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('setlist_id')) {
      context.handle(
        _setlistIdMeta,
        setlistId.isAcceptableOrUnknown(data['setlist_id']!, _setlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setlistIdMeta);
    }
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('start_page')) {
      context.handle(
        _startPageMeta,
        startPage.isAcceptableOrUnknown(data['start_page']!, _startPageMeta),
      );
    }
    if (data.containsKey('end_page')) {
      context.handle(
        _endPageMeta,
        endPage.isAcceptableOrUnknown(data['end_page']!, _endPageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetlistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetlistItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      setlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setlist_id'],
      )!,
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      startPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page'],
      ),
      endPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_page'],
      ),
    );
  }

  @override
  $SetlistItemsTable createAlias(String alias) {
    return $SetlistItemsTable(attachedDatabase, alias);
  }
}

class SetlistItem extends DataClass implements Insertable<SetlistItem> {
  final String id;
  final String setlistId;
  final String scoreId;
  final int sortOrder;

  /// null 이면 곡 전체. 값이 있으면 해당 페이지 구간만 이어 붙인다.
  final int? startPage;
  final int? endPage;
  const SetlistItem({
    required this.id,
    required this.setlistId,
    required this.scoreId,
    required this.sortOrder,
    this.startPage,
    this.endPage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['setlist_id'] = Variable<String>(setlistId);
    map['score_id'] = Variable<String>(scoreId);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || startPage != null) {
      map['start_page'] = Variable<int>(startPage);
    }
    if (!nullToAbsent || endPage != null) {
      map['end_page'] = Variable<int>(endPage);
    }
    return map;
  }

  SetlistItemsCompanion toCompanion(bool nullToAbsent) {
    return SetlistItemsCompanion(
      id: Value(id),
      setlistId: Value(setlistId),
      scoreId: Value(scoreId),
      sortOrder: Value(sortOrder),
      startPage: startPage == null && nullToAbsent
          ? const Value.absent()
          : Value(startPage),
      endPage: endPage == null && nullToAbsent
          ? const Value.absent()
          : Value(endPage),
    );
  }

  factory SetlistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetlistItem(
      id: serializer.fromJson<String>(json['id']),
      setlistId: serializer.fromJson<String>(json['setlistId']),
      scoreId: serializer.fromJson<String>(json['scoreId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      startPage: serializer.fromJson<int?>(json['startPage']),
      endPage: serializer.fromJson<int?>(json['endPage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'setlistId': serializer.toJson<String>(setlistId),
      'scoreId': serializer.toJson<String>(scoreId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'startPage': serializer.toJson<int?>(startPage),
      'endPage': serializer.toJson<int?>(endPage),
    };
  }

  SetlistItem copyWith({
    String? id,
    String? setlistId,
    String? scoreId,
    int? sortOrder,
    Value<int?> startPage = const Value.absent(),
    Value<int?> endPage = const Value.absent(),
  }) => SetlistItem(
    id: id ?? this.id,
    setlistId: setlistId ?? this.setlistId,
    scoreId: scoreId ?? this.scoreId,
    sortOrder: sortOrder ?? this.sortOrder,
    startPage: startPage.present ? startPage.value : this.startPage,
    endPage: endPage.present ? endPage.value : this.endPage,
  );
  SetlistItem copyWithCompanion(SetlistItemsCompanion data) {
    return SetlistItem(
      id: data.id.present ? data.id.value : this.id,
      setlistId: data.setlistId.present ? data.setlistId.value : this.setlistId,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      startPage: data.startPage.present ? data.startPage.value : this.startPage,
      endPage: data.endPage.present ? data.endPage.value : this.endPage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetlistItem(')
          ..write('id: $id, ')
          ..write('setlistId: $setlistId, ')
          ..write('scoreId: $scoreId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, setlistId, scoreId, sortOrder, startPage, endPage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetlistItem &&
          other.id == this.id &&
          other.setlistId == this.setlistId &&
          other.scoreId == this.scoreId &&
          other.sortOrder == this.sortOrder &&
          other.startPage == this.startPage &&
          other.endPage == this.endPage);
}

class SetlistItemsCompanion extends UpdateCompanion<SetlistItem> {
  final Value<String> id;
  final Value<String> setlistId;
  final Value<String> scoreId;
  final Value<int> sortOrder;
  final Value<int?> startPage;
  final Value<int?> endPage;
  final Value<int> rowid;
  const SetlistItemsCompanion({
    this.id = const Value.absent(),
    this.setlistId = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.startPage = const Value.absent(),
    this.endPage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetlistItemsCompanion.insert({
    required String id,
    required String setlistId,
    required String scoreId,
    required int sortOrder,
    this.startPage = const Value.absent(),
    this.endPage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       setlistId = Value(setlistId),
       scoreId = Value(scoreId),
       sortOrder = Value(sortOrder);
  static Insertable<SetlistItem> custom({
    Expression<String>? id,
    Expression<String>? setlistId,
    Expression<String>? scoreId,
    Expression<int>? sortOrder,
    Expression<int>? startPage,
    Expression<int>? endPage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setlistId != null) 'setlist_id': setlistId,
      if (scoreId != null) 'score_id': scoreId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (startPage != null) 'start_page': startPage,
      if (endPage != null) 'end_page': endPage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetlistItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? setlistId,
    Value<String>? scoreId,
    Value<int>? sortOrder,
    Value<int?>? startPage,
    Value<int?>? endPage,
    Value<int>? rowid,
  }) {
    return SetlistItemsCompanion(
      id: id ?? this.id,
      setlistId: setlistId ?? this.setlistId,
      scoreId: scoreId ?? this.scoreId,
      sortOrder: sortOrder ?? this.sortOrder,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (setlistId.present) {
      map['setlist_id'] = Variable<String>(setlistId.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (startPage.present) {
      map['start_page'] = Variable<int>(startPage.value);
    }
    if (endPage.present) {
      map['end_page'] = Variable<int>(endPage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetlistItemsCompanion(')
          ..write('id: $id, ')
          ..write('setlistId: $setlistId, ')
          ..write('scoreId: $scoreId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InkStrokesTable extends InkStrokes
    with TableInfo<$InkStrokesTable, InkStroke> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InkStrokesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<InkFormat, int> format =
      GeneratedColumn<int>(
        'format',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(InkFormat.vector.index),
      ).withConverter<InkFormat>($InkStrokesTable.$converterformat);
  @override
  late final GeneratedColumnWithTypeConverter<StrokeTool, int> tool =
      GeneratedColumn<int>(
        'tool',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(StrokeTool.pen.index),
      ).withConverter<StrokeTool>($InkStrokesTable.$convertertool);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF000000),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scoreId,
    page,
    format,
    tool,
    color,
    width,
    data,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ink_strokes';
  @override
  VerificationContext validateIntegrity(
    Insertable<InkStroke> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InkStroke map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InkStroke(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      format: $InkStrokesTable.$converterformat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}format'],
        )!,
      ),
      tool: $InkStrokesTable.$convertertool.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}tool'],
        )!,
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}data'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $InkStrokesTable createAlias(String alias) {
    return $InkStrokesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<InkFormat, int, int> $converterformat =
      const EnumIndexConverter<InkFormat>(InkFormat.values);
  static JsonTypeConverter2<StrokeTool, int, int> $convertertool =
      const EnumIndexConverter<StrokeTool>(StrokeTool.values);
}

class InkStroke extends DataClass implements Insertable<InkStroke> {
  final String id;
  final String scoreId;
  final int page;
  final InkFormat format;
  final StrokeTool tool;
  final int color;
  final double width;

  /// vector: 점 배열(x, y, 압력, 기울기)을 직렬화한 바이트.
  /// pencilKit: PKDrawing 의 dataRepresentation 바이트 그대로.
  final Uint8List data;

  /// 실행 취소 순서와 그리기 순서를 함께 결정한다.
  final int sortOrder;
  final DateTime createdAt;
  const InkStroke({
    required this.id,
    required this.scoreId,
    required this.page,
    required this.format,
    required this.tool,
    required this.color,
    required this.width,
    required this.data,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['score_id'] = Variable<String>(scoreId);
    map['page'] = Variable<int>(page);
    {
      map['format'] = Variable<int>(
        $InkStrokesTable.$converterformat.toSql(format),
      );
    }
    {
      map['tool'] = Variable<int>($InkStrokesTable.$convertertool.toSql(tool));
    }
    map['color'] = Variable<int>(color);
    map['width'] = Variable<double>(width);
    map['data'] = Variable<Uint8List>(data);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InkStrokesCompanion toCompanion(bool nullToAbsent) {
    return InkStrokesCompanion(
      id: Value(id),
      scoreId: Value(scoreId),
      page: Value(page),
      format: Value(format),
      tool: Value(tool),
      color: Value(color),
      width: Value(width),
      data: Value(data),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory InkStroke.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InkStroke(
      id: serializer.fromJson<String>(json['id']),
      scoreId: serializer.fromJson<String>(json['scoreId']),
      page: serializer.fromJson<int>(json['page']),
      format: $InkStrokesTable.$converterformat.fromJson(
        serializer.fromJson<int>(json['format']),
      ),
      tool: $InkStrokesTable.$convertertool.fromJson(
        serializer.fromJson<int>(json['tool']),
      ),
      color: serializer.fromJson<int>(json['color']),
      width: serializer.fromJson<double>(json['width']),
      data: serializer.fromJson<Uint8List>(json['data']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scoreId': serializer.toJson<String>(scoreId),
      'page': serializer.toJson<int>(page),
      'format': serializer.toJson<int>(
        $InkStrokesTable.$converterformat.toJson(format),
      ),
      'tool': serializer.toJson<int>(
        $InkStrokesTable.$convertertool.toJson(tool),
      ),
      'color': serializer.toJson<int>(color),
      'width': serializer.toJson<double>(width),
      'data': serializer.toJson<Uint8List>(data),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InkStroke copyWith({
    String? id,
    String? scoreId,
    int? page,
    InkFormat? format,
    StrokeTool? tool,
    int? color,
    double? width,
    Uint8List? data,
    int? sortOrder,
    DateTime? createdAt,
  }) => InkStroke(
    id: id ?? this.id,
    scoreId: scoreId ?? this.scoreId,
    page: page ?? this.page,
    format: format ?? this.format,
    tool: tool ?? this.tool,
    color: color ?? this.color,
    width: width ?? this.width,
    data: data ?? this.data,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  InkStroke copyWithCompanion(InkStrokesCompanion data) {
    return InkStroke(
      id: data.id.present ? data.id.value : this.id,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      page: data.page.present ? data.page.value : this.page,
      format: data.format.present ? data.format.value : this.format,
      tool: data.tool.present ? data.tool.value : this.tool,
      color: data.color.present ? data.color.value : this.color,
      width: data.width.present ? data.width.value : this.width,
      data: data.data.present ? data.data.value : this.data,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InkStroke(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('page: $page, ')
          ..write('format: $format, ')
          ..write('tool: $tool, ')
          ..write('color: $color, ')
          ..write('width: $width, ')
          ..write('data: $data, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scoreId,
    page,
    format,
    tool,
    color,
    width,
    $driftBlobEquality.hash(data),
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InkStroke &&
          other.id == this.id &&
          other.scoreId == this.scoreId &&
          other.page == this.page &&
          other.format == this.format &&
          other.tool == this.tool &&
          other.color == this.color &&
          other.width == this.width &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class InkStrokesCompanion extends UpdateCompanion<InkStroke> {
  final Value<String> id;
  final Value<String> scoreId;
  final Value<int> page;
  final Value<InkFormat> format;
  final Value<StrokeTool> tool;
  final Value<int> color;
  final Value<double> width;
  final Value<Uint8List> data;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InkStrokesCompanion({
    this.id = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.page = const Value.absent(),
    this.format = const Value.absent(),
    this.tool = const Value.absent(),
    this.color = const Value.absent(),
    this.width = const Value.absent(),
    this.data = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InkStrokesCompanion.insert({
    required String id,
    required String scoreId,
    required int page,
    this.format = const Value.absent(),
    this.tool = const Value.absent(),
    this.color = const Value.absent(),
    this.width = const Value.absent(),
    required Uint8List data,
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scoreId = Value(scoreId),
       page = Value(page),
       data = Value(data);
  static Insertable<InkStroke> custom({
    Expression<String>? id,
    Expression<String>? scoreId,
    Expression<int>? page,
    Expression<int>? format,
    Expression<int>? tool,
    Expression<int>? color,
    Expression<double>? width,
    Expression<Uint8List>? data,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scoreId != null) 'score_id': scoreId,
      if (page != null) 'page': page,
      if (format != null) 'format': format,
      if (tool != null) 'tool': tool,
      if (color != null) 'color': color,
      if (width != null) 'width': width,
      if (data != null) 'data': data,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InkStrokesCompanion copyWith({
    Value<String>? id,
    Value<String>? scoreId,
    Value<int>? page,
    Value<InkFormat>? format,
    Value<StrokeTool>? tool,
    Value<int>? color,
    Value<double>? width,
    Value<Uint8List>? data,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return InkStrokesCompanion(
      id: id ?? this.id,
      scoreId: scoreId ?? this.scoreId,
      page: page ?? this.page,
      format: format ?? this.format,
      tool: tool ?? this.tool,
      color: color ?? this.color,
      width: width ?? this.width,
      data: data ?? this.data,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (format.present) {
      map['format'] = Variable<int>(
        $InkStrokesTable.$converterformat.toSql(format.value),
      );
    }
    if (tool.present) {
      map['tool'] = Variable<int>(
        $InkStrokesTable.$convertertool.toSql(tool.value),
      );
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InkStrokesCompanion(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('page: $page, ')
          ..write('format: $format, ')
          ..write('tool: $tool, ')
          ..write('color: $color, ')
          ..write('width: $width, ')
          ..write('data: $data, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, Annotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<double> scale = GeneratedColumn<double>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF000000),
  );
  static const VerificationMeta _fontSizeMeta = const VerificationMeta(
    'fontSize',
  );
  @override
  late final GeneratedColumn<double> fontSize = GeneratedColumn<double>(
    'font_size',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scoreId,
    page,
    kind,
    value,
    x,
    y,
    scale,
    rotation,
    color,
    fontSize,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Annotation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('font_size')) {
      context.handle(
        _fontSizeMeta,
        fontSize.isAcceptableOrUnknown(data['font_size']!, _fontSizeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Annotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Annotation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scale'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      fontSize: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}font_size'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class Annotation extends DataClass implements Insertable<Annotation> {
  final String id;
  final String scoreId;
  final int page;

  /// 'stamp' | 'text'
  final String kind;

  /// 스탬프 식별자 또는 텍스트 내용.
  final String value;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int color;
  final double? fontSize;
  final int sortOrder;
  const Annotation({
    required this.id,
    required this.scoreId,
    required this.page,
    required this.kind,
    required this.value,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.color,
    this.fontSize,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['score_id'] = Variable<String>(scoreId);
    map['page'] = Variable<int>(page);
    map['kind'] = Variable<String>(kind);
    map['value'] = Variable<String>(value);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['scale'] = Variable<double>(scale);
    map['rotation'] = Variable<double>(rotation);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || fontSize != null) {
      map['font_size'] = Variable<double>(fontSize);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      scoreId: Value(scoreId),
      page: Value(page),
      kind: Value(kind),
      value: Value(value),
      x: Value(x),
      y: Value(y),
      scale: Value(scale),
      rotation: Value(rotation),
      color: Value(color),
      fontSize: fontSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fontSize),
      sortOrder: Value(sortOrder),
    );
  }

  factory Annotation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Annotation(
      id: serializer.fromJson<String>(json['id']),
      scoreId: serializer.fromJson<String>(json['scoreId']),
      page: serializer.fromJson<int>(json['page']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<String>(json['value']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      scale: serializer.fromJson<double>(json['scale']),
      rotation: serializer.fromJson<double>(json['rotation']),
      color: serializer.fromJson<int>(json['color']),
      fontSize: serializer.fromJson<double?>(json['fontSize']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scoreId': serializer.toJson<String>(scoreId),
      'page': serializer.toJson<int>(page),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<String>(value),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'scale': serializer.toJson<double>(scale),
      'rotation': serializer.toJson<double>(rotation),
      'color': serializer.toJson<int>(color),
      'fontSize': serializer.toJson<double?>(fontSize),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Annotation copyWith({
    String? id,
    String? scoreId,
    int? page,
    String? kind,
    String? value,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? color,
    Value<double?> fontSize = const Value.absent(),
    int? sortOrder,
  }) => Annotation(
    id: id ?? this.id,
    scoreId: scoreId ?? this.scoreId,
    page: page ?? this.page,
    kind: kind ?? this.kind,
    value: value ?? this.value,
    x: x ?? this.x,
    y: y ?? this.y,
    scale: scale ?? this.scale,
    rotation: rotation ?? this.rotation,
    color: color ?? this.color,
    fontSize: fontSize.present ? fontSize.value : this.fontSize,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Annotation copyWithCompanion(AnnotationsCompanion data) {
    return Annotation(
      id: data.id.present ? data.id.value : this.id,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      page: data.page.present ? data.page.value : this.page,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      scale: data.scale.present ? data.scale.value : this.scale,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      color: data.color.present ? data.color.value : this.color,
      fontSize: data.fontSize.present ? data.fontSize.value : this.fontSize,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Annotation(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('page: $page, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('scale: $scale, ')
          ..write('rotation: $rotation, ')
          ..write('color: $color, ')
          ..write('fontSize: $fontSize, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scoreId,
    page,
    kind,
    value,
    x,
    y,
    scale,
    rotation,
    color,
    fontSize,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Annotation &&
          other.id == this.id &&
          other.scoreId == this.scoreId &&
          other.page == this.page &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.x == this.x &&
          other.y == this.y &&
          other.scale == this.scale &&
          other.rotation == this.rotation &&
          other.color == this.color &&
          other.fontSize == this.fontSize &&
          other.sortOrder == this.sortOrder);
}

class AnnotationsCompanion extends UpdateCompanion<Annotation> {
  final Value<String> id;
  final Value<String> scoreId;
  final Value<int> page;
  final Value<String> kind;
  final Value<String> value;
  final Value<double> x;
  final Value<double> y;
  final Value<double> scale;
  final Value<double> rotation;
  final Value<int> color;
  final Value<double?> fontSize;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.page = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.scale = const Value.absent(),
    this.rotation = const Value.absent(),
    this.color = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    required String id,
    required String scoreId,
    required int page,
    required String kind,
    required String value,
    required double x,
    required double y,
    this.scale = const Value.absent(),
    this.rotation = const Value.absent(),
    this.color = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scoreId = Value(scoreId),
       page = Value(page),
       kind = Value(kind),
       value = Value(value),
       x = Value(x),
       y = Value(y);
  static Insertable<Annotation> custom({
    Expression<String>? id,
    Expression<String>? scoreId,
    Expression<int>? page,
    Expression<String>? kind,
    Expression<String>? value,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? scale,
    Expression<double>? rotation,
    Expression<int>? color,
    Expression<double>? fontSize,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scoreId != null) 'score_id': scoreId,
      if (page != null) 'page': page,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (scale != null) 'scale': scale,
      if (rotation != null) 'rotation': rotation,
      if (color != null) 'color': color,
      if (fontSize != null) 'font_size': fontSize,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnotationsCompanion copyWith({
    Value<String>? id,
    Value<String>? scoreId,
    Value<int>? page,
    Value<String>? kind,
    Value<String>? value,
    Value<double>? x,
    Value<double>? y,
    Value<double>? scale,
    Value<double>? rotation,
    Value<int>? color,
    Value<double?>? fontSize,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      scoreId: scoreId ?? this.scoreId,
      page: page ?? this.page,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (scale.present) {
      map['scale'] = Variable<double>(scale.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (fontSize.present) {
      map['font_size'] = Variable<double>(fontSize.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('page: $page, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('scale: $scale, ')
          ..write('rotation: $rotation, ')
          ..write('color: $color, ')
          ..write('fontSize: $fontSize, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordingsTable extends Recordings
    with TableInfo<$RecordingsTable, Recording> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scoreId,
    title,
    filePath,
    durationMs,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recording> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recording map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recording(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RecordingsTable createAlias(String alias) {
    return $RecordingsTable(attachedDatabase, alias);
  }
}

class Recording extends DataClass implements Insertable<Recording> {
  final String id;
  final String? scoreId;
  final String title;
  final String filePath;
  final int durationMs;
  final DateTime createdAt;
  const Recording({
    required this.id,
    this.scoreId,
    required this.title,
    required this.filePath,
    required this.durationMs,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || scoreId != null) {
      map['score_id'] = Variable<String>(scoreId);
    }
    map['title'] = Variable<String>(title);
    map['file_path'] = Variable<String>(filePath);
    map['duration_ms'] = Variable<int>(durationMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecordingsCompanion toCompanion(bool nullToAbsent) {
    return RecordingsCompanion(
      id: Value(id),
      scoreId: scoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(scoreId),
      title: Value(title),
      filePath: Value(filePath),
      durationMs: Value(durationMs),
      createdAt: Value(createdAt),
    );
  }

  factory Recording.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recording(
      id: serializer.fromJson<String>(json['id']),
      scoreId: serializer.fromJson<String?>(json['scoreId']),
      title: serializer.fromJson<String>(json['title']),
      filePath: serializer.fromJson<String>(json['filePath']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scoreId': serializer.toJson<String?>(scoreId),
      'title': serializer.toJson<String>(title),
      'filePath': serializer.toJson<String>(filePath),
      'durationMs': serializer.toJson<int>(durationMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Recording copyWith({
    String? id,
    Value<String?> scoreId = const Value.absent(),
    String? title,
    String? filePath,
    int? durationMs,
    DateTime? createdAt,
  }) => Recording(
    id: id ?? this.id,
    scoreId: scoreId.present ? scoreId.value : this.scoreId,
    title: title ?? this.title,
    filePath: filePath ?? this.filePath,
    durationMs: durationMs ?? this.durationMs,
    createdAt: createdAt ?? this.createdAt,
  );
  Recording copyWithCompanion(RecordingsCompanion data) {
    return Recording(
      id: data.id.present ? data.id.value : this.id,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      title: data.title.present ? data.title.value : this.title,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recording(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, scoreId, title, filePath, durationMs, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recording &&
          other.id == this.id &&
          other.scoreId == this.scoreId &&
          other.title == this.title &&
          other.filePath == this.filePath &&
          other.durationMs == this.durationMs &&
          other.createdAt == this.createdAt);
}

class RecordingsCompanion extends UpdateCompanion<Recording> {
  final Value<String> id;
  final Value<String?> scoreId;
  final Value<String> title;
  final Value<String> filePath;
  final Value<int> durationMs;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RecordingsCompanion({
    this.id = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.title = const Value.absent(),
    this.filePath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordingsCompanion.insert({
    required String id,
    this.scoreId = const Value.absent(),
    required String title,
    required String filePath,
    this.durationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       filePath = Value(filePath);
  static Insertable<Recording> custom({
    Expression<String>? id,
    Expression<String>? scoreId,
    Expression<String>? title,
    Expression<String>? filePath,
    Expression<int>? durationMs,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scoreId != null) 'score_id': scoreId,
      if (title != null) 'title': title,
      if (filePath != null) 'file_path': filePath,
      if (durationMs != null) 'duration_ms': durationMs,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordingsCompanion copyWith({
    Value<String>? id,
    Value<String?>? scoreId,
    Value<String>? title,
    Value<String>? filePath,
    Value<int>? durationMs,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RecordingsCompanion(
      id: id ?? this.id,
      scoreId: scoreId ?? this.scoreId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingsCompanion(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScoresTable scores = $ScoresTable(this);
  late final $ScorePagesTable scorePages = $ScorePagesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $JumpButtonsTable jumpButtons = $JumpButtonsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ScoreTagsTable scoreTags = $ScoreTagsTable(this);
  late final $SetlistsTable setlists = $SetlistsTable(this);
  late final $SetlistItemsTable setlistItems = $SetlistItemsTable(this);
  late final $InkStrokesTable inkStrokes = $InkStrokesTable(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  late final $RecordingsTable recordings = $RecordingsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scores,
    scorePages,
    bookmarks,
    jumpButtons,
    tags,
    scoreTags,
    setlists,
    setlistItems,
    inkStrokes,
    annotations,
    recordings,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('score_pages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bookmarks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('jump_buttons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('score_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('score_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'setlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('setlist_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('setlist_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ink_strokes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('annotations', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ScoresTableCreateCompanionBuilder =
    ScoresCompanion Function({
      required String id,
      required String title,
      Value<String?> artist,
      Value<String?> composer,
      Value<String?> genre,
      required String filePath,
      Value<String?> fileHash,
      Value<int> fileSize,
      Value<int> pageCount,
      Value<String?> pdfPassword,
      Value<String?> coverPath,
      Value<PageLayout?> layout,
      Value<TurnAnimation?> turnAnimation,
      Value<bool> startOnRight,
      Value<double> cropLeft,
      Value<double> cropTop,
      Value<double> cropRight,
      Value<double> cropBottom,
      Value<int?> autoScrollSeconds,
      Value<int> lastPage,
      Value<DateTime?> lastOpenedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ScoresTableUpdateCompanionBuilder =
    ScoresCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> artist,
      Value<String?> composer,
      Value<String?> genre,
      Value<String> filePath,
      Value<String?> fileHash,
      Value<int> fileSize,
      Value<int> pageCount,
      Value<String?> pdfPassword,
      Value<String?> coverPath,
      Value<PageLayout?> layout,
      Value<TurnAnimation?> turnAnimation,
      Value<bool> startOnRight,
      Value<double> cropLeft,
      Value<double> cropTop,
      Value<double> cropRight,
      Value<double> cropBottom,
      Value<int?> autoScrollSeconds,
      Value<int> lastPage,
      Value<DateTime?> lastOpenedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ScoresTableReferences
    extends BaseReferences<_$AppDatabase, $ScoresTable, Score> {
  $$ScoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScorePagesTable, List<ScorePage>>
  _scorePagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scorePages,
    aliasName: 'scores__id__score_pages__score_id',
  );

  $$ScorePagesTableProcessedTableManager get scorePagesRefs {
    final manager = $$ScorePagesTableTableManager(
      $_db,
      $_db.scorePages,
    ).filter((f) => f.scoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scorePagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'scores__id__bookmarks__score_id',
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.scoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JumpButtonsTable, List<JumpButton>>
  _jumpButtonsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.jumpButtons,
    aliasName: 'scores__id__jump_buttons__score_id',
  );

  $$JumpButtonsTableProcessedTableManager get jumpButtonsRefs {
    final manager = $$JumpButtonsTableTableManager(
      $_db,
      $_db.jumpButtons,
    ).filter((f) => f.scoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_jumpButtonsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScoreTagsTable, List<ScoreTag>>
  _scoreTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scoreTags,
    aliasName: 'scores__id__score_tags__score_id',
  );

  $$ScoreTagsTableProcessedTableManager get scoreTagsRefs {
    final manager = $$ScoreTagsTableTableManager(
      $_db,
      $_db.scoreTags,
    ).filter((f) => f.scoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scoreTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SetlistItemsTable, List<SetlistItem>>
  _setlistItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.setlistItems,
    aliasName: 'scores__id__setlist_items__score_id',
  );

  $$SetlistItemsTableProcessedTableManager get setlistItemsRefs {
    final manager = $$SetlistItemsTableTableManager(
      $_db,
      $_db.setlistItems,
    ).filter((f) => f.scoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_setlistItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InkStrokesTable, List<InkStroke>>
  _inkStrokesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inkStrokes,
    aliasName: 'scores__id__ink_strokes__score_id',
  );

  $$InkStrokesTableProcessedTableManager get inkStrokesRefs {
    final manager = $$InkStrokesTableTableManager(
      $_db,
      $_db.inkStrokes,
    ).filter((f) => f.scoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inkStrokesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AnnotationsTable, List<Annotation>>
  _annotationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.annotations,
    aliasName: 'scores__id__annotations__score_id',
  );

  $$AnnotationsTableProcessedTableManager get annotationsRefs {
    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.annotations,
    ).filter((f) => f.scoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScoresTableFilterComposer
    extends Composer<_$AppDatabase, $ScoresTable> {
  $$ScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfPassword => $composableBuilder(
    column: $table.pdfPassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PageLayout?, PageLayout, int> get layout =>
      $composableBuilder(
        column: $table.layout,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<TurnAnimation?, TurnAnimation, int>
  get turnAnimation => $composableBuilder(
    column: $table.turnAnimation,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get startOnRight => $composableBuilder(
    column: $table.startOnRight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropLeft => $composableBuilder(
    column: $table.cropLeft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropTop => $composableBuilder(
    column: $table.cropTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropRight => $composableBuilder(
    column: $table.cropRight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropBottom => $composableBuilder(
    column: $table.cropBottom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get autoScrollSeconds => $composableBuilder(
    column: $table.autoScrollSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scorePagesRefs(
    Expression<bool> Function($$ScorePagesTableFilterComposer f) f,
  ) {
    final $$ScorePagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scorePages,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScorePagesTableFilterComposer(
            $db: $db,
            $table: $db.scorePages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> jumpButtonsRefs(
    Expression<bool> Function($$JumpButtonsTableFilterComposer f) f,
  ) {
    final $$JumpButtonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jumpButtons,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JumpButtonsTableFilterComposer(
            $db: $db,
            $table: $db.jumpButtons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scoreTagsRefs(
    Expression<bool> Function($$ScoreTagsTableFilterComposer f) f,
  ) {
    final $$ScoreTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoreTags,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoreTagsTableFilterComposer(
            $db: $db,
            $table: $db.scoreTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> setlistItemsRefs(
    Expression<bool> Function($$SetlistItemsTableFilterComposer f) f,
  ) {
    final $$SetlistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setlistItems,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistItemsTableFilterComposer(
            $db: $db,
            $table: $db.setlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inkStrokesRefs(
    Expression<bool> Function($$InkStrokesTableFilterComposer f) f,
  ) {
    final $$InkStrokesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkStrokes,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkStrokesTableFilterComposer(
            $db: $db,
            $table: $db.inkStrokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> annotationsRefs(
    Expression<bool> Function($$AnnotationsTableFilterComposer f) f,
  ) {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ScoresTable> {
  $$ScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfPassword => $composableBuilder(
    column: $table.pdfPassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get turnAnimation => $composableBuilder(
    column: $table.turnAnimation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get startOnRight => $composableBuilder(
    column: $table.startOnRight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropLeft => $composableBuilder(
    column: $table.cropLeft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropTop => $composableBuilder(
    column: $table.cropTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropRight => $composableBuilder(
    column: $table.cropRight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropBottom => $composableBuilder(
    column: $table.cropBottom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get autoScrollSeconds => $composableBuilder(
    column: $table.autoScrollSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScoresTable> {
  $$ScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get composer =>
      $composableBuilder(column: $table.composer, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get pdfPassword => $composableBuilder(
    column: $table.pdfPassword,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PageLayout?, int> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TurnAnimation?, int> get turnAnimation =>
      $composableBuilder(
        column: $table.turnAnimation,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get startOnRight => $composableBuilder(
    column: $table.startOnRight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cropLeft =>
      $composableBuilder(column: $table.cropLeft, builder: (column) => column);

  GeneratedColumn<double> get cropTop =>
      $composableBuilder(column: $table.cropTop, builder: (column) => column);

  GeneratedColumn<double> get cropRight =>
      $composableBuilder(column: $table.cropRight, builder: (column) => column);

  GeneratedColumn<double> get cropBottom => $composableBuilder(
    column: $table.cropBottom,
    builder: (column) => column,
  );

  GeneratedColumn<int> get autoScrollSeconds => $composableBuilder(
    column: $table.autoScrollSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPage =>
      $composableBuilder(column: $table.lastPage, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> scorePagesRefs<T extends Object>(
    Expression<T> Function($$ScorePagesTableAnnotationComposer a) f,
  ) {
    final $$ScorePagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scorePages,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScorePagesTableAnnotationComposer(
            $db: $db,
            $table: $db.scorePages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> jumpButtonsRefs<T extends Object>(
    Expression<T> Function($$JumpButtonsTableAnnotationComposer a) f,
  ) {
    final $$JumpButtonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jumpButtons,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JumpButtonsTableAnnotationComposer(
            $db: $db,
            $table: $db.jumpButtons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scoreTagsRefs<T extends Object>(
    Expression<T> Function($$ScoreTagsTableAnnotationComposer a) f,
  ) {
    final $$ScoreTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoreTags,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoreTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.scoreTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> setlistItemsRefs<T extends Object>(
    Expression<T> Function($$SetlistItemsTableAnnotationComposer a) f,
  ) {
    final $$SetlistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setlistItems,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.setlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inkStrokesRefs<T extends Object>(
    Expression<T> Function($$InkStrokesTableAnnotationComposer a) f,
  ) {
    final $$InkStrokesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkStrokes,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkStrokesTableAnnotationComposer(
            $db: $db,
            $table: $db.inkStrokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> annotationsRefs<T extends Object>(
    Expression<T> Function($$AnnotationsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScoresTable,
          Score,
          $$ScoresTableFilterComposer,
          $$ScoresTableOrderingComposer,
          $$ScoresTableAnnotationComposer,
          $$ScoresTableCreateCompanionBuilder,
          $$ScoresTableUpdateCompanionBuilder,
          (Score, $$ScoresTableReferences),
          Score,
          PrefetchHooks Function({
            bool scorePagesRefs,
            bool bookmarksRefs,
            bool jumpButtonsRefs,
            bool scoreTagsRefs,
            bool setlistItemsRefs,
            bool inkStrokesRefs,
            bool annotationsRefs,
          })
        > {
  $$ScoresTableTableManager(_$AppDatabase db, $ScoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> composer = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<String?> pdfPassword = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<PageLayout?> layout = const Value.absent(),
                Value<TurnAnimation?> turnAnimation = const Value.absent(),
                Value<bool> startOnRight = const Value.absent(),
                Value<double> cropLeft = const Value.absent(),
                Value<double> cropTop = const Value.absent(),
                Value<double> cropRight = const Value.absent(),
                Value<double> cropBottom = const Value.absent(),
                Value<int?> autoScrollSeconds = const Value.absent(),
                Value<int> lastPage = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresCompanion(
                id: id,
                title: title,
                artist: artist,
                composer: composer,
                genre: genre,
                filePath: filePath,
                fileHash: fileHash,
                fileSize: fileSize,
                pageCount: pageCount,
                pdfPassword: pdfPassword,
                coverPath: coverPath,
                layout: layout,
                turnAnimation: turnAnimation,
                startOnRight: startOnRight,
                cropLeft: cropLeft,
                cropTop: cropTop,
                cropRight: cropRight,
                cropBottom: cropBottom,
                autoScrollSeconds: autoScrollSeconds,
                lastPage: lastPage,
                lastOpenedAt: lastOpenedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> artist = const Value.absent(),
                Value<String?> composer = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                required String filePath,
                Value<String?> fileHash = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<String?> pdfPassword = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<PageLayout?> layout = const Value.absent(),
                Value<TurnAnimation?> turnAnimation = const Value.absent(),
                Value<bool> startOnRight = const Value.absent(),
                Value<double> cropLeft = const Value.absent(),
                Value<double> cropTop = const Value.absent(),
                Value<double> cropRight = const Value.absent(),
                Value<double> cropBottom = const Value.absent(),
                Value<int?> autoScrollSeconds = const Value.absent(),
                Value<int> lastPage = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresCompanion.insert(
                id: id,
                title: title,
                artist: artist,
                composer: composer,
                genre: genre,
                filePath: filePath,
                fileHash: fileHash,
                fileSize: fileSize,
                pageCount: pageCount,
                pdfPassword: pdfPassword,
                coverPath: coverPath,
                layout: layout,
                turnAnimation: turnAnimation,
                startOnRight: startOnRight,
                cropLeft: cropLeft,
                cropTop: cropTop,
                cropRight: cropRight,
                cropBottom: cropBottom,
                autoScrollSeconds: autoScrollSeconds,
                lastPage: lastPage,
                lastOpenedAt: lastOpenedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScoresTable, Score>(table),
                  $$ScoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                scorePagesRefs = false,
                bookmarksRefs = false,
                jumpButtonsRefs = false,
                scoreTagsRefs = false,
                setlistItemsRefs = false,
                inkStrokesRefs = false,
                annotationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scorePagesRefs) db.scorePages,
                    if (bookmarksRefs) db.bookmarks,
                    if (jumpButtonsRefs) db.jumpButtons,
                    if (scoreTagsRefs) db.scoreTags,
                    if (setlistItemsRefs) db.setlistItems,
                    if (inkStrokesRefs) db.inkStrokes,
                    if (annotationsRefs) db.annotations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scorePagesRefs)
                        await $_getPrefetchedData<
                          Score,
                          $ScoresTable,
                          ScorePage
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableReferences
                              ._scorePagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).scorePagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedData<
                          Score,
                          $ScoresTable,
                          Bookmark
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (jumpButtonsRefs)
                        await $_getPrefetchedData<
                          Score,
                          $ScoresTable,
                          JumpButton
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableReferences
                              ._jumpButtonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).jumpButtonsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scoreTagsRefs)
                        await $_getPrefetchedData<
                          Score,
                          $ScoresTable,
                          ScoreTag
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableReferences
                              ._scoreTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).scoreTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (setlistItemsRefs)
                        await $_getPrefetchedData<
                          Score,
                          $ScoresTable,
                          SetlistItem
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableReferences
                              ._setlistItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).setlistItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inkStrokesRefs)
                        await $_getPrefetchedData<
                          Score,
                          $ScoresTable,
                          InkStroke
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableReferences
                              ._inkStrokesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).inkStrokesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (annotationsRefs)
                        await $_getPrefetchedData<
                          Score,
                          $ScoresTable,
                          Annotation
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableReferences
                              ._annotationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).annotationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoreId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScoresTable,
      Score,
      $$ScoresTableFilterComposer,
      $$ScoresTableOrderingComposer,
      $$ScoresTableAnnotationComposer,
      $$ScoresTableCreateCompanionBuilder,
      $$ScoresTableUpdateCompanionBuilder,
      (Score, $$ScoresTableReferences),
      Score,
      PrefetchHooks Function({
        bool scorePagesRefs,
        bool bookmarksRefs,
        bool jumpButtonsRefs,
        bool scoreTagsRefs,
        bool setlistItemsRefs,
        bool inkStrokesRefs,
        bool annotationsRefs,
      })
    >;
typedef $$ScorePagesTableCreateCompanionBuilder =
    ScorePagesCompanion Function({
      required String id,
      required String scoreId,
      required int sourceIndex,
      required int displayOrder,
      Value<bool> hidden,
      Value<double> rotation,
      Value<double?> cropLeft,
      Value<double?> cropTop,
      Value<double?> cropRight,
      Value<double?> cropBottom,
      Value<int> rowid,
    });
typedef $$ScorePagesTableUpdateCompanionBuilder =
    ScorePagesCompanion Function({
      Value<String> id,
      Value<String> scoreId,
      Value<int> sourceIndex,
      Value<int> displayOrder,
      Value<bool> hidden,
      Value<double> rotation,
      Value<double?> cropLeft,
      Value<double?> cropTop,
      Value<double?> cropRight,
      Value<double?> cropBottom,
      Value<int> rowid,
    });

final class $$ScorePagesTableReferences
    extends BaseReferences<_$AppDatabase, $ScorePagesTable, ScorePage> {
  $$ScorePagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScoresTable _scoreIdTable(_$AppDatabase db) =>
      db.scores.createAlias('score_pages__score_id__scores__id');

  $$ScoresTableProcessedTableManager get scoreId {
    final $_column = $_itemColumn<String>('score_id')!;

    final manager = $$ScoresTableTableManager(
      $_db,
      $_db.scores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScorePagesTableFilterComposer
    extends Composer<_$AppDatabase, $ScorePagesTable> {
  $$ScorePagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceIndex => $composableBuilder(
    column: $table.sourceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropLeft => $composableBuilder(
    column: $table.cropLeft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropTop => $composableBuilder(
    column: $table.cropTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropRight => $composableBuilder(
    column: $table.cropRight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cropBottom => $composableBuilder(
    column: $table.cropBottom,
    builder: (column) => ColumnFilters(column),
  );

  $$ScoresTableFilterComposer get scoreId {
    final $$ScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableFilterComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScorePagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScorePagesTable> {
  $$ScorePagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceIndex => $composableBuilder(
    column: $table.sourceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropLeft => $composableBuilder(
    column: $table.cropLeft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropTop => $composableBuilder(
    column: $table.cropTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropRight => $composableBuilder(
    column: $table.cropRight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cropBottom => $composableBuilder(
    column: $table.cropBottom,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScoresTableOrderingComposer get scoreId {
    final $$ScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableOrderingComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScorePagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScorePagesTable> {
  $$ScorePagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sourceIndex => $composableBuilder(
    column: $table.sourceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<double> get cropLeft =>
      $composableBuilder(column: $table.cropLeft, builder: (column) => column);

  GeneratedColumn<double> get cropTop =>
      $composableBuilder(column: $table.cropTop, builder: (column) => column);

  GeneratedColumn<double> get cropRight =>
      $composableBuilder(column: $table.cropRight, builder: (column) => column);

  GeneratedColumn<double> get cropBottom => $composableBuilder(
    column: $table.cropBottom,
    builder: (column) => column,
  );

  $$ScoresTableAnnotationComposer get scoreId {
    final $$ScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScorePagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScorePagesTable,
          ScorePage,
          $$ScorePagesTableFilterComposer,
          $$ScorePagesTableOrderingComposer,
          $$ScorePagesTableAnnotationComposer,
          $$ScorePagesTableCreateCompanionBuilder,
          $$ScorePagesTableUpdateCompanionBuilder,
          (ScorePage, $$ScorePagesTableReferences),
          ScorePage,
          PrefetchHooks Function({bool scoreId})
        > {
  $$ScorePagesTableTableManager(_$AppDatabase db, $ScorePagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScorePagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScorePagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScorePagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scoreId = const Value.absent(),
                Value<int> sourceIndex = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<double?> cropLeft = const Value.absent(),
                Value<double?> cropTop = const Value.absent(),
                Value<double?> cropRight = const Value.absent(),
                Value<double?> cropBottom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScorePagesCompanion(
                id: id,
                scoreId: scoreId,
                sourceIndex: sourceIndex,
                displayOrder: displayOrder,
                hidden: hidden,
                rotation: rotation,
                cropLeft: cropLeft,
                cropTop: cropTop,
                cropRight: cropRight,
                cropBottom: cropBottom,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scoreId,
                required int sourceIndex,
                required int displayOrder,
                Value<bool> hidden = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<double?> cropLeft = const Value.absent(),
                Value<double?> cropTop = const Value.absent(),
                Value<double?> cropRight = const Value.absent(),
                Value<double?> cropBottom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScorePagesCompanion.insert(
                id: id,
                scoreId: scoreId,
                sourceIndex: sourceIndex,
                displayOrder: displayOrder,
                hidden: hidden,
                rotation: rotation,
                cropLeft: cropLeft,
                cropTop: cropTop,
                cropRight: cropRight,
                cropBottom: cropBottom,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScorePagesTable, ScorePage>(table),
                  $$ScorePagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scoreId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scoreId,
                                referencedTable: $$ScorePagesTableReferences
                                    ._scoreIdTable(db),
                                referencedColumn: $$ScorePagesTableReferences
                                    ._scoreIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScorePagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScorePagesTable,
      ScorePage,
      $$ScorePagesTableFilterComposer,
      $$ScorePagesTableOrderingComposer,
      $$ScorePagesTableAnnotationComposer,
      $$ScorePagesTableCreateCompanionBuilder,
      $$ScorePagesTableUpdateCompanionBuilder,
      (ScorePage, $$ScorePagesTableReferences),
      ScorePage,
      PrefetchHooks Function({bool scoreId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      required String scoreId,
      required int page,
      required String label,
      Value<int> depth,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<String> scoreId,
      Value<int> page,
      Value<String> label,
      Value<int> depth,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScoresTable _scoreIdTable(_$AppDatabase db) =>
      db.scores.createAlias('bookmarks__score_id__scores__id');

  $$ScoresTableProcessedTableManager get scoreId {
    final $_column = $_itemColumn<String>('score_id')!;

    final manager = $$ScoresTableTableManager(
      $_db,
      $_db.scores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$ScoresTableFilterComposer get scoreId {
    final $$ScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableFilterComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScoresTableOrderingComposer get scoreId {
    final $$ScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableOrderingComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get depth =>
      $composableBuilder(column: $table.depth, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ScoresTableAnnotationComposer get scoreId {
    final $$ScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, $$BookmarksTableReferences),
          Bookmark,
          PrefetchHooks Function({bool scoreId})
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scoreId = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> depth = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                scoreId: scoreId,
                page: page,
                label: label,
                depth: depth,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scoreId,
                required int page,
                required String label,
                Value<int> depth = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                scoreId: scoreId,
                page: page,
                label: label,
                depth: depth,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarksTable, Bookmark>(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scoreId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scoreId,
                                referencedTable: $$BookmarksTableReferences
                                    ._scoreIdTable(db),
                                referencedColumn: $$BookmarksTableReferences
                                    ._scoreIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, $$BookmarksTableReferences),
      Bookmark,
      PrefetchHooks Function({bool scoreId})
    >;
typedef $$JumpButtonsTableCreateCompanionBuilder =
    JumpButtonsCompanion Function({
      required String id,
      required String scoreId,
      required int fromPage,
      required double x,
      required double y,
      required int toPage,
      Value<String?> label,
      Value<int> rowid,
    });
typedef $$JumpButtonsTableUpdateCompanionBuilder =
    JumpButtonsCompanion Function({
      Value<String> id,
      Value<String> scoreId,
      Value<int> fromPage,
      Value<double> x,
      Value<double> y,
      Value<int> toPage,
      Value<String?> label,
      Value<int> rowid,
    });

final class $$JumpButtonsTableReferences
    extends BaseReferences<_$AppDatabase, $JumpButtonsTable, JumpButton> {
  $$JumpButtonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScoresTable _scoreIdTable(_$AppDatabase db) =>
      db.scores.createAlias('jump_buttons__score_id__scores__id');

  $$ScoresTableProcessedTableManager get scoreId {
    final $_column = $_itemColumn<String>('score_id')!;

    final manager = $$ScoresTableTableManager(
      $_db,
      $_db.scores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JumpButtonsTableFilterComposer
    extends Composer<_$AppDatabase, $JumpButtonsTable> {
  $$JumpButtonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromPage => $composableBuilder(
    column: $table.fromPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toPage => $composableBuilder(
    column: $table.toPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  $$ScoresTableFilterComposer get scoreId {
    final $$ScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableFilterComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JumpButtonsTableOrderingComposer
    extends Composer<_$AppDatabase, $JumpButtonsTable> {
  $$JumpButtonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromPage => $composableBuilder(
    column: $table.fromPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toPage => $composableBuilder(
    column: $table.toPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScoresTableOrderingComposer get scoreId {
    final $$ScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableOrderingComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JumpButtonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JumpButtonsTable> {
  $$JumpButtonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get fromPage =>
      $composableBuilder(column: $table.fromPage, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<int> get toPage =>
      $composableBuilder(column: $table.toPage, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  $$ScoresTableAnnotationComposer get scoreId {
    final $$ScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JumpButtonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JumpButtonsTable,
          JumpButton,
          $$JumpButtonsTableFilterComposer,
          $$JumpButtonsTableOrderingComposer,
          $$JumpButtonsTableAnnotationComposer,
          $$JumpButtonsTableCreateCompanionBuilder,
          $$JumpButtonsTableUpdateCompanionBuilder,
          (JumpButton, $$JumpButtonsTableReferences),
          JumpButton,
          PrefetchHooks Function({bool scoreId})
        > {
  $$JumpButtonsTableTableManager(_$AppDatabase db, $JumpButtonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JumpButtonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JumpButtonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JumpButtonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scoreId = const Value.absent(),
                Value<int> fromPage = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<int> toPage = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JumpButtonsCompanion(
                id: id,
                scoreId: scoreId,
                fromPage: fromPage,
                x: x,
                y: y,
                toPage: toPage,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scoreId,
                required int fromPage,
                required double x,
                required double y,
                required int toPage,
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JumpButtonsCompanion.insert(
                id: id,
                scoreId: scoreId,
                fromPage: fromPage,
                x: x,
                y: y,
                toPage: toPage,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JumpButtonsTable, JumpButton>(table),
                  $$JumpButtonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scoreId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scoreId,
                                referencedTable: $$JumpButtonsTableReferences
                                    ._scoreIdTable(db),
                                referencedColumn: $$JumpButtonsTableReferences
                                    ._scoreIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$JumpButtonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JumpButtonsTable,
      JumpButton,
      $$JumpButtonsTableFilterComposer,
      $$JumpButtonsTableOrderingComposer,
      $$JumpButtonsTableAnnotationComposer,
      $$JumpButtonsTableCreateCompanionBuilder,
      $$JumpButtonsTableUpdateCompanionBuilder,
      (JumpButton, $$JumpButtonsTableReferences),
      JumpButton,
      PrefetchHooks Function({bool scoreId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      Value<int?> color,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int?> color,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScoreTagsTable, List<ScoreTag>>
  _scoreTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scoreTags,
    aliasName: 'tags__id__score_tags__tag_id',
  );

  $$ScoreTagsTableProcessedTableManager get scoreTagsRefs {
    final manager = $$ScoreTagsTableTableManager(
      $_db,
      $_db.scoreTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scoreTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scoreTagsRefs(
    Expression<bool> Function($$ScoreTagsTableFilterComposer f) f,
  ) {
    final $$ScoreTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoreTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoreTagsTableFilterComposer(
            $db: $db,
            $table: $db.scoreTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> scoreTagsRefs<T extends Object>(
    Expression<T> Function($$ScoreTagsTableAnnotationComposer a) f,
  ) {
    final $$ScoreTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoreTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoreTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.scoreTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool scoreTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scoreTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (scoreTagsRefs) db.scoreTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scoreTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, ScoreTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._scoreTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).scoreTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool scoreTagsRefs})
    >;
typedef $$ScoreTagsTableCreateCompanionBuilder =
    ScoreTagsCompanion Function({
      required String scoreId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$ScoreTagsTableUpdateCompanionBuilder =
    ScoreTagsCompanion Function({
      Value<String> scoreId,
      Value<String> tagId,
      Value<int> rowid,
    });

final class $$ScoreTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ScoreTagsTable, ScoreTag> {
  $$ScoreTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScoresTable _scoreIdTable(_$AppDatabase db) =>
      db.scores.createAlias('score_tags__score_id__scores__id');

  $$ScoresTableProcessedTableManager get scoreId {
    final $_column = $_itemColumn<String>('score_id')!;

    final manager = $$ScoresTableTableManager(
      $_db,
      $_db.scores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('score_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScoreTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ScoreTagsTable> {
  $$ScoreTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ScoresTableFilterComposer get scoreId {
    final $$ScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableFilterComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScoreTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScoreTagsTable> {
  $$ScoreTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ScoresTableOrderingComposer get scoreId {
    final $$ScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableOrderingComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScoreTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScoreTagsTable> {
  $$ScoreTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ScoresTableAnnotationComposer get scoreId {
    final $$ScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScoreTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScoreTagsTable,
          ScoreTag,
          $$ScoreTagsTableFilterComposer,
          $$ScoreTagsTableOrderingComposer,
          $$ScoreTagsTableAnnotationComposer,
          $$ScoreTagsTableCreateCompanionBuilder,
          $$ScoreTagsTableUpdateCompanionBuilder,
          (ScoreTag, $$ScoreTagsTableReferences),
          ScoreTag,
          PrefetchHooks Function({bool scoreId, bool tagId})
        > {
  $$ScoreTagsTableTableManager(_$AppDatabase db, $ScoreTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoreTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoreTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoreTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scoreId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoreTagsCompanion(
                scoreId: scoreId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scoreId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => ScoreTagsCompanion.insert(
                scoreId: scoreId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScoreTagsTable, ScoreTag>(table),
                  $$ScoreTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scoreId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scoreId,
                                referencedTable: $$ScoreTagsTableReferences
                                    ._scoreIdTable(db),
                                referencedColumn: $$ScoreTagsTableReferences
                                    ._scoreIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$ScoreTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$ScoreTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScoreTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScoreTagsTable,
      ScoreTag,
      $$ScoreTagsTableFilterComposer,
      $$ScoreTagsTableOrderingComposer,
      $$ScoreTagsTableAnnotationComposer,
      $$ScoreTagsTableCreateCompanionBuilder,
      $$ScoreTagsTableUpdateCompanionBuilder,
      (ScoreTag, $$ScoreTagsTableReferences),
      ScoreTag,
      PrefetchHooks Function({bool scoreId, bool tagId})
    >;
typedef $$SetlistsTableCreateCompanionBuilder =
    SetlistsCompanion Function({
      required String id,
      required String name,
      Value<String?> note,
      Value<DateTime?> performedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SetlistsTableUpdateCompanionBuilder =
    SetlistsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> note,
      Value<DateTime?> performedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SetlistsTableReferences
    extends BaseReferences<_$AppDatabase, $SetlistsTable, Setlist> {
  $$SetlistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SetlistItemsTable, List<SetlistItem>>
  _setlistItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.setlistItems,
    aliasName: 'setlists__id__setlist_items__setlist_id',
  );

  $$SetlistItemsTableProcessedTableManager get setlistItemsRefs {
    final manager = $$SetlistItemsTableTableManager(
      $_db,
      $_db.setlistItems,
    ).filter((f) => f.setlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_setlistItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SetlistsTableFilterComposer
    extends Composer<_$AppDatabase, $SetlistsTable> {
  $$SetlistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> setlistItemsRefs(
    Expression<bool> Function($$SetlistItemsTableFilterComposer f) f,
  ) {
    final $$SetlistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setlistItems,
      getReferencedColumn: (t) => t.setlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistItemsTableFilterComposer(
            $db: $db,
            $table: $db.setlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SetlistsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetlistsTable> {
  $$SetlistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SetlistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetlistsTable> {
  $$SetlistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> setlistItemsRefs<T extends Object>(
    Expression<T> Function($$SetlistItemsTableAnnotationComposer a) f,
  ) {
    final $$SetlistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setlistItems,
      getReferencedColumn: (t) => t.setlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.setlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SetlistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetlistsTable,
          Setlist,
          $$SetlistsTableFilterComposer,
          $$SetlistsTableOrderingComposer,
          $$SetlistsTableAnnotationComposer,
          $$SetlistsTableCreateCompanionBuilder,
          $$SetlistsTableUpdateCompanionBuilder,
          (Setlist, $$SetlistsTableReferences),
          Setlist,
          PrefetchHooks Function({bool setlistItemsRefs})
        > {
  $$SetlistsTableTableManager(_$AppDatabase db, $SetlistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetlistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetlistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetlistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> performedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistsCompanion(
                id: id,
                name: name,
                note: note,
                performedAt: performedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> note = const Value.absent(),
                Value<DateTime?> performedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistsCompanion.insert(
                id: id,
                name: name,
                note: note,
                performedAt: performedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SetlistsTable, Setlist>(table),
                  $$SetlistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setlistItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (setlistItemsRefs) db.setlistItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (setlistItemsRefs)
                    await $_getPrefetchedData<
                      Setlist,
                      $SetlistsTable,
                      SetlistItem
                    >(
                      currentTable: table,
                      referencedTable: $$SetlistsTableReferences
                          ._setlistItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SetlistsTableReferences(
                        db,
                        table,
                        p0,
                      ).setlistItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.setlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SetlistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetlistsTable,
      Setlist,
      $$SetlistsTableFilterComposer,
      $$SetlistsTableOrderingComposer,
      $$SetlistsTableAnnotationComposer,
      $$SetlistsTableCreateCompanionBuilder,
      $$SetlistsTableUpdateCompanionBuilder,
      (Setlist, $$SetlistsTableReferences),
      Setlist,
      PrefetchHooks Function({bool setlistItemsRefs})
    >;
typedef $$SetlistItemsTableCreateCompanionBuilder =
    SetlistItemsCompanion Function({
      required String id,
      required String setlistId,
      required String scoreId,
      required int sortOrder,
      Value<int?> startPage,
      Value<int?> endPage,
      Value<int> rowid,
    });
typedef $$SetlistItemsTableUpdateCompanionBuilder =
    SetlistItemsCompanion Function({
      Value<String> id,
      Value<String> setlistId,
      Value<String> scoreId,
      Value<int> sortOrder,
      Value<int?> startPage,
      Value<int?> endPage,
      Value<int> rowid,
    });

final class $$SetlistItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SetlistItemsTable, SetlistItem> {
  $$SetlistItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SetlistsTable _setlistIdTable(_$AppDatabase db) =>
      db.setlists.createAlias('setlist_items__setlist_id__setlists__id');

  $$SetlistsTableProcessedTableManager get setlistId {
    final $_column = $_itemColumn<String>('setlist_id')!;

    final manager = $$SetlistsTableTableManager(
      $_db,
      $_db.setlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_setlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ScoresTable _scoreIdTable(_$AppDatabase db) =>
      db.scores.createAlias('setlist_items__score_id__scores__id');

  $$ScoresTableProcessedTableManager get scoreId {
    final $_column = $_itemColumn<String>('score_id')!;

    final manager = $$ScoresTableTableManager(
      $_db,
      $_db.scores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetlistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SetlistItemsTable> {
  $$SetlistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnFilters(column),
  );

  $$SetlistsTableFilterComposer get setlistId {
    final $$SetlistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setlistId,
      referencedTable: $db.setlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistsTableFilterComposer(
            $db: $db,
            $table: $db.setlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoresTableFilterComposer get scoreId {
    final $$ScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableFilterComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetlistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetlistItemsTable> {
  $$SetlistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnOrderings(column),
  );

  $$SetlistsTableOrderingComposer get setlistId {
    final $$SetlistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setlistId,
      referencedTable: $db.setlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistsTableOrderingComposer(
            $db: $db,
            $table: $db.setlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoresTableOrderingComposer get scoreId {
    final $$ScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableOrderingComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetlistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetlistItemsTable> {
  $$SetlistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get startPage =>
      $composableBuilder(column: $table.startPage, builder: (column) => column);

  GeneratedColumn<int> get endPage =>
      $composableBuilder(column: $table.endPage, builder: (column) => column);

  $$SetlistsTableAnnotationComposer get setlistId {
    final $$SetlistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setlistId,
      referencedTable: $db.setlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistsTableAnnotationComposer(
            $db: $db,
            $table: $db.setlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoresTableAnnotationComposer get scoreId {
    final $$ScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetlistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetlistItemsTable,
          SetlistItem,
          $$SetlistItemsTableFilterComposer,
          $$SetlistItemsTableOrderingComposer,
          $$SetlistItemsTableAnnotationComposer,
          $$SetlistItemsTableCreateCompanionBuilder,
          $$SetlistItemsTableUpdateCompanionBuilder,
          (SetlistItem, $$SetlistItemsTableReferences),
          SetlistItem,
          PrefetchHooks Function({bool setlistId, bool scoreId})
        > {
  $$SetlistItemsTableTableManager(_$AppDatabase db, $SetlistItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetlistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetlistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetlistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> setlistId = const Value.absent(),
                Value<String> scoreId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int?> startPage = const Value.absent(),
                Value<int?> endPage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistItemsCompanion(
                id: id,
                setlistId: setlistId,
                scoreId: scoreId,
                sortOrder: sortOrder,
                startPage: startPage,
                endPage: endPage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String setlistId,
                required String scoreId,
                required int sortOrder,
                Value<int?> startPage = const Value.absent(),
                Value<int?> endPage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistItemsCompanion.insert(
                id: id,
                setlistId: setlistId,
                scoreId: scoreId,
                sortOrder: sortOrder,
                startPage: startPage,
                endPage: endPage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SetlistItemsTable, SetlistItem>(table),
                  $$SetlistItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setlistId = false, scoreId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (setlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.setlistId,
                                referencedTable: $$SetlistItemsTableReferences
                                    ._setlistIdTable(db),
                                referencedColumn: $$SetlistItemsTableReferences
                                    ._setlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (scoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scoreId,
                                referencedTable: $$SetlistItemsTableReferences
                                    ._scoreIdTable(db),
                                referencedColumn: $$SetlistItemsTableReferences
                                    ._scoreIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SetlistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetlistItemsTable,
      SetlistItem,
      $$SetlistItemsTableFilterComposer,
      $$SetlistItemsTableOrderingComposer,
      $$SetlistItemsTableAnnotationComposer,
      $$SetlistItemsTableCreateCompanionBuilder,
      $$SetlistItemsTableUpdateCompanionBuilder,
      (SetlistItem, $$SetlistItemsTableReferences),
      SetlistItem,
      PrefetchHooks Function({bool setlistId, bool scoreId})
    >;
typedef $$InkStrokesTableCreateCompanionBuilder =
    InkStrokesCompanion Function({
      required String id,
      required String scoreId,
      required int page,
      Value<InkFormat> format,
      Value<StrokeTool> tool,
      Value<int> color,
      Value<double> width,
      required Uint8List data,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$InkStrokesTableUpdateCompanionBuilder =
    InkStrokesCompanion Function({
      Value<String> id,
      Value<String> scoreId,
      Value<int> page,
      Value<InkFormat> format,
      Value<StrokeTool> tool,
      Value<int> color,
      Value<double> width,
      Value<Uint8List> data,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$InkStrokesTableReferences
    extends BaseReferences<_$AppDatabase, $InkStrokesTable, InkStroke> {
  $$InkStrokesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScoresTable _scoreIdTable(_$AppDatabase db) =>
      db.scores.createAlias('ink_strokes__score_id__scores__id');

  $$ScoresTableProcessedTableManager get scoreId {
    final $_column = $_itemColumn<String>('score_id')!;

    final manager = $$ScoresTableTableManager(
      $_db,
      $_db.scores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InkStrokesTableFilterComposer
    extends Composer<_$AppDatabase, $InkStrokesTable> {
  $$InkStrokesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<InkFormat, InkFormat, int> get format =>
      $composableBuilder(
        column: $table.format,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<StrokeTool, StrokeTool, int> get tool =>
      $composableBuilder(
        column: $table.tool,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScoresTableFilterComposer get scoreId {
    final $$ScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableFilterComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkStrokesTableOrderingComposer
    extends Composer<_$AppDatabase, $InkStrokesTable> {
  $$InkStrokesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tool => $composableBuilder(
    column: $table.tool,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScoresTableOrderingComposer get scoreId {
    final $$ScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableOrderingComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkStrokesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InkStrokesTable> {
  $$InkStrokesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumnWithTypeConverter<InkFormat, int> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StrokeTool, int> get tool =>
      $composableBuilder(column: $table.tool, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ScoresTableAnnotationComposer get scoreId {
    final $$ScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkStrokesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InkStrokesTable,
          InkStroke,
          $$InkStrokesTableFilterComposer,
          $$InkStrokesTableOrderingComposer,
          $$InkStrokesTableAnnotationComposer,
          $$InkStrokesTableCreateCompanionBuilder,
          $$InkStrokesTableUpdateCompanionBuilder,
          (InkStroke, $$InkStrokesTableReferences),
          InkStroke,
          PrefetchHooks Function({bool scoreId})
        > {
  $$InkStrokesTableTableManager(_$AppDatabase db, $InkStrokesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InkStrokesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InkStrokesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InkStrokesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scoreId = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<InkFormat> format = const Value.absent(),
                Value<StrokeTool> tool = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<Uint8List> data = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InkStrokesCompanion(
                id: id,
                scoreId: scoreId,
                page: page,
                format: format,
                tool: tool,
                color: color,
                width: width,
                data: data,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scoreId,
                required int page,
                Value<InkFormat> format = const Value.absent(),
                Value<StrokeTool> tool = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<double> width = const Value.absent(),
                required Uint8List data,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InkStrokesCompanion.insert(
                id: id,
                scoreId: scoreId,
                page: page,
                format: format,
                tool: tool,
                color: color,
                width: width,
                data: data,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InkStrokesTable, InkStroke>(table),
                  $$InkStrokesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scoreId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scoreId,
                                referencedTable: $$InkStrokesTableReferences
                                    ._scoreIdTable(db),
                                referencedColumn: $$InkStrokesTableReferences
                                    ._scoreIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InkStrokesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InkStrokesTable,
      InkStroke,
      $$InkStrokesTableFilterComposer,
      $$InkStrokesTableOrderingComposer,
      $$InkStrokesTableAnnotationComposer,
      $$InkStrokesTableCreateCompanionBuilder,
      $$InkStrokesTableUpdateCompanionBuilder,
      (InkStroke, $$InkStrokesTableReferences),
      InkStroke,
      PrefetchHooks Function({bool scoreId})
    >;
typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      required String id,
      required String scoreId,
      required int page,
      required String kind,
      required String value,
      required double x,
      required double y,
      Value<double> scale,
      Value<double> rotation,
      Value<int> color,
      Value<double?> fontSize,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<String> id,
      Value<String> scoreId,
      Value<int> page,
      Value<String> kind,
      Value<String> value,
      Value<double> x,
      Value<double> y,
      Value<double> scale,
      Value<double> rotation,
      Value<int> color,
      Value<double?> fontSize,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$AnnotationsTableReferences
    extends BaseReferences<_$AppDatabase, $AnnotationsTable, Annotation> {
  $$AnnotationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScoresTable _scoreIdTable(_$AppDatabase db) =>
      db.scores.createAlias('annotations__score_id__scores__id');

  $$ScoresTableProcessedTableManager get scoreId {
    final $_column = $_itemColumn<String>('score_id')!;

    final manager = $$ScoresTableTableManager(
      $_db,
      $_db.scores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fontSize => $composableBuilder(
    column: $table.fontSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$ScoresTableFilterComposer get scoreId {
    final $$ScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableFilterComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fontSize => $composableBuilder(
    column: $table.fontSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScoresTableOrderingComposer get scoreId {
    final $$ScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableOrderingComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get fontSize =>
      $composableBuilder(column: $table.fontSize, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ScoresTableAnnotationComposer get scoreId {
    final $$ScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationsTable,
          Annotation,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (Annotation, $$AnnotationsTableReferences),
          Annotation,
          PrefetchHooks Function({bool scoreId})
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scoreId = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> scale = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<double?> fontSize = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                scoreId: scoreId,
                page: page,
                kind: kind,
                value: value,
                x: x,
                y: y,
                scale: scale,
                rotation: rotation,
                color: color,
                fontSize: fontSize,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scoreId,
                required int page,
                required String kind,
                required String value,
                required double x,
                required double y,
                Value<double> scale = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<double?> fontSize = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion.insert(
                id: id,
                scoreId: scoreId,
                page: page,
                kind: kind,
                value: value,
                x: x,
                y: y,
                scale: scale,
                rotation: rotation,
                color: color,
                fontSize: fontSize,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AnnotationsTable, Annotation>(table),
                  $$AnnotationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scoreId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scoreId,
                                referencedTable: $$AnnotationsTableReferences
                                    ._scoreIdTable(db),
                                referencedColumn: $$AnnotationsTableReferences
                                    ._scoreIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationsTable,
      Annotation,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (Annotation, $$AnnotationsTableReferences),
      Annotation,
      PrefetchHooks Function({bool scoreId})
    >;
typedef $$RecordingsTableCreateCompanionBuilder =
    RecordingsCompanion Function({
      required String id,
      Value<String?> scoreId,
      required String title,
      required String filePath,
      Value<int> durationMs,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$RecordingsTableUpdateCompanionBuilder =
    RecordingsCompanion Function({
      Value<String> id,
      Value<String?> scoreId,
      Value<String> title,
      Value<String> filePath,
      Value<int> durationMs,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$RecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoreId => $composableBuilder(
    column: $table.scoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoreId => $composableBuilder(
    column: $table.scoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scoreId =>
      $composableBuilder(column: $table.scoreId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordingsTable,
          Recording,
          $$RecordingsTableFilterComposer,
          $$RecordingsTableOrderingComposer,
          $$RecordingsTableAnnotationComposer,
          $$RecordingsTableCreateCompanionBuilder,
          $$RecordingsTableUpdateCompanionBuilder,
          (
            Recording,
            BaseReferences<_$AppDatabase, $RecordingsTable, Recording>,
          ),
          Recording,
          PrefetchHooks Function()
        > {
  $$RecordingsTableTableManager(_$AppDatabase db, $RecordingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> scoreId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordingsCompanion(
                id: id,
                scoreId: scoreId,
                title: title,
                filePath: filePath,
                durationMs: durationMs,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> scoreId = const Value.absent(),
                required String title,
                required String filePath,
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordingsCompanion.insert(
                id: id,
                scoreId: scoreId,
                title: title,
                filePath: filePath,
                durationMs: durationMs,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecordingsTable, Recording>(table),
                  BaseReferences<_$AppDatabase, $RecordingsTable, Recording>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordingsTable,
      Recording,
      $$RecordingsTableFilterComposer,
      $$RecordingsTableOrderingComposer,
      $$RecordingsTableAnnotationComposer,
      $$RecordingsTableCreateCompanionBuilder,
      $$RecordingsTableUpdateCompanionBuilder,
      (Recording, BaseReferences<_$AppDatabase, $RecordingsTable, Recording>),
      Recording,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScoresTableTableManager get scores =>
      $$ScoresTableTableManager(_db, _db.scores);
  $$ScorePagesTableTableManager get scorePages =>
      $$ScorePagesTableTableManager(_db, _db.scorePages);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$JumpButtonsTableTableManager get jumpButtons =>
      $$JumpButtonsTableTableManager(_db, _db.jumpButtons);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$ScoreTagsTableTableManager get scoreTags =>
      $$ScoreTagsTableTableManager(_db, _db.scoreTags);
  $$SetlistsTableTableManager get setlists =>
      $$SetlistsTableTableManager(_db, _db.setlists);
  $$SetlistItemsTableTableManager get setlistItems =>
      $$SetlistItemsTableTableManager(_db, _db.setlistItems);
  $$InkStrokesTableTableManager get inkStrokes =>
      $$InkStrokesTableTableManager(_db, _db.inkStrokes);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db, _db.recordings);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
