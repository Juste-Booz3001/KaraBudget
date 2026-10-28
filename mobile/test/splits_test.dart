import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/core/splits.dart';

void main() {
  test('partage égal : la somme vaut toujours le montant', () {
    final s = sharesFor(1000, const SplitSpec.equal(['c', 'a', 'b']));
    expect(s, {'a': 334, 'b': 333, 'c': 333});
    expect(s.values.fold(0, (a, b) => a + b), 1000);
    expect(sharesFor(1, const SplitSpec.equal(['a', 'b'])), {'a': 1, 'b': 0});
  });

  test('parts exactes valides, sinon retour au partage égal', () {
    expect(sharesFor(1000, const SplitSpec.exact({'a': 300, 'b': 700})), {'a': 300, 'b': 700});
    expect(sharesFor(1100, const SplitSpec.exact({'a': 300, 'b': 700})), {'a': 550, 'b': 550}); // montant modifié depuis
    expect(exactSharesValid(1000, {'a': 300, 'b': 700}), isTrue);
    expect(exactSharesValid(1000, {'a': 300, 'b': 600}), isFalse);
  });

  test('parseSplit / encode', () {
    final s = parseSplit(const SplitSpec.equal(['a', 'b']).encode())!;
    expect(s.mode, 'equal');
    expect(s.users, ['a', 'b']);
    final e = parseSplit(const SplitSpec.exact({'a': 5}).encode())!;
    expect(e.shares, {'a': 5});
    expect(parseSplit(''), isNull);
    expect(parseSplit('pas du json'), isNull);
    expect(parseSplit('{"mode":"equal","with":[]}'), isNull);
    expect(parseSplit('{"mode":"x"}'), isNull);
  });

  group('soldes', () {
    final eq3 = const SplitSpec.equal(['a', 'b', 'c']).encode();
    final eq2 = const SplitSpec.equal(['a', 'b']).encode();
    final expenses = [
      SharedExpense(amount: 3000, currency: 'EUR', paidBy: 'a', splitRaw: eq3),
      SharedExpense(amount: 600, currency: 'EUR', paidBy: 'b', splitRaw: eq2),
      const SharedExpense(amount: 999, currency: 'EUR', paidBy: 'a', splitRaw: ''), // non partagée
      const SharedExpense(amount: 999, currency: 'EUR', paidBy: null, splitRaw: '{"mode":"equal","with":["a"]}'),
    ];

    test('qui doit quoi', () {
      final b = computeBalances(expenses, const []);
      expect(b['EUR'], {'a': 1700, 'b': -700, 'c': -1000});
      expect(b['EUR']!.values.fold(0, (x, y) => x + y), 0);
    });

    test('un remboursement solde la dette', () {
      final b = computeBalances(expenses, const [Payment(from: 'c', to: 'a', amount: 1000, currency: 'EUR')]);
      expect(b['EUR'], {'a': 700, 'b': -700}); // c est soldé et disparaît
    });

    test('devises séparées, tout soldé = vide', () {
      final b = computeBalances([
        SharedExpense(amount: 100, currency: 'EUR', paidBy: 'a', splitRaw: eq2),
        SharedExpense(amount: 5000, currency: 'MGA', paidBy: 'b', splitRaw: eq2),
      ], const [
        Payment(from: 'b', to: 'a', amount: 50, currency: 'EUR'),
      ]);
      expect(b.containsKey('EUR'), isFalse);
      expect(b['MGA'], {'b': 2500, 'a': -2500});
    });

    test('remboursements proposés', () {
      final t = suggestTransfers({'a': 1700, 'b': -700, 'c': -1000});
      expect(t, hasLength(2));
      expect(t[0], (from: 'c', to: 'a', amount: 1000));
      expect(t[1], (from: 'b', to: 'a', amount: 700));
      expect(suggestTransfers({}), isEmpty);
      expect(suggestTransfers({'a': 0}), isEmpty);
    });

    test('les remboursements proposés soldent tout le monde', () {
      final net = {'a': 500, 'b': 300, 'c': -450, 'd': -350};
      final left = Map.of(net);
      for (final t in suggestTransfers(net)) {
        left[t.from] = left[t.from]! + t.amount;
        left[t.to] = left[t.to]! - t.amount;
      }
      expect(left.values.every((v) => v == 0), isTrue);
    });
  });
}
