import 'dart:math';

/// Une dépense déjà convertie dans la devise d'affichage (montant en unité mineure).
class Spend {
  const Spend(this.amount, this.at, this.categoryId);
  final int amount;
  final int at; // ms epoch
  final String? categoryId;
}

int totalOf(Iterable<Spend> list) => list.fold(0, (a, s) => a + s.amount);

int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// Variation entre deux mois. [pct] est null si le mois précédent est à 0.
({int delta, double? pct}) compareTotals(int current, int previous) =>
    (delta: current - previous, pct: previous == 0 ? null : (current - previous) * 100 / previous);

typedef CategoryShare = ({String? categoryId, int amount, double share});

/// Les [limit] plus grosses catégories (le reste est regroupé dans « autres » par l'appelant).
List<CategoryShare> topCategories(Iterable<Spend> list, {int limit = 5}) {
  final by = <String?, int>{};
  var total = 0;
  for (final s in list) {
    by[s.categoryId] = (by[s.categoryId] ?? 0) + s.amount;
    total += s.amount;
  }
  final entries = by.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : (a.key ?? '').compareTo(b.key ?? '');
    });
  return [
    for (final e in entries.take(limit))
      (categoryId: e.key, amount: e.value, share: total == 0 ? 0.0 : e.value * 100 / total),
  ];
}

typedef CategoryDelta = ({String? categoryId, int current, int previous, int delta});

/// Évolution par catégorie entre le mois affiché et le précédent, triée par variation absolue.
List<CategoryDelta> categoryDeltas(Iterable<Spend> current, Iterable<Spend> previous) {
  final cur = <String?, int>{}, prev = <String?, int>{};
  for (final s in current) {
    cur[s.categoryId] = (cur[s.categoryId] ?? 0) + s.amount;
  }
  for (final s in previous) {
    prev[s.categoryId] = (prev[s.categoryId] ?? 0) + s.amount;
  }
  final keys = {...cur.keys, ...prev.keys};
  final out = [
    for (final k in keys)
      (categoryId: k, current: cur[k] ?? 0, previous: prev[k] ?? 0, delta: (cur[k] ?? 0) - (prev[k] ?? 0)),
  ]..sort((a, b) {
      final c = b.delta.abs().compareTo(a.delta.abs());
      return c != 0 ? c : (a.categoryId ?? '').compareTo(b.categoryId ?? '');
    });
  return out;
}

/// Nombre de jours « écoulés » pour la moyenne : jour du mois si c'est le mois courant,
/// tout le mois si c'est un mois passé, 0 pour un mois futur.
int elapsedDays(DateTime month, DateTime now) {
  if (isSameMonth(month, now)) return now.day;
  return DateTime(month.year, month.month).isBefore(DateTime(now.year, now.month)) ? daysInMonth(month) : 0;
}

/// Dépense moyenne par jour écoulé (unité mineure, arrondie).
int averagePerDay(int total, DateTime month, DateTime now) {
  final d = elapsedDays(month, now);
  return d == 0 ? 0 : (total / d).round();
}

typedef Projection = ({int projected, bool reliable});

/// Projection de fin de mois au rythme actuel. null si le mois n'est pas le mois courant.
/// [reliable] : au moins 5 jours de recul, sinon l'estimation est trop volatile.
Projection? projectMonth(int total, DateTime month, DateTime now) {
  if (!isSameMonth(month, now)) return null;
  final days = daysInMonth(month);
  final projected = (total * days / max(now.day, 1)).round();
  return (projected: max(projected, total), reliable: now.day >= 5);
}
