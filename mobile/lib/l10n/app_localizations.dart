import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_mg.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('mg')
  ];

  /// No description provided for @accountAndSync.
  ///
  /// In fr, this message translates to:
  /// **'Compte et synchronisation'**
  String get accountAndSync;

  /// No description provided for @activity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get activity;

  /// No description provided for @activityCreate.
  ///
  /// In fr, this message translates to:
  /// **'{who} a ajouté {entity} {label}'**
  String activityCreate(String who, String entity, String label);

  /// No description provided for @activityUpdate.
  ///
  /// In fr, this message translates to:
  /// **'{who} a modifié {entity} {label}'**
  String activityUpdate(String who, String entity, String label);

  /// No description provided for @activityDelete.
  ///
  /// In fr, this message translates to:
  /// **'{who} a supprimé {entity} {label}'**
  String activityDelete(String who, String entity, String label);

  /// No description provided for @addContribution.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un versement'**
  String get addContribution;

  /// No description provided for @allSettled.
  ///
  /// In fr, this message translates to:
  /// **'Tout est réglé : personne ne doit rien.'**
  String get allSettled;

  /// No description provided for @alreadyPresent.
  ///
  /// In fr, this message translates to:
  /// **'déjà présente'**
  String get alreadyPresent;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @amountOptional.
  ///
  /// In fr, this message translates to:
  /// **'Montant (facultatif)'**
  String get amountOptional;

  /// No description provided for @andMore.
  ///
  /// In fr, this message translates to:
  /// **'… et {n} autres lignes'**
  String andMore(int n);

  /// No description provided for @appLockHelp.
  ///
  /// In fr, this message translates to:
  /// **'Demande un code PIN à l’ouverture et après 30 s en arrière-plan'**
  String get appLockHelp;

  /// No description provided for @appLocked.
  ///
  /// In fr, this message translates to:
  /// **'KaraBudget est verrouillé'**
  String get appLocked;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence et langue'**
  String get appearance;

  /// No description provided for @atCurrentPace.
  ///
  /// In fr, this message translates to:
  /// **'au rythme actuel'**
  String get atCurrentPace;

  /// No description provided for @attachPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get attachPhoto;

  /// No description provided for @autoSyncActive.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation automatique active'**
  String get autoSyncActive;

  /// No description provided for @averagePerDay.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne par jour'**
  String get averagePerDay;

  /// No description provided for @backupCreated.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde créée'**
  String get backupCreated;

  /// No description provided for @backupDatabase.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder la base'**
  String get backupDatabase;

  /// No description provided for @backupHelp.
  ///
  /// In fr, this message translates to:
  /// **'Crée un fichier SQLite à enregistrer ou partager (les reçus ne sont pas inclus)'**
  String get backupHelp;

  /// No description provided for @balances.
  ///
  /// In fr, this message translates to:
  /// **'Soldes'**
  String get balances;

  /// No description provided for @budgetAlmostReached.
  ///
  /// In fr, this message translates to:
  /// **'Budget presque atteint'**
  String get budgetAlmostReached;

  /// No description provided for @budgetAndData.
  ///
  /// In fr, this message translates to:
  /// **'Budget et données'**
  String get budgetAndData;

  /// No description provided for @budgetExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Budget dépassé'**
  String get budgetExceeded;

  /// No description provided for @budgetOf.
  ///
  /// In fr, this message translates to:
  /// **'Budget « {name} »'**
  String budgetOf(String name);

  /// No description provided for @budgets.
  ///
  /// In fr, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @byCategory.
  ///
  /// In fr, this message translates to:
  /// **'Par catégorie'**
  String get byCategory;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @carryNegative.
  ///
  /// In fr, this message translates to:
  /// **'Dépassement reporté du mois précédent : −{amount}'**
  String carryNegative(String amount);

  /// No description provided for @carryPositive.
  ///
  /// In fr, this message translates to:
  /// **'Reste reporté du mois précédent : +{amount}'**
  String carryPositive(String amount);

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @changePin.
  ///
  /// In fr, this message translates to:
  /// **'Changer le code PIN'**
  String get changePin;

  /// No description provided for @changesVsPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Évolution par rapport au mois précédent'**
  String get changesVsPrevious;

  /// No description provided for @chooseColumns.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins la colonne date et la colonne montant (ou débit).'**
  String get chooseColumns;

  /// No description provided for @chooseFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get chooseFile;

  /// No description provided for @choosePin.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un code PIN (4 à 8 chiffres)'**
  String get choosePin;

  /// No description provided for @clearDates.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les dates'**
  String get clearDates;

  /// No description provided for @closeApp.
  ///
  /// In fr, this message translates to:
  /// **'Fermer l’application'**
  String get closeApp;

  /// No description provided for @codeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get codeCopied;

  /// No description provided for @colAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get colAmount;

  /// No description provided for @colCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get colCategory;

  /// No description provided for @colDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colDebit.
  ///
  /// In fr, this message translates to:
  /// **'Débit'**
  String get colDebit;

  /// No description provided for @colNote.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get colNote;

  /// No description provided for @confirmPin.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le code PIN'**
  String get confirmPin;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @createSharedSpace.
  ///
  /// In fr, this message translates to:
  /// **'Créer un espace partagé'**
  String get createSharedSpace;

  /// No description provided for @csvEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Fichier CSV vide ou illisible'**
  String get csvEmpty;

  /// No description provided for @currency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get currency;

  /// No description provided for @dataStaysOnDevice.
  ///
  /// In fr, this message translates to:
  /// **'Vos données restent sur cet appareil'**
  String get dataStaysOnDevice;

  /// No description provided for @dayFirst.
  ///
  /// In fr, this message translates to:
  /// **'Dates au format jour/mois/année'**
  String get dayFirst;

  /// No description provided for @defaultCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise par défaut'**
  String get defaultCurrency;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ? Les dépenses restent, sans catégorie.'**
  String deleteCategoryConfirm(String name);

  /// No description provided for @deleteGoalConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet objectif et tous ses versements ?'**
  String get deleteGoalConfirm;

  /// No description provided for @disableAppLock.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver le verrouillage'**
  String get disableAppLock;

  /// No description provided for @dueDate.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get dueDate;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @editCategory.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la catégorie'**
  String get editCategory;

  /// No description provided for @editGoal.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’objectif'**
  String get editGoal;

  /// No description provided for @editRate.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le taux'**
  String get editRate;

  /// No description provided for @editTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le modèle'**
  String get editTemplate;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enableAppLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller l’application'**
  String get enableAppLock;

  /// No description provided for @entBudget.
  ///
  /// In fr, this message translates to:
  /// **'le budget'**
  String get entBudget;

  /// No description provided for @entCategory.
  ///
  /// In fr, this message translates to:
  /// **'la catégorie'**
  String get entCategory;

  /// No description provided for @entContribution.
  ///
  /// In fr, this message translates to:
  /// **'le versement'**
  String get entContribution;

  /// No description provided for @entExpense.
  ///
  /// In fr, this message translates to:
  /// **'la dépense'**
  String get entExpense;

  /// No description provided for @entGoal.
  ///
  /// In fr, this message translates to:
  /// **'l’objectif'**
  String get entGoal;

  /// No description provided for @entRate.
  ///
  /// In fr, this message translates to:
  /// **'le taux de change'**
  String get entRate;

  /// No description provided for @entRecurring.
  ///
  /// In fr, this message translates to:
  /// **'la dépense récurrente'**
  String get entRecurring;

  /// No description provided for @entSettlement.
  ///
  /// In fr, this message translates to:
  /// **'le remboursement'**
  String get entSettlement;

  /// No description provided for @enterCurrentPin.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code PIN actuel'**
  String get enterCurrentPin;

  /// No description provided for @enterPin.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get enterPin;

  /// No description provided for @everyDay.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour'**
  String get everyDay;

  /// No description provided for @everyMonth.
  ///
  /// In fr, this message translates to:
  /// **'Chaque mois'**
  String get everyMonth;

  /// No description provided for @everyWeek.
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine'**
  String get everyWeek;

  /// No description provided for @exceededBy.
  ///
  /// In fr, this message translates to:
  /// **'dépassé de {amount}'**
  String exceededBy(String amount);

  /// No description provided for @exchangeRates.
  ///
  /// In fr, this message translates to:
  /// **'Taux de change'**
  String get exchangeRates;

  /// No description provided for @expense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense'**
  String get expense;

  /// No description provided for @expenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get expenses;

  /// No description provided for @exportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV (mois affiché)'**
  String get exportCsv;

  /// No description provided for @exportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF (mois affiché)'**
  String get exportPdf;

  /// No description provided for @filters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filters;

  /// No description provided for @firstLineIsHeader.
  ///
  /// In fr, this message translates to:
  /// **'La première ligne est un en-tête'**
  String get firstLineIsHeader;

  /// No description provided for @fromDate.
  ///
  /// In fr, this message translates to:
  /// **'Du…'**
  String get fromDate;

  /// No description provided for @goalDue.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {date}'**
  String goalDue(String date);

  /// No description provided for @goalName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’objectif'**
  String get goalName;

  /// No description provided for @goalOverdue.
  ///
  /// In fr, this message translates to:
  /// **'Date cible dépassée'**
  String get goalOverdue;

  /// No description provided for @goalReached.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint !'**
  String get goalReached;

  /// No description provided for @haveAccount.
  ///
  /// In fr, this message translates to:
  /// **'J’ai déjà un compte'**
  String get haveAccount;

  /// No description provided for @importBadAmount.
  ///
  /// In fr, this message translates to:
  /// **'montant illisible'**
  String get importBadAmount;

  /// No description provided for @importBadDate.
  ///
  /// In fr, this message translates to:
  /// **'date illisible'**
  String get importBadDate;

  /// No description provided for @importCsv.
  ///
  /// In fr, this message translates to:
  /// **'Importer un CSV'**
  String get importCsv;

  /// No description provided for @importDone.
  ///
  /// In fr, this message translates to:
  /// **'{n} dépense(s) importée(s)'**
  String importDone(int n);

  /// No description provided for @importDuplicates.
  ///
  /// In fr, this message translates to:
  /// **'{n} doublon(s)'**
  String importDuplicates(int n);

  /// No description provided for @importErrors.
  ///
  /// In fr, this message translates to:
  /// **'{n} erreur(s)'**
  String importErrors(int n);

  /// No description provided for @importExportBackup.
  ///
  /// In fr, this message translates to:
  /// **'Import, export et sauvegarde'**
  String get importExportBackup;

  /// No description provided for @importIncomeSkipped.
  ///
  /// In fr, this message translates to:
  /// **'revenu ignoré'**
  String get importIncomeSkipped;

  /// No description provided for @importIntro.
  ///
  /// In fr, this message translates to:
  /// **'Importez un relevé bancaire ou un ancien suivi (CSV). Les lignes déjà présentes sont détectées et ne sont pas ajoutées deux fois.'**
  String get importIntro;

  /// No description provided for @importLine.
  ///
  /// In fr, this message translates to:
  /// **'Ligne {n}'**
  String importLine(int n);

  /// No description provided for @importN.
  ///
  /// In fr, this message translates to:
  /// **'Importer {n} dépense(s)'**
  String importN(int n);

  /// No description provided for @importNew.
  ///
  /// In fr, this message translates to:
  /// **'{n} nouvelle(s)'**
  String importNew(int n);

  /// No description provided for @importSkipped.
  ///
  /// In fr, this message translates to:
  /// **'{n} ignorée(s)'**
  String importSkipped(int n);

  /// No description provided for @importZeroSkipped.
  ///
  /// In fr, this message translates to:
  /// **'montant nul ignoré'**
  String get importZeroSkipped;

  /// No description provided for @invalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get invalidAmount;

  /// No description provided for @invalidRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux invalide'**
  String get invalidRate;

  /// No description provided for @inviteCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d’invitation'**
  String get inviteCode;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code d’invitation : {code}'**
  String inviteCodeLabel(String code);

  /// No description provided for @inviteHelp.
  ///
  /// In fr, this message translates to:
  /// **'À donner aux personnes à inviter'**
  String get inviteHelp;

  /// No description provided for @isOwed.
  ///
  /// In fr, this message translates to:
  /// **'On lui doit de l’argent'**
  String get isOwed;

  /// No description provided for @joinSpace.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre un espace partagé'**
  String get joinSpace;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @lastSixMonths.
  ///
  /// In fr, this message translates to:
  /// **'6 derniers mois'**
  String get lastSixMonths;

  /// No description provided for @lastSync.
  ///
  /// In fr, this message translates to:
  /// **'dernière synchro {time}'**
  String lastSync(String time);

  /// No description provided for @leaveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Quitter cet espace ? Vous perdrez l’accès à ses données.'**
  String get leaveConfirm;

  /// No description provided for @leaveSpace.
  ///
  /// In fr, this message translates to:
  /// **'Quitter l’espace'**
  String get leaveSpace;

  /// No description provided for @localModeHint.
  ///
  /// In fr, this message translates to:
  /// **'Mode local — connectez-vous pour synchroniser'**
  String get localModeHint;

  /// No description provided for @lockEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage activé'**
  String get lockEnabled;

  /// No description provided for @manageCategories.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les catégories'**
  String get manageCategories;

  /// No description provided for @markRepaid.
  ///
  /// In fr, this message translates to:
  /// **'Marquer remboursé'**
  String get markRepaid;

  /// No description provided for @maxAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant max'**
  String get maxAmount;

  /// No description provided for @members.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get members;

  /// No description provided for @membersBalancesActivity.
  ///
  /// In fr, this message translates to:
  /// **'Membres, soldes et activité'**
  String get membersBalancesActivity;

  /// No description provided for @minAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant min'**
  String get minAmount;

  /// No description provided for @missingRates.
  ///
  /// In fr, this message translates to:
  /// **'Aucun taux pour {list} vers {currency} : ces dépenses sont exclues des totaux.'**
  String missingRates(String list, String currency);

  /// No description provided for @monthTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total du mois'**
  String get monthTotal;

  /// No description provided for @monthlyAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant mensuel'**
  String get monthlyAmount;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @newCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get newCategory;

  /// No description provided for @newExpense.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dépense'**
  String get newExpense;

  /// No description provided for @newGoal.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel objectif'**
  String get newGoal;

  /// No description provided for @newRate.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau taux'**
  String get newRate;

  /// No description provided for @newRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle récurrence'**
  String get newRecurring;

  /// No description provided for @newTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau modèle'**
  String get newTemplate;

  /// No description provided for @nextDue.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine échéance : {date}'**
  String nextDue(String date);

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @noActivity.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité pour l’instant'**
  String get noActivity;

  /// No description provided for @noAmountDetected.
  ///
  /// In fr, this message translates to:
  /// **'Total introuvable : saisissez le montant.'**
  String get noAmountDetected;

  /// No description provided for @noBudgetSet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun budget défini'**
  String get noBudgetSet;

  /// No description provided for @noCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get noCategory;

  /// No description provided for @noDataThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée ce mois-ci'**
  String get noDataThisMonth;

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense ce mois-ci'**
  String get noExpensesThisMonth;

  /// No description provided for @noGoals.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objectif d’épargne'**
  String get noGoals;

  /// No description provided for @noPreviousData.
  ///
  /// In fr, this message translates to:
  /// **'pas de comparaison'**
  String get noPreviousData;

  /// No description provided for @noRateFor.
  ///
  /// In fr, this message translates to:
  /// **'Aucun taux {from} → {to}'**
  String noRateFor(String from, String to);

  /// No description provided for @noRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense récurrente'**
  String get noRecurring;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @noTargetDate.
  ///
  /// In fr, this message translates to:
  /// **'Pas de date cible'**
  String get noTargetDate;

  /// No description provided for @noTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Créez des modèles (montant, catégorie, note) pour saisir vos dépenses fréquentes en un geste.'**
  String get noTemplates;

  /// No description provided for @none.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get none;

  /// No description provided for @notABackup.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n’est pas une sauvegarde KaraBudget'**
  String get notABackup;

  /// No description provided for @notSignedIn.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté'**
  String get notSignedIn;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noteRecurringHint.
  ///
  /// In fr, this message translates to:
  /// **'Note (loyer, abonnement…)'**
  String get noteRecurringHint;

  /// No description provided for @nothingToExport.
  ///
  /// In fr, this message translates to:
  /// **'Rien à exporter pour ce mois'**
  String get nothingToExport;

  /// No description provided for @ofTarget.
  ///
  /// In fr, this message translates to:
  /// **'sur {amount}'**
  String ofTarget(String amount);

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @onlyWithReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Seulement avec un reçu'**
  String get onlyWithReceipt;

  /// No description provided for @owes.
  ///
  /// In fr, this message translates to:
  /// **'Doit de l’argent'**
  String get owes;

  /// No description provided for @paidBy.
  ///
  /// In fr, this message translates to:
  /// **'Payé par'**
  String get paidBy;

  /// No description provided for @paidByName.
  ///
  /// In fr, this message translates to:
  /// **'payé par {name}'**
  String paidByName(String name);

  /// No description provided for @passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe (8+ caractères)'**
  String get passwordHint;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In fr, this message translates to:
  /// **'Coller le presse-papiers'**
  String get pasteFromClipboard;

  /// No description provided for @pendingChanges.
  ///
  /// In fr, this message translates to:
  /// **'{n} modification(s) en attente'**
  String pendingChanges(int n);

  /// No description provided for @perMonthNeeded.
  ///
  /// In fr, this message translates to:
  /// **'À épargner : {amount} par mois'**
  String perMonthNeeded(String amount);

  /// No description provided for @personal.
  ///
  /// In fr, this message translates to:
  /// **'Personnel'**
  String get personal;

  /// No description provided for @pinHint.
  ///
  /// In fr, this message translates to:
  /// **'4 à 8 chiffres'**
  String get pinHint;

  /// No description provided for @pinMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les codes ne correspondent pas'**
  String get pinMismatch;

  /// No description provided for @pinTooShort.
  ///
  /// In fr, this message translates to:
  /// **'4 chiffres minimum'**
  String get pinTooShort;

  /// No description provided for @previousMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois précédent'**
  String get previousMonth;

  /// No description provided for @projectedEndOfMonth.
  ///
  /// In fr, this message translates to:
  /// **'Projection fin de mois'**
  String get projectedEndOfMonth;

  /// No description provided for @projectionEarly.
  ///
  /// In fr, this message translates to:
  /// **'estimation peu fiable (début de mois)'**
  String get projectionEarly;

  /// No description provided for @quickEntryBody.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour ajouter une dépense'**
  String get quickEntryBody;

  /// No description provided for @quickEntryHelp.
  ///
  /// In fr, this message translates to:
  /// **'Notification permanente : un toucher ouvre l’ajout de dépense'**
  String get quickEntryHelp;

  /// No description provided for @quickEntryNotification.
  ///
  /// In fr, this message translates to:
  /// **'Notification de saisie rapide'**
  String get quickEntryNotification;

  /// No description provided for @quickEntryTitle.
  ///
  /// In fr, this message translates to:
  /// **'KaraBudget'**
  String get quickEntryTitle;

  /// No description provided for @quickTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Modèles de saisie rapide'**
  String get quickTemplates;

  /// No description provided for @rateFrom.
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get rateFrom;

  /// No description provided for @rateHelp.
  ///
  /// In fr, this message translates to:
  /// **'Exemple : 4800 si 1 EUR = 4 800 MGA'**
  String get rateHelp;

  /// No description provided for @rateTo.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get rateTo;

  /// No description provided for @rateValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur de 1 {from} en {to}'**
  String rateValue(String from, String to);

  /// No description provided for @ratesIntro.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez vos taux pour convertir les dépenses en autres devises vers {currency} dans les totaux, budgets et statistiques.'**
  String ratesIntro(String currency);

  /// No description provided for @readOnlyBanner.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes en lecture seule dans cet espace.'**
  String get readOnlyBanner;

  /// No description provided for @receipt.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get receipt;

  /// No description provided for @recurring.
  ///
  /// In fr, this message translates to:
  /// **'Récurrence'**
  String get recurring;

  /// No description provided for @recurringExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses récurrentes'**
  String get recurringExpenses;

  /// No description provided for @recurringReminderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépense récurrente'**
  String get recurringReminderTitle;

  /// No description provided for @regenerateCode.
  ///
  /// In fr, this message translates to:
  /// **'Générer un nouveau code'**
  String get regenerateCode;

  /// No description provided for @regenerateConfirm.
  ///
  /// In fr, this message translates to:
  /// **'L’ancien code ne fonctionnera plus. Générer un nouveau code ?'**
  String get regenerateConfirm;

  /// No description provided for @removeMember.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l’espace'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {email} de l’espace ?'**
  String removeMemberConfirm(String email);

  /// No description provided for @removePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get removePhoto;

  /// No description provided for @repayments.
  ///
  /// In fr, this message translates to:
  /// **'Remboursements'**
  String get repayments;

  /// No description provided for @restartToFinish.
  ///
  /// In fr, this message translates to:
  /// **'Fermez puis rouvrez KaraBudget pour terminer la restauration des données.'**
  String get restartToFinish;

  /// No description provided for @restoreConfirm.
  ///
  /// In fr, this message translates to:
  /// **'La sauvegarde remplacera toutes les données de cet appareil. Continuer ?'**
  String get restoreConfirm;

  /// No description provided for @restoreDatabase.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une sauvegarde'**
  String get restoreDatabase;

  /// No description provided for @restorePrepared.
  ///
  /// In fr, this message translates to:
  /// **'Restauration prête'**
  String get restorePrepared;

  /// No description provided for @resultsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} résultat(s)'**
  String resultsCount(int n);

  /// No description provided for @roleEditor.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur'**
  String get roleEditor;

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get roleOwner;

  /// No description provided for @roleViewer.
  ///
  /// In fr, this message translates to:
  /// **'Lecteur'**
  String get roleViewer;

  /// No description provided for @rolloverHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le reste (ou le dépassement) du mois précédent s’ajoute à ce budget'**
  String get rolloverHelp;

  /// No description provided for @rolloverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reporter le reste'**
  String get rolloverTitle;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @saveAsTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer comme modèle'**
  String get saveAsTemplate;

  /// No description provided for @savingsGoals.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs d’épargne'**
  String get savingsGoals;

  /// No description provided for @scanFailed.
  ///
  /// In fr, this message translates to:
  /// **'Scan impossible : {error}'**
  String scanFailed(String error);

  /// No description provided for @scanReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un reçu'**
  String get scanReceipt;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une dépense…'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Tapez un mot ou choisissez des filtres'**
  String get searchPrompt;

  /// No description provided for @security.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get security;

  /// No description provided for @serverAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du serveur'**
  String get serverAddress;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @sharedOnly.
  ///
  /// In fr, this message translates to:
  /// **'Disponible dans un espace partagé. Choisissez-en un dans les réglages.'**
  String get sharedOnly;

  /// No description provided for @sharesMustEqualTotal.
  ///
  /// In fr, this message translates to:
  /// **'La somme des parts doit être égale au montant'**
  String get sharesMustEqualTotal;

  /// No description provided for @signAbsolute.
  ///
  /// In fr, this message translates to:
  /// **'Tout est une dépense (valeur absolue)'**
  String get signAbsolute;

  /// No description provided for @signAuto.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get signAuto;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get signIn;

  /// No description provided for @signInAction.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signInAction;

  /// No description provided for @signMode.
  ///
  /// In fr, this message translates to:
  /// **'Sens des montants'**
  String get signMode;

  /// No description provided for @signNegative.
  ///
  /// In fr, this message translates to:
  /// **'Les négatifs sont des dépenses'**
  String get signNegative;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get signOut;

  /// No description provided for @signPositive.
  ///
  /// In fr, this message translates to:
  /// **'Les positifs sont des dépenses'**
  String get signPositive;

  /// No description provided for @signedIn.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get signedIn;

  /// No description provided for @spaceName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’espace'**
  String get spaceName;

  /// No description provided for @spaceNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Couple, colocation…'**
  String get spaceNameHint;

  /// No description provided for @spacesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espaces (budget partagé)'**
  String get spacesTitle;

  /// No description provided for @splitEqual.
  ///
  /// In fr, this message translates to:
  /// **'Parts égales'**
  String get splitEqual;

  /// No description provided for @splitExact.
  ///
  /// In fr, this message translates to:
  /// **'Montants'**
  String get splitExact;

  /// No description provided for @splitNeedsPeople.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins une personne'**
  String get splitNeedsPeople;

  /// No description provided for @splitNone.
  ///
  /// In fr, this message translates to:
  /// **'Non partagée'**
  String get splitNone;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @statsShort.
  ///
  /// In fr, this message translates to:
  /// **'Stats'**
  String get statsShort;

  /// No description provided for @syncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get syncNow;

  /// No description provided for @synced.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé'**
  String get synced;

  /// No description provided for @syncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation…'**
  String get syncing;

  /// No description provided for @tags.
  ///
  /// In fr, this message translates to:
  /// **'Étiquettes'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In fr, this message translates to:
  /// **'courses, resto'**
  String get tagsHint;

  /// No description provided for @targetAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant cible'**
  String get targetAmount;

  /// No description provided for @templateName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du modèle'**
  String get templateName;

  /// No description provided for @templateSaved.
  ///
  /// In fr, this message translates to:
  /// **'Modèle enregistré'**
  String get templateSaved;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @toDate.
  ///
  /// In fr, this message translates to:
  /// **'Au…'**
  String get toDate;

  /// No description provided for @tooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop d’essais. Patientez 30 secondes.'**
  String get tooManyAttempts;

  /// No description provided for @totalDetected.
  ///
  /// In fr, this message translates to:
  /// **'Total détecté sur le reçu : vérifiez-le'**
  String get totalDetected;

  /// No description provided for @transferLine.
  ///
  /// In fr, this message translates to:
  /// **'{from} → {to} : {amount}'**
  String transferLine(String from, String to, String amount);

  /// No description provided for @unconvertedWarning.
  ///
  /// In fr, this message translates to:
  /// **'{n} dépense(s) exclue(s) : taux de change manquant'**
  String unconvertedWarning(int n);

  /// No description provided for @unlock.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get unlock;

  /// No description provided for @unlockReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller KaraBudget'**
  String get unlockReason;

  /// No description provided for @useBiometrics.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l’empreinte / le visage'**
  String get useBiometrics;

  /// No description provided for @vsPreviousMonth.
  ///
  /// In fr, this message translates to:
  /// **'vs mois précédent'**
  String get vsPreviousMonth;

  /// No description provided for @withdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l’argent'**
  String get withdraw;

  /// No description provided for @wrongPin.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN incorrect'**
  String get wrongPin;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @youLabel.
  ///
  /// In fr, this message translates to:
  /// **'{email} (vous)'**
  String youLabel(String email);

  /// No description provided for @zeroDecimalHint.
  ///
  /// In fr, this message translates to:
  /// **'Cette devise n’a pas de décimales : « 1 500 » vaut 1 500.'**
  String get zeroDecimalHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'mg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'mg':
      return AppLocalizationsMg();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
