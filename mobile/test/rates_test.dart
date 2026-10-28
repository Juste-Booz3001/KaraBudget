import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/core/rates.dart';

void main() {
  group('RateTable', () {
    final t = RateTable(const [
      RateEntry('EUR', 'MGA', 4800000000), // 1 EUR = 4800 MGA
      RateEntry('USD', 'MGA', 4400000000),
    ]);

    test('taux direct', () => expect(t.convert(1250, 'EUR', 'MGA'), 60000)); // 12,50 € -> 60 000 Ar
    test('taux inverse', () => expect(t.convert(60000, 'MGA', 'EUR'), 1250));
    test('arrondi à l\'unité mineure la plus proche', () {
      expect(t.convert(1, 'MGA', 'EUR'), 0);
      expect(t.convert(100, 'MGA', 'EUR'), 2); // 2,08 centimes
      expect(t.convert(-100, 'MGA', 'EUR'), -2);
    });
    test('passage par une devise intermédiaire', () => expect(t.convert(10000, 'EUR', 'USD'), 10909));
    test('même devise = identité', () => expect(t.convert(777, 'EUR', 'EUR'), 777));
    test('sans taux : null', () {
      expect(t.convert(100, 'EUR', 'JPY'), isNull);
      expect(t.canConvert('EUR', 'JPY'), isFalse);
      expect(t.canConvert('EUR', 'USD'), isTrue);
    });
    test('table vide', () => expect(RateTable.empty.convert(5, 'EUR', 'USD'), isNull));
    test('gros montants sans débordement', () => expect(t.convert(900000000000, 'EUR', 'MGA'), 43200000000000));
  });

  group('saisie des taux', () {
    test('parseRatePpm', () {
      expect(parseRatePpm('4800'), 4800000000);
      expect(parseRatePpm('4 800,5'), 4800500000);
      expect(parseRatePpm('0,000001'), 1);
      expect(parseRatePpm('0'), isNull);
      expect(parseRatePpm('1,1234567'), isNull);
      expect(parseRatePpm('abc'), isNull);
    });
    test('formatRatePpm', () {
      expect(formatRatePpm(4800500000), '4800,5');
      expect(formatRatePpm(1000000), '1');
      expect(formatRatePpm(1234567), '1,234567');
    });
  });
}
