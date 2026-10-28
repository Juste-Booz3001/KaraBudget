import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

mixin Scoped on Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text()();
  IntColumn get deletedAt => integer().nullable()(); // suppression logique (tombstone)
}

class Categories extends Table with Scoped {
  TextColumn get name => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFF607D8B))();
  TextColumn get icon => text().withDefault(const Constant('label'))();
  @override
  Set<Column> get primaryKey => {spaceId, id};
}

class Expenses extends Table with Scoped {
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get spentAt => integer()();
  TextColumn get tags => text().withDefault(const Constant(''))(); // "courses,resto"
  TextColumn get paidBy => text().nullable()(); // user_id du payeur (dépense partagée)
  TextColumn get splitJson => text().withDefault(const Constant(''))(); // voir core/splits.dart
  TextColumn get attachmentId => text().nullable()(); // photo du reçu
  @override
  Set<Column> get primaryKey => {spaceId, id};
}

class Budgets extends Table with Scoped {
  TextColumn get categoryId => text()();
  TextColumn get month => text()(); // "2026-10"
  IntColumn get limitMinor => integer()();
  IntColumn get rollover => integer().withDefault(const Constant(0))(); // 1 = reporte le reste du mois précédent
  @override
  Set<Column> get primaryKey => {spaceId, id};
}

class Recurrings extends Table with Scoped {
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get period => text()(); // daily | weekly | monthly
  IntColumn get nextDue => integer()();
  @override
  Set<Column> get primaryKey => {spaceId, id};
}

/// Taux de change saisi à la main : 1 [fromCurrency] = ratePpm / 1 000 000 [toCurrency].
class Rates extends Table with Scoped {
  TextColumn get fromCurrency => text()();
  TextColumn get toCurrency => text()();
  IntColumn get ratePpm => integer()();
  @override
  Set<Column> get primaryKey => {spaceId, id};
}

class Goals extends Table with Scoped {
  TextColumn get name => text()();
  IntColumn get targetMinor => integer()();
  TextColumn get currency => text()();
  IntColumn get dueAt => integer().withDefault(const Constant(0))(); // 0 = pas de date cible
  IntColumn get color => integer().withDefault(const Constant(0xFF009688))();
  @override
  Set<Column> get primaryKey => {spaceId, id};
}

/// Un versement = une ligne (le solde d'un objectif est la somme) : pas de conflit entre appareils.
class Contributions extends Table with Scoped {
  TextColumn get goalId => text()();
  IntColumn get amountMinor => integer()(); // négatif = retrait
  IntColumn get at => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  @override
  Set<Column> get primaryKey => {spaceId, id};
}

/// Remboursement entre deux membres d'un espace partagé.
class Settlements extends Table with Scoped {
  TextColumn get fromUser => text()();
  TextColumn get toUser => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  IntColumn get at => integer()();
  @override
  Set<Column> get primaryKey => {spaceId, id};
}

/// Modèles de saisie rapide : propres à l'appareil (non synchronisés).
@DataClassName('QuickTemplate')
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get amountMinor => integer().nullable()();
  TextColumn get currency => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Photos de reçus à envoyer au serveur (le fichier est sur l'appareil).
class AttachmentStates extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text()();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

/// File d'opérations locales (outbox) : chaque écriture utilisateur y ajoute une op.
@DataClassName('OutboxOp')
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get opId => text().unique()();
  TextColumn get spaceId => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // upsert | delete
  TextColumn get fieldsJson => text()();
  IntColumn get ts => integer()();
}

class SyncStates extends Table {
  TextColumn get spaceId => text()();
  IntColumn get cursor => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {spaceId};
}

const dbName = 'karabudget';

/// Chemin du fichier SQLite (sauvegarde / restauration).
Future<String> databaseFilePath() async => '${(await getApplicationDocumentsDirectory()).path}/$dbName.sqlite';

@DriftDatabase(tables: [
  Categories,
  Expenses,
  Budgets,
  Recurrings,
  Rates,
  Goals,
  Contributions,
  Settlements,
  Templates,
  AttachmentStates,
  Outbox,
  SyncStates,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: dbName, native: DriftNativeOptions(databasePath: databaseFilePath)));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(expenses, expenses.tags);
            await m.addColumn(expenses, expenses.paidBy);
            await m.addColumn(expenses, expenses.splitJson);
            await m.addColumn(expenses, expenses.attachmentId);
            await m.addColumn(budgets, budgets.rollover);
            await m.createTable(rates);
            await m.createTable(goals);
            await m.createTable(contributions);
            await m.createTable(settlements);
            await m.createTable(templates);
            await m.createTable(attachmentStates);
          }
        },
      );

  TableInfo tableByName(String name) => switch (name) {
        'categories' => categories,
        'expenses' => expenses,
        'budgets' => budgets,
        'recurrings' => recurrings,
        'rates' => rates,
        'goals' => goals,
        'contributions' => contributions,
        'settlements' => settlements,
        _ => throw ArgumentError('table inconnue: $name'),
      };
}
