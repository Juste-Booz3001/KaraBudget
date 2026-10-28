import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/goals.dart';
import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../data/db.dart';
import '../providers.dart';
import 'common.dart';

/// Solde d'un objectif : somme de ses versements (non supprimés).
int savedOf(Goal g, Iterable<Contribution> all) =>
    all.where((c) => c.goalId == g.id).fold(0, (a, c) => a + c.amountMinor);

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, Goal? g) async {
    final display = ref.read(currencyProvider);
    final name = TextEditingController(text: g?.name);
    var currency = g?.currency ?? display.code;
    final target = TextEditingController(text: g == null ? '' : plainMinor(g.targetMinor, currencyOf(g.currency)).replaceAll('.', ','));
    int? due = g != null && g.dueAt > 0 ? g.dueAt : null;
    var color = g?.color ?? 0xFF009688;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(g == null ? ctx.t.newGoal : ctx.t.editGoal),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: ctx.t.goalName)),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: target,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: ctx.t.targetAmount),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 100, child: CurrencyDropdown(value: currency, onChanged: (c) => setS(() => currency = c))),
              ]),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(due == null ? ctx.t.noTargetDate : ctx.dayLabelFull(due!)),
                trailing: due == null ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => setS(() => due = null)),
                onTap: () async {
                  final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100));
                  if (d != null) setS(() => due = DateTime(d.year, d.month, d.day, 12).millisecondsSinceEpoch);
                },
              ),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in palette)
                  GestureDetector(
                    onTap: () => setS(() => color = p),
                    child: CircleAvatar(
                      backgroundColor: Color(p),
                      radius: 14,
                      child: color == p ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t.ok)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final minor = parseMinor(target.text, currencyOf(currency).decimals);
    if (name.text.trim().isEmpty || minor == null || minor <= 0) {
      if (context.mounted) snack(context, context.t.invalidAmount);
      return;
    }
    await ref.read(repoProvider).saveGoal(
          id: g?.id,
          spaceId: g?.spaceId ?? ref.read(spaceIdProvider),
          name: name.text.trim(),
          targetMinor: minor,
          currency: currency,
          dueAt: due ?? 0,
          color: color,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final goals = ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
    final parts = ref.watch(contributionsProvider).valueOrNull ?? const <Contribution>[];
    final canWrite = ref.watch(canWriteProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.savingsGoals)),
      floatingActionButton: canWrite ? FloatingActionButton(onPressed: () => _edit(context, ref, null), child: const Icon(Icons.add)) : null,
      body: goals.isEmpty
          ? Center(child: Text(t.noGoals))
          : ListView(padding: const EdgeInsets.only(bottom: 88), children: [
              for (final g in goals)
                Builder(builder: (ctx) {
                  final cur = currencyOf(g.currency);
                  final p = goalProgress(target: g.targetMinor, saved: savedOf(g, parts), dueAtMs: g.dueAt, now: DateTime.now());
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: Color(g.color), child: const Icon(Icons.flag, color: Colors.white, size: 18)),
                    title: Text(g.name),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        LinearProgressIndicator(
                          value: p.ratio.clamp(0, 1).toDouble(),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                          color: Color(g.color),
                        ),
                        const SizedBox(height: 4),
                        Text('${formatMinor(p.saved, cur)} / ${formatMinor(g.targetMinor, cur)}  ·  ${(p.ratio * 100).floor()} %'),
                        if (g.dueAt > 0) Text(p.overdue ? t.goalOverdue : t.goalDue(ctx.dayLabelFull(g.dueAt))),
                        if (p.monthlyNeeded != null && p.monthlyNeeded! > 0) Text(t.perMonthNeeded(formatMinor(p.monthlyNeeded!, cur))),
                        if (p.remaining == 0) Text(t.goalReached),
                      ]),
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: g.id))),
                    onLongPress: canWrite ? () => _edit(context, ref, g) : null,
                  );
                }),
            ]),
    );
  }
}

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  Future<void> _contribute(BuildContext context, WidgetRef ref, Goal g, {required bool withdraw}) async {
    final cur = currencyOf(g.currency);
    final v = await promptText(context, withdraw ? context.t.withdraw : context.t.addContribution, hint: cur.symbol, numeric: true);
    if (v == null || v.isEmpty) return;
    final minor = parseMinor(v, cur.decimals);
    if (minor == null || minor <= 0) {
      if (context.mounted) snack(context, context.t.invalidAmount);
      return;
    }
    await ref.read(repoProvider).addContribution(g.spaceId, g.id, withdraw ? -minor : minor);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final g = (ref.watch(goalsProvider).valueOrNull ?? const <Goal>[]).where((x) => x.id == goalId).firstOrNull;
    if (g == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(t.noGoals)));
    final cur = currencyOf(g.currency);
    final parts = (ref.watch(contributionsProvider).valueOrNull ?? const <Contribution>[]).where((c) => c.goalId == g.id).toList();
    final canWrite = ref.watch(canWriteProvider);
    final p = goalProgress(target: g.targetMinor, saved: parts.fold(0, (a, c) => a + c.amountMinor), dueAtMs: g.dueAt, now: DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          if (canWrite)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (!await confirm(context, t.deleteGoalConfirm)) return;
                await ref.read(repoProvider).deleteGoal(g.spaceId, g.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Text(formatMinor(p.saved, cur), style: Theme.of(context).textTheme.displaySmall)),
        Center(child: Text(t.ofTarget(formatMinor(g.targetMinor, cur)))),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: p.ratio.clamp(0, 1).toDouble(), minHeight: 12, borderRadius: BorderRadius.circular(6), color: Color(g.color)),
        const SizedBox(height: 12),
        if (p.monthlyNeeded != null && p.monthlyNeeded! > 0) Text(t.perMonthNeeded(formatMinor(p.monthlyNeeded!, cur))),
        if (p.overdue) Text(t.goalOverdue),
        if (canWrite)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Expanded(child: FilledButton.icon(onPressed: () => _contribute(context, ref, g, withdraw: false), icon: const Icon(Icons.add), label: Text(t.addContribution))),
              const SizedBox(width: 12),
              OutlinedButton.icon(onPressed: () => _contribute(context, ref, g, withdraw: true), icon: const Icon(Icons.remove), label: Text(t.withdraw)),
            ]),
          ),
        const Divider(),
        for (final c in parts)
          ListTile(
            dense: true,
            leading: Icon(c.amountMinor >= 0 ? Icons.arrow_downward : Icons.arrow_upward),
            title: Text(formatMinor(c.amountMinor, cur)),
            subtitle: Text(context.dayLabelFull(c.at)),
            trailing: canWrite
                ? IconButton(icon: const Icon(Icons.close), onPressed: () => ref.read(repoProvider).deleteContribution(c.spaceId, c.id))
                : null,
          ),
      ]),
    );
  }
}
