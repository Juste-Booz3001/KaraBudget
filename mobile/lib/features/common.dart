import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../providers.dart';
import '../theme.dart';

const palette = <int>[
  0xFF4CAF50, 0xFF2196F3, 0xFF795548, 0xFF9C27B0, 0xFFF44336,
  0xFFFF9800, 0xFF009688, 0xFFE91E63, 0xFF3F51B5, 0xFF607D8B,
];

/// Sélecteur de mois. Un appui sur le nom du mois revient au mois en cours.
class MonthBar extends ConsumerWidget {
  const MonthBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(selectedMonthProvider);
    final k = context.kara;
    final now = DateTime.now();
    final isCurrent = m.year == now.year && m.month == now.month;
    void go(int delta) => ref.read(selectedMonthProvider.notifier).state = DateTime(m.year, m.month + delta);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: k.hairline)),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => go(-1)),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: isCurrent ? null : () => ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  toBeginningOfSentenceCase(context.monthLabel(m)) ?? context.monthLabel(m),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'Urbanist', fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => go(1)),
        ]),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.kara.muted)),
      );
}

/// Bandeau affiché quand l'utilisateur est « lecteur » de l'espace actif.
class ReadOnlyBanner extends ConsumerWidget {
  const ReadOnlyBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(canWriteProvider)) return const SizedBox.shrink();
    final k = context.kara;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: k.warn.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(Icons.visibility_outlined, size: 20, color: k.warn),
        const SizedBox(width: 12),
        Expanded(child: Text(context.t.readOnlyBanner, style: Theme.of(context).textTheme.bodyMedium)),
      ]),
    );
  }
}

Future<String?> promptText(BuildContext context, String title, {String? initial, String? hint, bool numeric = false}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(ctx.t.ok)),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t.no)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t.yes)),
        ],
      ),
    ) ??
    false;

void snack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

/// Fond pour le glisser-supprimer.
Widget deleteBackground() => Builder(
      builder: (context) => Container(
        color: context.kara.bad,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
    );

/// Pastille d'une catégorie : initiale sur fond teinté (reçu joint : icône de reçu).
class CategoryMark extends StatelessWidget {
  const CategoryMark({super.key, required this.color, required this.name, this.receipt = false, this.size = 44});
  final Color color;
  final String name;
  final bool receipt;
  final double size;
  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '·' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(size * .32)),
      child: receipt
          ? Icon(Icons.receipt_long_outlined, size: size * .46, color: color)
          : Text(letter, style: TextStyle(fontFamily: 'Urbanist', fontWeight: FontWeight.w800, fontSize: size * .42, color: color)),
    );
  }
}

/// État vide : une phrase qui dit quoi faire ensuite.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 44, color: context.kara.muted.withValues(alpha: .6)),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.kara.muted)),
          ]),
        ),
      );
}

/// Sélecteur de devise commun.
class CurrencyDropdown extends StatelessWidget {
  const CurrencyDropdown({super.key, required this.value, required this.onChanged, this.label});
  final String value;
  final ValueChanged<String> onChanged;
  final String? label;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        key: ValueKey(value),
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [for (final c in currenciesList) DropdownMenuItem(value: c, child: Text(c))],
        onChanged: (v) => v == null ? null : onChanged(v),
      );
}
