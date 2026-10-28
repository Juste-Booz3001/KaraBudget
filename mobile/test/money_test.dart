import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/core/money.dart';

void main() {
  const eur = Currency('EUR', 2, '€');
  const mga = Currency('MGA', 0, 'Ar');

  test('parseMinor : entiers exacts, pas de float', () {
    expect(parseMinor('12,50', 2), 1250);
    expect(parseMinor('12.5', 2), 1250);
    expect(parseMinor('0.1', 2) , 10);
    expect(parseMinor('19.99', 2), 1999);
    expect(parseMinor('7', 2), 700);
    expect(parseMinor('1,005', 2), isNull); // trop de décimales : refusé plutôt qu'arrondi
    expect(parseMinor('abc', 2), isNull);
    expect(parseMinor('-5', 2), isNull);
    expect(parseMinor('1500', 0), 1500);
    expect(parseMinor('1500,5', 0), isNull);
  });

  test('formatMinor / plainMinor', () {
    expect(formatMinor(123456, eur), '1 234,56 €');
    expect(formatMinor(-5, eur), '-0,05 €');
    expect(formatMinor(1500000, mga), '1 500 000 Ar');
    expect(plainMinor(1250, eur), '12.50');
    expect(plainMinor(7000, mga), '7000');
  });

  test('parseAmountLoose', () {
    expect(parseAmountLoose('1.234,50', 2), 123450);
    expect(parseAmountLoose('1,234.50', 2), 123450);
    expect(parseAmountLoose('12.5', 2), 1250);
    expect(parseAmountLoose('1.234', 2), 123400); // 3 chiffres après le séparateur = milliers
    expect(parseAmountLoose('15000', 0), 15000);
  });

  test('extractTotal privilégie la ligne TOTAL', () {
    const ticket = 'SUPERMARCHE\nPain 1,20\nLait 0,95\nSous-total 2,15\nTVA 0,43\nTOTAL TTC 2,58\nCarte 2,58\nMerci 12/10/2026';
    expect(extractTotal(ticket, 2), 258);
    expect(extractTotal('rien ici', 2), isNull);
    expect(extractTotal('Café 3,50\nCroissant 2,00', 2), 350); // sans mot-clé : plus grand montant
  });

  test('addPeriod gère les fins de mois', () {
    expect(addPeriod(DateTime(2026, 1, 31), 'monthly'), DateTime(2026, 2, 28));
    expect(addPeriod(DateTime(2026, 12, 15), 'monthly'), DateTime(2027, 1, 15));
    expect(addPeriod(DateTime(2026, 2, 27), 'weekly'), DateTime(2026, 3, 6));
    expect(addPeriod(DateTime(2026, 12, 31), 'daily'), DateTime(2027, 1, 1));
  });

  test('monthKey / monthRange', () {
    expect(monthKey(DateTime(2026, 3, 9)), '2026-03');
    final (a, b) = monthRange(DateTime(2026, 12, 5));
    expect(a, DateTime(2026, 12).millisecondsSinceEpoch);
    expect(b, DateTime(2027, 1).millisecondsSinceEpoch);
  });
}
