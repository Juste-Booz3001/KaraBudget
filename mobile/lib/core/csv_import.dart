import 'money.dart';
import 'search_filter.dart' show foldText;

/// Import de dépenses depuis un CSV (relevé bancaire, ancien suivi) : parseur, détection des
/// colonnes, lecture des dates/montants, et détection des doublons (déjà importé / déjà présent).

String detectDelimiter(String text) {
  final line = text.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  var best = ',', bestCount = 0;
  for (final d in [';', ',', '\t', '|']) {
    var inQuotes = false, n = 0;
    for (final ch in line.split('')) {
      if (ch == '"') inQuotes = !inQuotes;
      if (!inQuotes && ch == d) n++;
    }
    if (n > bestCount) {
      best = d;
      bestCount = n;
    }
  }
  return best;
}

/// Parseur CSV (RFC 4180) : guillemets, guillemets doublés, retours ligne dans un champ, BOM.
List<List<String>> parseCsv(String text, {String? delimiter}) {
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  final d = delimiter ?? detectDelimiter(text);
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false, wasQuoted = false;

  void endCell() {
    row.add(wasQuoted ? cell.toString() : cell.toString().trim());
    cell.clear();
    wasQuoted = false;
  }

  void endRow() {
    endCell();
    if (!(row.length == 1 && row[0].isEmpty)) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"' && cell.toString().trim().isEmpty) {
      inQuotes = true;
      wasQuoted = true;
      cell.clear();
    } else if (ch == d) {
      endCell();
    } else if (ch == '\n') {
      endRow();
    } else if (ch == '\r') {
      if (i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else {
      cell.write(ch);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty || wasQuoted) endRow();
  return rows;
}

class ColumnMap {
  const ColumnMap({this.date, this.amount, this.debit, this.credit, this.note, this.category, this.currency});
  final int? date, amount, debit, credit, note, category, currency;

  bool get usable => date != null && (amount != null || debit != null);

  ColumnMap copyWith({
    int? date,
    int? amount,
    int? debit,
    int? credit,
    int? note,
    int? category,
    int? currency,
    bool clearAmount = false,
    bool clearDebit = false,
    bool clearCredit = false,
    bool clearNote = false,
    bool clearCategory = false,
    bool clearCurrency = false,
  }) =>
      ColumnMap(
        date: date ?? this.date,
        amount: clearAmount ? null : (amount ?? this.amount),
        debit: clearDebit ? null : (debit ?? this.debit),
        credit: clearCredit ? null : (credit ?? this.credit),
        note: clearNote ? null : (note ?? this.note),
        category: clearCategory ? null : (category ?? this.category),
        currency: clearCurrency ? null : (currency ?? this.currency),
      );
}

/// Devine les colonnes d'après les en-têtes (français / anglais).
ColumnMap guessColumns(List<String> header) {
  final h = [for (final c in header) foldText(c)];
  int? find(List<String> words, {List<String> not = const []}) {
    for (var i = 0; i < h.length; i++) {
      if (words.any(h[i].contains) && !not.any(h[i].contains)) return i;
    }
    return null;
  }

  final debit = find(['debit', 'sortie', 'withdrawal']);
  final credit = find(['credit', 'entree', 'deposit']);
  final amount = find(['montant', 'amount', 'somme', 'valeur', 'total'], not: ['debit', 'credit']);
  return ColumnMap(
    date: find(['date', 'jour', 'day']),
    amount: amount,
    debit: amount == null ? debit : null,
    credit: amount == null ? credit : null,
    note: find(['libelle', 'note', 'description', 'label', 'memo', 'detail', 'objet', 'reference', 'tiers', 'payee']),
    category: find(['categorie', 'category']),
    currency: find(['devise', 'currency']),
  );
}

/// Dates : 2026-10-26, 26/10/2026, 26-10-26, 26.10.2026, avec ou sans heure. [dayFirst] : jj/mm vs mm/jj.
DateTime? parseImportDate(String raw, {bool dayFirst = true}) {
  final s = raw.trim().split(RegExp(r'[ T]')).first;
  int? y, m, d;
  var r = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$').firstMatch(s);
  if (r != null) {
    y = int.parse(r.group(1)!);
    m = int.parse(r.group(2)!);
    d = int.parse(r.group(3)!);
  } else {
    r = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2}|\d{4})$').firstMatch(s);
    if (r == null) return null;
    final a = int.parse(r.group(1)!), b = int.parse(r.group(2)!);
    d = dayFirst ? a : b;
    m = dayFirst ? b : a;
    y = int.parse(r.group(3)!);
    if (r.group(3)!.length == 2) y += 2000;
  }
  final dt = DateTime(y, m, d, 12); // midi : pas de décalage de jour selon le fuseau
  return dt.year == y && dt.month == m && dt.day == d ? dt : null;
}

/// "-12,50", "(12.50)", "12,50 €", "1 234,5-" -> montant signé en unité mineure.
int? parseSignedAmount(String raw, int decimals) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  final negative = s.startsWith('-') || s.startsWith('−') || (s.startsWith('(') && s.endsWith(')')) || s.endsWith('-');
  s = s.replaceAll(RegExp(r'[^0-9.,\s]'), '').trim();
  final v = parseAmountLoose(s, decimals);
  if (v == null) return null;
  return negative ? -v : v;
}

enum ImportSign { auto, negativeIsExpense, positiveIsExpense, absolute }

enum ImportStatus { ok, duplicate, skipped, error }

class ImportRow {
  const ImportRow({
    required this.line,
    required this.status,
    this.date,
    this.amountMinor = 0,
    this.note = '',
    this.category,
    this.currency,
    this.reason,
  });
  final int line; // numéro de ligne dans le fichier (1 = première ligne)
  final ImportStatus status;
  final DateTime? date;
  final int amountMinor; // toujours positif
  final String note;
  final String? category, currency, reason;
}

class ImportOptions {
  const ImportOptions({
    required this.columns,
    required this.decimals,
    this.hasHeader = true,
    this.sign = ImportSign.auto,
    this.dayFirst = true,
  });
  final ColumnMap columns;
  final int decimals;
  final bool hasHeader, dayFirst;
  final ImportSign sign;
}

String _normNote(String s) => foldText(s).replaceAll(RegExp(r'\s+'), ' ').trim();

String dedupKey(DateTime day, int amountMinor, String note) =>
    '${day.year}-${day.month}-${day.day}|$amountMinor|${_normNote(note)}';

/// Si le fichier contient des montants négatifs, ce sont des débits (relevé bancaire).
ImportSign detectSign(List<List<String>> rows, ColumnMap c, int decimals) {
  final col = c.amount;
  if (col == null) return ImportSign.absolute;
  for (final r in rows) {
    final v = col < r.length ? parseSignedAmount(r[col], decimals) : null;
    if (v != null && v < 0) return ImportSign.negativeIsExpense;
  }
  return ImportSign.absolute;
}

/// Construit les lignes à importer. [existingCounts] : nombre de dépenses déjà présentes par clé
/// (date|montant|libellé). Deux lignes identiques dans un même fichier restent toutes les deux
/// valides (deux cafés le même jour), mais ré-importer le même fichier ne crée rien.
List<ImportRow> buildImport(List<List<String>> rows, ImportOptions o, Map<String, int> existingCounts) {
  final c = o.columns;
  final body = o.hasHeader && rows.isNotEmpty ? rows.sublist(1) : rows;
  final offset = o.hasHeader ? 2 : 1;
  final sign = o.sign == ImportSign.auto ? detectSign(body, c, o.decimals) : o.sign;
  final seen = <String, int>{};
  final out = <ImportRow>[];

  String cell(List<String> r, int? i) => i == null || i >= r.length ? '' : r[i].trim();

  for (var n = 0; n < body.length; n++) {
    final r = body[n];
    final line = n + offset;
    if (r.every((x) => x.trim().isEmpty)) continue;

    final date = parseImportDate(cell(r, c.date), dayFirst: o.dayFirst);
    if (date == null) {
      out.add(ImportRow(line: line, status: ImportStatus.error, reason: 'date'));
      continue;
    }

    int? amount;
    String? skip;
    if (c.amount != null) {
      final v = parseSignedAmount(cell(r, c.amount), o.decimals);
      if (v == null) {
        out.add(ImportRow(line: line, status: ImportStatus.error, date: date, reason: 'amount'));
        continue;
      }
      switch (sign) {
        case ImportSign.negativeIsExpense:
          if (v < 0) {
            amount = -v;
          } else {
            skip = 'income';
          }
        case ImportSign.positiveIsExpense:
          if (v > 0) {
            amount = v;
          } else {
            skip = 'income';
          }
        case ImportSign.absolute || ImportSign.auto:
          amount = v.abs();
      }
    } else {
      final debit = parseSignedAmount(cell(r, c.debit), o.decimals);
      if (debit != null && debit != 0) {
        amount = debit.abs();
      } else {
        skip = 'income';
      }
    }
    if (skip == null && (amount == null || amount == 0)) skip = 'zero';
    final note = cell(r, c.note);
    if (skip != null) {
      out.add(ImportRow(line: line, status: ImportStatus.skipped, date: date, note: note, reason: skip));
      continue;
    }

    final key = dedupKey(date, amount!, note);
    final k = (seen[key] ?? 0) + 1;
    seen[key] = k;
    final cat = cell(r, c.category);
    final cur = cell(r, c.currency).toUpperCase();
    out.add(ImportRow(
      line: line,
      status: k <= (existingCounts[key] ?? 0) ? ImportStatus.duplicate : ImportStatus.ok,
      date: date,
      amountMinor: amount,
      note: note,
      category: cat.isEmpty ? null : cat,
      currency: cur.length == 3 ? cur : null,
    ));
  }
  return out;
}
