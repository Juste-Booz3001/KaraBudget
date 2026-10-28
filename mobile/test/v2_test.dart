import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/core/csv_import.dart';
import 'package:karabudget/core/rates.dart';
import 'package:karabudget/data/db.dart';
import 'package:karabudget/data/repository.dart';
import 'package:karabudget/sync/sync_service.dart';

class _Api implements SyncApi {
  @override
  Future<List<Map<String, dynamic>>> push(String spaceId, String deviceId, List<Map<String, dynamic>> ops) async =>
      [for (final o in ops) {'op_id': o['op_id'], 'status': 'applied'}];

  @override
  Future<Map<String, dynamic>> pull(String spaceId, int since) async => {'changes': [], 'next_cursor': since, 'has_more': false};
}

void main() {
  const space = 'space-1';
  late AppDatabase db;
  late Repository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, () {});
  });
  tearDown(() => db.close());

  Future<List<OutboxOp>> outbox() => db.select(db.outbox).get();
  Map<String, dynamic> fields(OutboxOp o) => jsonDecode(o.fieldsJson) as Map<String, dynamic>;

  test('étiquettes, payeur, partage et reçu : stockés et envoyés ; une édition n\'envoie que le changement', () async {
    final id = await repo.saveExpense(
        spaceId: space,
        amountMinor: 1000,
        currency: 'EUR',
        note: 'pizza',
        spentAt: 1,
        tags: 'Resto, #Midi',
        paidBy: 'u1',
        splitJson: '{"mode":"equal","with":["u1","u2"]}',
        attachmentId: 'att-1');
    final e = (await db.select(db.expenses).get()).single;
    expect(e.tags, 'resto,midi');
    expect(e.paidBy, 'u1');
    expect(e.attachmentId, 'att-1');
    expect(fields((await outbox()).single)['tags'], 'resto,midi');

    await SyncService(db, _Api(), 'dev').syncSpace(space);
    await repo.saveExpense(
        id: id,
        spaceId: space,
        amountMinor: 1000,
        currency: 'EUR',
        note: 'pizza',
        spentAt: 1,
        tags: 'resto,midi,soir',
        paidBy: 'u1',
        splitJson: '{"mode":"equal","with":["u1","u2"]}',
        attachmentId: 'att-1');
    expect(fields((await outbox()).single), {'tags': 'resto,midi,soir'});
  });

  test('ré-ajouter une dépense supprimée la ressuscite et le signale au serveur (deleted_at: null)', () async {
    final id = await repo.saveExpense(spaceId: space, amountMinor: 5, currency: 'EUR', note: 'x', spentAt: 1);
    await repo.deleteExpense(space, id);
    await repo.saveExpense(id: id, spaceId: space, amountMinor: 5, currency: 'EUR', note: 'x', spentAt: 1);
    expect((await db.select(db.expenses).get()).single.deletedAt, isNull);
    final last = fields((await outbox()).last);
    expect(last.containsKey('deleted_at'), isTrue);
    expect(last['deleted_at'], isNull);
  });

  test('budget : report, taux de change et dépensé converti (budgetState)', () async {
    final cat = await repo.saveCategory(spaceId: space, name: 'Food', color: 1);
    final rates = RateTable(const [RateEntry('EUR', 'USD', 1100000)]); // 1 EUR = 1,10 USD
    final sep = DateTime(2026, 9, 10).millisecondsSinceEpoch, oct = DateTime(2026, 10, 10).millisecondsSinceEpoch;
    await repo.setBudget(space, cat, '2026-09', 10000);
    await repo.setBudget(space, cat, '2026-10', 10000, rollover: true);
    await repo.saveExpense(spaceId: space, amountMinor: 6000, currency: 'USD', categoryId: cat, note: '', spentAt: sep); // 60,00 $
    await repo.saveExpense(spaceId: space, amountMinor: 1000, currency: 'EUR', categoryId: cat, note: '', spentAt: oct); // 10,00 € = 11,00 $
    await repo.saveExpense(spaceId: space, amountMinor: 500, currency: 'JPY', categoryId: cat, note: '', spentAt: oct); // pas de taux

    final st = await repo.budgetState(space, cat, DateTime(2026, 10, 15), 'USD', rates);
    expect(st.spent, 1100);
    expect(st.carry, 4000); // 100 $ - 60 $ reportés de septembre
    expect(st.limit, 10000);
    expect(st.effective, 14000);
    expect(st.unconverted, 1);
    final none = await repo.budgetState(space, cat, DateTime(2026, 8, 1), 'USD', rates);
    expect(none.limit, isNull);
    expect(none.effective, isNull);
  });

  test('taux de change : ajout, suppression, ré-ajout (id déterministe)', () async {
    await repo.setRate(space, 'EUR', 'MGA', 4800000000);
    await repo.removeRate(space, 'EUR', 'MGA');
    expect(await db.select(db.rates).get(), hasLength(1)); // tombstone gardé
    expect((await db.select(db.rates).get()).single.deletedAt, isNotNull);
    await repo.setRate(space, 'EUR', 'MGA', 4900000000);
    final row = (await db.select(db.rates).get()).single;
    expect(row.deletedAt, isNull);
    expect(row.ratePpm, 4900000000);
    final last = fields((await outbox()).last);
    expect(last['rate_ppm'], 4900000000);
    expect(last['deleted_at'], isNull);
    expect(await repo.watchRates(space).first, hasLength(1));
  });

  test('objectifs : le solde est la somme des versements ; suppression en cascade', () async {
    final g = await repo.saveGoal(spaceId: space, name: 'Vacances', targetMinor: 100000, currency: 'EUR');
    await repo.addContribution(space, g, 2500);
    await repo.addContribution(space, g, 1500);
    await repo.addContribution(space, g, -500);
    final parts = await repo.watchContributions(space).first;
    expect(parts.fold<int>(0, (a, c) => a + c.amountMinor), 3500);
    await repo.deleteGoal(space, g);
    expect(await repo.watchGoals(space).first, isEmpty);
    expect(await repo.watchContributions(space).first, isEmpty);
  });

  test('remboursements entre membres', () async {
    await repo.addSettlement(space, from: 'u2', to: 'u1', amountMinor: 700, currency: 'EUR');
    final s = (await repo.watchSettlements(space).first).single;
    expect([s.fromUser, s.toUser, s.amountMinor], ['u2', 'u1', 700]);
    expect(fields((await outbox()).single)['amount_minor'], 700);
  });

  test('modèles de saisie rapide : locaux, jamais envoyés', () async {
    await repo.saveTemplate(name: 'Café', amountMinor: 250, currency: 'EUR', tags: 'Café, Midi');
    await repo.saveTemplate(name: 'Bus', amountMinor: 400, currency: 'EUR');
    final list = await repo.watchTemplates().first;
    expect(list.map((t) => t.name).toList(), ['Café', 'Bus']);
    expect(list.first.tags, 'café,midi');
    await repo.deleteTemplate(list.first.id);
    expect(await repo.watchTemplates().first, hasLength(1));
    expect(await outbox(), isEmpty);
  });

  test('import CSV : catégories créées, doublons évités, ré-import sans effet', () async {
    final existing = await repo.saveCategory(spaceId: space, name: 'Alimentation', color: 1);
    final rows = buildImport(
      parseCsv('Date;Libellé;Montant;Catégorie\n01/10/2026;CAFE;-3,50;alimentation\n01/10/2026;CAFE;-3,50;alimentation\n02/10/2026;BUS;-1,20;Transport\n03/10/2026;PAIE;900;\n'),
      const ImportOptions(columns: ColumnMap(date: 0, note: 1, amount: 2, category: 3), decimals: 2),
      await repo.existingExpenseCounts(space),
    );
    expect(await repo.importRows(space, rows, defaultCurrency: 'EUR', categoryColor: 7), 3);
    final cats = await db.select(db.categories).get();
    expect(cats.map((c) => c.name).toSet(), {'Alimentation', 'Transport'});
    final all = await db.select(db.expenses).get();
    expect(all, hasLength(3));
    expect(all.where((e) => e.categoryId == existing), hasLength(2));

    final again = buildImport(
      parseCsv('Date;Libellé;Montant;Catégorie\n01/10/2026;CAFE;-3,50;alimentation\n01/10/2026;CAFE;-3,50;alimentation\n02/10/2026;BUS;-1,20;Transport\n'),
      const ImportOptions(columns: ColumnMap(date: 0, note: 1, amount: 2, category: 3), decimals: 2),
      await repo.existingExpenseCounts(space),
    );
    expect(again.every((r) => r.status == ImportStatus.duplicate), isTrue);
    expect(await repo.importRows(space, again, defaultCurrency: 'EUR', categoryColor: 7), 0);
    expect(await db.select(db.expenses).get(), hasLength(3));
  });

  test('sync : champs et entités inconnus (serveur plus récent) sont ignorés sans erreur', () async {
    final sync = SyncService(db, _Api(), 'dev');
    await sync.applyChange(space, {
      'entity': 'expense', 'id': 'e1', 'rev': 1, 'deleted_at': null,
      'fields': {'amount_minor': 100, 'currency': 'EUR', 'category_id': null, 'note': 'x', 'spent_at': 1, 'champ_futur': 'abc'},
      'field_ts': <String, dynamic>{},
    });
    await sync.applyChange(space, {'entity': 'hologramme', 'id': 'h1', 'rev': 1, 'deleted_at': null, 'fields': {'a': 1}, 'field_ts': <String, dynamic>{}});
    expect((await db.select(db.expenses).get()).single.amountMinor, 100);
  });

  test('sync : les nouvelles entités sont appliquées (taux, objectif, versement, remboursement)', () async {
    final sync = SyncService(db, _Api(), 'dev');
    Future<void> put(String entity, String id, Map<String, Object?> f) => sync.applyChange(
        space, {'entity': entity, 'id': id, 'rev': 1, 'deleted_at': null, 'fields': f, 'field_ts': <String, dynamic>{}});
    await put('rate', 'r1', {'from_currency': 'EUR', 'to_currency': 'MGA', 'rate_ppm': 4800000000});
    await put('goal', 'g1', {'name': 'Moto', 'target_minor': 5000000, 'currency': 'MGA', 'due_at': 0, 'color': 4283215696});
    await put('contribution', 'c1', {'goal_id': 'g1', 'amount_minor': 100000, 'at': 5, 'note': ''});
    await put('settlement', 's1', {'from_user': 'a', 'to_user': 'b', 'amount_minor': 10, 'currency': 'EUR', 'at': 5});
    expect((await db.select(db.rates).get()).single.ratePpm, 4800000000);
    expect((await db.select(db.goals).get()).single.name, 'Moto');
    expect((await db.select(db.contributions).get()).single.goalId, 'g1');
    expect((await db.select(db.settlements).get()).single.toUser, 'b');
  });

  test('changement d\'espace : les nouvelles tables suivent', () async {
    await repo.saveGoal(spaceId: 'local', name: 'x', targetMinor: 1, currency: 'EUR');
    await repo.setRate('local', 'EUR', 'USD', 1100000);
    await repo.migrateSpace('local', 'perso');
    expect((await db.select(db.goals).get()).single.spaceId, 'perso');
    expect((await db.select(db.rates).get()).single.spaceId, 'perso');
    expect((await outbox()).every((o) => o.spaceId == 'perso'), isTrue);
  });
}
