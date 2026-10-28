import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'core/money.dart';
import 'core/rates.dart';
import 'core/reports.dart';
import 'data/db.dart';
import 'data/repository.dart';
import 'sync/api_client.dart';
import 'sync/attachment_sync.dart';
import 'sync/sync_service.dart';

// ---------------- réglages ----------------
class SpaceInfo {
  const SpaceInfo(this.id, this.name, this.inviteCode, this.isPersonal, {this.role = 'owner'});
  final String id, name, inviteCode, role;
  final bool isPersonal;

  /// "member" = ancien nom de "editor" côté serveur.
  bool get canWrite => role != 'viewer';
  bool get isOwner => role == 'owner';

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': inviteCode, 'personal': isPersonal, 'role': role};
  factory SpaceInfo.fromJson(Map<String, dynamic> j) => SpaceInfo(
        j['id'] as String,
        j['name'] as String,
        j['code'] as String,
        j['personal'] as bool,
        role: (j['role'] as String?) ?? 'owner',
      );
}

class MemberInfo {
  const MemberInfo(this.userId, this.email, this.role);
  final String userId, email, role;

  String get label => email.contains('@') ? email.split('@').first : email;

  Map<String, dynamic> toJson() => {'u': userId, 'e': email, 'r': role};
  factory MemberInfo.fromJson(Map<String, dynamic> j) => MemberInfo(j['u'] as String, j['e'] as String, j['r'] as String);
}

class AppSettings {
  const AppSettings({
    required this.baseUrl,
    required this.currency,
    required this.themeMode,
    required this.activeSpaceId,
    required this.deviceId,
    required this.spaces,
    this.email,
    this.userId,
    this.language = 'system',
    this.quickNotification = false,
  });
  final String baseUrl, currency, themeMode, activeSpaceId, deviceId, language;
  final List<SpaceInfo> spaces;
  final String? email, userId;
  final bool quickNotification;

  AppSettings copyWith({
    String? baseUrl,
    String? currency,
    String? themeMode,
    String? activeSpaceId,
    List<SpaceInfo>? spaces,
    String? email,
    String? userId,
    String? language,
    bool? quickNotification,
    bool clearEmail = false,
  }) =>
      AppSettings(
        baseUrl: baseUrl ?? this.baseUrl,
        currency: currency ?? this.currency,
        themeMode: themeMode ?? this.themeMode,
        activeSpaceId: activeSpaceId ?? this.activeSpaceId,
        deviceId: deviceId,
        spaces: spaces ?? this.spaces,
        email: clearEmail ? null : (email ?? this.email),
        userId: clearEmail ? null : (userId ?? this.userId),
        language: language ?? this.language,
        quickNotification: quickNotification ?? this.quickNotification,
      );
}

final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('override in main()'));

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final p = ref.read(prefsProvider);
    var device = p.getString('deviceId');
    if (device == null) {
      device = const Uuid().v4();
      p.setString('deviceId', device);
    }
    final spaces = (jsonDecode(p.getString('spaces') ?? '[]') as List)
        .map((e) => SpaceInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    return AppSettings(
      baseUrl: p.getString('baseUrl') ?? 'http://10.0.2.2:8000', // 10.0.2.2 = hôte vu depuis l'émulateur Android
      currency: p.getString('currency') ?? 'USD',
      themeMode: p.getString('themeMode') ?? 'system',
      activeSpaceId: p.getString('space') ?? 'local',
      deviceId: device,
      spaces: spaces,
      email: p.getString('email'),
      userId: p.getString('userId'),
      language: p.getString('language') ?? 'system',
      quickNotification: p.getBool('quickNotification') ?? false,
    );
  }

  void update({
    String? baseUrl,
    String? currency,
    String? themeMode,
    String? activeSpaceId,
    List<SpaceInfo>? spaces,
    String? email,
    String? userId,
    String? language,
    bool? quickNotification,
    bool clearEmail = false,
  }) {
    final p = ref.read(prefsProvider);
    if (baseUrl != null) p.setString('baseUrl', baseUrl);
    if (currency != null) p.setString('currency', currency);
    if (themeMode != null) p.setString('themeMode', themeMode);
    if (activeSpaceId != null) p.setString('space', activeSpaceId);
    if (spaces != null) p.setString('spaces', jsonEncode(spaces.map((s) => s.toJson()).toList()));
    if (email != null) p.setString('email', email);
    if (userId != null) p.setString('userId', userId);
    if (language != null) p.setString('language', language);
    if (quickNotification != null) p.setBool('quickNotification', quickNotification);
    if (clearEmail) {
      p.remove('email');
      p.remove('userId');
    }
    state = state.copyWith(
      baseUrl: baseUrl,
      currency: currency,
      themeMode: themeMode,
      activeSpaceId: activeSpaceId,
      spaces: spaces,
      email: email,
      userId: userId,
      language: language,
      quickNotification: quickNotification,
      clearEmail: clearEmail,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
final spaceIdProvider = Provider<String>((ref) => ref.watch(settingsProvider.select((s) => s.activeSpaceId)));
final currencyProvider = Provider<Currency>((ref) => currencyOf(ref.watch(settingsProvider.select((s) => s.currency))));
final themeModeProvider = Provider<ThemeMode>((ref) => switch (ref.watch(settingsProvider.select((s) => s.themeMode))) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    });

/// null = langue du système.
final localeProvider = Provider<Locale?>((ref) {
  final l = ref.watch(settingsProvider.select((s) => s.language));
  return l == 'system' ? null : Locale(l);
});

/// Espace actif (null = espace local, avant connexion).
final activeSpaceProvider = Provider<SpaceInfo?>((ref) {
  final id = ref.watch(spaceIdProvider);
  return ref.watch(settingsProvider.select((s) => s.spaces)).where((s) => s.id == id).firstOrNull;
});

/// Faux si l'utilisateur est « lecteur » de l'espace actif.
final canWriteProvider = Provider<bool>((ref) => ref.watch(activeSpaceProvider)?.canWrite ?? true);

/// Vrai pour un espace partagé (soldes, payeur, partage de dépenses).
final isSharedSpaceProvider = Provider<bool>((ref) {
  final s = ref.watch(activeSpaceProvider);
  return s != null && !s.isPersonal;
});

// ---------------- données ----------------
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repoProvider = Provider<Repository>(
    (ref) => Repository(ref.watch(dbProvider), () => ref.read(syncControllerProvider.notifier).trigger()));

final selectedMonthProvider = StateProvider<DateTime>((_) {
  final n = DateTime.now();
  return DateTime(n.year, n.month);
});

final categoriesProvider =
    StreamProvider<List<Category>>((ref) => ref.watch(repoProvider).watchCategories(ref.watch(spaceIdProvider)));

final monthExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final (from, to) = monthRange(ref.watch(selectedMonthProvider));
  return ref.watch(repoProvider).watchExpenses(ref.watch(spaceIdProvider), from, to);
});

/// Mois précédent le mois affiché (comparaison mois par mois).
final previousMonthExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final m = ref.watch(selectedMonthProvider);
  final (from, to) = monthRange(DateTime(m.year, m.month - 1));
  return ref.watch(repoProvider).watchExpenses(ref.watch(spaceIdProvider), from, to);
});

/// 6 derniers mois (pour la courbe mensuelle).
final lastMonthsExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final m = ref.watch(selectedMonthProvider);
  final from = DateTime(m.year, m.month - 5).millisecondsSinceEpoch;
  final to = DateTime(m.year, m.month + 1).millisecondsSinceEpoch;
  return ref.watch(repoProvider).watchExpenses(ref.watch(spaceIdProvider), from, to);
});

/// 13 derniers mois : sert au report de budget (jusqu'à 12 mois en arrière).
final rolloverExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final m = ref.watch(selectedMonthProvider);
  final from = DateTime(m.year, m.month - 12).millisecondsSinceEpoch;
  final to = DateTime(m.year, m.month + 1).millisecondsSinceEpoch;
  return ref.watch(repoProvider).watchExpenses(ref.watch(spaceIdProvider), from, to);
});

/// Mois en cours (indépendant du mois affiché) : alimente le widget d'écran d'accueil.
final currentMonthExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final (from, to) = monthRange(DateTime.now());
  return ref.watch(repoProvider).watchExpenses(ref.watch(spaceIdProvider), from, to);
});

final currentMonthBudgetsProvider = StreamProvider<List<Budget>>(
    (ref) => ref.watch(repoProvider).watchBudgets(ref.watch(spaceIdProvider), monthKey(DateTime.now())));

final allExpensesProvider =
    StreamProvider<List<Expense>>((ref) => ref.watch(repoProvider).watchAllExpenses(ref.watch(spaceIdProvider)));

final monthBudgetsProvider = StreamProvider<List<Budget>>((ref) => ref
    .watch(repoProvider)
    .watchBudgets(ref.watch(spaceIdProvider), monthKey(ref.watch(selectedMonthProvider))));

final allBudgetsProvider =
    StreamProvider<List<Budget>>((ref) => ref.watch(repoProvider).watchAllBudgets(ref.watch(spaceIdProvider)));

final recurringProvider =
    StreamProvider<List<Recurring>>((ref) => ref.watch(repoProvider).watchRecurrings(ref.watch(spaceIdProvider)));

final ratesProvider = StreamProvider<List<Rate>>((ref) => ref.watch(repoProvider).watchRates(ref.watch(spaceIdProvider)));

final goalsProvider = StreamProvider<List<Goal>>((ref) => ref.watch(repoProvider).watchGoals(ref.watch(spaceIdProvider)));

final contributionsProvider =
    StreamProvider<List<Contribution>>((ref) => ref.watch(repoProvider).watchContributions(ref.watch(spaceIdProvider)));

final settlementsProvider =
    StreamProvider<List<Settlement>>((ref) => ref.watch(repoProvider).watchSettlements(ref.watch(spaceIdProvider)));

final templatesProvider = StreamProvider<List<QuickTemplate>>((ref) => ref.watch(repoProvider).watchTemplates());

final pendingOpsProvider = StreamProvider<int>((ref) => ref.watch(repoProvider).watchPendingCount());

/// Taux saisis à la main pour l'espace actif.
final rateTableProvider = Provider<RateTable>((ref) {
  final rows = ref.watch(ratesProvider).valueOrNull ?? const <Rate>[];
  return RateTable([for (final r in rows) RateEntry(r.fromCurrency, r.toCurrency, r.ratePpm)]);
});

/// Dépenses converties dans la devise d'affichage. [unconverted] : lignes sans taux (ignorées des totaux).
typedef ConvertedSpends = ({List<Spend> spends, int unconverted});

ConvertedSpends convertSpends(Iterable<Expense> list, RateTable rates, String currency) {
  final out = <Spend>[];
  var unconverted = 0;
  for (final e in list) {
    final v = rates.convert(e.amountMinor, e.currency, currency);
    if (v == null) {
      unconverted++;
    } else {
      out.add(Spend(v, e.spentAt, e.categoryId));
    }
  }
  return (spends: out, unconverted: unconverted);
}

final monthSpendsProvider = Provider<ConvertedSpends>((ref) => convertSpends(
    ref.watch(monthExpensesProvider).valueOrNull ?? const [],
    ref.watch(rateTableProvider),
    ref.watch(settingsProvider.select((s) => s.currency))));

final previousMonthSpendsProvider = Provider<ConvertedSpends>((ref) => convertSpends(
    ref.watch(previousMonthExpensesProvider).valueOrNull ?? const [],
    ref.watch(rateTableProvider),
    ref.watch(settingsProvider.select((s) => s.currency))));

// ---------------- compte & API ----------------
final apiProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(settingsProvider.select((s) => s.baseUrl))));

final attachmentSyncProvider = Provider<AttachmentSync>((ref) => AttachmentSync(ref.watch(repoProvider), ref.watch(apiProvider)));

/// Membres d'un espace partagé : réseau si possible, sinon dernière liste connue.
final membersProvider = FutureProvider.family<List<MemberInfo>, String>((ref, spaceId) async {
  final prefs = ref.read(prefsProvider);
  final cache = (jsonDecode(prefs.getString('members') ?? '{}') as Map<String, dynamic>);
  try {
    final list = await ref.read(apiProvider).members(spaceId);
    final members = [for (final m in list) MemberInfo(m['user_id'] as String, m['email'] as String, m['role'] as String)];
    cache[spaceId] = [for (final m in members) m.toJson()];
    await prefs.setString('members', jsonEncode(cache));
    return members;
  } catch (_) {
    final cached = cache[spaceId] as List?;
    if (cached == null) rethrow;
    return [for (final m in cached) MemberInfo.fromJson(m as Map<String, dynamic>)];
  }
});

class Session {
  const Session(this.loggedIn);
  final bool loggedIn;
}

class SessionNotifier extends AsyncNotifier<Session> {
  @override
  Future<Session> build() async => Session(await ref.watch(apiProvider).hasToken());

  Future<void> authenticate(String email, String password, {required bool register}) async {
    final api = ref.read(apiProvider);
    final personal = await api.authenticate(email.trim(), password, register: register);
    final settings = ref.read(settingsProvider);
    // les données saisies hors-ligne dans l'espace "local" deviennent celles de l'espace personnel
    await ref.read(repoProvider).migrateSpace('local', personal);
    ref.read(settingsProvider.notifier).update(
          email: email.trim(),
          userId: await api.userId(),
          activeSpaceId: settings.activeSpaceId == 'local' ? personal : null,
        );
    state = const AsyncData(Session(true));
    await refreshSpaces();
    ref.read(syncControllerProvider.notifier).trigger(immediate: true);
  }

  Future<void> logout() async {
    await ref.read(apiProvider).logout();
    ref.read(settingsProvider.notifier).update(clearEmail: true);
    state = const AsyncData(Session(false));
  }

  Future<void> refreshSpaces() async {
    final list = await ref.read(apiProvider).listSpaces();
    final spaces = [
      for (final s in list)
        SpaceInfo(s['id'], s['name'], s['invite_code'], s['is_personal'], role: s['role'] == 'member' ? 'editor' : s['role'] as String)
    ];
    final notifier = ref.read(settingsProvider.notifier);
    notifier.update(spaces: spaces);
    // espace actif supprimé ou quitté : retour à l'espace personnel
    final active = ref.read(settingsProvider).activeSpaceId;
    if (active != 'local' && !spaces.any((s) => s.id == active)) {
      final personal = spaces.where((s) => s.isPersonal).firstOrNull;
      if (personal != null) notifier.update(activeSpaceId: personal.id);
    }
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session>(SessionNotifier.new);

// ---------------- synchronisation automatique ----------------
class SyncStatus {
  const SyncStatus({this.syncing = false, this.error, this.last});
  final bool syncing;
  final String? error;
  final DateTime? last;
}

class SyncController extends Notifier<SyncStatus> {
  Timer? _debounce, _periodic;
  StreamSubscription<List<ConnectivityResult>>? _net;
  bool _running = false, _again = false;

  @override
  SyncStatus build() {
    // retour du réseau => sync ; filet de sécurité toutes les 2 minutes
    _net = Connectivity().onConnectivityChanged.listen((r) {
      if (!r.contains(ConnectivityResult.none)) trigger();
    });
    _periodic = Timer.periodic(const Duration(minutes: 2), (_) => trigger());
    ref.onDispose(() {
      _debounce?.cancel();
      _periodic?.cancel();
      _net?.cancel();
    });
    return const SyncStatus();
  }

  void trigger({bool immediate = false}) {
    _debounce?.cancel();
    _debounce = Timer(immediate ? Duration.zero : const Duration(milliseconds: 600), _run);
  }

  Future<void> _run() async {
    if (_running) {
      _again = true;
      return;
    }
    if (ref.read(sessionProvider).valueOrNull?.loggedIn != true) return;
    _running = true;
    state = SyncStatus(syncing: true, last: state.last);
    try {
      await ref.read(sessionProvider.notifier).refreshSpaces(); // rôles à jour, espaces quittés/retirés
      final settings = ref.read(settingsProvider);
      final svc = SyncService(ref.read(dbProvider), ref.read(apiProvider), settings.deviceId);
      for (final s in settings.spaces) {
        await svc.syncSpace(s.id);
        try {
          if (s.canWrite) await ref.read(attachmentSyncProvider).uploadPending(s.id);
        } catch (_) {
          // les reçus restent en file d'attente ; ils ne doivent pas faire échouer la synchro des données
        }
      }
      state = SyncStatus(last: DateTime.now());
    } catch (e) {
      state = SyncStatus(error: apiError(e), last: state.last);
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        trigger();
      }
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);
