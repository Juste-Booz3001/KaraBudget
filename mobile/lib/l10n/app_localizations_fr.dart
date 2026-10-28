// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get accountAndSync => 'Compte et synchronisation';

  @override
  String get activity => 'Activité';

  @override
  String activityCreate(String who, String entity, String label) {
    return '$who a ajouté $entity $label';
  }

  @override
  String activityUpdate(String who, String entity, String label) {
    return '$who a modifié $entity $label';
  }

  @override
  String activityDelete(String who, String entity, String label) {
    return '$who a supprimé $entity $label';
  }

  @override
  String get addContribution => 'Ajouter un versement';

  @override
  String get allSettled => 'Tout est réglé : personne ne doit rien.';

  @override
  String get alreadyPresent => 'déjà présente';

  @override
  String get amount => 'Montant';

  @override
  String get amountOptional => 'Montant (facultatif)';

  @override
  String andMore(int n) {
    return '… et $n autres lignes';
  }

  @override
  String get appLockHelp =>
      'Demande un code PIN à l’ouverture et après 30 s en arrière-plan';

  @override
  String get appLocked => 'KaraBudget est verrouillé';

  @override
  String get appearance => 'Apparence et langue';

  @override
  String get atCurrentPace => 'au rythme actuel';

  @override
  String get attachPhoto => 'Ajouter une photo';

  @override
  String get autoSyncActive => 'Synchronisation automatique active';

  @override
  String get averagePerDay => 'Moyenne par jour';

  @override
  String get backupCreated => 'Sauvegarde créée';

  @override
  String get backupDatabase => 'Sauvegarder la base';

  @override
  String get backupHelp =>
      'Crée un fichier SQLite à enregistrer ou partager (les reçus ne sont pas inclus)';

  @override
  String get balances => 'Soldes';

  @override
  String get budgetAlmostReached => 'Budget presque atteint';

  @override
  String get budgetAndData => 'Budget et données';

  @override
  String get budgetExceeded => 'Budget dépassé';

  @override
  String budgetOf(String name) {
    return 'Budget « $name »';
  }

  @override
  String get budgets => 'Budgets';

  @override
  String get byCategory => 'Par catégorie';

  @override
  String get cancel => 'Annuler';

  @override
  String carryNegative(String amount) {
    return 'Dépassement reporté du mois précédent : −$amount';
  }

  @override
  String carryPositive(String amount) {
    return 'Reste reporté du mois précédent : +$amount';
  }

  @override
  String get categories => 'Catégories';

  @override
  String get category => 'Catégorie';

  @override
  String get changePin => 'Changer le code PIN';

  @override
  String get changesVsPrevious => 'Évolution par rapport au mois précédent';

  @override
  String get chooseColumns =>
      'Choisissez au moins la colonne date et la colonne montant (ou débit).';

  @override
  String get chooseFile => 'Choisir un fichier';

  @override
  String get choosePin => 'Choisissez un code PIN (4 à 8 chiffres)';

  @override
  String get clearDates => 'Effacer les dates';

  @override
  String get closeApp => 'Fermer l’application';

  @override
  String get codeCopied => 'Code copié';

  @override
  String get colAmount => 'Montant';

  @override
  String get colCategory => 'Catégorie';

  @override
  String get colDate => 'Date';

  @override
  String get colDebit => 'Débit';

  @override
  String get colNote => 'Libellé';

  @override
  String get confirmPin => 'Confirmez le code PIN';

  @override
  String get create => 'Créer';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get createSharedSpace => 'Créer un espace partagé';

  @override
  String get csvEmpty => 'Fichier CSV vide ou illisible';

  @override
  String get currency => 'Devise';

  @override
  String get dataStaysOnDevice => 'Vos données restent sur cet appareil';

  @override
  String get dayFirst => 'Dates au format jour/mois/année';

  @override
  String get defaultCurrency => 'Devise par défaut';

  @override
  String get delete => 'Supprimer';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Supprimer « $name » ? Les dépenses restent, sans catégorie.';
  }

  @override
  String get deleteGoalConfirm =>
      'Supprimer cet objectif et tous ses versements ?';

  @override
  String get disableAppLock => 'Désactiver le verrouillage';

  @override
  String get dueDate => 'Échéance';

  @override
  String get edit => 'Modifier';

  @override
  String get editCategory => 'Modifier la catégorie';

  @override
  String get editGoal => 'Modifier l’objectif';

  @override
  String get editRate => 'Modifier le taux';

  @override
  String get editTemplate => 'Modifier le modèle';

  @override
  String get email => 'Email';

  @override
  String get enableAppLock => 'Verrouiller l’application';

  @override
  String get entBudget => 'le budget';

  @override
  String get entCategory => 'la catégorie';

  @override
  String get entContribution => 'le versement';

  @override
  String get entExpense => 'la dépense';

  @override
  String get entGoal => 'l’objectif';

  @override
  String get entRate => 'le taux de change';

  @override
  String get entRecurring => 'la dépense récurrente';

  @override
  String get entSettlement => 'le remboursement';

  @override
  String get enterCurrentPin => 'Entrez le code PIN actuel';

  @override
  String get enterPin => 'Code PIN';

  @override
  String get everyDay => 'Chaque jour';

  @override
  String get everyMonth => 'Chaque mois';

  @override
  String get everyWeek => 'Chaque semaine';

  @override
  String exceededBy(String amount) {
    return 'dépassé de $amount';
  }

  @override
  String get exchangeRates => 'Taux de change';

  @override
  String get expense => 'Dépense';

  @override
  String get expenses => 'Dépenses';

  @override
  String get exportCsv => 'Exporter en CSV (mois affiché)';

  @override
  String get exportPdf => 'Exporter en PDF (mois affiché)';

  @override
  String get filters => 'Filtres';

  @override
  String get firstLineIsHeader => 'La première ligne est un en-tête';

  @override
  String get fromDate => 'Du…';

  @override
  String goalDue(String date) {
    return 'Échéance : $date';
  }

  @override
  String get goalName => 'Nom de l’objectif';

  @override
  String get goalOverdue => 'Date cible dépassée';

  @override
  String get goalReached => 'Objectif atteint !';

  @override
  String get haveAccount => 'J’ai déjà un compte';

  @override
  String get importBadAmount => 'montant illisible';

  @override
  String get importBadDate => 'date illisible';

  @override
  String get importCsv => 'Importer un CSV';

  @override
  String importDone(int n) {
    return '$n dépense(s) importée(s)';
  }

  @override
  String importDuplicates(int n) {
    return '$n doublon(s)';
  }

  @override
  String importErrors(int n) {
    return '$n erreur(s)';
  }

  @override
  String get importExportBackup => 'Import, export et sauvegarde';

  @override
  String get importIncomeSkipped => 'revenu ignoré';

  @override
  String get importIntro =>
      'Importez un relevé bancaire ou un ancien suivi (CSV). Les lignes déjà présentes sont détectées et ne sont pas ajoutées deux fois.';

  @override
  String importLine(int n) {
    return 'Ligne $n';
  }

  @override
  String importN(int n) {
    return 'Importer $n dépense(s)';
  }

  @override
  String importNew(int n) {
    return '$n nouvelle(s)';
  }

  @override
  String importSkipped(int n) {
    return '$n ignorée(s)';
  }

  @override
  String get importZeroSkipped => 'montant nul ignoré';

  @override
  String get invalidAmount => 'Montant invalide';

  @override
  String get invalidRate => 'Taux invalide';

  @override
  String get inviteCode => 'Code d’invitation';

  @override
  String inviteCodeLabel(String code) {
    return 'Code d’invitation : $code';
  }

  @override
  String get inviteHelp => 'À donner aux personnes à inviter';

  @override
  String get isOwed => 'On lui doit de l’argent';

  @override
  String get joinSpace => 'Rejoindre un espace partagé';

  @override
  String get language => 'Langue';

  @override
  String get lastSixMonths => '6 derniers mois';

  @override
  String lastSync(String time) {
    return 'dernière synchro $time';
  }

  @override
  String get leaveConfirm =>
      'Quitter cet espace ? Vous perdrez l’accès à ses données.';

  @override
  String get leaveSpace => 'Quitter l’espace';

  @override
  String get localModeHint => 'Mode local — connectez-vous pour synchroniser';

  @override
  String get lockEnabled => 'Verrouillage activé';

  @override
  String get manageCategories => 'Gérer les catégories';

  @override
  String get markRepaid => 'Marquer remboursé';

  @override
  String get maxAmount => 'Montant max';

  @override
  String get members => 'Membres';

  @override
  String get membersBalancesActivity => 'Membres, soldes et activité';

  @override
  String get minAmount => 'Montant min';

  @override
  String missingRates(String list, String currency) {
    return 'Aucun taux pour $list vers $currency : ces dépenses sont exclues des totaux.';
  }

  @override
  String get monthTotal => 'Total du mois';

  @override
  String get monthlyAmount => 'Montant mensuel';

  @override
  String get name => 'Nom';

  @override
  String get newCategory => 'Nouvelle catégorie';

  @override
  String get newExpense => 'Nouvelle dépense';

  @override
  String get newGoal => 'Nouvel objectif';

  @override
  String get newRate => 'Nouveau taux';

  @override
  String get newRecurring => 'Nouvelle récurrence';

  @override
  String get newTemplate => 'Nouveau modèle';

  @override
  String nextDue(String date) {
    return 'Prochaine échéance : $date';
  }

  @override
  String get no => 'Non';

  @override
  String get noActivity => 'Aucune activité pour l’instant';

  @override
  String get noAmountDetected => 'Total introuvable : saisissez le montant.';

  @override
  String get noBudgetSet => 'Aucun budget défini';

  @override
  String get noCategory => 'Sans catégorie';

  @override
  String get noDataThisMonth => 'Aucune donnée ce mois-ci';

  @override
  String get noExpensesThisMonth => 'Aucune dépense ce mois-ci';

  @override
  String get noGoals => 'Aucun objectif d’épargne';

  @override
  String get noPreviousData => 'pas de comparaison';

  @override
  String noRateFor(String from, String to) {
    return 'Aucun taux $from → $to';
  }

  @override
  String get noRecurring => 'Aucune dépense récurrente';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get noTargetDate => 'Pas de date cible';

  @override
  String get noTemplates =>
      'Créez des modèles (montant, catégorie, note) pour saisir vos dépenses fréquentes en un geste.';

  @override
  String get none => 'Aucune';

  @override
  String get notABackup => 'Ce fichier n’est pas une sauvegarde KaraBudget';

  @override
  String get notSignedIn => 'Non connecté';

  @override
  String get note => 'Note';

  @override
  String get noteRecurringHint => 'Note (loyer, abonnement…)';

  @override
  String get nothingToExport => 'Rien à exporter pour ce mois';

  @override
  String ofTarget(String amount) {
    return 'sur $amount';
  }

  @override
  String get ok => 'OK';

  @override
  String get onlyWithReceipt => 'Seulement avec un reçu';

  @override
  String get owes => 'Doit de l’argent';

  @override
  String get paidBy => 'Payé par';

  @override
  String paidByName(String name) {
    return 'payé par $name';
  }

  @override
  String get passwordHint => 'Mot de passe (8+ caractères)';

  @override
  String get pasteFromClipboard => 'Coller le presse-papiers';

  @override
  String pendingChanges(int n) {
    return '$n modification(s) en attente';
  }

  @override
  String perMonthNeeded(String amount) {
    return 'À épargner : $amount par mois';
  }

  @override
  String get personal => 'Personnel';

  @override
  String get pinHint => '4 à 8 chiffres';

  @override
  String get pinMismatch => 'Les codes ne correspondent pas';

  @override
  String get pinTooShort => '4 chiffres minimum';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get projectedEndOfMonth => 'Projection fin de mois';

  @override
  String get projectionEarly => 'estimation peu fiable (début de mois)';

  @override
  String get quickEntryBody => 'Touchez pour ajouter une dépense';

  @override
  String get quickEntryHelp =>
      'Notification permanente : un toucher ouvre l’ajout de dépense';

  @override
  String get quickEntryNotification => 'Notification de saisie rapide';

  @override
  String get quickEntryTitle => 'KaraBudget';

  @override
  String get quickTemplates => 'Modèles de saisie rapide';

  @override
  String get rateFrom => 'De';

  @override
  String get rateHelp => 'Exemple : 4800 si 1 EUR = 4 800 MGA';

  @override
  String get rateTo => 'Vers';

  @override
  String rateValue(String from, String to) {
    return 'Valeur de 1 $from en $to';
  }

  @override
  String ratesIntro(String currency) {
    return 'Saisissez vos taux pour convertir les dépenses en autres devises vers $currency dans les totaux, budgets et statistiques.';
  }

  @override
  String get readOnlyBanner => 'Vous êtes en lecture seule dans cet espace.';

  @override
  String get receipt => 'Reçu';

  @override
  String get recurring => 'Récurrence';

  @override
  String get recurringExpenses => 'Dépenses récurrentes';

  @override
  String get recurringReminderTitle => 'Dépense récurrente';

  @override
  String get regenerateCode => 'Générer un nouveau code';

  @override
  String get regenerateConfirm =>
      'L’ancien code ne fonctionnera plus. Générer un nouveau code ?';

  @override
  String get removeMember => 'Retirer de l’espace';

  @override
  String removeMemberConfirm(String email) {
    return 'Retirer $email de l’espace ?';
  }

  @override
  String get removePhoto => 'Retirer la photo';

  @override
  String get repayments => 'Remboursements';

  @override
  String get restartToFinish =>
      'Fermez puis rouvrez KaraBudget pour terminer la restauration des données.';

  @override
  String get restoreConfirm =>
      'La sauvegarde remplacera toutes les données de cet appareil. Continuer ?';

  @override
  String get restoreDatabase => 'Restaurer une sauvegarde';

  @override
  String get restorePrepared => 'Restauration prête';

  @override
  String resultsCount(int n) {
    return '$n résultat(s)';
  }

  @override
  String get roleEditor => 'Éditeur';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleViewer => 'Lecteur';

  @override
  String get rolloverHelp =>
      'Le reste (ou le dépassement) du mois précédent s’ajoute à ce budget';

  @override
  String get rolloverTitle => 'Reporter le reste';

  @override
  String get save => 'Enregistrer';

  @override
  String get saveAsTemplate => 'Enregistrer comme modèle';

  @override
  String get savingsGoals => 'Objectifs d’épargne';

  @override
  String scanFailed(String error) {
    return 'Scan impossible : $error';
  }

  @override
  String get scanReceipt => 'Scanner un reçu';

  @override
  String get search => 'Rechercher';

  @override
  String get searchHint => 'Rechercher une dépense…';

  @override
  String get searchPrompt => 'Tapez un mot ou choisissez des filtres';

  @override
  String get security => 'Sécurité';

  @override
  String get serverAddress => 'Adresse du serveur';

  @override
  String get settings => 'Réglages';

  @override
  String get sharedOnly =>
      'Disponible dans un espace partagé. Choisissez-en un dans les réglages.';

  @override
  String get sharesMustEqualTotal =>
      'La somme des parts doit être égale au montant';

  @override
  String get signAbsolute => 'Tout est une dépense (valeur absolue)';

  @override
  String get signAuto => 'Automatique';

  @override
  String get signIn => 'Connexion';

  @override
  String get signInAction => 'Se connecter';

  @override
  String get signMode => 'Sens des montants';

  @override
  String get signNegative => 'Les négatifs sont des dépenses';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get signPositive => 'Les positifs sont des dépenses';

  @override
  String get signedIn => 'Connecté';

  @override
  String get spaceName => 'Nom de l’espace';

  @override
  String get spaceNameHint => 'Couple, colocation…';

  @override
  String get spacesTitle => 'Espaces (budget partagé)';

  @override
  String get splitEqual => 'Parts égales';

  @override
  String get splitExact => 'Montants';

  @override
  String get splitNeedsPeople => 'Choisissez au moins une personne';

  @override
  String get splitNone => 'Non partagée';

  @override
  String get statistics => 'Statistiques';

  @override
  String get statsShort => 'Stats';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get synced => 'Synchronisé';

  @override
  String get syncing => 'Synchronisation…';

  @override
  String get tags => 'Étiquettes';

  @override
  String get tagsHint => 'courses, resto';

  @override
  String get targetAmount => 'Montant cible';

  @override
  String get templateName => 'Nom du modèle';

  @override
  String get templateSaved => 'Modèle enregistré';

  @override
  String get theme => 'Thème';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSystem => 'Système';

  @override
  String get toDate => 'Au…';

  @override
  String get tooManyAttempts => 'Trop d’essais. Patientez 30 secondes.';

  @override
  String get totalDetected => 'Total détecté sur le reçu : vérifiez-le';

  @override
  String transferLine(String from, String to, String amount) {
    return '$from → $to : $amount';
  }

  @override
  String unconvertedWarning(int n) {
    return '$n dépense(s) exclue(s) : taux de change manquant';
  }

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get unlockReason => 'Déverrouiller KaraBudget';

  @override
  String get useBiometrics => 'Utiliser l’empreinte / le visage';

  @override
  String get vsPreviousMonth => 'vs mois précédent';

  @override
  String get withdraw => 'Retirer de l’argent';

  @override
  String get wrongPin => 'Code PIN incorrect';

  @override
  String get yes => 'Oui';

  @override
  String youLabel(String email) {
    return '$email (vous)';
  }

  @override
  String get zeroDecimalHint =>
      'Cette devise n’a pas de décimales : « 1 500 » vaut 1 500.';
}
