import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/json_store.dart';
import 'l10n/strings.dart';
import 'services/notification_service.dart';
import 'state/settings_store.dart';
import 'state/task_store.dart';
import 'ui/navigation.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting();

  final db = await JsonStore.open();
  final notifications = NotificationService.instance;
  await notifications.init();

  final settings = SettingsStore(db);
  await settings.load();
  S.load(_resolve(settings.value.locale ?? WidgetsBinding.instance.platformDispatcher.locale));

  final tasks = TaskStore(db, settings, notifications);
  await tasks.load();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: tasks),
    ],
    child: const MomentumApp(),
  ));
}

/// Russian for Russian-speaking regions' languages, English otherwise.
Locale _resolve(Locale? device) {
  const russianFallback = {'ru', 'uk', 'be', 'kk', 'ky', 'tg', 'uz', 'tk', 'hy', 'az'};
  return russianFallback.contains(device?.languageCode) ? const Locale('ru') : const Locale('en');
}

class MomentumApp extends StatelessWidget {
  const MomentumApp({super.key});

  @override
  Widget build(BuildContext context) {
    final (mode, locale) = context.select<SettingsStore, (ThemeMode, Locale?)>(
        (s) => (s.value.themeMode, s.value.locale));
    return MaterialApp(
      title: 'Momentum',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      themeAnimationDuration: const Duration(milliseconds: 450),
      themeAnimationCurve: Curves.easeOutCubic,
      locale: locale,
      supportedLocales: S.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      localeResolutionCallback: (device, _) => _resolve(device),
      builder: (context, child) {
        S.load(Localizations.localeOf(context));
        return child!;
      },
      home: const Shell(),
    );
  }
}
