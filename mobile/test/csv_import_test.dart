import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/core/csv_import.dart';

void main() {
  group('parseCsv', () {
    test('séparateur détecté, guillemets doublés', () {
      final r = parseCsv('date;montant;libellé\n26/10/2026;-12,50;"CAFÉ ""CENTRAL"""\n');
      expect(r, hasLength(2));
      expect(r[1], ['26/10/2026', '-12,50', 'CAFÉ "CENTRAL"']);
    });
    test('virgule dans un champ entre guillemets, CRLF, BOM, sans retour final', () {
      final r = parseCsv('\uFEFFa,"b,c",d\r\n1,2,3');
      expect(r, [
        ['a', 'b,c', 'd'],
        ['1', '2', '3']
      ]);
    });
    test('retour à la ligne dans un champ', () {
      final r = parseCsv('a;b\n"ligne 1\nligne 2";x\n');
      expect(r[1][0], 'ligne 1\nligne 2');
      expect(r[1][1], 'x');
    });
    test('lignes vides ignorées, champs vides conservés', () {
      expect(parseCsv('a;;c\n\n;;\n'), [
        ['a', '', 'c'],
        ['', '', '']
      ]);
    });
    test('détection du séparateur', () {
      expect(detectDelimiter('a;b;c'), ';');
      expect(detectDelimiter('a,b,c'), ',');
      expect(detectDelimiter('a\tb'), '\t');
      expect(detectDelimiter('"a;b",c'), ',');
    });
  });

  group('colonnes', () {
    test('relevé français débit / crédit', () {
      final c = guessColumns(['Date opération', 'Libellé', 'Débit', 'Crédit']);
      expect([c.date, c.note, c.debit, c.credit, c.amount], [0, 1, 2, 3, null]);
      expect(c.usable, isTrue);
    });
    test('en-têtes anglais', () {
      final c = guessColumns(['Date', 'Description', 'Amount', 'Category', 'Currency']);
      expect([c.date, c.note, c.amount, c.category, c.currency], [0, 1, 2, 3, 4]);
    });
    test('non reconnu', () => expect(guessColumns(['x', 'y']).usable, isFalse));
  });

  group('dates et montants', () {
    test('formats de date', () {
      expect(parseImportDate('26/10/2026')!.day, 26);
      expect(parseImportDate('2026-10-26 14:30:00')!.month, 10);
      expect(parseImportDate('5/3/26')!.month, 3);
      expect(parseImportDate('26.10.2026')!.year, 2026);
      expect(parseImportDate('10/26/2026', dayFirst: false)!.day, 26);
      expect(parseImportDate('31/02/2026'), isNull);
      expect(parseImportDate('hier'), isNull);
    });
    test('montants signés', () {
      expect(parseSignedAmount('-12,50', 2), -1250);
      expect(parseSignedAmount('(12.50)', 2), -1250);
      expect(parseSignedAmount('1 234,50 €', 2), 123450);
      expect(parseSignedAmount('12,50-', 2), -1250);
      expect(parseSignedAmount('+5', 2), 500);
      expect(parseSignedAmount('15 000 Ar', 0), 15000);
      expect(parseSignedAmount('abc', 2), isNull);
      expect(parseSignedAmount('', 2), isNull);
    });
  });

  group('buildImport', () {
    const opts = ImportOptions(columns: ColumnMap(date: 0, note: 1, amount: 2), decimals: 2);
    final file = parseCsv('Date;Libellé;Montant\n'
        '26/10/2026;CAFE;-3,50\n'
        '26/10/2026;CAFE;-3,50\n'
        '25/10/2026;SALAIRE;1500,00\n'
        '??;X;-1\n'
        '24/10/2026;Y;abc\n');

    test('relevé bancaire : débits importés, crédits ignorés, erreurs signalées', () {
      final rows = buildImport(file, opts, {});
      expect(rows.map((r) => r.status).toList(), [
        ImportStatus.ok,
        ImportStatus.ok, // deux cafés identiques le même jour : légitimes
        ImportStatus.skipped,
        ImportStatus.error,
        ImportStatus.error,
      ]);
      expect(rows.map((r) => r.line).toList(), [2, 3, 4, 5, 6]);
      expect(rows[0].amountMinor, 350);
      expect(rows[0].note, 'CAFE');
      expect(rows[3].reason, 'date');
      expect(rows[4].reason, 'amount');
    });

    test('doublons avec l\'existant : un seul café déjà présent', () {
      final key = dedupKey(DateTime(2026, 10, 26), 350, 'cafe');
      final rows = buildImport(file, opts, {key: 1});
      expect(rows[0].status, ImportStatus.duplicate);
      expect(rows[1].status, ImportStatus.ok);
    });

    test('ré-importer le même fichier ne crée rien', () {
      final first = buildImport(file, opts, {});
      final counts = <String, int>{};
      for (final r in first.where((r) => r.status == ImportStatus.ok)) {
        final k = dedupKey(r.date!, r.amountMinor, r.note);
        counts[k] = (counts[k] ?? 0) + 1;
      }
      final second = buildImport(file, opts, counts);
      expect(second.where((r) => r.status == ImportStatus.ok), isEmpty);
      expect(second.where((r) => r.status == ImportStatus.duplicate), hasLength(2));
    });

    test('la clé ignore la casse, les accents et les espaces multiples', () {
      expect(dedupKey(DateTime(2026, 1, 2), 5, 'Café  Central'), dedupKey(DateTime(2026, 1, 2, 18), 5, 'cafe central'));
    });

    test('sans montants négatifs : tout est une dépense', () {
      final rows = buildImport(parseCsv('d;n;m\n01/01/2026;A;12,5\n'), opts, {});
      expect(rows.single.status, ImportStatus.ok);
      expect(rows.single.amountMinor, 1250);
    });

    test('colonnes débit / crédit', () {
      final f = parseCsv('Date;Libellé;Débit;Crédit\n01/01/2026;LOYER;500,00;\n02/01/2026;PAIE;;1000,00\n');
      final o = ImportOptions(columns: guessColumns(f.first), decimals: 2);
      final rows = buildImport(f, o, {});
      expect(rows[0].status, ImportStatus.ok);
      expect(rows[0].amountMinor, 50000);
      expect(rows[1].status, ImportStatus.skipped);
    });

    test('mode forcé : positifs = dépenses', () {
      final f = parseCsv('d;n;m\n01/01/2026;A;10\n02/01/2026;B;-5\n');
      final rows = buildImport(f, const ImportOptions(columns: ColumnMap(date: 0, note: 1, amount: 2), decimals: 2, sign: ImportSign.positiveIsExpense), {});
      expect(rows.map((r) => r.status).toList(), [ImportStatus.ok, ImportStatus.skipped]);
    });

    test('catégorie et devise du fichier', () {
      final f = parseCsv('Date,Note,Amount,Category,Currency\n01/01/2026,A,5,Food,eur\n');
      final rows = buildImport(f, ImportOptions(columns: guessColumns(f.first), decimals: 2), {});
      expect(rows.single.category, 'Food');
      expect(rows.single.currency, 'EUR');
    });

    test('sans en-tête, ligne vide ignorée', () {
      final rows = buildImport(parseCsv('01/01/2026;A;5\n;;\n'), const ImportOptions(columns: ColumnMap(date: 0, note: 1, amount: 2), decimals: 2, hasHeader: false), {});
      expect(rows, hasLength(1));
      expect(rows.single.line, 1);
    });
  });
}
