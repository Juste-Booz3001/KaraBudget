import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, toBeginningOfSentenceCase;

import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../core/reports.dart';
import '../core/tags.dart';
import '../data/db.dart';
import '../providers.dart';
import '../theme.dart';
import 'common.dart';
import 'expense_edit.dart';

/// Ligne de dépense (liste du mois et résultats de recherche).
/// [showDate] : à désactiver quand la ligne est déjà sous un en-tête de jour.
class ExpenseTile extends ConsumerWidget {
  const ExpenseTile({super.key, required this.expense, required this.categories, this.members = const [], this.showDate = true});
  final Expense expense;
  final Map<String, Category> categories;
  final List<MemberInfo> members;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = expense;
    final k = context.kara;
    final text = Theme.of(context).textTheme;
    final cat = categories[e.categoryId];
    final catName = cat?.name ?? context.t.noCategory;
    final payer = members.where((m) => m.userId == e.paidBy).firstOrNull;
    final tags = splitTags(e.tags);
    final shared = e.splitJson.isNotEmpty && payer != null;
    final hasNote = e.note.isNotEmpty;
    final subtitle = [
      if (hasNote) catName,
      if (showDate) context.dayLabel(e.spentAt),
      if (shared) context.t.paidByName(payer.label),
      if (tags.isNotEmpty) tags.map((t) => '#$t').join(' '),
    ].join(' · ');
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseEditScreen(expense: e))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          CategoryMark(color: Color(cat?.color ?? 0xFF9E9E9E), name: catName, receipt: e.attachmentId != null),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hasNote ? e.note : catName, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
              if (subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: k.muted)),
                ),
            ]),
          ),
          const SizedBox(width: 12),
          Text(
            formatMinor(e.amountMinor, currencyOf(e.currency)),
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontFeatures: amountFeatures),
          ),
        ]),
      ),
    );
  }
}

/// Carte du mois : total en grand + répartition par catégorie en une barre.
class _MonthHero extends ConsumerWidget {
  const _MonthHero({required this.converted, required this.cats});
  final ConvertedSpends converted;
  final Map<String, Category> cats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final k = context.kara;
    final cur = ref.watch(currencyProvider);
    final month = ref.watch(selectedMonthProvider);
    final total = totalOf(converted.spends);
    final avg = averagePerDay(total, month, DateTime.now());
    final shares = topCategories(converted.spends, limit: 8);
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(color: k.onHeroMuted);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(color: k.hero, borderRadius: BorderRadius.circular(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.monthTotal, style: labelStyle),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          // le montant glisse vers sa nouvelle valeur quand on change de mois ou d'espace
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: total.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              formatMinor(v.round(), cur),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: k.onHero, fontFeatures: amountFeatures),
            ),
          ),
        ),
        if (total > 0) ...[
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(children: [
                for (var i = 0; i < shares.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: (shares[i].share * 100).round().clamp(1, 10000),
                    child: ColoredBox(color: Color(cats[shares[i].categoryId]?.color ?? 0xFF9E9E9E)),
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Text(t.averagePerDay, style: labelStyle),
            const Spacer(),
            Text(
              formatMinor(avg, cur),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: k.onHero, fontFeatures: amountFeatures),
            ),
          ]),
        ],
        if (converted.unconverted > 0) ...[
          const SizedBox(height: 10),
          Text(t.unconvertedWarning(converted.unconverted), style: labelStyle?.copyWith(fontSize: 12)),
        ],
      ]),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.total, required this.cur});
  final DateTime day;
  final int total;
  final Currency cur;
  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE d MMM', context.dateLocale).format(day);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Row(children: [
        Expanded(child: Text(toBeginningOfSentenceCase(label) ?? label, style: text.titleSmall?.copyWith(color: context.kara.muted))),
        Text(formatMinor(total, cur), style: text.titleSmall?.copyWith(color: context.kara.muted, fontFeatures: amountFeatures)),
      ]),
    );
  }
}

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(monthExpensesProvider);
    final cats = {for (final c in ref.watch(categoriesProvider).valueOrNull ?? const <Category>[]) c.id: c};
    final cur = ref.watch(currencyProvider);
    final rates = ref.watch(rateTableProvider);
    final canWrite = ref.watch(canWriteProvider);
    final space = ref.watch(spaceIdProvider);
    final members = ref.watch(isSharedSpaceProvider) ? (ref.watch(membersProvider(space)).valueOrNull ?? const <MemberInfo>[]) : const <MemberInfo>[];
    final converted = ref.watch(monthSpendsProvider);

    return Column(children: [
      const ReadOnlyBanner(),
      const MonthBar(),
      Expanded(
        child: expenses.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            if (list.isEmpty) return EmptyState(icon: Icons.receipt_long_outlined, text: context.t.noExpensesThisMonth);

            // regroupement par jour (la liste arrive déjà triée du plus récent au plus ancien)
            final groups = <DateTime, List<Expense>>{};
            for (final e in list) {
              final d = DateTime.fromMillisecondsSinceEpoch(e.spentAt);
              groups.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(e);
            }
            final days = groups.keys.toList();

            return ListView.builder(
              padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
              itemCount: days.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) return _MonthHero(converted: converted, cats: cats);
                final day = days[i - 1];
                final items = groups[day]!;
                final dayTotal = items.fold<int>(0, (a, e) => a + (rates.convert(e.amountMinor, e.currency, cur.code) ?? 0));
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _DayHeader(day: day, total: dayTotal, cur: cur),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Column(children: [
                        for (var j = 0; j < items.length; j++) ...[
                          if (j > 0) const Divider(indent: 74),
                          _row(ref, items[j], cats, members, canWrite),
                        ],
                      ]),
                    ),
                  ),
                ]);
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _row(WidgetRef ref, Expense e, Map<String, Category> cats, List<MemberInfo> members, bool canWrite) {
    final tile = ExpenseTile(expense: e, categories: cats, members: members, showDate: false);
    if (!canWrite) return tile;
    return Dismissible(
      key: ValueKey('${e.spaceId}/${e.id}'),
      direction: DismissDirection.endToStart,
      background: deleteBackground(),
      onDismissed: (_) => ref.read(repoProvider).deleteExpense(e.spaceId, e.id),
      child: tile,
    );
  }
}
