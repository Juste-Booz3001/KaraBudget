import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../core/reports.dart';
import '../data/db.dart';
import '../providers.dart';
import '../theme.dart';
import 'common.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cur = ref.watch(currencyProvider);
    final cats = {for (final c in ref.watch(categoriesProvider).valueOrNull ?? const <Category>[]) c.id: c};
    final month = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final current = ref.watch(monthSpendsProvider);
    final previous = ref.watch(previousMonthSpendsProvider);
    final rates = ref.watch(rateTableProvider);
    final history = convertSpends(ref.watch(lastMonthsExpensesProvider).valueOrNull ?? const <Expense>[], rates, cur.code).spends;
    final div = pow(10, cur.decimals).toDouble();

    final total = totalOf(current.spends);
    final prevTotal = totalOf(previous.spends);
    final cmp = compareTotals(total, prevTotal);
    final avg = averagePerDay(total, month, now);
    final proj = projectMonth(total, month, now);
    final top = topCategories(current.spends, limit: 50);
    final deltas = categoryDeltas(current.spends, previous.spends).where((d) => d.delta != 0).take(5).toList();
    final unconverted = current.unconverted + previous.unconverted;

    final months = [for (var i = 5; i >= 0; i--) DateTime(month.year, month.month - i)];
    final totals = {for (final m in months) monthKey(m): 0};
    for (final s in history) {
      final k = monthKey(DateTime.fromMillisecondsSinceEpoch(s.at));
      if (totals.containsKey(k)) totals[k] = totals[k]! + s.amount;
    }
    final spots = [for (var i = 0; i < months.length; i++) FlSpot(i.toDouble(), totals[monthKey(months[i])]! / div)];

    final k = context.kara;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget stat(String label, String value, {String? sub, Color? subColor}) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(label, style: text.bodySmall?.copyWith(color: k.muted)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: text.titleLarge?.copyWith(fontFeatures: amountFeatures)),
              ),
              if (sub != null) Text(sub, style: text.bodySmall?.copyWith(color: subColor ?? k.muted, fontWeight: FontWeight.w600)),
            ]),
          ),
        );

    String pct(double? p) => p == null ? t.noPreviousData : '${p >= 0 ? '+' : ''}${p.toStringAsFixed(0)} %';
    final up = cmp.delta > 0; // dépenser plus = en rouge

    return ListView(padding: EdgeInsets.only(bottom: 32 + MediaQuery.paddingOf(context).bottom), children: [
      const MonthBar(),
      if (unconverted > 0) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text(t.unconvertedWarning(unconverted), style: text.bodySmall?.copyWith(color: k.muted))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            stat(t.monthTotal, formatMinor(total, cur),
                sub: prevTotal == 0 && total == 0 ? null : '${pct(cmp.pct)} ${t.vsPreviousMonth}', subColor: cmp.delta == 0 ? null : (up ? k.bad : k.good)),
            stat(t.averagePerDay, formatMinor(avg, cur)),
            if (proj != null) stat(t.projectedEndOfMonth, formatMinor(proj.projected, cur), sub: proj.reliable ? t.atCurrentPace : t.projectionEarly),
            stat(t.previousMonth, formatMinor(prevTotal, cur)),
          ],
        ),
      ),
      SectionHeader(t.byCategory),
      if (top.isEmpty)
        EmptyState(icon: Icons.pie_chart_outline, text: t.noDataThisMonth)
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
              child: Column(children: [
                SizedBox(
                  height: 190,
                  child: Stack(alignment: Alignment.center, children: [
                    PieChart(PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 66,
                      sections: [
                        for (final e in top)
                          PieChartSectionData(
                            value: e.amount.toDouble(),
                            color: Color(cats[e.categoryId]?.color ?? 0xFF9E9E9E),
                            showTitle: false,
                            radius: 22,
                          ),
                      ],
                    )),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(t.monthTotal, style: text.bodySmall?.copyWith(color: k.muted)),
                      Text(formatMinor(total, cur, symbol: false), style: text.titleLarge?.copyWith(fontFeatures: amountFeatures)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 8),
                for (final e in top)
                  ListTile(
                    dense: true,
                    leading: CategoryMark(color: Color(cats[e.categoryId]?.color ?? 0xFF9E9E9E), name: cats[e.categoryId]?.name ?? t.noCategory, size: 32),
                    title: Text(cats[e.categoryId]?.name ?? t.noCategory),
                    subtitle: Text('${e.share.round()} %', style: text.bodySmall?.copyWith(color: k.muted)),
                    trailing: Text(formatMinor(e.amount, cur), style: text.titleSmall?.copyWith(fontFeatures: amountFeatures)),
                  ),
              ]),
            ),
          ),
        ),
      if (deltas.isNotEmpty) ...[
        SectionHeader(t.changesVsPrevious),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Column(children: [
              for (var i = 0; i < deltas.length; i++) ...[
                if (i > 0) const Divider(indent: 20, endIndent: 20),
                Builder(builder: (_) {
                  final d = deltas[i];
                  final color = d.delta > 0 ? k.bad : k.good;
                  return ListTile(
                    leading: Icon(d.delta > 0 ? Icons.trending_up : Icons.trending_down, color: color),
                    title: Text(cats[d.categoryId]?.name ?? t.noCategory),
                    subtitle: Text('${formatMinor(d.previous, cur)} → ${formatMinor(d.current, cur)}', style: text.bodySmall?.copyWith(color: k.muted)),
                    trailing: Text('${d.delta > 0 ? '+' : ''}${formatMinor(d.delta, cur)}', style: text.titleSmall?.copyWith(color: color, fontFeatures: amountFeatures)),
                  );
                }),
              ],
            ]),
          ),
        ),
      ],
      SectionHeader(t.lastSixMonths),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 20, 12),
            child: SizedBox(
              height: 190,
              child: LineChart(LineChartData(
                minY: 0,
                gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: k.hairline, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(context.shortMonth(months[v.toInt().clamp(0, 5)]), style: text.bodySmall?.copyWith(color: k.muted)),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: .25,
                    color: scheme.primary,
                    barWidth: 3.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(radius: 4, color: k.card, strokeWidth: 2.5, strokeColor: scheme.primary),
                    ),
                    belowBarData: BarAreaData(show: true, color: scheme.primary.withValues(alpha: .10)),
                  ),
                ],
              )),
            ),
          ),
        ),
      ),
    ]);
  }
}
