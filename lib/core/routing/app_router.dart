import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../layout/app_shell.dart';
import '../../features/importer/presentation/import_page.dart';
import '../../features/library/presentation/library_page.dart';
import '../../features/setlist/presentation/setlist_detail_page.dart';
import '../../features/setlist/presentation/setlist_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/viewer/data/score_session.dart';
import '../../features/viewer/presentation/viewer_page.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/library',
    // 다른 앱에서 "HIScore 로 열기" 하면 iOS 가 파일 URL 을 화면 경로처럼도
    // 밀어 넣는다. 파일은 OpenInHandler 가 따로 받아 라이브러리에 넣으므로,
    // 여기서는 길 없는 주소로 오류 화면에 갇히지 않게 라이브러리로 돌린다.
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == 'file' || uri.path.isEmpty || uri.path == '/') {
        return '/library';
      }
      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) {
          final index = _indexOf(state.uri.path);
          return AppShell(
            currentIndex: index,
            onDestinationSelected: (i) =>
                context.go(shellDestinations[i].path),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LibraryPage()),
          ),
          GoRoute(
            path: '/setlists',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SetlistPage()),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    SetlistDetailPage(setlistId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/import',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ImportPage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),

      /// 악보 보기는 껍데기 밖에서 전체 화면으로 연다.
      ///
      /// 탭을 옮길 때마다 pushReplacement 로 이 경로를 다시 여는데, 기본
      /// 전환을 쓰면 악보가 옆에서 밀려 들어온다. 곡을 오가는 것뿐이라
      /// 그 움직임이 거슬려 전환을 없앤다.
      GoRoute(
        path: '/score/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => NoTransitionPage(
          child: ViewerPage(
            sessionKey: SessionKey.score(state.pathParameters['id']!),
            initialPage: int.tryParse(state.uri.queryParameters['page'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: '/play/setlist/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => NoTransitionPage(
          child: ViewerPage(
            sessionKey: SessionKey.setlist(state.pathParameters['id']!),
            initialPage: int.tryParse(state.uri.queryParameters['page'] ?? ''),
          ),
        ),
      ),
    ],
  );
});

int _indexOf(String location) {
  final i = shellDestinations.indexWhere((d) => location.startsWith(d.path));
  return i < 0 ? 0 : i;
}
