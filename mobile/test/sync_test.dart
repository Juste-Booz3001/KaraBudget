import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karabudget/data/db.dart';
import 'package:karabudget/data/repository.dart';
import 'package:karabudget/sync/sync_service.dart';

class FakeApi implements SyncApi {
  final pushed = <Map<String, dynamic>>[];
  final pullPages = <Map<String, dynamic>>[];
  bool failNextPush = false;

  @override
  Future<List<Map<String, dynamic>>> push(String spaceId, String deviceId, List<Map<String, dynamic>> ops) async {
    if (failNextPush) {
      failNextPush = false;
      throw Exception('réseau coupé');
    }
    pushed.addAll(ops);
    return [for (final o in ops) {'op_id': o['op_id'], 'status': 'applied'}];
  }

  @override
  Future<Map<String, dynamic>> pull(String spaceId, int since) async =>
      pullPages.isEmpty ? {'changes': [], 'next_cursor': since, 'has_more': false} : pullPages.removeAt(0);
}

void main() {
  const space = 'space-1';
  late AppDatabase db;
  late Repository repo;
  late FakeApi api;
  late SyncService sync;
  var changes = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, () => changes++);
    api = FakeApi();
    sync = SyncService(db, api, 'device-A');
  });
  tearDown(() => db.close());

  Future<List<OutboxOp>> outbox() => db.select(db.outbox).get();

  test('écrire = ligne locale + op dans l\'outbox, sans réseau', () async {
    final id = await repo.saveExpense(
        spaceId: space, amountMinor: 1250, currency: 'EUR', note: 'café', spentAt: 1000);
    final rows = await db.select(db.expenses).get();
    expect(rows.single.amountMinor, 1250);
    final ops = await outbox();
    expect(ops.single.entityId, id);
    expect(jsonDecode(ops.single.fieldsJson)['amount_minor'], 1250);
    expect(changes, greaterThan(0));
  });

  test('une édition n\'envoie que les champs modifiés', () async {
    final id = await repo.saveExpense(spaceId: space, amountMinor: 1000, currency: 'EUR', note: 'a', spentAt: 1);
    await sync.syncSpace(space); // vide l'outbox
    await repo.saveExpense(id: id, spaceId: space, amountMinor: 1000, currency: 'EUR', note: 'b', spentAt: 1);
    final ops = await outbox();
    expect(jsonDecode(ops.single.fieldsJson), {'note': 'b'});
  });

  test('un push en échec conserve l\'outbox ; le retry vide la file', () async {
    await repo.saveExpense(spaceId: space, amountMinor: 1, currency: 'EUR', note: '', spentAt: 1);
    api.failNextPush = true;
    await expectLater(sync.syncSpace(space), throwsException);
    expect(await outbox(), hasLength(1));
    await sync.syncSpace(space);
    expect(await outbox(), isEmpty);
    expect(api.pushed, hasLength(1));
  });

  test('le pull n\'écrase pas les champs en attente, mais applique les autres', () async {
    final id = await repo.saveExpense(spaceId: space, amountMinor: 1000, currency: 'EUR', note: 'a', spentAt: 1);
    await sync.syncSpace(space);
    await repo.saveExpense(id: id, spaceId: space, amountMinor: 1000, currency: 'EUR', note: 'local', spentAt: 1);
    await sync.applyChange(space, {
      'entity': 'expense',
      'id': id,
      'rev': 5,
      'deleted_at': null,
      'fields': {'amount_minor': 2000, 'currency': 'EUR', 'category_id': null, 'note': 'serveur', 'spent_at': 1},
      'field_ts': <String, dynamic>{},
    });
    final e = (await db.select(db.expenses).get()).single;
    expect(e.note, 'local'); // édition locale non encore envoyée : préservée
    expect(e.amountMinor, 2000); // champ modifié ailleurs : appliqué
  });

  test('pull : nouvelle ligne distante, tombstone et curseur', () async {
    api.pullPages.add({
      'changes': [
        {
          'entity': 'expense', 'id': 'remote-1', 'rev': 1, 'deleted_at': null,
          'fields': {'amount_minor': 500, 'currency': 'EUR', 'category_id': null, 'note': 'x', 'spent_at': 9},
          'field_ts': <String, dynamic>{},
        },
      ],
      'next_cursor': 1,
      'has_more': true,
    });
    api.pullPages.add({
      'changes': [
        {
          'entity': 'expense', 'id': 'remote-1', 'rev': 2, 'deleted_at': 777,
          'fields': {'amount_minor': 500, 'currency': 'EUR', 'category_id': null, 'note': 'x', 'spent_at': 9},
          'field_ts': <String, dynamic>{},
        },
      ],
      'next_cursor': 2,
      'has_more': false,
    });
    await sync.syncSpace(space);
    final e = (await db.select(db.expenses).get()).single;
    expect(e.deletedAt, 777);
    final st = await db.select(db.syncStates).getSingle();
    expect(st.cursor, 2);
  });

  test('catégories par défaut : ts=0 et ids déterministes (deux appareils convergent)', () async {
    await repo.seedDefaults(space);
    final ops = await outbox();
    expect(ops, hasLength(defaultCategories.length));
    expect(ops.every((o) => o.ts == 0), isTrue);
    final db2 = AppDatabase(NativeDatabase.memory());
    await Repository(db2, () {}).seedDefaults(space);
    final ids1 = (await db.select(db.categories).get()).map((c) => c.id).toSet();
    final ids2 = (await db2.select(db2.categories).get()).map((c) => c.id).toSet();
    expect(ids1, ids2);
    await db2.close();
  });

  test('dépenses récurrentes : matérialisation idempotente', () async {
    final past = DateTime.now().subtract(const Duration(days: 70)).millisecondsSinceEpoch;
    await repo.saveRecurring(
        spaceId: space, amountMinor: 5000, currency: 'EUR', note: 'loyer', period: 'monthly', nextDue: past);
    final n = await repo.materializeDue(space);
    expect(n, inInclusiveRange(2, 3));
    expect(await repo.materializeDue(space), 0); // rien de plus à créer
    expect((await db.select(db.expenses).get()), hasLength(n));
  });

  test('suppression logique : tombstone + op delete', () async {
    final id = await repo.saveExpense(spaceId: space, amountMinor: 1, currency: 'EUR', note: '', spentAt: 1);
    await repo.deleteExpense(space, id);
    expect((await db.select(db.expenses).get()).single.deletedAt, isNotNull);
    expect((await outbox()).last.action, 'delete');
  });

  test('budgetStatus : dépensé vs limite du mois', () async {
    final now = DateTime.now();
    final catId = await repo.saveCategory(spaceId: space, name: 'Food', color: 0xFF000000);
    await repo.saveExpense(spaceId: space, amountMinor: 800, currency: 'EUR', categoryId: catId, note: '', spentAt: now.millisecondsSinceEpoch);
    await repo.setBudget(space, catId, '${now.year}-${now.month.toString().padLeft(2, '0')}', 1000);
    final st = await repo.budgetStatus(space, catId, now);
    expect(st.spent, 800);
    expect(st.limit, 1000);
  });
}
