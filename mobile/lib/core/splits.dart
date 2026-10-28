import 'dart:convert';

/// Partage d'une dépense entre membres d'un espace.
///  - equal : parts égales entre [users] (le reste en centimes va aux premiers ids, ordre alphabétique)
///  - exact : parts explicites ; si leur somme ne vaut plus le montant (montant modifié depuis),
///            on retombe sur un partage égal entre les mêmes personnes.
class SplitSpec {
  const SplitSpec.equal(this.users)
      : mode = 'equal',
        shares = const {};
  const SplitSpec.exact(this.shares)
      : mode = 'exact',
        users = const [];
  final String mode;
  final List<String> users;
  final Map<String, int> shares;

  List<String> get participants => mode == 'equal' ? users : shares.keys.toList();

  String encode() => mode == 'equal'
      ? jsonEncode({'mode': 'equal', 'with': users})
      : jsonEncode({'mode': 'exact', 'shares': shares});
}

SplitSpec? parseSplit(String raw) {
  if (raw.isEmpty) return null;
  try {
    final j = jsonDecode(raw);
    if (j is! Map) return null;
    if (j['mode'] == 'equal') {
      final users = (j['with'] as List).cast<String>();
      return users.isEmpty ? null : SplitSpec.equal(users);
    }
    if (j['mode'] == 'exact') {
      final shares = (j['shares'] as Map).map((k, v) => MapEntry(k as String, v as int));
      return shares.isEmpty ? null : SplitSpec.exact(shares);
    }
  } catch (_) {}
  return null;
}

Map<String, int> _equalShares(int amount, List<String> users) {
  final ids = ({...users}.toList())..sort();
  final base = amount ~/ ids.length, rem = amount % ids.length;
  return {for (var i = 0; i < ids.length; i++) ids[i]: base + (i < rem ? 1 : 0)};
}

/// Part due par chaque participant ; la somme vaut toujours exactement [amount].
Map<String, int> sharesFor(int amount, SplitSpec split) {
  if (split.mode == 'exact') {
    final sum = split.shares.values.fold(0, (a, b) => a + b);
    return sum == amount ? Map.of(split.shares) : _equalShares(amount, split.shares.keys.toList());
  }
  return _equalShares(amount, split.users);
}

/// Parts de l'utilisateur saisies en texte -> null si la somme ne correspond pas.
bool exactSharesValid(int amount, Map<String, int> shares) =>
    shares.isNotEmpty && shares.values.every((v) => v >= 0) && shares.values.fold(0, (a, b) => a + b) == amount;

class SharedExpense {
  const SharedExpense({required this.amount, required this.currency, required this.paidBy, required this.splitRaw});
  final int amount;
  final String currency;
  final String? paidBy;
  final String splitRaw;
}

class Payment {
  const Payment({required this.from, required this.to, required this.amount, required this.currency});
  final String from, to;
  final int amount;
  final String currency;
}

/// devise -> (utilisateur -> solde). Solde > 0 : on lui doit de l'argent ; < 0 : il doit de l'argent.
typedef Balances = Map<String, Map<String, int>>;

Balances computeBalances(Iterable<SharedExpense> expenses, Iterable<Payment> payments) {
  final out = <String, Map<String, int>>{};
  void add(String cur, String user, int v) {
    final m = out.putIfAbsent(cur, () => {});
    m[user] = (m[user] ?? 0) + v;
  }

  for (final e in expenses) {
    final split = parseSplit(e.splitRaw);
    if (split == null || e.paidBy == null || e.paidBy!.isEmpty) continue; // dépense non partagée
    add(e.currency, e.paidBy!, e.amount);
    sharesFor(e.amount, split).forEach((u, v) => add(e.currency, u, -v));
  }
  for (final p in payments) {
    add(p.currency, p.from, p.amount);
    add(p.currency, p.to, -p.amount);
  }
  for (final m in out.values) {
    m.removeWhere((_, v) => v == 0);
  }
  out.removeWhere((_, m) => m.isEmpty);
  return out;
}

typedef Transfer = ({String from, String to, int amount});

/// Remboursements proposés (au plus n−1) pour solder tout le monde : le plus gros débiteur
/// rembourse le plus gros créancier, et ainsi de suite.
List<Transfer> suggestTransfers(Map<String, int> net) {
  final debtors = [for (final e in net.entries) if (e.value < 0) (id: e.key, v: -e.value)];
  final creditors = [for (final e in net.entries) if (e.value > 0) (id: e.key, v: e.value)];
  int order(({String id, int v}) a, ({String id, int v}) b) {
    final c = b.v.compareTo(a.v);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  debtors.sort(order);
  creditors.sort(order);
  final out = <Transfer>[];
  var i = 0, j = 0;
  var dv = debtors.isEmpty ? 0 : debtors[0].v, cv = creditors.isEmpty ? 0 : creditors[0].v;
  while (i < debtors.length && j < creditors.length) {
    final pay = dv < cv ? dv : cv;
    out.add((from: debtors[i].id, to: creditors[j].id, amount: pay));
    dv -= pay;
    cv -= pay;
    if (dv == 0 && ++i < debtors.length) dv = debtors[i].v;
    if (cv == 0 && ++j < creditors.length) cv = creditors[j].v;
  }
  return out;
}
