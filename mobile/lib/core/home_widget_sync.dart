import 'dart:io';

import 'package:home_widget/home_widget.dart';

/// Données affichées par le widget d'écran d'accueil Android (voir android_widget/README.md).
/// Sans effet ailleurs que sur Android/iOS, et sans erreur si le widget natif n'est pas installé.
class HomeWidgetService {
  static const androidProvider = 'KaraBudgetWidgetProvider';

  static Future<void> update({required String month, required String spent, required String remaining, required double ratio}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await HomeWidget.saveWidgetData<String>('month', month);
      await HomeWidget.saveWidgetData<String>('spent', spent);
      await HomeWidget.saveWidgetData<String>('remaining', remaining);
      await HomeWidget.saveWidgetData<int>('percent', (ratio.clamp(0, 1) * 100).round());
      await HomeWidget.updateWidget(name: androidProvider, androidName: androidProvider);
    } catch (_) {}
  }

  /// Uri du clic sur le bouton « + » du widget (démarrage à froid), ou null.
  static Future<Uri?> launchUri() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (_) {
      return null;
    }
  }

  static Stream<Uri?> get clicks {
    if (!Platform.isAndroid && !Platform.isIOS) return const Stream.empty();
    return HomeWidget.widgetClicked;
  }
}
