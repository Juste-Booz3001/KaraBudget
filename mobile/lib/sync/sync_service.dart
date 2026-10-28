import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/db.dart';

abstract class SyncApi {
  /// Retourne un résultat par op : {op_id, status, error?}.
  Future<List<Map<String, dynamic>>> push(String spaceId, String deviceId, List<Map<String, dynamic>> ops);
  Future<Map<String, dynamic>> pull(String spaceId, int since);
}

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

/// push (vider l'outbox) puis pull (appliquer les changements distants).
/// En cas d'erreur réseau, rien n'est perdu : l'outbox n'est vidée qu'après la réponse du serveur.
class SyncService {
  SyncService(this.db, this.api, this.deviceId);
  final AppDatabase db;
  final SyncApi api;
  final String deviceId;

  Future<void> syncSpace(String spaceId) async {
    await _push(spaceId);
    await _pull(spaceId);
  }

  Future<void> _push(String spaceId) async {
    while (true) {
      final ops = await (db.select(db.outbox)
            ..where((o) => o.spaceId.equals(spaceId))
            ..orderBy([(o) => OrderingTerm.asc(o.seq)])
            ..limit(200))
          .get();
      if (ops.isEmpty) return;
      final results = await api.push(spaceId, deviceId, ops.map(_opToJson).toList());
      for (final r in results.where((r) => r['status'] == 'rejected')) {
        // une op invalide ne doit pas bloquer la file : on la journalise et on l'abandonne
        // ignore: avoid_print
        print('sync: op rejetée ${r['op_id']}: ${r['error']}');
      }
      await (db.delete(db.outbox)..where((o) => o.seq.isIn(ops.map((o) => o.seq)))).go();
    }
  }

  Map<String, dynamic> _opToJson(OutboxOp o) => {
        'op_id': o.opId,
        'entity': o.entity,
        'entity_id': o.entityId,
        'action': o.action,
        'fields': jsonDecode(o.fieldsJson),
        'ts': o.ts,
      };

  Future<void> _pull(String spaceId) async {
    var cursor = (await (db.select(db.syncStates)..where((s) => s.spaceId.equals(spaceId))).getSingleOrNull())?.cursor ?? 0;
    while (true) {
      final r = await api.pull(spaceId, cursor);
      final changes = (r['changes'] as List).cast<Map<String, dynamic>>();
      final next = r['next_cursor'] as int;
      await db.transaction(() async {
        for (final c in changes) {
          await applyChange(spaceId, c);
        }
        await db.into(db.syncStates).insertOnConflictUpdate(SyncStatesCompanion.insert(spaceId: spaceId, cursor: Value(next)));
      });
      cursor = next;
      if (r['has_more'] != true) break;
    }
  }

  /// Applique une ligne distante, SAUF les champs que l'utilisateur a modifiés localement
  /// et qui attendent encore dans l'outbox (ils seront arbitrés par le serveur au prochain push).
  Future<void> applyChange(String spaceId, Map<String, dynamic> c) async {
    final entity = c['entity'] as String;
    final id = c['id'] as String;
    final pending = await (db.select(db.outbox)..where((o) => o.spaceId.equals(spaceId) & o.entityId.equals(id))).get();
    final skip = <String>{};
    for (final p in pending) {
      if (p.action == 'delete') {
        skip.add('deleted_at');
      } else {
        skip.addAll((jsonDecode(p.fieldsJson) as Map).keys.cast<String>());
      }
    }
    final table = _tableOf[entity];
    if (table == null) return; // entité inconnue (serveur plus récent que l'app) : on l'ignore
    final known = await _columns(table);
    final values = <String, Object?>{
      'id': id,
      'space_id': spaceId,
      'deleted_at': c['deleted_at'],
      // champs inconnus de cette version de l'app : ignorés plutôt que de faire échouer toute la sync
      for (final e in (c['fields'] as Map<String, dynamic>).entries)
        if (known.contains(e.key)) e.key: e.value,
    };
    await _upsertRaw(table, values, skip);
  }

  final Map<String, Set<String>> _columnCache = {};

  Future<Set<String>> _columns(String table) async {
    final cached = _columnCache[table];
    if (cached != null) return cached;
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return _columnCache[table] = {for (final r in rows) r.read<String>('name')};
  }

  Future<void> _upsertRaw(String table, Map<String, Object?> values, Set<String> skip) async {
    final cols = values.keys.toList();
    final updateCols = cols.where((c) => c != 'id' && c != 'space_id' && !skip.contains(c)).toList();
    final conflict = updateCols.isEmpty
        ? 'DO NOTHING'
        : 'DO UPDATE SET ${updateCols.map((c) => '$c = excluded.$c').join(', ')}';
    final sql = 'INSERT INTO $table (${cols.join(', ')}) VALUES (${cols.map((_) => '?').join(', ')}) '
        'ON CONFLICT(space_id, id) $conflict';
    await db.customInsert(
      sql,
      variables: [for (final v in values.values) _variable(v)],
      updates: {db.tableByName(table)},
    );
  }

  Variable _variable(Object? v) => switch (v) {
        int() => Variable.withInt(v),
        String() => Variable.withString(v),
        _ => Variable<Object>(null),
      };
}
