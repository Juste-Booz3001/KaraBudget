import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/home_widget_sync.dart';
import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../core/notifications.dart';
import '../providers.dart';
import '../theme.dart';
import 'budgets.dart';
import 'expense_edit.dart';
import 'expenses.dart';
import 'search.dart';
import 'settings.dart';
import 'stats.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  StreamSubscription<Uri?>? _widgetClicks;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.onTap = (payload) {
      if (payload == 'quick_add') _openAdd();
    };
    _widgetClicks = HomeWidgetService.clicks.listen((uri) {
      if (uri?.host == 'add') _openAdd();
    });
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _widgetClicks?.cancel();
    NotificationService.instance.onTap = null;
    super.dispose();
  }

  void _openAdd() {
    if (!mounted || !ref.read(canWriteProvider)) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseEditScreen()));
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(repoProvider);
    final space = ref.read(spaceIdProvider);
    await repo.seedDefaults(space);
    await repo.materializeDue(space); // dépenses récurrentes échues (fonctionne hors-ligne)
    ref.read(syncControllerProvider.notifier).trigger(immediate: true);
    if (!mounted) return;
    _syncQuickNotification(ref.read(settingsProvider).quickNotification);
    _pushWidget();
    // démarrage à froid depuis la notification de saisie rapide ou le bouton « + » du widget
    if (await NotificationService.instance.launchPayload() == 'quick_add' || (await HomeWidgetService.launchUri())?.host == 'add') {
      _openAdd();
    }
  }

  void _syncQuickNotification(bool on) {
    final t = context.t;
    if (on) {
      NotificationService.instance.showQuickEntry(t.quickEntryTitle, t.quickEntryBody);
    } else {
      NotificationService.instance.hideQuickEntry();
    }
  }

  /// Résumé du mois en cours pour le widget d'écran d'accueil : dépensé / budgets du mois.
  void _pushWidget() {
    if (!mounted) return;
    final cur = ref.read(currencyProvider);
    final rates = ref.read(rateTableProvider);
    final spent = convertSpends(ref.read(currentMonthExpensesProvider).valueOrNull ?? const [], rates, cur.code).spends.fold<int>(0, (a, s) => a + s.amount);
    final limit = (ref.read(currentMonthBudgetsProvider).valueOrNull ?? const []).fold<int>(0, (a, b) => a + b.limitMinor);
    HomeWidgetService.update(
      month: context.monthLabel(DateTime.now()),
      spent: formatMinor(spent, cur),
      remaining: limit == 0 ? '—' : formatMinor(limit - spent, cur),
      ratio: limit == 0 ? 0 : spent / limit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    // replanifie les rappels à chaque changement des règles récurrentes
    ref.listen(recurringProvider, (_, next) {
      next.whenData((rules) => NotificationService.instance.syncReminders(rules, title: t.recurringReminderTitle, fallbackNote: t.dueDate));
    });
    ref.listen(settingsProvider.select((s) => s.quickNotification), (_, on) => _syncQuickNotification(on));
    ref.listen(currentMonthExpensesProvider, (_, __) => _pushWidget());
    ref.listen(currentMonthBudgetsProvider, (_, __) => _pushWidget());
    // changement d'espace : s'assure que l'espace a ses catégories par défaut (espaces personnels uniquement)
    ref.listen(spaceIdProvider, (_, space) async {
      final isPersonal = ref.read(settingsProvider).spaces.any((s) => s.id == space && s.isPersonal) || space == 'local';
      if (isPersonal) await ref.read(repoProvider).seedDefaults(space);
    });

    final canWrite = ref.watch(canWriteProvider);
    final titles = [t.expenses, t.budgets, t.statistics, t.settings];
    const pages = [ExpensesScreen(), BudgetsScreen(), StatsScreen(), SettingsScreen()];
    return Scaffold(
      extendBody: true, // le contenu défile sous la barre flottante
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          if (_tab == 0)
            IconButton(
              tooltip: t.search,
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
          const SyncBadge(),
        ],
      ),
      body: pages[_tab],
      floatingActionButton: _tab == 0 && canWrite
          ? FloatingActionButton.extended(icon: const Icon(Icons.add), label: Text(t.expense), onPressed: _openAdd)
          : null,
      bottomNavigationBar: _FloatingNav(
        index: _tab,
        onChanged: (i) {
          HapticFeedback.selectionClick();
          setState(() => _tab = i);
        },
        items: [
          (icon: Icons.receipt_long_outlined, active: Icons.receipt_long, label: t.expenses),
          (icon: Icons.savings_outlined, active: Icons.savings, label: t.budgets),
          (icon: Icons.pie_chart_outline, active: Icons.pie_chart, label: t.statsShort),
          (icon: Icons.settings_outlined, active: Icons.settings, label: t.settings),
        ],
      ),
    );
  }
}

/// Barre de navigation flottante en verre dépoli : l'onglet actif s'élargit et montre son nom.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onChanged, required this.items});
  final int index;
  final ValueChanged<int> onChanged;
  final List<({IconData icon, IconData active, String label})> items;

  @override
  Widget build(BuildContext context) {
    final k = context.kara;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 66,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: k.card.withValues(alpha: .80),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: k.hairline),
              ),
              child: LayoutBuilder(builder: (context, c) {
                final selW = c.maxWidth * .36;
                final otherW = (c.maxWidth - selW) / (items.length - 1);
                return Row(children: [
                  for (var i = 0; i < items.length; i++)
                    Semantics(
                      button: true,
                      selected: i == index,
                      label: items[i].label,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          width: i == index ? selW : otherW,
                          height: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == index ? scheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: ClipRect(
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(i == index ? items[i].active : items[i].icon, size: 24, color: i == index ? scheme.onPrimaryContainer : k.muted),
                              if (i == index) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    items[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w700, fontSize: 13, color: scheme.onPrimaryContainer),
                                  ),
                                ),
                              ],
                            ]),
                          ),
                        ),
                      ),
                    ),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final status = ref.watch(syncControllerProvider);
    final pending = ref.watch(pendingOpsProvider).valueOrNull ?? 0;
    final loggedIn = ref.watch(sessionProvider).valueOrNull?.loggedIn ?? false;
    Widget icon;
    String tip;
    if (!loggedIn) {
      icon = const Icon(Icons.cloud_off);
      tip = t.localModeHint;
    } else if (status.syncing) {
      icon = const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
      tip = t.syncing;
    } else if (status.error != null) {
      icon = const Icon(Icons.sync_problem);
      tip = '${status.error} (${t.pendingChanges(pending)})';
    } else if (pending > 0) {
      icon = Badge(label: Text('$pending'), child: const Icon(Icons.cloud_upload));
      tip = t.pendingChanges(pending);
    } else {
      icon = const Icon(Icons.cloud_done);
      tip = t.synced;
    }
    return IconButton(
      tooltip: tip,
      icon: icon,
      onPressed: loggedIn ? () => ref.read(syncControllerProvider.notifier).trigger(immediate: true) : null,
    );
  }
}
