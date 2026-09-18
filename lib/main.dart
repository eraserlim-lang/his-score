import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/db/settings_dao.dart';
import 'core/i18n/tr.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/importer/data/open_in_handler.dart';
import 'features/importer/data/watch_folder_service.dart';
import 'features/sync/data/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // pdfium 을 올린다. 이걸 빼면 첫 악보를 여는 순간 죽는다.
  await pdfrxFlutterInitialize();
  await AppLocale.load();

  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  runApp(const ProviderScope(child: HIScoreApp()));
}

class HIScoreApp extends ConsumerWidget {
  const HIScoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 앱이 떠 있는 동안 계속 살아 있어야 하는 것들.
    ref.watch(openInHandlerProvider);
    if (WatchFolderService.supported) ref.watch(watchFolderServiceProvider);
    ref.watch(syncServiceProvider);

    // 저장된 언어와 테마를 첫 프레임 전에 반영한다.
    final settings = ref.watch(settingsDaoProvider);
    final savedLocale = ref.watch(settingProvider(SettingKeys.locale)).value;
    AppLocale.override.value = savedLocale == null ? null : Locale(savedLocale);
    final savedTheme = ref.watch(settingProvider(SettingKeys.themeMode)).value;
    final themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == savedTheme,
      orElse: () => ThemeMode.system,
    );
    settings.hashCode;

    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLocale.override,
      builder: (context, _, _) => MaterialApp.router(
        title: 'HIScore',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: AppLocale.current,
        supportedLocales: AppLocale.supported,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
