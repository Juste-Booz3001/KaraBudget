import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/core/goals.dart';

void main() {
  final now = DateTime(2026, 10, 26);
  int ms(int y, int m, int d) => DateTime(y, m, d).millisecondsSinceEpoch;

  test('objectif sans date : pas de montant mensuel', () {
    final p = goalProgress(target: 1000, saved: 250, dueAtMs: 0, now: now);
    expect(p.remaining, 750);
    expect(p.ratio, 0.25);
    expect(p.monthlyNeeded, isNull);
    expect(p.overdue, isFalse);
  });

  test('montant mensuel nécessaire, arrondi au supérieur', () {
    final p = goalProgress(target: 1000, saved: 0, dueAtMs: ms(2027, 1, 31), now: now);
    expect(p.monthsLeft, 3);
    expect(p.monthlyNeeded, 334);
  });

  test('échéance ce mois-ci : au moins un mois', () {
    final p = goalProgress(target: 100, saved: 0, dueAtMs: ms(2026, 10, 30), now: now);
    expect(p.monthsLeft, 1);
    expect(p.monthlyNeeded, 100);
  });

  test('objectif atteint, ou date dépassée', () {
    expect(goalProgress(target: 100, saved: 150, dueAtMs: ms(2027, 1, 1), now: now).monthlyNeeded, 0);
    final late = goalProgress(target: 100, saved: 10, dueAtMs: ms(2026, 9, 1), now: now);
    expect(late.overdue, isTrue);
    expect(late.monthlyNeeded, isNull);
    expect(goalProgress(target: 100, saved: 100, dueAtMs: ms(2026, 9, 1), now: now).overdue, isFalse);
  });
}
