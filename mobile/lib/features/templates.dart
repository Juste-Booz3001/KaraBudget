import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../data/db.dart';
import '../providers.dart';
import 'common.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, QuickTemplate? tpl) async {
    final name = TextEditingController(text: tpl?.name);
    var currency = tpl?.currency ?? ref.read(settingsProvider).currency;
    final amount = TextEditingController(text: tpl?.amountMinor == null ? '' : plainMinor(tpl!.amountMinor!, currencyOf(currency)).replaceAll('.', ','));
    final note = TextEditingController(text: tpl?.note);
    final tags = TextEditingController(text: tpl?.tags.replaceAll(',', ', '));
    String? cat = tpl?.categoryId;
    final cats = ref.read(categoriesProvider).valueOrNull ?? const <Category>[];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(tpl == null ? ctx.t.newTemplate : ctx.t.editTemplate),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: ctx.t.templateName)),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: ctx.t.amountOptional),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 100, child: CurrencyDropdown(value: currency, onChanged: (c) => setS(() => currency = c))),
              ]),
              DropdownButtonFormField<String?>(
                initialValue: cats.any((c) => c.id == cat) ? cat : null,
                hint: Text(ctx.t.category),
                items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))],
                onChanged: (v) => setS(() => cat = v),
              ),
              TextField(controller: note, decoration: InputDecoration(labelText: ctx.t.note)),
              TextField(controller: tags, decoration: InputDecoration(labelText: ctx.t.tags)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t.ok)),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await ref.read(repoProvider).saveTemplate(
          id: tpl?.id,
          name: name.text.trim(),
          amountMinor: parseMinor(amount.text, currencyOf(currency).decimals),
          currency: currency,
          categoryId: cat,
          note: note.text.trim(),
          tags: tags.text,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final list = ref.watch(templatesProvider).valueOrNull ?? const <QuickTemplate>[];
    final cats = {for (final c in ref.watch(categoriesProvider).valueOrNull ?? const <Category>[]) c.id: c};
    return Scaffold(
      appBar: AppBar(title: Text(t.quickTemplates)),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(context, ref, null), child: const Icon(Icons.add)),
      body: list.isEmpty
          ? Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(t.noTemplates, textAlign: TextAlign.center)))
          : ListView(children: [
              for (final tpl in list)
                Dismissible(
                  key: ValueKey(tpl.id),
                  direction: DismissDirection.endToStart,
                  background: deleteBackground(),
                  onDismissed: (_) => ref.read(repoProvider).deleteTemplate(tpl.id),
                  child: ListTile(
                    leading: const Icon(Icons.bolt),
                    title: Text(tpl.name),
                    subtitle: Text([cats[tpl.categoryId]?.name, if (tpl.note.isNotEmpty) tpl.note].whereType<String>().join(' · ')),
                    trailing: tpl.amountMinor == null ? null : Text(formatMinor(tpl.amountMinor!, currencyOf(tpl.currency ?? 'USD'))),
                    onTap: () => _edit(context, ref, tpl),
                  ),
                ),
            ]),
    );
  }
}
