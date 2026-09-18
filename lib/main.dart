import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // pdfium 을 올린다. 이걸 빼면 첫 악보를 여는 순간 죽는다.
  await pdfrxFlutterInitialize();

  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  runApp(const ProviderScope(child: HIScoreApp()));
}

class HIScoreApp extends ConsumerWidget {
  const HIScoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'HIScore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
