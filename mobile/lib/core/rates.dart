import 'money.dart';

/// Taux de change saisi à la main : 1 [from] = [ratePpm] / 1 000 000 [to] (en unités principales,
/// pas en centimes). Entier en « parts par million » : aucun float.
class RateEntry {
  const RateEntry(this.from, this.to, this.ratePpm);
  final String from, to;
  final int ratePpm;
}

typedef _Factor = (BigInt num, BigInt den);

final _million = BigInt.from(1000000);

/// Convertit des montants en unité mineure entre devises, avec les taux de l'utilisateur.
/// Cherche un taux direct, le taux inverse, puis un passage par une devise intermédiaire.
class RateTable {
  RateTable(Iterable<RateEntry> entries) {
    for (final e in entries) {
      if (e.ratePpm > 0 && e.from != e.to) _direct['${e.from}>${e.to}'] = e.ratePpm;
    }
  }

  static final RateTable empty = RateTable(const []);

  final Map<String, int> _direct = {};

  Set<String> get _codes => {for (final k in _direct.keys) ...k.split('>')};

  _Factor? _step(String a, String b) {
    final d = _direct['$a>$b'];
    if (d != null) return (BigInt.from(d), _million);
    final inv = _direct['$b>$a'];
    if (inv != null) return (_million, BigInt.from(inv));
    return null;
  }

  _Factor? _factor(String a, String b) {
    if (a == b) return (BigInt.one, BigInt.one);
    final one = _step(a, b);
    if (one != null) return one;
    for (final mid in _codes) {
      if (mid == a || mid == b) continue;
      final f1 = _step(a, mid);
      final f2 = f1 == null ? null : _step(mid, b);
      if (f1 != null && f2 != null) return (f1.$1 * f2.$1, f1.$2 * f2.$2);
    }
    return null;
  }

  bool canConvert(String from, String to) => _factor(from, to) != null;

  /// Montant converti en unité mineure de [to] (arrondi à l'unité la plus proche), ou null si aucun taux.
  int? convert(int minor, String from, String to) {
    if (from == to) return minor;
    final f = _factor(from, to);
    if (f == null) return null;
    final dFrom = BigInt.from(10).pow(currencyOf(from).decimals);
    final dTo = BigInt.from(10).pow(currencyOf(to).decimals);
    return _divRound(BigInt.from(minor) * f.$1 * dTo, f.$2 * dFrom).toInt();
  }

  /// Taux effectif 1 [from] = ? [to] (pour l'affichage), ou null.
  double? display(String from, String to) {
    final f = _factor(from, to);
    return f == null ? null : f.$1.toDouble() / f.$2.toDouble();
  }
}

BigInt _divRound(BigInt n, BigInt d) {
  final neg = n.isNegative;
  final q = (n.abs() * BigInt.two + d) ~/ (d * BigInt.two); // arrondi à l'unité la plus proche
  return neg ? -q : q;
}

/// "4800" ou "4 800,5" -> 4_800_500_000 ppm (jusqu'à 6 décimales). null si invalide ou <= 0.
int? parseRatePpm(String input) {
  final s = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  final m = RegExp(r'^(\d+)(?:\.(\d{0,6}))?$').firstMatch(s);
  if (m == null) return null;
  final frac = (m.group(2) ?? '').padRight(6, '0');
  final v = int.parse(m.group(1)!) * 1000000 + int.parse(frac);
  return v > 0 ? v : null;
}

String formatRatePpm(int ppm) {
  final whole = ppm ~/ 1000000;
  final frac = (ppm % 1000000).toString().padLeft(6, '0').replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? '$whole' : '$whole,$frac';
}
