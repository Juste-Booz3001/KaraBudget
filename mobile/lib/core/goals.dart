/// Avancement d'un objectif d'épargne.
typedef GoalProgress = ({int saved, int remaining, double ratio, int monthsLeft, int? monthlyNeeded, bool overdue});

GoalProgress goalProgress({required int target, required int saved, required int dueAtMs, required DateTime now}) {
  final remaining = target > saved ? target - saved : 0;
  final ratio = target <= 0 ? 0.0 : saved / target;
  if (dueAtMs <= 0) {
    return (saved: saved, remaining: remaining, ratio: ratio, monthsLeft: 0, monthlyNeeded: null, overdue: false);
  }
  final due = DateTime.fromMillisecondsSinceEpoch(dueAtMs);
  var months = (due.year - now.year) * 12 + due.month - now.month;
  if (due.day < now.day) months--; // le mois en cours n'est pas terminé
  final overdue = !due.isAfter(now);
  final left = overdue ? 0 : (months < 1 ? 1 : months);
  final needed = remaining == 0 ? 0 : (overdue ? null : (remaining + left - 1) ~/ left); // arrondi au supérieur
  return (saved: saved, remaining: remaining, ratio: ratio, monthsLeft: left, monthlyNeeded: needed, overdue: overdue && remaining > 0);
}
