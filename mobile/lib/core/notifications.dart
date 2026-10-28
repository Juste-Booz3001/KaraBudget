import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/db.dart';
import 'money.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  /// Appelé quand l'utilisateur touche une notification (payload : 'quick_add' pour la saisie rapide).
  void Function(String? payload)? onTap;

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _quickId = 424242;
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails('karabudget', 'KaraBudget',
        channelDescription: 'Alertes de budget et rappels', importance: Importance.high),
    iOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
  );
  static const _quickDetails = NotificationDetails(
    android: AndroidNotificationDetails('karabudget_quick', 'Saisie rapide',
        channelDescription: 'Raccourci permanent pour ajouter une dépense',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: false),
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          linux: LinuxInitializationSettings(defaultActionName: 'Ouvrir'),
        ),
        onDidReceiveNotificationResponse: (r) => onTap?.call(r.payload),
      );
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } catch (_) {
      // une plateforme sans notifications ne doit jamais empêcher l'application de démarrer
    }
  }

  Future<void> alert(String title, String body) async {
    try {
      await _plugin.show(Random().nextInt(1 << 30), title, body, _details);
    } catch (_) {
      // pas de démon de notifications (ordinateur) : on ignore
    }
  }

  /// Rappel à 9h le jour de chaque échéance future. On replanifie tout à chaque changement.
  /// (Les rappels planifiés ne sont pas disponibles sous Linux.)
  Future<void> syncReminders(List<Recurring> rules, {required String title, required String fallbackNote}) async {
    if (Platform.isLinux) return;
    final now = DateTime.now();
    for (final r in rules) {
      final id = r.id.hashCode & 0x7fffffff;
      await _plugin.cancel(id);
      final due = DateTime.fromMillisecondsSinceEpoch(r.nextDue);
      final when = DateTime(due.year, due.month, due.day, 9);
      if (!when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id,
        title,
        '${r.note.isEmpty ? fallbackNote : r.note} : ${formatMinor(r.amountMinor, currencyOf(r.currency))}',
        tz.TZDateTime.from(when, tz.local), // même instant, quel que soit le fuseau configuré
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Notification permanente (Android) : un toucher ouvre directement l'ajout de dépense.
  Future<void> showQuickEntry(String title, String body) async {
    if (!Platform.isAndroid) return;
    try {
      await _plugin.show(_quickId, title, body, _quickDetails, payload: 'quick_add');
    } catch (_) {}
  }

  Future<void> hideQuickEntry() async {
    try {
      await _plugin.cancel(_quickId);
    } catch (_) {}
  }

  /// Payload de la notification qui a lancé l'application (démarrage à froid), s'il y en a une.
  Future<String?> launchPayload() async {
    try {
      final d = await _plugin.getNotificationAppLaunchDetails();
      return d?.didNotificationLaunchApp == true ? d?.notificationResponse?.payload : null;
    } catch (_) {
      return null;
    }
  }
}
