# KaraBudget — refonte du design

## Installer
```bash
cd ~/Documents/"Dev Project"/flutter
cp -r karabudget karabudget.bak            # ou : git commit
unzip -o ~/Téléchargements/karabudget_design.zip
cd karabudget/mobile
flutter pub get                            # enregistre les polices embarquées
flutter analyze
flutter run -d linux
```
Le zip ne contient que les fichiers modifiés (partant de v2 + fix1). Si vous avez modifié `pubspec.yaml`
localement, reportez uniquement le bloc `fonts:` situé sous `generate: true`.

## Ce qui change
- `lib/theme.dart` (nouveau) : palette, typographie, formes de tous les composants (cartes, champs, boutons,
  dialogues, barre de navigation), clair et sombre. Couleurs sémantiques via `context.kara` (good / warn / bad / hero…).
- Polices embarquées (hors-ligne, licence OFL) : Bricolage Grotesque (titres, montants) et Figtree (texte).
- `features/common.dart` : sélecteur de mois en pastille (appui sur le mois = retour au mois en cours),
  `CategoryMark` (initiale sur fond teinté), `EmptyState`, bannière lecture seule, fond de suppression.
- `features/expenses.dart` : grande carte du mois avec barre de répartition par catégorie, dépenses regroupées par jour
  avec total du jour. `ExpenseTile` garde sa signature (+ `showDate`), la recherche fonctionne sans changement.
- `features/budgets.dart` : une carte par catégorie, barre de progression épaisse, pourcentage, vert/orange/rouge.
- `features/stats.dart` : cartes de chiffres, anneau avec total au centre, courbe 6 mois épurée.
- `features/home.dart` : icônes contour/plein dans la barre de navigation.

Aucune nouvelle chaîne à traduire : les fichiers `.arb` ne changent pas.

## Passe « très moderne » (v2 du design)
- Barre de navigation **flottante en verre dépoli** : l'onglet actif s'élargit et affiche son nom ; le contenu défile dessous.
- Montant du mois **animé** (il glisse vers la nouvelle valeur quand on change de mois).
- Titres d'écran plus grands, transitions de page « zoom » (Android/Linux/Windows) et « cupertino » (iOS/macOS).
- Retour haptique léger au changement d'onglet.

## Passe « fintech sombre » (d'après votre référence Behance)
- Palette : fond quasi noir, cartes anthracite, **vert citron** (#D4FF26) comme seule couleur d'accent
  (boutons, carte du mois, onglet actif, bordure de la catégorie choisie). En mode clair : fond gris chaud, même accent.
  Pour la voir : Réglages → Apparence → Sombre.
- Typographie : Urbanist (titres, grands montants) + Figtree (texte, montants alignés).
- **Saisie d'une dépense** refaite : montant en très grand, pastille de devise, catégories en pastilles défilantes,
  **pavé numérique** (appui long sur ⌫ = tout effacer), gros bouton « Enregistrer » collé en bas.
  Le pavé se masque quand le clavier système s'ouvre (note, étiquettes). Sur ordinateur : clavier physique
  (chiffres, virgule/point, Retour arrière, Entrée).
- `pubspec.yaml` : `intl: ^0.20.3` (requis par votre version de Flutter) et polices Urbanist + Figtree.
