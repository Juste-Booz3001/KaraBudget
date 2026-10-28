import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../core/splits.dart';
import '../data/db.dart';
import '../providers.dart';
import '../sync/api_client.dart';
import 'common.dart';

final activityProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
    (ref, spaceId) => ref.read(apiProvider).activity(spaceId));

/// Espace partagé : soldes (qui doit quoi), membres et rôles, journal d'activité.
class SharedSpaceScreen extends ConsumerWidget {
  const SharedSpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final space = ref.watch(activeSpaceProvider);
    if (space == null || space.isPersonal) {
      return Scaffold(appBar: AppBar(), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(t.sharedOnly, textAlign: TextAlign.center))));
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(space.name),
          bottom: TabBar(tabs: [Tab(text: t.balances), Tab(text: t.members), Tab(text: t.activity)]),
        ),
        body: TabBarView(children: [_BalancesTab(space: space), _MembersTab(space: space), _ActivityTab(space: space)]),
      ),
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  const _BalancesTab({required this.space});
  final SpaceInfo space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final members = ref.watch(membersProvider(space.id)).valueOrNull ?? const <MemberInfo>[];
    final names = {for (final m in members) m.userId: m.label};
    String who(String id) => names[id] ?? '?';
    final expenses = ref.watch(allExpensesProvider).valueOrNull ?? const <Expense>[];
    final settlements = ref.watch(settlementsProvider).valueOrNull ?? const <Settlement>[];
    final canWrite = space.canWrite;

    final balances = computeBalances(
      [for (final e in expenses) SharedExpense(amount: e.amountMinor, currency: e.currency, paidBy: e.paidBy, splitRaw: e.splitJson)],
      [for (final s in settlements) Payment(from: s.fromUser, to: s.toUser, amount: s.amountMinor, currency: s.currency)],
    );

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (balances.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(t.allSettled))),
      for (final entry in balances.entries) ...[
        Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final b in (entry.value.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(b.value > 0 ? Icons.arrow_circle_down : Icons.arrow_circle_up, color: b.value > 0 ? Colors.green : Colors.red),
            title: Text(who(b.key)),
            subtitle: Text(b.value > 0 ? t.isOwed : t.owes),
            trailing: Text(formatMinor(b.value.abs(), currencyOf(entry.key))),
          ),
        const SizedBox(height: 4),
        for (final tr in suggestTransfers(entry.value))
          Card(
            child: ListTile(
              title: Text(t.transferLine(who(tr.from), who(tr.to), formatMinor(tr.amount, currencyOf(entry.key)))),
              trailing: canWrite
                  ? TextButton(
                      onPressed: () => ref
                          .read(repoProvider)
                          .addSettlement(space.id, from: tr.from, to: tr.to, amountMinor: tr.amount, currency: entry.key),
                      child: Text(t.markRepaid),
                    )
                  : null,
            ),
          ),
        const SizedBox(height: 16),
      ],
      if (settlements.isNotEmpty) ...[
        const Divider(),
        Text(t.repayments, style: Theme.of(context).textTheme.titleMedium),
        for (final s in settlements)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.handshake_outlined),
            title: Text(t.transferLine(who(s.fromUser), who(s.toUser), formatMinor(s.amountMinor, currencyOf(s.currency)))),
            subtitle: Text(context.dayLabelFull(s.at)),
            trailing: canWrite ? IconButton(icon: const Icon(Icons.close), onPressed: () => ref.read(repoProvider).deleteSettlement(s.spaceId, s.id)) : null,
          ),
      ],
    ]);
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.space});
  final SpaceInfo space;

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
      ref.invalidate(membersProvider(space.id));
    } catch (e) {
      if (context.mounted) snack(context, apiError(e));
    }
  }

  String _roleLabel(BuildContext c, String role) => switch (role) {
        'owner' => c.t.roleOwner,
        'viewer' => c.t.roleViewer,
        _ => c.t.roleEditor,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final members = ref.watch(membersProvider(space.id));
    final me = ref.watch(settingsProvider.select((s) => s.userId));
    final api = ref.read(apiProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.vpn_key),
        title: Text(t.inviteCodeLabel(space.inviteCode)),
        subtitle: Text(t.inviteHelp),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: space.inviteCode));
            snack(context, t.codeCopied);
          },
        ),
      ),
      if (space.isOwner)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(t.regenerateCode),
            onPressed: () => _run(context, ref, () async {
              if (!await confirm(context, t.regenerateConfirm)) return;
              await api.rotateInvite(space.id);
              await ref.read(sessionProvider.notifier).refreshSpaces();
            }),
          ),
        ),
      const Divider(),
      members.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text(apiError(e))),
        data: (list) => Column(children: [
          for (final m in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(m.label.isEmpty ? '?' : m.label[0].toUpperCase())),
              title: Text(m.userId == me ? t.youLabel(m.email) : m.email),
              subtitle: Text(_roleLabel(context, m.role == 'member' ? 'editor' : m.role)),
              trailing: space.isOwner && m.role != 'owner'
                  ? PopupMenuButton<String>(
                      onSelected: (v) => _run(context, ref, () async {
                        if (v == 'remove') {
                          if (!await confirm(context, t.removeMemberConfirm(m.email))) return;
                          await api.removeMember(space.id, m.userId);
                        } else {
                          await api.setRole(space.id, m.userId, v);
                        }
                      }),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'editor', child: Text(t.roleEditor)),
                        PopupMenuItem(value: 'viewer', child: Text(t.roleViewer)),
                        PopupMenuItem(value: 'remove', child: Text(t.removeMember)),
                      ],
                    )
                  : null,
            ),
        ]),
      ),
      if (!space.isOwner)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(t.leaveSpace),
            onPressed: () => _run(context, ref, () async {
              if (!await confirm(context, t.leaveConfirm)) return;
              await api.leaveSpace(space.id);
              await ref.read(sessionProvider.notifier).refreshSpaces();
              if (context.mounted) Navigator.pop(context);
            }),
          ),
        ),
    ]);
  }
}

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab({required this.space});
  final SpaceInfo space;

  String _entity(BuildContext c, String e) => switch (e) {
        'expense' => c.t.entExpense,
        'category' => c.t.entCategory,
        'budget' => c.t.entBudget,
        'recurring' => c.t.entRecurring,
        'rate' => c.t.entRate,
        'goal' => c.t.entGoal,
        'contribution' => c.t.entContribution,
        'settlement' => c.t.entSettlement,
        _ => e,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final log = ref.watch(activityProvider(space.id));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(activityProvider(space.id)),
      child: log.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(apiError(e)))]),
        data: (list) => list.isEmpty
            ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(t.noActivity)))])
            : ListView(children: [
                for (final a in list)
                  ListTile(
                    dense: true,
                    leading: Icon(switch (a['action']) {
                      'create' => Icons.add_circle_outline,
                      'delete' => Icons.remove_circle_outline,
                      _ => Icons.edit_outlined,
                    }),
                    title: Text(() {
                      final who = (a['email'] as String).split('@').first;
                      final ent = _entity(context, a['entity'] as String);
                      final label = (a['label'] as String?) ?? '';
                      return switch (a['action']) {
                        'create' => t.activityCreate(who, ent, label),
                        'delete' => t.activityDelete(who, ent, label),
                        _ => t.activityUpdate(who, ent, label),
                      };
                    }()),
                    subtitle: Text(context.dateTimeLabel(a['ts'] as int)),
                  ),
              ]),
      ),
    );
  }
}
