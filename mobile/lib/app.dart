import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n_ext.dart';
import 'features/app_lock.dart';
import 'features/home.dart';
import 'providers.dart';
import 'theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class KaraBudgetApp extends ConsumerWidget {
  const KaraBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'KaraBudget',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildKaraTheme(Brightness.light),
      darkTheme: buildKaraTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider), // null = langue du système
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...fallbackDelegates, // malgache : composants système en français
      ],
      localeResolutionCallback: (device, supported) {
        for (final s in supported) {
          if (s.languageCode == device?.languageCode) return s;
        }
        return const Locale('fr');
      },
      builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
      home: const HomeShell(),
    );
  }
}
