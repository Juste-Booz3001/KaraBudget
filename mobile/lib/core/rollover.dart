/// Budget d'un mois pour une catégorie.
class BudgetMonth {
  const BudgetMonth(this.limit, {this.rollover = false});
  final int limit;
  final bool rollover; // reporte le reste (ou le dépassement) du mois précédent
}

String previousMonthKey(String month) {
  final y = int.parse(month.substring(0, 4)), m = int.parse(month.substring(5, 7));
  final d = DateTime(y, m - 1);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

typedef EffectiveBudget = ({int limit, int carry, int effective});

/// Budget disponible = limite du mois + report. Le report vient du mois précédent
/// (limite + son propre report − dépensé), à condition que ce mois ait un budget ;
/// la chaîne remonte au plus de [maxBack] mois (comme des enveloppes).
EffectiveBudget effectiveBudget({
  required String month,
  required Map<String, BudgetMonth> budgets,
  required Map<String, int> spent,
  int maxBack = 12,
}) {
  int carryInto(String m, int depth) {
    if (depth >= maxBack) return 0;
    final b = budgets[m];
    if (b == null || !b.rollover) return 0;
    final prev = previousMonthKey(m);
    final pb = budgets[prev];
    if (pb == null) return 0;
    return pb.limit + carryInto(prev, depth + 1) - (spent[prev] ?? 0);
  }

  final b = budgets[month];
  if (b == null) return (limit: 0, carry: 0, effective: 0);
  final carry = carryInto(month, 0);
  return (limit: b.limit, carry: carry, effective: b.limit + carry);
}
