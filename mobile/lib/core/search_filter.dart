/// Critères de recherche d'une dépense. Tous optionnels ; ils se cumulent (ET).
class SearchFilter {
  const SearchFilter({
    this.query = '',
    this.from,
    this.to,
    this.minMinor,
    this.maxMinor,
    this.categoryIds = const {},
    this.tag,
    this.onlyWithReceipt = false,
  });

  final String query;
  final DateTime? from, to; // jours inclus
  final int? minMinor, maxMinor;
  final Set<String> categoryIds; // '' = « sans catégorie »
  final String? tag;
  final bool onlyWithReceipt;

  bool get isEmpty =>
      query.trim().isEmpty &&
      from == null &&
      to == null &&
      minMinor == null &&
      maxMinor == null &&
      categoryIds.isEmpty &&
      tag == null &&
      !onlyWithReceipt;

  SearchFilter copyWith({
    String? query,
    DateTime? from,
    DateTime? to,
    int? minMinor,
    int? maxMinor,
    Set<String>? categoryIds,
    String? tag,
    bool? onlyWithReceipt,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearMin = false,
    bool clearMax = false,
    bool clearTag = false,
  }) =>
      SearchFilter(
        query: query ?? this.query,
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
        minMinor: clearMin ? null : (minMinor ?? this.minMinor),
        maxMinor: clearMax ? null : (maxMinor ?? this.maxMinor),
        categoryIds: categoryIds ?? this.categoryIds,
        tag: clearTag ? null : (tag ?? this.tag),
        onlyWithReceipt: onlyWithReceipt ?? this.onlyWithReceipt,
      );
}

String foldText(String s) {
  const from = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaceeeeiiiinooooouuuuyy';
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

/// [amount] est le montant converti dans la devise d'affichage (null si aucun taux : les bornes
/// de montant ne s'appliquent alors pas, pour ne pas masquer la ligne).
bool matchesFilter(
  SearchFilter f, {
  required String note,
  required String tags,
  required String categoryName,
  required String? categoryId,
  required int? amount,
  required int at,
  required bool hasReceipt,
}) {
  final q = foldText(f.query.trim());
  if (q.isNotEmpty) {
    final hay = foldText('$note $tags $categoryName');
    if (!q.split(RegExp(r'\s+')).every(hay.contains)) return false;
  }
  final day = DateTime.fromMillisecondsSinceEpoch(at);
  final d = DateTime(day.year, day.month, day.day);
  if (f.from != null && d.isBefore(DateTime(f.from!.year, f.from!.month, f.from!.day))) return false;
  if (f.to != null && d.isAfter(DateTime(f.to!.year, f.to!.month, f.to!.day))) return false;
  if (amount != null) {
    if (f.minMinor != null && amount < f.minMinor!) return false;
    if (f.maxMinor != null && amount > f.maxMinor!) return false;
  }
  if (f.categoryIds.isNotEmpty && !f.categoryIds.contains(categoryId ?? '')) return false;
  if (f.tag != null && !tags.split(',').contains(f.tag)) return false;
  if (f.onlyWithReceipt && !hasReceipt) return false;
  return true;
}
