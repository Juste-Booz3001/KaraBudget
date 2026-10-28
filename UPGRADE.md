# Mise à jour v1 → v2

**À lire d'abord** : le code Flutter de cette version n'a jamais été compilé (pas de SDK Flutter dans l'environnement de
rédaction). Seuls le backend (27 tests) et la logique pure de `mobile/lib/core/` (59 tests) ont été exécutés.
Envoyez-moi les erreurs de `flutter analyze` / `flutter run` et je les corrige.

## 1. Sauvegarder puis copier
```bash
cd ~/Documents/"Dev Project"/flutter
cp -r karabudget karabudget.bak                       # ou : git commit
unzip -o ~/Téléchargements/karabudget_v2.zip          # écrase backend/, mobile/lib, mobile/test, pubspec.yaml…
```
Le zip ne contient **pas** `mobile/linux/`, `mobile/android/`, `mobile/ios/` : vos dossiers de plateforme sont conservés.
Il contient déjà vos correctifs locaux (`TokenStore`, notifications Linux, suppression de `widget_test.dart`).

## 2. Mobile
```bash
cd karabudget/mobile
sudo apt install -y zenity                            # sélecteur de fichiers de file_picker sous Linux
flutter pub get                                       # télécharge file_picker, local_auth, home_widget, crypto + génère les traductions
dart run build_runner build --delete-conflicting-outputs   # OBLIGATOIRE : les tables Drift ont changé (schéma v2)
flutter analyze
flutter test
flutter run -d linux
```
Votre base locale existante est migrée automatiquement (schéma 1 → 2), sans perte.

## 3. Backend
```bash
cd ../backend
pip install -r requirements.txt
pytest -q                                             # 27 tests
```
Au démarrage, une base v1 existante reçoit les nouvelles tables et colonnes (`upgrade_schema`). Redémarrez le serveur
**avant** de synchroniser avec la nouvelle app. Les membres `member` deviennent `editor`.

## 4. Sous Linux desktop
Indisponibles (désactivés proprement) : scan ML Kit, rappels planifiés, biométrie, widget, notification de saisie rapide.
Disponibles : tout le reste, y compris import CSV, sauvegarde (boîte « Enregistrer sous »), verrouillage par PIN.
