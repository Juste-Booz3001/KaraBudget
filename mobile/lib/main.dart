import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/backup.dart';
import 'core/notifications.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // toutes les langues (fr, en ; le malgache réutilise le français)
  await applyPendingRestore(); // restauration préparée : à faire AVANT d'ouvrir la base
  final prefs = await SharedPreferences.getInstance();
  await NotificationService.instance.init();
  runApp(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    child: const KaraBudgetApp(),
  ));
}
