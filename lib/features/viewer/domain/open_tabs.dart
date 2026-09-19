import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

/// 열어 둔 문서 목록. 앱이 살아 있는 동안만 유지한다.
class OpenTabs extends Notifier<List<OpenTab>> {
  /// 너무 많이 쌓이면 탭 줄이 쓸모없어진다. 가장 오래된 것부터 밀어낸다.
  static const maxTabs = 12;

  @override
  List<OpenTab> build() => const [];

  /// 탭을 열거나, 이미 있으면 제목과 페이지를 갱신한다.
  void open(SessionKey key, String title, {int? page}) {
    final i = state.indexWhere((t) => t.key == key);
    if (i >= 0) {
      final tab = state[i];
      final next = tab.copyWith(title: title, page: page);
      if (next.title == tab.title && next.page == tab.page) return;
      state = [...state]..[i] = next;
      return;
    }
    final added = [...state, OpenTab(key: key, title: title, page: page ?? 0)];
    state = added.length > maxTabs
        ? added.sublist(added.length - maxTabs)
        : added;
  }

  /// 보던 자리를 기억해 둔다. 탭이 없으면 아무것도 하지 않는다.
  void updatePage(SessionKey key, int page) {
    final i = state.indexWhere((t) => t.key == key);
    if (i < 0 || state[i].page == page) return;
    state = [...state]..[i] = state[i].copyWith(page: page);
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
  }

  /// 곡이나 세트리스트가 지워졌을 때 남은 탭을 치운다.
  void closeIds(Iterable<String> ids) {
    final gone = ids.toSet();
    if (!state.any((t) => gone.contains(t.key.id))) return;
    state = [for (final t in state) if (!gone.contains(t.key.id)) t];
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
