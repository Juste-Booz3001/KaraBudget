# Widget d'écran d'accueil Android

> ⚠ **Non vérifié** : ce code natif n'a jamais été compilé (pas de SDK Android dans l'environnement où il a été écrit).
> Le côté Flutter (`lib/core/home_widget_sync.dart`) est branché et sans effet tant que ce widget n'est pas installé.

Le widget affiche le **budget restant du mois** (somme des budgets − dépensé), une barre de progression, et un
bouton **+** qui ouvre directement l'ajout de dépense. Il est mis à jour à chaque changement des dépenses ou budgets.

## Installation (après `flutter create`)

Depuis la racine du dépôt, en remplaçant `com.example.karabudget` par votre `applicationId` :

```bash
APP=mobile/android/app/src/main
PKG_DIR=$APP/kotlin/com/example/karabudget          # adaptez au package de MainActivity.kt
cp android_widget/kotlin/KaraBudgetWidgetProvider.kt $PKG_DIR/
mkdir -p $APP/res/layout $APP/res/xml $APP/res/drawable
cp android_widget/res/layout/*   $APP/res/layout/
cp android_widget/res/xml/*      $APP/res/xml/
cp android_widget/res/drawable/* $APP/res/drawable/
```

1. Vérifiez que la première ligne de `KaraBudgetWidgetProvider.kt` (`package …`) correspond au package de `MainActivity`.
2. Dans `AndroidManifest.xml`, **à l'intérieur de `<application>`**, ajoutez :

```xml
<receiver android:name=".KaraBudgetWidgetProvider" android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data android:name="android.appwidget.provider" android:resource="@xml/karabudget_widget_info" />
</receiver>
```

3. `flutter pub get`, `flutter run`, puis appui long sur l'écran d'accueil → Widgets → KaraBudget.

Le nom de la classe (`KaraBudgetWidgetProvider`) doit rester identique à `HomeWidgetService.androidProvider`
dans `lib/core/home_widget_sync.dart`.

## Pas fait
- Widget iOS (WidgetKit / SwiftUI : projet Xcode dédié).
- Le widget affiche les budgets de l'**espace actif** dans la **devise par défaut**, sans report de budget.
