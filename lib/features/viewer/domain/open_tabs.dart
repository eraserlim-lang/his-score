import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/score_dao.dart';
import '../../../core/db/settings_dao.dart';
import '../../../core/db/setlist_dao.dart';
import '../data/score_session.dart';

/// 상단 탭에 걸린 문서 하나. 악보 한 곡이거나 세트리스트 하나다.
///
/// 탭은 열어 둔 자리를 기억할 뿐 PDF 를 붙들고 있지 않다.
/// 다시 고르면 세션을 새로 열고 [page] 로 되돌아간다.
@immutable
class OpenTab {
  const OpenTab({required this.key, required this.title, this.page = 0});

  final SessionKey key;
  final String title;

  /// 이 탭을 마지막으로 떠날 때 보고 있던 0-based 페이지.
  final int page;

  String get location =>
      key.isSetlist ? '/play/setlist/${key.id}' : '/score/${key.id}';

  OpenTab copyWith({String? title, int? page}) => OpenTab(
        key: key,
        title: title ?? this.title,
        page: page ?? this.page,
      );

  Map<String, dynamic> toJson() => {
        'id': key.id,
        'setlist': key.isSetlist,
        'title': title,
        'page': page,
      };

  static OpenTab? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    if (id is! String || id.isEmpty || title is! String) return null;
    return OpenTab(
      key: raw['setlist'] == true
          ? SessionKey.setlist(id)
          : SessionKey.score(id),
      title: title,
      page: raw['page'] is int ? raw['page'] as int : 0,
    );
  }
}

/// 열어 둔 문서 목록. 앱이 살아 있는 동안만 유지한다.
class OpenTabs extends Notifier<List<OpenTab>> {
  /// 너무 많이 쌓이면 탭 줄이 쓸모없어진다. 가장 오래된 것부터 밀어낸다.
  static const maxTabs = 12;

  /// 잦은 쓰기를 모은다. 쪽을 넘길 때마다 자리가 바뀌기 때문이다.
  static const _saveDelay = Duration(milliseconds: 600);
  Timer? _saveTimer;

  @override
  List<OpenTab> build() {
    ref.onDispose(() {
      _saveTimer?.cancel();
      _saveTimer = null;
    });
    // 지난번에 열어 둔 탭을 되살린다. 그사이 사용자가 연 탭이 있으면
    // 그쪽이 먼저다. 되살리기는 화면을 막을 일이 아니라 뒤에서 한다.
    unawaited(_restore());
    return const [];
  }

  Future<void> _restore() async {
    final raw = await ref.read(settingsDaoProvider).get(SettingKeys.openTabs);
    if (raw == null || raw.isEmpty) return;

    final List<OpenTab> saved;
    try {
      saved = [
        for (final entry in jsonDecode(raw) as List)
          ?OpenTab.fromJson(entry),
      ];
    } on Object {
      // 읽을 수 없는 값이면 없던 것으로 친다.
      return;
    }
    if (saved.isEmpty) return;

    // 그사이 지워진 곡이나 세트리스트는 빼고 돌려놓는다.
    final scoreIds = {
      for (final t in saved)
        if (!t.key.isSetlist) t.key.id,
    };
    final alive = <String>{
      for (final s in await ref.read(scoreDaoProvider).findByIds(scoreIds))
        s.id,
    };
    final setlistDao = ref.read(setlistDaoProvider);
    for (final t in saved) {
      if (!t.key.isSetlist) continue;
      if (await setlistDao.findById(t.key.id) != null) alive.add(t.key.id);
    }

    final restored = [
      for (final t in saved)
        if (alive.contains(t.key.id)) t,
    ];
    if (restored.isEmpty) {
      _write(const []);
      return;
    }

    // 되살리는 동안 사용자가 연 탭이 있으면 그 뒤에 붙인다.
    final opened = {for (final t in state) t.key};
    state = [
      ...restored.where((t) => !opened.contains(t.key)),
      ...state,
    ];
  }

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, () => _write(state));
  }

  void _write(List<OpenTab> tabs) {
    ref
        .read(settingsDaoProvider)
        .set(SettingKeys.openTabs, jsonEncode([
          for (final t in tabs) t.toJson(),
        ]));
  }

  /// 탭을 열거나, 이미 있으면 제목과 페이지를 갱신한다.
  void open(SessionKey key, String title, {int? page}) {
    final i = state.indexWhere((t) => t.key == key);
    if (i >= 0) {
      final tab = state[i];
      final next = tab.copyWith(title: title, page: page);
      if (next.title == tab.title && next.page == tab.page) return;
      state = [...state]..[i] = next;
      _save();
      return;
    }
    final added = [...state, OpenTab(key: key, title: title, page: page ?? 0)];
    state = added.length > maxTabs
        ? added.sublist(added.length - maxTabs)
        : added;
    _save();
  }

  /// 보던 자리를 기억해 둔다. 탭이 없으면 아무것도 하지 않는다.
  void updatePage(SessionKey key, int page) {
    final i = state.indexWhere((t) => t.key == key);
    if (i < 0 || state[i].page == page) return;
    state = [...state]..[i] = state[i].copyWith(page: page);
    _save();
  }

  /// 탭을 끌어 옮긴 자리로 옮긴다.
  ///
  /// [newIndex] 는 빼낸 뒤 기준이다(ReorderableListView 의 onReorderItem).
  void move(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    final next = [...state];
    final tab = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), tab);
    state = next;
  }

  void close(SessionKey key) {
    if (!state.any((t) => t.key == key)) return;
    state = [for (final t in state) if (t.key != key) t];
    _save();
  }

  /// 곡이나 세트리스트가 지워졌을 때 남은 탭을 치운다.
  void closeIds(Iterable<String> ids) {
    final gone = ids.toSet();
    if (!state.any((t) => gone.contains(t.key.id))) return;
    state = [for (final t in state) if (!gone.contains(t.key.id)) t];
    _save();
  }

  int? pageOf(SessionKey key) {
    for (final t in state) {
      if (t.key == key) return t.page;
    }
    return null;
  }

  /// 탭을 닫은 뒤 대신 보여 줄 이웃 탭. 마지막 하나였으면 null.
  OpenTab? neighbourOf(SessionKey key) {
    final i = state.indexWhere((t) => t.key == key);
    if (i < 0 || state.length <= 1) return null;
    return i == 0 ? state[1] : state[i - 1];
  }
}

final openTabsProvider =
    NotifierProvider<OpenTabs, List<OpenTab>>(OpenTabs.new);
