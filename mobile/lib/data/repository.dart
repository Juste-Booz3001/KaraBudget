import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/csv_import.dart';
import '../core/money.dart';
import '../core/rates.dart';
import '../core/rollover.dart';
import '../core/search_filter.dart' show foldText;
import '../core/tags.dart';
import 'db.dart';

const _uuid = Uuid();
String _v5(String name) => _uuid.v5(Namespace.url.value, name);
int _now() => DateTime.now().millisecondsSinceEpoch;

const _tableOf = {
  'category': 'categories',
  'expense': 'expenses',
  'budget': 'budgets',
  'recurring': 'recurrings',
  'rate': 'rates',
  'goal': 'goals',
  'contribution': 'contributions',
  'settlement': 'settlements',
};

const defaultCategories = [
  ('Alimentation', 0xFF4CAF50),
  ('Transport', 0xFF2196F3),
  ('Logement', 0xFF795548),
  ('Loisirs', 0xFF9C27B0),
  ('Santé', 0xFFF44336),
  ('Autre', 0xFF607D8B),
];

/// Toute écriture = mise à jour locale + ajout d'une op dans l'outbox, dans UNE transaction.
/// L'UI ne dépend donc jamais du réseau.
class Repository {
  Repository(this.db, this.onChange);
  final AppDatabase db;
  final void Function() onChange;

  // ---------- lecture (streams réactifs) ----------
  Stream<List<Category>> watchCategories(String spaceId) => (db.select(db.categories)
        ..where((c) => c.spaceId.equals(spaceId) & c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch();

  Stream<List<Expense>> watchExpenses(String spaceId, int from, int to) => (db.select(db.expenses)
        ..where((e) =>
            e.spaceId.equals(spaceId) &
            e.deletedAt.isNull() &
            e.spentAt.isBiggerOrEqualValue(from) &
            e.spentAt.isSmallerThanValue(to))
        ..orderBy([(e) => OrderingTerm.desc(e.spentAt)]))
      .watch();

  Stream<List<Budget>> watchBudgets(String spaceId, String month) => (db.select(db.budgets)
        ..where((b) => b.spaceId.equals(spaceId) & b.month.equals(month) & b.deletedAt.isNull()))
      .watch();

  Stream<List<Recurring>> watchRecurrings(String spaceId) => (db.select(db.recurrings)
        ..where((r) => r.spaceId.equals(spaceId) & r.deletedAt.isNull())
        ..orderBy([(r) => OrderingTerm.asc(r.nextDue)]))
      .watch();

  Stream<List<Expense>> watchAllExpenses(String spaceId) => (db.select(db.expenses)
        ..where((e) => e.spaceId.equals(spaceId) & e.deletedAt.isNull())
        ..orderBy([(e) => OrderingTerm.desc(e.spentAt)]))
      .watch();

  Stream<List<Budget>> watchAllBudgets(String spaceId) =>
      (db.select(db.budgets)..where((b) => b.spaceId.equals(spaceId) & b.deletedAt.isNull())).watch();

  Stream<List<Rate>> watchRates(String spaceId) => (db.select(db.rates)
        ..where((r) => r.spaceId.equals(spaceId) & r.deletedAt.isNull())
        ..orderBy([(r) => OrderingTerm.asc(r.fromCurrency), (r) => OrderingTerm.asc(r.toCurrency)]))
      .watch();

  Stream<List<Goal>> watchGoals(String spaceId) => (db.select(db.goals)
        ..where((g) => g.spaceId.equals(spaceId) & g.deletedAt.isNull())
        ..orderBy([(g) => OrderingTerm.asc(g.name)]))
      .watch();

  Stream<List<Contribution>> watchContributions(String spaceId) => (db.select(db.contributions)
        ..where((c) => c.spaceId.equals(spaceId) & c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.desc(c.at)]))
      .watch();

  Stream<List<Settlement>> watchSettlements(String spaceId) => (db.select(db.settlements)
        ..where((s) => s.spaceId.equals(spaceId) & s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.desc(s.at)]))
      .watch();

  Stream<List<QuickTemplate>> watchTemplates() =>
      (db.select(db.templates)..orderBy([(t) => OrderingTerm.asc(t.position), (t) => OrderingTerm.asc(t.name)])).watch();

  Stream<int> watchPendingCount() => db.select(db.outbox).watch().map((l) => l.length);

  // ---------- outbox ----------
  Future<void> _enqueue(String spaceId, String entity, String id, String action, Map<String, Object?> fields,
      {int? ts}) async {
    await db.into(db.outbox).insert(OutboxCompanion.insert(
          opId: _uuid.v4(),
          spaceId: spaceId,
          entity: entity,
          entityId: id,
          action: action,
          fieldsJson: jsonEncode(fields),
          ts: ts ?? _now(),
        ));
  }

  /// Ne garde que les champs modifiés : deux appareils qui éditent des champs différents
  /// d'une même ligne n'écrasent donc pas le travail l'un de l'autre.
  Map<String, Object?> _diff(Map<String, Object?> next, Map<String, Object?>? prev) =>
      prev == null ? next : {for (final e in next.entries) if (prev[e.key] != e.value) e.key: e.value};

  Future<void> _softDelete(String spaceId, String entity, String id) => db.transaction(() async {
        final ts = _now();
        final table = _tableOf[entity]!;
        await db.customUpdate(
          'UPDATE $table SET deleted_at = ? WHERE space_id = ? AND id = ?',
          variables: [Variable.withInt(ts), Variable.withString(spaceId), Variable.withString(id)],
          updates: {db.tableByName(table)},
        );
        await _enqueue(spaceId, entity, id, 'delete', {}, ts: ts);
        onChange();
      });

  // ---------- catégories ----------
  Future<String> saveCategory({String? id, required String spaceId, required String name, required int color}) =>
      db.transaction(() async {
        final cid = id ?? _uuid.v4();
        final prev = id == null
            ? null
            : await (db.select(db.categories)..where((c) => c.spaceId.equals(spaceId) & c.id.equals(cid))).getSingleOrNull();
        final next = {'name': name, 'color': color};
        final fields = _diff(next, prev == null ? null : {'name': prev.name, 'color': prev.color});
        await db.into(db.categories).insertOnConflictUpdate(
            CategoriesCompanion.insert(id: cid, spaceId: spaceId, name: name, color: Value(color)));
        if (fields.isNotEmpty) await _enqueue(spaceId, 'category', cid, 'upsert', fields);
        onChange();
        return cid;
      });

  Future<void> deleteCategory(String spaceId, String id) => _softDelete(spaceId, 'category', id);

  /// Catégories par défaut : ids déterministes + ts=0, pour que deux appareils convergent
  /// et qu'un renommage réel (ts > 0) gagne toujours sur ces valeurs initiales.
  Future<void> seedDefaults(String spaceId) => db.transaction(() async {
        final any = await (db.select(db.categories)..where((c) => c.spaceId.equals(spaceId))..limit(1)).get();
        if (any.isNotEmpty) return;
        for (final (name, color) in defaultCategories) {
          final id = _v5('karabudget:default-category:$name');
          await db.into(db.categories).insertOnConflictUpdate(
              CategoriesCompanion.insert(id: id, spaceId: spaceId, name: name, color: Value(color)));
          await _enqueue(spaceId, 'category', id, 'upsert', {'name': name, 'color': color}, ts: 0);
        }
      });

  // ---------- dépenses ----------
  Future<void> _putExpense(String spaceId, String id, int amount, String currency, String? categoryId, String note,
      int spentAt,
      {String tags = '', String? paidBy, String splitJson = '', String? attachmentId}) async {
    final prev = await (db.select(db.expenses)..where((e) => e.spaceId.equals(spaceId) & e.id.equals(id))).getSingleOrNull();
    final cleanTags = normalizeTags(tags);
    final next = <String, Object?>{
      'amount_minor': amount,
      'currency': currency,
      'category_id': categoryId,
      'note': note,
      'spent_at': spentAt,
      'tags': cleanTags,
      'paid_by': paidBy,
      'split_json': splitJson,
      'attachment_id': attachmentId,
    };
    final revived = prev != null && prev.deletedAt != null; // ré-ajout d'une ligne supprimée (id déterministe)
    final fields = _diff(
        next,
        prev == null || revived
            ? null
            : {
                'amount_minor': prev.amountMinor,
                'currency': prev.currency,
                'category_id': prev.categoryId,
                'note': prev.note,
                'spent_at': prev.spentAt,
                'tags': prev.tags,
                'paid_by': prev.paidBy,
                'split_json': prev.splitJson,
                'attachment_id': prev.attachmentId,
              });
    if (revived) fields['deleted_at'] = null;
    await db.into(db.expenses).insertOnConflictUpdate(ExpensesCompanion.insert(
          id: id,
          spaceId: spaceId,
          amountMinor: amount,
          currency: currency,
          categoryId: Value(categoryId),
          note: Value(note),
          spentAt: spentAt,
          tags: Value(cleanTags),
          paidBy: Value(paidBy),
          splitJson: Value(splitJson),
          attachmentId: Value(attachmentId),
          deletedAt: const Value(null),
        ));
    if (fields.isNotEmpty) await _enqueue(spaceId, 'expense', id, 'upsert', fields);
  }

  Future<String> saveExpense({
    String? id,
    required String spaceId,
    required int amountMinor,
    required String currency,
    String? categoryId,
    required String note,
    required int spentAt,
    String tags = '',
    String? paidBy,
    String splitJson = '',
    String? attachmentId,
  }) =>
      db.transaction(() async {
        final eid = id ?? _uuid.v4();
        await _putExpense(spaceId, eid, amountMinor, currency, categoryId, note, spentAt,
            tags: tags, paidBy: paidBy, splitJson: splitJson, attachmentId: attachmentId);
        onChange();
        return eid;
      });

  Future<void> deleteExpense(String spaceId, String id) => _softDelete(spaceId, 'expense', id);

  // ---------- budgets ----------
  /// Un seul budget par (catégorie, mois) : id déterministe, donc pas de doublons entre appareils.
  Future<void> setBudget(String spaceId, String categoryId, String month, int limitMinor, {bool rollover = false}) =>
      db.transaction(() async {
        final id = _v5('budget:$categoryId:$month');
        await db.into(db.budgets).insertOnConflictUpdate(BudgetsCompanion.insert(
            id: id,
            spaceId: spaceId,
            categoryId: categoryId,
            month: month,
            limitMinor: limitMinor,
            rollover: Value(rollover ? 1 : 0),
            deletedAt: const Value(null)));
        await _enqueue(spaceId, 'budget', id, 'upsert', {
          'category_id': categoryId,
          'month': month,
          'limit_minor': limitMinor,
          'rollover': rollover ? 1 : 0,
          'deleted_at': null, // ré-ajout après suppression : lève le tombstone côté serveur
        });
        onChange();
      });

  Future<void> removeBudget(String spaceId, String categoryId, String month) =>
      _softDelete(spaceId, 'budget', _v5('budget:$categoryId:$month'));

  Future<({int spent, int? limit})> budgetStatus(String spaceId, String categoryId, DateTime month) async {
    final (from, to) = monthRange(month);
    final sum = db.expenses.amountMinor.sum();
    final q = db.selectOnly(db.expenses)
      ..addColumns([sum])
      ..where(db.expenses.spaceId.equals(spaceId) &
          db.expenses.categoryId.equals(categoryId) &
          db.expenses.deletedAt.isNull() &
          db.expenses.spentAt.isBiggerOrEqualValue(from) &
          db.expenses.spentAt.isSmallerThanValue(to));
    final spent = await q.map((r) => r.read(sum)).getSingle() ?? 0;
    final b = await (db.select(db.budgets)
          ..where((b) =>
              b.spaceId.equals(spaceId) & b.categoryId.equals(categoryId) & b.month.equals(monthKey(month)) & b.deletedAt.isNull()))
        .getSingleOrNull();
    return (spent: spent, limit: b?.limitMinor);
  }

  /// Dépensé et budget disponible (limite + report éventuel) d'une catégorie pour un mois.
  /// Les dépenses sont converties dans [currency] avec [rates] ; [unconverted] compte celles sans taux.
  Future<({int spent, int? limit, int carry, int? effective, int unconverted})> budgetState(
      String spaceId, String categoryId, DateTime month, String currency, RateTable rates) async {
    final first = DateTime(month.year, month.month - 12);
    final rows = await (db.select(db.expenses)
          ..where((e) =>
              e.spaceId.equals(spaceId) &
              e.categoryId.equals(categoryId) &
              e.deletedAt.isNull() &
              e.spentAt.isBiggerOrEqualValue(first.millisecondsSinceEpoch) &
              e.spentAt.isSmallerThanValue(DateTime(month.year, month.month + 1).millisecondsSinceEpoch)))
        .get();
    final spentBy = <String, int>{};
    var unconverted = 0;
    for (final e in rows) {
      final v = rates.convert(e.amountMinor, e.currency, currency);
      if (v == null) {
        unconverted++;
        continue;
      }
      final k = monthKey(DateTime.fromMillisecondsSinceEpoch(e.spentAt));
      spentBy[k] = (spentBy[k] ?? 0) + v;
    }
    final budgets = await (db.select(db.budgets)
          ..where((b) => b.spaceId.equals(spaceId) & b.categoryId.equals(categoryId) & b.deletedAt.isNull()))
        .get();
    final byMonth = {for (final b in budgets) b.month: BudgetMonth(b.limitMinor, rollover: b.rollover == 1)};
    final key = monthKey(month);
    final eff = effectiveBudget(month: key, budgets: byMonth, spent: spentBy);
    final has = byMonth.containsKey(key);
    return (
      spent: spentBy[key] ?? 0,
      limit: has ? eff.limit : null,
      carry: eff.carry,
      effective: has ? eff.effective : null,
      unconverted: unconverted
    );
  }

  // ---------- taux de change ----------
  Future<void> setRate(String spaceId, String from, String to, int ratePpm) => db.transaction(() async {
        final id = _v5('rate:$from:$to');
        await db.into(db.rates).insertOnConflictUpdate(RatesCompanion.insert(
            id: id, spaceId: spaceId, fromCurrency: from, toCurrency: to, ratePpm: ratePpm, deletedAt: const Value(null)));
        await _enqueue(spaceId, 'rate', id, 'upsert',
            {'from_currency': from, 'to_currency': to, 'rate_ppm': ratePpm, 'deleted_at': null});
        onChange();
      });

  Future<void> removeRate(String spaceId, String from, String to) => _softDelete(spaceId, 'rate', _v5('rate:$from:$to'));

  // ---------- objectifs d'épargne ----------
  Future<String> saveGoal({
    String? id,
    required String spaceId,
    required String name,
    required int targetMinor,
    required String currency,
    int dueAt = 0,
    int color = 0xFF009688,
  }) =>
      db.transaction(() async {
        final gid = id ?? _uuid.v4();
        final prev = id == null ? null : await (db.select(db.goals)..where((g) => g.spaceId.equals(spaceId) & g.id.equals(gid))).getSingleOrNull();
        final next = {'name': name, 'target_minor': targetMinor, 'currency': currency, 'due_at': dueAt, 'color': color};
        final fields = _diff(
            next,
            prev == null
                ? null
                : {
                    'name': prev.name,
                    'target_minor': prev.targetMinor,
                    'currency': prev.currency,
                    'due_at': prev.dueAt,
                    'color': prev.color,
                  });
        await db.into(db.goals).insertOnConflictUpdate(GoalsCompanion.insert(
            id: gid, spaceId: spaceId, name: name, targetMinor: targetMinor, currency: currency, dueAt: Value(dueAt), color: Value(color)));
        if (fields.isNotEmpty) await _enqueue(spaceId, 'goal', gid, 'upsert', fields);
        onChange();
        return gid;
      });

  Future<void> deleteGoal(String spaceId, String id) => db.transaction(() async {
        final parts = await (db.select(db.contributions)
              ..where((c) => c.spaceId.equals(spaceId) & c.goalId.equals(id) & c.deletedAt.isNull()))
            .get();
        for (final c in parts) {
          await _softDelete(spaceId, 'contribution', c.id);
        }
        await _softDelete(spaceId, 'goal', id);
      });

  Future<void> addContribution(String spaceId, String goalId, int amountMinor, {String note = '', int? at}) =>
      db.transaction(() async {
        final id = _uuid.v4();
        final when = at ?? _now();
        await db.into(db.contributions).insert(ContributionsCompanion.insert(
            id: id, spaceId: spaceId, goalId: goalId, amountMinor: amountMinor, at: when, note: Value(note)));
        await _enqueue(spaceId, 'contribution', id, 'upsert',
            {'goal_id': goalId, 'amount_minor': amountMinor, 'at': when, 'note': note});
        onChange();
      });

  Future<void> deleteContribution(String spaceId, String id) => _softDelete(spaceId, 'contribution', id);

  // ---------- remboursements entre membres ----------
  Future<void> addSettlement(String spaceId, {required String from, required String to, required int amountMinor, required String currency}) =>
      db.transaction(() async {
        final id = _uuid.v4();
        final when = _now();
        await db.into(db.settlements).insert(SettlementsCompanion.insert(
            id: id, spaceId: spaceId, fromUser: from, toUser: to, amountMinor: amountMinor, currency: currency, at: when));
        await _enqueue(spaceId, 'settlement', id, 'upsert',
            {'from_user': from, 'to_user': to, 'amount_minor': amountMinor, 'currency': currency, 'at': when});
        onChange();
      });

  Future<void> deleteSettlement(String spaceId, String id) => _softDelete(spaceId, 'settlement', id);

  // ---------- modèles de saisie rapide (locaux) ----------
  Future<void> saveTemplate({
    String? id,
    required String name,
    int? amountMinor,
    String? currency,
    String? categoryId,
    String note = '',
    String tags = '',
  }) async {
    final tid = id ?? _uuid.v4();
    final maxPos = await (db.selectOnly(db.templates)..addColumns([db.templates.position.max()]))
        .map((r) => r.read(db.templates.position.max()))
        .getSingle();
    await db.into(db.templates).insertOnConflictUpdate(TemplatesCompanion(
          id: Value(tid),
          name: Value(name),
          amountMinor: Value(amountMinor),
          currency: Value(currency),
          categoryId: Value(categoryId),
          note: Value(note),
          tags: Value(normalizeTags(tags)),
          position: id == null ? Value((maxPos ?? 0) + 1) : const Value.absent(),
        ));
  }

  Future<void> deleteTemplate(String id) => (db.delete(db.templates)..where((t) => t.id.equals(id))).go();

  // ---------- pièces jointes (suivi local des envois) ----------
  Future<void> markAttachmentPending(String spaceId, String id) => db
      .into(db.attachmentStates)
      .insertOnConflictUpdate(AttachmentStatesCompanion.insert(id: id, spaceId: spaceId, uploaded: const Value(false)));

  Future<List<AttachmentState>> pendingAttachments(String spaceId) =>
      (db.select(db.attachmentStates)..where((a) => a.spaceId.equals(spaceId) & a.uploaded.equals(false))).get();

  Future<void> markAttachmentUploaded(String id) =>
      (db.update(db.attachmentStates)..where((a) => a.id.equals(id))).write(const AttachmentStatesCompanion(uploaded: Value(true)));

  // ---------- import CSV ----------
  /// Nombre de dépenses déjà présentes par clé (date|montant|libellé), pour repérer les doublons.
  Future<Map<String, int>> existingExpenseCounts(String spaceId) async {
    final rows = await (db.select(db.expenses)..where((e) => e.spaceId.equals(spaceId) & e.deletedAt.isNull())).get();
    final out = <String, int>{};
    for (final e in rows) {
      final k = dedupKey(DateTime.fromMillisecondsSinceEpoch(e.spentAt), e.amountMinor, e.note);
      out[k] = (out[k] ?? 0) + 1;
    }
    return out;
  }

  /// Crée les dépenses des lignes `ok` (et les catégories inconnues). Les ids sont déterministes :
  /// importer le même fichier sur deux appareils ne crée pas de doublons après synchronisation.
  Future<int> importRows(String spaceId, List<ImportRow> rows, {required String defaultCurrency, required int categoryColor}) =>
      db.transaction(() async {
        final cats = await (db.select(db.categories)..where((c) => c.spaceId.equals(spaceId) & c.deletedAt.isNull())).get();
        final byName = {for (final c in cats) foldText(c.name).trim(): c.id};
        final occurrence = <String, int>{};
        var created = 0;
        for (final r in rows.where((r) => r.status == ImportStatus.ok)) {
          String? catId;
          final name = r.category?.trim();
          if (name != null && name.isNotEmpty) {
            final key = foldText(name).trim();
            catId = byName[key];
            if (catId == null) {
              catId = _v5('import-category:$spaceId:$key');
              byName[key] = catId;
              await db.into(db.categories).insertOnConflictUpdate(
                  CategoriesCompanion.insert(id: catId, spaceId: spaceId, name: name, color: Value(categoryColor), deletedAt: const Value(null)));
              await _enqueue(spaceId, 'category', catId, 'upsert', {'name': name, 'color': categoryColor});
            }
          }
          final key = dedupKey(r.date!, r.amountMinor, r.note);
          final n = (occurrence[key] ?? 0) + 1;
          occurrence[key] = n;
          await _putExpense(spaceId, _v5('import:$spaceId:$key#$n'), r.amountMinor, r.currency ?? defaultCurrency, catId, r.note,
              r.date!.millisecondsSinceEpoch);
          created++;
        }
        if (created > 0) onChange();
        return created;
      });

  // ---------- dépenses récurrentes ----------
  Future<String> saveRecurring({
    String? id,
    required String spaceId,
    required int amountMinor,
    required String currency,
    String? categoryId,
    required String note,
    required String period,
    required int nextDue,
  }) =>
      db.transaction(() async {
        final rid = id ?? _uuid.v4();
        await db.into(db.recurrings).insertOnConflictUpdate(RecurringsCompanion.insert(
              id: rid,
              spaceId: spaceId,
              amountMinor: amountMinor,
              currency: currency,
              categoryId: Value(categoryId),
              note: Value(note),
              period: period,
              nextDue: nextDue,
            ));
        await _enqueue(spaceId, 'recurring', rid, 'upsert', {
          'amount_minor': amountMinor,
          'currency': currency,
          'category_id': categoryId,
          'note': note,
          'period': period,
          'next_due': nextDue,
        });
        onChange();
        return rid;
      });

  Future<void> deleteRecurring(String spaceId, String id) => _softDelete(spaceId, 'recurring', id);

  /// Crée les dépenses échues. Id de dépense = v5(règle, échéance) : si deux appareils
  /// matérialisent la même échéance hors-ligne, ils produisent LA MÊME ligne (pas de doublon).
  Future<int> materializeDue(String spaceId) async {
    final now = DateTime.now();
    final rules = await (db.select(db.recurrings)
          ..where((r) =>
              r.spaceId.equals(spaceId) & r.deletedAt.isNull() & r.nextDue.isSmallerOrEqualValue(now.millisecondsSinceEpoch)))
        .get();
    var created = 0;
    for (final r in rules) {
      await db.transaction(() async {
        var due = DateTime.fromMillisecondsSinceEpoch(r.nextDue);
        var guard = 0;
        while (!due.isAfter(now) && guard++ < 400) {
          final id = _v5('recurring:${r.id}:${due.millisecondsSinceEpoch}');
          await _putExpense(spaceId, id, r.amountMinor, r.currency, r.categoryId, r.note, due.millisecondsSinceEpoch);
          created++;
          due = addPeriod(due, r.period);
        }
        await (db.update(db.recurrings)..where((x) => x.spaceId.equals(spaceId) & x.id.equals(r.id)))
            .write(RecurringsCompanion(nextDue: Value(due.millisecondsSinceEpoch)));
        await _enqueue(spaceId, 'recurring', r.id, 'upsert', {'next_due': due.millisecondsSinceEpoch});
      });
    }
    if (created > 0) onChange();
    return created;
  }

  // ---------- migration local -> espace personnel au premier login ----------
  Future<void> migrateSpace(String from, String to) async {
    if (from == to) return;
    await db.transaction(() async {
      for (final t in ['categories', 'expenses', 'budgets', 'recurrings', 'rates', 'goals', 'contributions', 'settlements']) {
        await db.customStatement('UPDATE OR REPLACE $t SET space_id = ? WHERE space_id = ?', [to, from]);
      }
      await db.customStatement('UPDATE outbox SET space_id = ? WHERE space_id = ?', [to, from]);
      await db.customStatement('UPDATE attachment_states SET space_id = ? WHERE space_id = ?', [to, from]);
    });
    db.markTablesUpdated([db.categories, db.expenses, db.budgets, db.recurrings, db.rates, db.goals, db.contributions, db.settlements, db.outbox]);
  }
}
