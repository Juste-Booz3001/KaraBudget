import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/core/reports.dart';

void main() {
  final oct = DateTime(2026, 10);
  final now = DateTime(2026, 10, 26, 10);

  test('compareTotals', () {
    expect(compareTotals(150, 100).delta, 50);
    expect(compareTotals(150, 100).pct, 50.0);
    expect(compareTotals(50, 100).pct, -50.0);
    expect(compareTotals(10, 0).pct, isNull);
  });

  test('topCategories : tri, parts, limite', () {
    const list = [Spend(300, 0, 'a'), Spend(500, 0, 'b'), Spend(200, 0, null), Spend(100, 0, 'a')];
    final top = topCategories(list);
    expect(top.map((e) => e.categoryId).toList(), ['b', 'a', null]);
    expect(top[0].amount, 500);
    expect(top[1].amount, 400);
    expect(top[0].share, closeTo(45.45, 0.01)); // 500 / 1100
    expect(topCategories(list, limit: 1), hasLength(1));
    expect(topCategories(const []), isEmpty);
  });

  test('categoryDeltas : tri par variation absolue', () {
    final d = categoryDeltas(const [Spend(300, 0, 'a'), Spend(50, 0, 'c')], const [Spend(100, 0, 'a'), Spend(400, 0, 'b')]);
    expect(d.map((e) => e.categoryId).toList(), ['b', 'a', 'c']);
    expect(d[0].delta, -400);
    expect(d[1].delta, 200);
  });

  test('moyenne par jour', () {
    expect(averagePerDay(2600, oct, now), 100); // 26 jours écoulés
    expect(averagePerDay(3000, DateTime(2026, 9), now), 100); // mois passé : 30 jours
    expect(averagePerDay(500, DateTime(2026, 11), now), 0); // mois futur
  });

  test('projection de fin de mois', () {
    final p = projectMonth(2600, oct, now)!;
    expect(p.projected, 3100); // 2600 / 26 * 31
    expect(p.reliable, isTrue);
    expect(projectMonth(100, oct, DateTime(2026, 10, 3))!.reliable, isFalse);
    expect(projectMonth(100, DateTime(2026, 9), now), isNull);
    expect(projectMonth(0, oct, now)!.projected, 0);
  });

  test('daysInMonth', () {
    expect(daysInMonth(DateTime(2026, 2)), 28);
    expect(daysInMonth(DateTime(2028, 2)), 29);
    expect(daysInMonth(DateTime(2026, 12)), 31);
  });
}
