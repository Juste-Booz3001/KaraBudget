import 'dart:math';

/// Les montants sont TOUJOURS des entiers en unité mineure (centimes), jamais des double.
class Currency {
  const Currency(this.code, this.decimals, this.symbol);
  final String code;
  final int decimals;
  final String symbol;
}

const currencies = <String, Currency>{
  'USD': Currency('USD', 2, r'$'),
  'EUR': Currency('EUR', 2, '€'),
  'MGA': Currency('MGA', 0, 'Ar'),
  'GBP': Currency('GBP', 2, '£'),
  'CAD': Currency('CAD', 2, r'CA$'),
  'CHF': Currency('CHF', 2, 'CHF'),
  'XOF': Currency('XOF', 0, 'F CFA'),
  'MAD': Currency('MAD', 2, 'DH'),
  'ZAR': Currency('ZAR', 2, 'R'),
  'JPY': Currency('JPY', 0, '¥'),
  'CNY': Currency('CNY', 2, 'CN¥'),
};

final List<String> currenciesList = currencies.keys.toList();

Currency currencyOf(String code) => currencies[code] ?? currencies['USD']!;

int _pow10(int n) => pow(10, n).toInt();

/// "12,5" -> 1250 (decimals=2). Retourne null si invalide ou trop de décimales.
int? parseMinor(String input, int decimals) {
  final s = input.trim().replaceAll(',', '.').replaceAll(' ', '');
  final m = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(s);
  if (m == null) return null;
  final frac = m.group(2) ?? '';
  if (frac.length > decimals) return null;
  final fracValue = decimals == 0 ? 0 : int.parse(frac.padRight(decimals, '0'));
  return int.parse(m.group(1)!) * _pow10(decimals) + fracValue;
}

String formatMinor(int minor, Currency c, {bool symbol = true}) {
  final abs = minor.abs();
  final div = _pow10(c.decimals);
  final whole = (abs ~/ div)
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  final frac = c.decimals == 0 ? '' : ',${(abs % div).toString().padLeft(c.decimals, '0')}';
  return '${minor < 0 ? '-' : ''}$whole$frac${symbol ? ' ${c.symbol}' : ''}';
}

/// "12.50" (point décimal, sans séparateur de milliers) pour les exports.
String plainMinor(int minor, Currency c) {
  final abs = minor.abs();
  final div = _pow10(c.decimals);
  final frac = c.decimals == 0 ? '' : '.${(abs % div).toString().padLeft(c.decimals, '0')}';
  return '${minor < 0 ? '-' : ''}${abs ~/ div}$frac';
}

/// Lecture tolérante d'un montant de ticket : "1.234,50" / "1,234.50" / "12.5" / "1 234".
int? parseAmountLoose(String raw, int decimals) {
  final s = raw.replaceAll(RegExp(r'\s'), '');
  if (s.isEmpty) return null;
  final lastSep = max(s.lastIndexOf('.'), s.lastIndexOf(','));
  final tail = lastSep < 0 ? 0 : s.length - lastSep - 1;
  String intPart;
  String fracPart = '';
  if (lastSep >= 0 && decimals > 0 && tail >= 1 && tail <= decimals) {
    intPart = s.substring(0, lastSep).replaceAll(RegExp(r'[.,]'), '');
    fracPart = s.substring(lastSep + 1);
  } else {
    intPart = s.replaceAll(RegExp(r'[.,]'), '');
  }
  return parseMinor(fracPart.isEmpty ? intPart : '$intPart.$fracPart', decimals);
}

/// Cherche le total d'un ticket : plus grand montant d'une ligne "total/montant/ttc",
/// sinon plus grand montant du ticket.
int? extractTotal(String text, int decimals) {
  final numRe = RegExp(r'\d[\d.,]*\d|\d');
  final keyword = RegExp(r'total|montant|ttc|net à payer|amount due');
  int? best;
  int? bestKeyword;
  for (final line in text.split('\n')) {
    final lower = line.toLowerCase();
    final isTotal = keyword.hasMatch(lower) && !lower.contains('sous');
    for (final m in numRe.allMatches(line)) {
      final v = parseAmountLoose(m.group(0)!, decimals);
      if (v == null) continue;
      if (isTotal && (bestKeyword == null || v > bestKeyword)) bestKeyword = v;
      if (best == null || v > best) best = v;
    }
  }
  return bestKeyword ?? best;
}

String monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

(int, int) monthRange(DateTime d) =>
    (DateTime(d.year, d.month).millisecondsSinceEpoch, DateTime(d.year, d.month + 1).millisecondsSinceEpoch);

DateTime addPeriod(DateTime d, String period) {
  switch (period) {
    case 'daily':
      return DateTime(d.year, d.month, d.day + 1, d.hour, d.minute);
    case 'weekly':
      return DateTime(d.year, d.month, d.day + 7, d.hour, d.minute);
    default:
      final y = d.year + (d.month == 12 ? 1 : 0);
      final m = d.month == 12 ? 1 : d.month + 1;
      final lastDay = DateTime(y, m + 1, 0).day;
      return DateTime(y, m, min(d.day, lastDay), d.hour, d.minute);
  }
}
