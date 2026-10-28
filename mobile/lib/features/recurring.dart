import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../data/db.dart';
import '../providers.dart';
import 'common.dart';


String _periodLabel(BuildContext c, String p) => switch (p) { 'daily' => c.t.everyDay, 'weekly' => c.t.everyWeek, _ => c.t.everyMonth };

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, Recurring? r) async {
    final cur = ref.read(currencyProvider);
    final amount = TextEditingController(text: r == null ? '' : plainMinor(r.amountMinor, currencyOf(r.currency)).replaceAll('.', ','));
    final note = TextEditingController(text: r?.note);
    var period = r?.period ?? 'monthly';
    var due = DateTime.fromMillisecondsSinceEpoch(r?.nextDue ?? DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch);
    String? cat = r?.categoryId;
    final cats = ref.read(categoriesProvider).valueOrNull ?? const <Category>[];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(r == null ? ctx.t.newRecurring : ctx.t.edit),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: ctx.t.amount, suffixText: cur.symbol)),
              TextField(controller: note, decoration: InputDecoration(labelText: ctx.t.noteRecurringHint)),
              DropdownButtonFormField<String>(
                initialValue: period,
                items: [for (final p in const ['daily', 'weekly', 'monthly']) DropdownMenuItem(value: p, child: Text(_periodLabel(ctx, p)))],
                onChanged: (v) => setS(() => period = v!),
              ),
              DropdownButtonFormField<String?>(
                initialValue: cats.any((c) => c.id == cat) ? cat : null,
                hint: Text(ctx.t.category),
                items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))],
                onChanged: (v) => setS(() => cat = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ctx.t.nextDue(ctx.dayLabelFull(due.millisecondsSinceEpoch))),
                trailing: const Icon(Icons.event),
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: due, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null) setS(() => due = DateTime(d.year, d.month, d.day, 9));
                },
              ),
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
    final minor = parseMinor(amount.text, cur.decimals);
    if (minor == null || minor <= 0) {
      if (context.mounted) snack(context, context.t.invalidAmount);
      return;
    }
    final repo = ref.read(repoProvider);
    final String space = r?.spaceId ?? ref.read(spaceIdProvider);
    await repo.saveRecurring(
      id: r?.id,
      spaceId: space,
      amountMinor: minor,
      currency: r?.currency ?? cur.code,
      categoryId: cat,
      note: note.text.trim(),
      period: period,
      nextDue: due.millisecondsSinceEpoch,
    );
    await repo.materializeDue(space); // échéance déjà passée => dépense créée tout de suite
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringProvider).valueOrNull ?? const <Recurring>[];
    final cats = <String, Category>{for (final c in ref.watch(categoriesProvider).valueOrNull ?? const <Category>[]) c.id: c};
    return Scaffold(
      appBar: AppBar(title: Text(context.t.recurringExpenses)),
      floatingActionButton: ref.watch(canWriteProvider) ? FloatingActionButton(onPressed: () => _edit(context, ref, null), child: const Icon(Icons.add)) : null,
      body: rules.isEmpty
          ? Center(child: Text(context.t.noRecurring))
          : ListView(children: [
              for (final r in rules)
                Dismissible(
                  key: ValueKey('${r.spaceId}/${r.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (_) => ref.read(repoProvider).deleteRecurring(r.spaceId, r.id),
                  child: ListTile(
                    leading: const Icon(Icons.repeat),
                    title: Text(r.note.isEmpty ? (cats[r.categoryId]?.name ?? context.t.recurring) : r.note),
                    subtitle: Text('${_periodLabel(context, r.period)} · ${context.t.nextDue(context.dayLabelFull(r.nextDue))}'),
                    trailing: Text(formatMinor(r.amountMinor, currencyOf(r.currency))),
                    onTap: () => _edit(context, ref, r),
                  ),
                ),
            ]),
    );
  }
}
