import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../core/rollover.dart';
import '../data/db.dart';
import '../providers.dart';
import '../theme.dart';
import 'categories.dart';
import 'common.dart';
import 'goals.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, Category c, Budget? current) async {
    final cur = ref.read(currencyProvider);
    final month = ref.read(selectedMonthProvider);
    final space = ref.read(spaceIdProvider);
    final ctrl = TextEditingController(text: current == null ? '' : plainMinor(current.limitMinor, cur).replaceAll('.', ','));
    var rollover = current?.rollover == 1;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(ctx.t.budgetOf(c.name)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: ctx.t.monthlyAmount, suffixText: cur.symbol),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ctx.t.rolloverTitle),
              subtitle: Text(ctx.t.rolloverHelp),
              value: rollover,
              onChanged: (v) => setS(() => rollover = v),
            ),
          ]),
          actions: [
            if (current != null) TextButton(onPressed: () => Navigator.pop(ctx, 'delete'), child: Text(ctx.t.delete)),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: Text(ctx.t.ok)),
          ],
        ),
      ),
    );
    if (action == null) return;
    final repo = ref.read(repoProvider);
    if (action == 'delete' || ctrl.text.trim().isEmpty) {
      if (current != null) await repo.removeBudget(space, c.id, monthKey(month));
      return;
    }
    final minor = parseMinor(ctrl.text, cur.decimals);
    if (minor == null) {
      if (context.mounted) snack(context, context.t.invalidAmount);
      return;
    }
    await repo.setBudget(space, c.id, monthKey(month), minor, rollover: rollover);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final allBudgets = ref.watch(allBudgetsProvider).valueOrNull ?? const <Budget>[];
    final cur = ref.watch(currencyProvider);
    final rates = ref.watch(rateTableProvider);
    final month = ref.watch(selectedMonthProvider);
    final key = monthKey(month);
    final canWrite = ref.watch(canWriteProvider);

    // dépensé par catégorie et par mois (13 mois), converti dans la devise d'affichage
    final spent = <String, Map<String, int>>{};
    var unconverted = 0;
    for (final e in ref.watch(rolloverExpensesProvider).valueOrNull ?? const <Expense>[]) {
      final v = rates.convert(e.amountMinor, e.currency, cur.code);
      if (v == null) {
        unconverted++;
        continue;
      }
      final byMonth = spent.putIfAbsent(e.categoryId ?? '', () => {});
      final k = monthKey(DateTime.fromMillisecondsSinceEpoch(e.spentAt));
      byMonth[k] = (byMonth[k] ?? 0) + v;
    }

    final k = context.kara;
    final text = Theme.of(context).textTheme;

    Widget budgetCard(Category c) {
      final mine = allBudgets.where((b) => b.categoryId == c.id).toList();
      final byMonth = {for (final b in mine) b.month: BudgetMonth(b.limitMinor, rollover: b.rollover == 1)};
      final current = mine.where((b) => b.month == key).firstOrNull;
      final eff = effectiveBudget(month: key, budgets: byMonth, spent: spent[c.id]?.map((k, v) => MapEntry(k, v)) ?? const {});
      final spentNow = spent[c.id]?[key] ?? 0;
      final limit = current == null ? null : eff.effective;
      final ratio = limit == null || limit <= 0 ? (spentNow > 0 && limit != null ? 1.0 : 0.0) : spentNow / limit;
      final over = limit != null && spentNow > limit;
      final statusColor = over ? k.bad : (ratio >= .8 ? k.warn : Color(c.color));
      return Card(
        child: InkWell(
          onTap: canWrite ? () => _edit(context, ref, c, current) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CategoryMark(color: Color(c.color), name: c.name, size: 36),
                const SizedBox(width: 12),
                Expanded(child: Text(c.name, style: text.titleMedium)),
                if (current?.rollover == 1) Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.autorenew, size: 18, color: k.muted)),
                if (limit != null) Text('${(ratio * 100).round()} %', style: text.titleMedium?.copyWith(color: statusColor, fontFeatures: amountFeatures)),
              ]),
              if (limit == null)
                Padding(padding: const EdgeInsets.only(top: 10), child: Text(t.noBudgetSet, style: text.bodyMedium?.copyWith(color: k.muted)))
              else ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: ratio.clamp(0, 1).toDouble(),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                  color: statusColor,
                ),
                const SizedBox(height: 10),
                Text.rich(TextSpan(children: [
                  TextSpan(text: formatMinor(spentNow, cur), style: text.titleSmall?.copyWith(fontFeatures: amountFeatures)),
                  TextSpan(text: ' / ${formatMinor(limit, cur)}', style: text.bodyMedium?.copyWith(color: k.muted, fontFeatures: amountFeatures)),
                ])),
                if (over)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(t.exceededBy(formatMinor(spentNow - limit, cur)), style: text.bodySmall?.copyWith(color: k.bad, fontWeight: FontWeight.w600)),
                  ),
                if (eff.carry != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      eff.carry > 0 ? t.carryPositive(formatMinor(eff.carry, cur)) : t.carryNegative(formatMinor(-eff.carry, cur)),
                      style: text.bodySmall?.copyWith(color: k.muted),
                    ),
                  ),
              ],
            ]),
          ),
        ),
      );
    }

    return Column(children: [
      const ReadOnlyBanner(),
      const MonthBar(),
      if (unconverted > 0)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(t.unconvertedWarning(unconverted), style: text.bodySmall?.copyWith(color: k.muted))),
      Expanded(
        child: ListView(padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.paddingOf(context).bottom), children: [
          for (final c in cats) ...[budgetCard(c), const SizedBox(height: 10)],
          const SizedBox(height: 6),
          Card(
            child: Column(children: [
              ListTile(
                leading: Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary),
                title: Text(t.savingsGoals),
                trailing: Icon(Icons.chevron_right, color: k.muted),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
              ),
              const Divider(indent: 20, endIndent: 20),
              ListTile(
                leading: Icon(Icons.category_outlined, color: Theme.of(context).colorScheme.primary),
                title: Text(t.manageCategories),
                trailing: Icon(Icons.chevron_right, color: k.muted),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
