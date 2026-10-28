import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/core/rollover.dart';

void main() {
  test('previousMonthKey', () {
    expect(previousMonthKey('2026-01'), '2025-12');
    expect(previousMonthKey('2026-10'), '2026-09');
  });

  test('le reste du mois précédent est reporté', () {
    final b = {
      '2026-08': const BudgetMonth(1000),
      '2026-09': const BudgetMonth(1000, rollover: true),
      '2026-10': const BudgetMonth(1000, rollover: true),
    };
    final spent = {'2026-08': 700, '2026-09': 1200};
    final sep = effectiveBudget(month: '2026-09', budgets: b, spent: spent);
    expect(sep.carry, 300);
    expect(sep.effective, 1300);
    final oct = effectiveBudget(month: '2026-10', budgets: b, spent: spent);
    expect(oct.carry, 100); // 1000 + 300 - 1200
    expect(oct.effective, 1100);
  });

  test('un dépassement est reporté en négatif', () {
    final b = {'2026-09': const BudgetMonth(1000), '2026-10': const BudgetMonth(1000, rollover: true)};
    final r = effectiveBudget(month: '2026-10', budgets: b, spent: {'2026-09': 1500});
    expect(r.carry, -500);
    expect(r.effective, 500);
  });

  test('sans option de report, ou sans budget le mois précédent : pas de report', () {
    final off = effectiveBudget(
        month: '2026-10', budgets: {'2026-09': const BudgetMonth(1000), '2026-10': const BudgetMonth(1000)}, spent: {'2026-09': 100});
    expect(off.carry, 0);
    final noPrev = effectiveBudget(month: '2026-10', budgets: {'2026-10': const BudgetMonth(1000, rollover: true)}, spent: {'2026-09': 100});
    expect(noPrev.carry, 0);
    expect(effectiveBudget(month: '2026-10', budgets: {}, spent: {}).effective, 0);
  });

  test('la chaîne de report est bornée', () {
    final b = <String, BudgetMonth>{};
    var m = '2026-10';
    for (var i = 0; i < 60; i++) {
      b[m] = const BudgetMonth(100, rollover: true);
      m = previousMonthKey(m);
    }
    final r = effectiveBudget(month: '2026-10', budgets: b, spent: {}, maxBack: 12);
    expect(r.carry, 1200); // 12 mois de 100 non dépensés
  });
}
