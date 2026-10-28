# KaraBudget

Gestionnaire de dépenses **offline-first** : tout fonctionne sans réseau, les modifications sont mises en file
(outbox) puis synchronisées dès que la connexion revient.

- **Mobile** : Flutter, Riverpod, Drift (SQLite), Dio, fl_chart, ML Kit (OCR), notifications locales
- **Backend** : FastAPI, SQLAlchemy 2, PostgreSQL, JWT (access + refresh)
- **Langues** : français, anglais, malgache (fichiers ARB — la traduction malgache est à faire relire)
- **Qualité** : 27 tests backend (pytest), 59 tests Dart de logique pure, tests Flutter (sync, dépôt), CI GitHub Actions

> **État de vérification** — backend : testé. Logique pure Dart (`lib/core/*` : argent, taux, rapports, report de budget,
> partage, import CSV, filtres) : testée. **Écrans Flutter, couche Drift/dépôt, code natif Android : écrits mais jamais
> compilés ni exécutés.** Attendez-vous à corriger quelques erreurs de compilation à la première exécution.

## Architecture

```
┌────────── Flutter ──────────┐        ┌──────── FastAPI ────────────────────┐
│ UI (Riverpod)               │        │ /auth  /spaces (+ rôles, membres)   │
│   ↕ streams Drift           │  HTTPS │ /spaces/{id}/sync/push | pull       │
│ SQLite ←→ Repository        │ ─────→ │ /spaces/{id}/activity               │
│   (ligne locale + op outbox │ ←───── │ /spaces/{id}/attachments/{id}       │
│    dans UNE transaction)    │        │ /spaces/{id}/export/csv             │
│ SyncService (push → pull)   │        │ PostgreSQL                          │
│ AttachmentSync (reçus)      │        └─────────────────────────────────────┘
└─────────────────────────────┘
```

## Protocole de synchronisation

| Besoin | Solution |
|---|---|
| Créer hors-ligne sans collision d'ID | UUID générés côté client, clé serveur `(space_id, id)` |
| Réseau coupé en plein envoi | chaque op a un `op_id` ; le serveur ignore un `op_id` déjà vu (idempotence) |
| Deux appareils éditent la même ligne | **last-write-wins par champ** : une op ne gagne que si `ts > field_ts[champ]` |
| Horloge d'un appareil fausse | le `ts` client est borné à `now + 5 min` côté serveur |
| Suppression | suppression logique (`deleted_at`) ; un ré-ajout plus récent envoie `deleted_at: null` et ressuscite la ligne (LWW) |
| Récupérer les changements | `pull?since=<rev>` : curseur monotone par espace, paginé |
| Ne pas écraser une édition locale non envoyée | le pull saute les champs encore présents dans l'outbox |
| Éditions de champs différents | l'app n'envoie que les champs modifiés (diff) → les deux éditions survivent |
| Épargne à deux appareils | un **versement = une ligne** (le solde est la somme) : aucun écrasement possible |
| App plus ancienne que le serveur | champs et entités inconnus ignorés au pull, au lieu de faire échouer la synchro |
| Montants | entiers en unité mineure, jamais de float ; taux de change en parts par million (entier) |

## Fonctionnalités

| | État |
|---|---|
| Dépenses : ajout rapide, édition, suppression (glisser), **étiquettes**, **devise par dépense** | ✅ |
| **Recherche** : texte (sans accents), période, montant min/max, catégories, étiquette, « avec reçu » | ✅ |
| Budgets mensuels + barres, alerte à 80 % ; **report du reste / dépassement** (enveloppes, 12 mois max) | ✅ |
| **Objectifs d'épargne** : versements/retraits, progression, montant mensuel à épargner pour la date cible | ✅ |
| **Rapports** : total vs mois précédent, moyenne/jour, projection de fin de mois, évolution par catégorie, courbe 6 mois | ✅ |
| **Multi-devises** : taux saisis à la main (direct, inverse ou via une devise intermédiaire), totaux convertis | ✅ |
| **Reçus** : photo gardée avec la dépense (envoyée au serveur, téléchargée à la demande) + scan ML Kit | ✅ |
| **Import CSV** (relevés bancaires) : détection des colonnes/séparateur, doublons, ré-import sans effet | ✅ |
| Export CSV / PDF (client) et CSV (serveur, anti-injection de formules) | ✅ |
| **Rôles** (propriétaire / éditeur / lecteur), retrait d'un membre, nouveau code d'invitation, quitter l'espace | ✅ |
| **Partage de dépenses** (parts égales ou exactes), soldes par devise, remboursements proposés | ✅ |
| **Journal d'activité** (qui a modifié quoi, quand — écrit par le serveur) | ✅ |
| **Verrouillage** par code PIN (+ biométrie), reverrouillage après 30 s en arrière-plan | ✅ (à tester) |
| **Saisie rapide** : modèles + notification permanente Android | ✅ (à tester) |
| **Sauvegarde / restauration** du fichier SQLite | ✅ (à tester) |
| **Langues** fr / en / mg (ARB) | ✅ |
| **Widget d'écran d'accueil Android** | ⚠ code fourni dans `android_widget/`, non compilé |
| Widget iOS | ❌ |
| Migrations Alembic, rate-limiting `/auth`, sync en arrière-plan app fermée | ❌ |

## Lancer

### Backend
```bash
cd backend
pip install -r requirements.txt
pytest -q                                   # 27 tests
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload   # SQLite local, http://localhost:8000/docs

# ou avec PostgreSQL
export KARA_SECRET_KEY="$(openssl rand -hex 32)"
docker compose up --build                   # depuis la racine
```
**Mise à jour d'une base v1** : au démarrage, `upgrade_schema()` crée les nouvelles tables et ajoute les colonnes
manquantes (`expenses.tags/paid_by/split_json/attachment_id`, `budgets.rollover`). C'est un palliatif ; en production,
utilisez de vraies migrations Alembic. Les anciens membres au rôle `member` sont traités comme `editor`.

### Mobile
```bash
cd mobile
flutter create --platforms=android,ios,linux . --project-name karabudget   # une seule fois
flutter pub get                                                 # génère aussi lib/l10n/app_localizations.dart
dart run build_runner build --delete-conflicting-outputs        # régénère lib/data/db.g.dart (schéma v2 !)
flutter test
flutter run
```
La base locale passe en **schéma v2** : la migration ajoute les colonnes et tables à une base existante.
Après avoir mis à jour `lib/`, relancez **obligatoirement** `build_runner` (les tables Drift ont changé).

Dans l'app : Réglages → adresse du serveur (`http://10.0.2.2:8000` pour l'émulateur Android, `http://localhost:8000`
sur Linux desktop) → Connexion.

### Réglages de plateforme après `flutter create`
- **Android** (`AndroidManifest.xml`) : permissions `POST_NOTIFICATIONS`, `CAMERA`, `USE_BIOMETRIC` ;
  `android:usesCleartextTraffic="true"` en dev uniquement ; `minSdkVersion 21`.
- **Android — biométrie** (`local_auth`) : `MainActivity` doit étendre `FlutterFragmentActivity`
  (`import io.flutter.embedding.android.FlutterFragmentActivity`), et le thème `LaunchTheme`/`NormalTheme` doit hériter de
  `Theme.AppCompat…` ou `Theme.MaterialComponents…` (voir la doc du package `local_auth`).
- **iOS** (`Info.plist`) : `NSCameraUsageDescription`, `NSFaceIDUsageDescription`.
- **Linux desktop** : ML Kit, rappels planifiés, biométrie et widget n'existent pas ; l'app les désactive sans planter.
- **Widget Android** : voir `android_widget/README.md`.

### Jetons d'authentification
`lib/sync/token_store.dart` stocke les jetons dans `shared_preferences` (**non chiffré**), pour pouvoir compiler sur un
Linux sans `libsecret-1-dev`. Avant une version de production sur Android/iOS, remplacez-le par `flutter_secure_storage`
(même interface : `read/write/delete(key:)`).

## Traductions
Fichiers : `mobile/lib/l10n/app_fr.arb` (modèle), `app_en.arb`, `app_mg.arb`. Ajouter une chaîne = une clé dans les trois
fichiers (avec `@clé` + `placeholders` dans `app_fr.arb` si elle a des paramètres). Évitez l'apostrophe ASCII `'` dans les
messages (caractère d'échappement ICU) : utilisez `’`. Le malgache utilise les composants Material en français
(Flutter n'a pas de textes système malgaches) et les noms de mois français.
