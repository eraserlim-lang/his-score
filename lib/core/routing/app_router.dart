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
      GoRoute(
        path: '/score/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ViewerPage(
          sessionKey: SessionKey.score(state.pathParameters['id']!),
          initialPage: int.tryParse(state.uri.queryParameters['page'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/play/setlist/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ViewerPage(
          sessionKey: SessionKey.setlist(state.pathParameters['id']!),
          initialPage: int.tryParse(state.uri.queryParameters['page'] ?? ''),
        ),
      ),
    ],
  );
});

int _indexOf(String location) {
  final i = shellDestinations.indexWhere((d) => location.startsWith(d.path));
  return i < 0 ? 0 : i;
}
