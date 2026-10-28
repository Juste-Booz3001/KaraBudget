import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/core/search_filter.dart';
import 'package:karabudget/core/tags.dart';

bool m(
  SearchFilter f, {
  String note = 'Café Central',
  String tags = 'resto,midi',
  String cat = 'Alimentation',
  String? catId = 'c1',
  int? amount = 1000,
  DateTime? at,
  bool receipt = false,
}) =>
    matchesFilter(f,
        note: note,
        tags: tags,
        categoryName: cat,
        categoryId: catId,
        amount: amount,
        at: (at ?? DateTime(2026, 10, 15, 18)).millisecondsSinceEpoch,
        hasReceipt: receipt);

void main() {
  test('filtre vide : tout passe', () {
    expect(const SearchFilter().isEmpty, isTrue);
    expect(m(const SearchFilter()), isTrue);
  });

  test('texte : insensible à la casse et aux accents, tous les mots, sur note/étiquettes/catégorie', () {
    expect(m(const SearchFilter(query: 'cafe centr')), isTrue);
    expect(m(const SearchFilter(query: 'CAFÉ')), isTrue);
    expect(m(const SearchFilter(query: 'midi')), isTrue);
    expect(m(const SearchFilter(query: 'aliment')), isTrue);
    expect(m(const SearchFilter(query: 'cafe pizza')), isFalse);
  });

  test('période : bornes incluses', () {
    final f = SearchFilter(from: DateTime(2026, 10, 15), to: DateTime(2026, 10, 15));
    expect(m(f), isTrue);
    expect(m(f, at: DateTime(2026, 10, 14, 23, 59)), isFalse);
    expect(m(f, at: DateTime(2026, 10, 16, 0, 1)), isFalse);
  });

  test('montant : bornes incluses ; montant inconnu = non filtré', () {
    expect(m(const SearchFilter(minMinor: 1000, maxMinor: 1000)), isTrue);
    expect(m(const SearchFilter(minMinor: 1001)), isFalse);
    expect(m(const SearchFilter(maxMinor: 999)), isFalse);
    expect(m(const SearchFilter(minMinor: 5000), amount: null), isTrue);
  });

  test('catégories, étiquette, reçu', () {
    expect(m(const SearchFilter(categoryIds: {'c1', 'c2'})), isTrue);
    expect(m(const SearchFilter(categoryIds: {'c2'})), isFalse);
    expect(m(const SearchFilter(categoryIds: {''}), catId: null), isTrue);
    expect(m(const SearchFilter(tag: 'resto')), isTrue);
    expect(m(const SearchFilter(tag: 'rest')), isFalse); // étiquette entière, pas un fragment
    expect(m(const SearchFilter(onlyWithReceipt: true)), isFalse);
    expect(m(const SearchFilter(onlyWithReceipt: true), receipt: true), isTrue);
  });

  test('critères cumulés (ET)', () {
    expect(m(const SearchFilter(query: 'cafe', tag: 'resto', minMinor: 500)), isTrue);
    expect(m(const SearchFilter(query: 'cafe', tag: 'autre')), isFalse);
  });

  test('étiquettes', () {
    expect(parseTags('Courses, #Resto ; courses'), ['courses', 'resto']);
    expect(normalizeTags('  A  b,,C '), 'a,b,c');
    expect(splitTags(''), isEmpty);
    expect(splitTags('a,b'), ['a', 'b']);
    expect(normalizeTags(List.generate(80, (i) => 'tag$i').join(',')).length <= 300, isTrue);
  });
}
