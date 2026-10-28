import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../core/rates.dart';
import '../data/db.dart';
import '../providers.dart';
import 'common.dart';

class RatesScreen extends ConsumerWidget {
  const RatesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, Rate? r) async {
    final display = ref.read(currencyProvider).code;
    var from = r?.fromCurrency ?? (display == 'EUR' ? 'USD' : 'EUR');
    var to = r?.toCurrency ?? display;
    final rate = TextEditingController(text: r == null ? '' : formatRatePpm(r.ratePpm));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(r == null ? ctx.t.newRate : ctx.t.editRate),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: CurrencyDropdown(value: from, label: ctx.t.rateFrom, onChanged: (c) => setS(() => from = c))),
              const SizedBox(width: 12),
              Expanded(child: CurrencyDropdown(value: to, label: ctx.t.rateTo, onChanged: (c) => setS(() => to = c))),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: rate,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: ctx.t.rateValue(from, to), helperText: ctx.t.rateHelp),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t.ok)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final ppm = parseRatePpm(rate.text);
    if (ppm == null || from == to) {
      if (context.mounted) snack(context, context.t.invalidRate);
      return;
    }
    final String space = r?.spaceId ?? ref.read(spaceIdProvider);
    final repo = ref.read(repoProvider);
    if (r != null && (r.fromCurrency != from || r.toCurrency != to)) await repo.removeRate(space, r.fromCurrency, r.toCurrency);
    await repo.setRate(space, from, to, ppm);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final rows = ref.watch(ratesProvider).valueOrNull ?? const <Rate>[];
    final display = ref.watch(currencyProvider).code;
    final table = ref.watch(rateTableProvider);
    final canWrite = ref.watch(canWriteProvider);
    // devises utilisées dans les dépenses mais sans taux vers la devise d'affichage
    final used = {for (final e in ref.watch(allExpensesProvider).valueOrNull ?? const <Expense>[]) e.currency};
    final missing = [for (final c in used) if (!table.canConvert(c, display)) c]..sort();
    return Scaffold(
      appBar: AppBar(title: Text(t.exchangeRates)),
      floatingActionButton: canWrite ? FloatingActionButton(onPressed: () => _edit(context, ref, null), child: const Icon(Icons.add)) : null,
      body: ListView(padding: const EdgeInsets.only(bottom: 88), children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(t.ratesIntro(display))),
        if (missing.isNotEmpty)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(padding: const EdgeInsets.all(12), child: Text(t.missingRates(missing.join(', '), display))),
          ),
        for (final r in rows)
          Dismissible(
            key: ValueKey('${r.spaceId}/${r.id}'),
            direction: canWrite ? DismissDirection.endToStart : DismissDirection.none,
            background: deleteBackground(),
            onDismissed: (_) => ref.read(repoProvider).removeRate(r.spaceId, r.fromCurrency, r.toCurrency),
            child: ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: Text('1 ${r.fromCurrency} = ${formatRatePpm(r.ratePpm)} ${r.toCurrency}'),
              onTap: canWrite ? () => _edit(context, ref, r) : null,
            ),
          ),
      ]),
    );
  }
}
