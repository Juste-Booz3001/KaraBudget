/// Étiquettes : stockées en minuscules, séparées par des virgules ("courses,resto").
List<String> parseTags(String raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final part in raw.split(RegExp(r'[,;\s#]+'))) {
    final t = part.trim().toLowerCase();
    if (t.isEmpty || t.length > 30 || !seen.add(t)) continue;
    out.add(t);
  }
  return out;
}

String normalizeTags(String raw) {
  final joined = parseTags(raw).join(',');
  return joined.length <= 300 ? joined : joined.substring(0, 300).replaceFirst(RegExp(r',[^,]*$'), '');
}

List<String> splitTags(String stored) => stored.isEmpty ? const [] : stored.split(',');
