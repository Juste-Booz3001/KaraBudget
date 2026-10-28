// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malagasy (`mg`).
class AppLocalizationsMg extends AppLocalizations {
  AppLocalizationsMg([String locale = 'mg']) : super(locale);

  @override
  String get accountAndSync => 'Kaonty sy fampifanarahana';

  @override
  String get activity => 'Hetsika';

  @override
  String activityCreate(String who, String entity, String label) {
    return '$who namorona $entity $label';
  }

  @override
  String activityUpdate(String who, String entity, String label) {
    return '$who nanova $entity $label';
  }

  @override
  String activityDelete(String who, String entity, String label) {
    return '$who namafa $entity $label';
  }

  @override
  String get addContribution => 'Hanampy vola';

  @override
  String get allSettled => 'Voaloa daholo: tsy misy trosa.';

  @override
  String get alreadyPresent => 'efa misy';

  @override
  String get amount => 'Vola';

  @override
  String get amountOptional => 'Vola (tsy voatery)';

  @override
  String andMore(int n) {
    return '… ary andalana $n hafa';
  }

  @override
  String get appLockHelp =>
      'Mangataka kaody PIN rehefa misokatra ny rindrambaiko sy aorian’ny 30 segondra';

  @override
  String get appLocked => 'Voahidy ny KaraBudget';

  @override
  String get appearance => 'Endrika sy fiteny';

  @override
  String get atCurrentPace => 'amin’ny hafainganam-pandehan’izao';

  @override
  String get attachPhoto => 'Hanisy sary';

  @override
  String get autoSyncActive => 'Mandeha ho azy ny fampifanarahana';

  @override
  String get averagePerDay => 'Salan’isa isan’andro';

  @override
  String get backupCreated => 'Voaforona ny kopia fiarovana';

  @override
  String get backupDatabase => 'Hanao kopia fiarovana';

  @override
  String get backupHelp =>
      'Mamorona rakitra SQLite azo tehirizina na zaraina (tsy tafiditra ny sarin’ny rosia)';

  @override
  String get balances => 'Sisa';

  @override
  String get budgetAlmostReached => 'Efa saika tonga ny tetibola';

  @override
  String get budgetAndData => 'Tetibola sy angona';

  @override
  String get budgetExceeded => 'Nihoatra ny tetibola';

  @override
  String budgetOf(String name) {
    return 'Tetibola: $name';
  }

  @override
  String get budgets => 'Tetibola';

  @override
  String get byCategory => 'Araka ny sokajy';

  @override
  String get cancel => 'Foano';

  @override
  String carryNegative(String amount) {
    return 'Fihoarana nafindra avy tamin’ny volana teo aloha: −$amount';
  }

  @override
  String carryPositive(String amount) {
    return 'Sisa nafindra avy tamin’ny volana teo aloha: +$amount';
  }

  @override
  String get categories => 'Sokajy';

  @override
  String get category => 'Sokajy';

  @override
  String get changePin => 'Hanova ny kaody PIN';

  @override
  String get changesVsPrevious =>
      'Fiovana raha oharina amin’ny volana teo aloha';

  @override
  String get chooseColumns =>
      'Fidio farafahakeliny ny tsanganana daty sy ny vola (na debita).';

  @override
  String get chooseFile => 'Misafidia rakitra';

  @override
  String get choosePin => 'Mifidiana kaody PIN (isa 4 ka hatramin’ny 8)';

  @override
  String get clearDates => 'Afaho ny daty';

  @override
  String get closeApp => 'Akatony ny rindrambaiko';

  @override
  String get codeCopied => 'Voadika ny kaody';

  @override
  String get colAmount => 'Vola';

  @override
  String get colCategory => 'Sokajy';

  @override
  String get colDate => 'Daty';

  @override
  String get colDebit => 'Debita';

  @override
  String get colNote => 'Fanamarihana';

  @override
  String get confirmPin => 'Ampidiro indray ny kaody PIN';

  @override
  String get create => 'Hamorona';

  @override
  String get createAccount => 'Hamorona kaonty';

  @override
  String get createSharedSpace => 'Hamorona toerana iombonana';

  @override
  String get csvEmpty => 'Foana na tsy mety vakiana ny rakitra CSV';

  @override
  String get currency => 'Moneta';

  @override
  String get dataStaysOnDevice =>
      'Mijanona ao amin’ity fitaovana ity ny angonao';

  @override
  String get dayFirst => 'Daty: andro/volana/taona';

  @override
  String get defaultCurrency => 'Moneta tsotra';

  @override
  String get delete => 'Fafao';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Fafana ve ny sokajy « $name »? Mijanona ny fandaniana nefa tsy misy sokajy.';
  }

  @override
  String get deleteGoalConfirm =>
      'Fafana ve ity tanjona ity sy ny vola nampidirina rehetra?';

  @override
  String get disableAppLock => 'Hanala ny fanidiana';

  @override
  String get dueDate => 'Fe-potoana';

  @override
  String get edit => 'Ovay';

  @override
  String get editCategory => 'Ovay ny sokajy';

  @override
  String get editGoal => 'Ovay ny tanjona';

  @override
  String get editRate => 'Ovay ny tahany';

  @override
  String get editTemplate => 'Ovay ny môdely';

  @override
  String get email => 'Mailaka';

  @override
  String get enableAppLock => 'Hanidy ny rindrambaiko';

  @override
  String get entBudget => 'ny tetibola';

  @override
  String get entCategory => 'ny sokajy';

  @override
  String get entContribution => 'ny fandoavam-bola';

  @override
  String get entExpense => 'ny fandaniana';

  @override
  String get entGoal => 'ny tanjona';

  @override
  String get entRate => 'ny tahan’ny fifanakalozam-bola';

  @override
  String get entRecurring => 'ny fandaniana miverimberina';

  @override
  String get entSettlement => 'ny famerenana vola';

  @override
  String get enterCurrentPin => 'Ampidiro ny kaody PIN ankehitriny';

  @override
  String get enterPin => 'Kaody PIN';

  @override
  String get everyDay => 'Isan’andro';

  @override
  String get everyMonth => 'Isam-bolana';

  @override
  String get everyWeek => 'Isan-kerinandro';

  @override
  String exceededBy(String amount) {
    return 'nihoatra $amount';
  }

  @override
  String get exchangeRates => 'Tahan’ny fifanakalozam-bola';

  @override
  String get expense => 'Fandaniana';

  @override
  String get expenses => 'Fandaniana';

  @override
  String get exportCsv => 'Hanondrana CSV (volana aseho)';

  @override
  String get exportPdf => 'Hanondrana PDF (volana aseho)';

  @override
  String get filters => 'Sivana';

  @override
  String get firstLineIsHeader => 'Lohateny ny andalana voalohany';

  @override
  String get fromDate => 'Manomboka…';

  @override
  String goalDue(String date) {
    return 'Daty tanjona: $date';
  }

  @override
  String get goalName => 'Anaran’ny tanjona';

  @override
  String get goalOverdue => 'Lany daty ny tanjona';

  @override
  String get goalReached => 'Tratra ny tanjona!';

  @override
  String get haveAccount => 'Manana kaonty aho';

  @override
  String get importBadAmount => 'vola tsy mety vakiana';

  @override
  String get importBadDate => 'daty tsy mety vakiana';

  @override
  String get importCsv => 'Hampiditra CSV';

  @override
  String importDone(int n) {
    return 'Voampiditra ny fandaniana $n';
  }

  @override
  String importDuplicates(int n) {
    return '$n efa misy';
  }

  @override
  String importErrors(int n) {
    return '$n diso';
  }

  @override
  String get importExportBackup => 'Fampidirana, fanondranana ary kopia';

  @override
  String get importIncomeSkipped => 'vola miditra: tsy raharahaina';

  @override
  String get importIntro =>
      'Ampidiro ny tahiry avy amin’ny banky na ny fanaraha-maso taloha (CSV). Ny andalana efa misy dia tsy hampidirina indroa.';

  @override
  String importLine(int n) {
    return 'Andalana $n';
  }

  @override
  String importN(int n) {
    return 'Ampidiro ny fandaniana $n';
  }

  @override
  String importNew(int n) {
    return '$n vaovao';
  }

  @override
  String importSkipped(int n) {
    return '$n navela';
  }

  @override
  String get importZeroSkipped => 'vola 0: tsy raharahaina';

  @override
  String get invalidAmount => 'Vola tsy mety';

  @override
  String get invalidRate => 'Tahany tsy mety';

  @override
  String get inviteCode => 'Kaody fanasana';

  @override
  String inviteCodeLabel(String code) {
    return 'Kaody fanasana: $code';
  }

  @override
  String get inviteHelp => 'Zarao amin’ny olona tianao hasaina';

  @override
  String get isOwed => 'Tokony horaisina vola';

  @override
  String get joinSpace => 'Hiditra amin’ny toerana iombonana';

  @override
  String get language => 'Fiteny';

  @override
  String get lastSixMonths => 'Volana enina farany';

  @override
  String lastSync(String time) {
    return 'fampifanarahana farany $time';
  }

  @override
  String get leaveConfirm =>
      'Hiala amin’ity toerana ity ve? Tsy ho azonao intsony ny angony.';

  @override
  String get leaveSpace => 'Hiala amin’ny toerana';

  @override
  String get localModeHint => 'Fomba eo an-toerana — miditra mba hampifanaraka';

  @override
  String get lockEnabled => 'Misy fanidiana ankehitriny';

  @override
  String get manageCategories => 'Hitantana ny sokajy';

  @override
  String get markRepaid => 'Efa voaloa';

  @override
  String get maxAmount => 'Vola ambony indrindra';

  @override
  String get members => 'Mpikambana';

  @override
  String get membersBalancesActivity => 'Mpikambana, sisa ary hetsika';

  @override
  String get minAmount => 'Vola ambany indrindra';

  @override
  String missingRates(String list, String currency) {
    return 'Tsy misy tahany ho an’ny $list mankany amin’ny $currency: tsy tafiditra ao amin’ny fitambarana ireo fandaniana ireo.';
  }

  @override
  String get monthTotal => 'Fitambaran’ny volana';

  @override
  String get monthlyAmount => 'Vola isam-bolana';

  @override
  String get name => 'Anarana';

  @override
  String get newCategory => 'Sokajy vaovao';

  @override
  String get newExpense => 'Fandaniana vaovao';

  @override
  String get newGoal => 'Tanjona vaovao';

  @override
  String get newRate => 'Tahany vaovao';

  @override
  String get newRecurring => 'Fandaniana miverimberina vaovao';

  @override
  String get newTemplate => 'Môdely vaovao';

  @override
  String nextDue(String date) {
    return 'Daty manaraka: $date';
  }

  @override
  String get no => 'Tsia';

  @override
  String get noActivity => 'Mbola tsy misy hetsika';

  @override
  String get noAmountDetected => 'Tsy hita ny totaliny: ampidiro ny vola.';

  @override
  String get noBudgetSet => 'Tsy mbola misy tetibola';

  @override
  String get noCategory => 'Tsy misy sokajy';

  @override
  String get noDataThisMonth => 'Tsy misy angona amin’ity volana ity';

  @override
  String get noExpensesThisMonth => 'Tsy misy fandaniana amin’ity volana ity';

  @override
  String get noGoals => 'Mbola tsy misy tanjona fitsitsiana';

  @override
  String get noPreviousData => 'tsy misy fampitahana';

  @override
  String noRateFor(String from, String to) {
    return 'Tsy misy tahany $from → $to';
  }

  @override
  String get noRecurring => 'Tsy misy fandaniana miverimberina';

  @override
  String get noResults => 'Tsy misy valiny';

  @override
  String get noTargetDate => 'Tsy misy daty tanjona';

  @override
  String get noTemplates =>
      'Mamorona môdely (vola, sokajy, fanamarihana) mba hampiditra haingana ny fandaniana tsy mitsaha-mitranga.';

  @override
  String get none => 'Tsy misy';

  @override
  String get notABackup => 'Tsy rakitra kopia fiarovana KaraBudget ity';

  @override
  String get notSignedIn => 'Tsy niditra';

  @override
  String get note => 'Fanamarihana';

  @override
  String get noteRecurringHint => 'Fanamarihana (hofa-trano, famandrihana…)';

  @override
  String get nothingToExport => 'Tsy misy hanondrana amin’ity volana ity';

  @override
  String ofTarget(String amount) {
    return 'amin’ny $amount';
  }

  @override
  String get ok => 'OK';

  @override
  String get onlyWithReceipt => 'Misy rosia ihany';

  @override
  String get owes => 'Tokony handoa vola';

  @override
  String get paidBy => 'Nandoa';

  @override
  String paidByName(String name) {
    return 'nandoa: $name';
  }

  @override
  String get passwordHint => 'Tenimiafina (8+ tarehintsoratra)';

  @override
  String get pasteFromClipboard => 'Apetaka avy amin’ny clipboard';

  @override
  String pendingChanges(int n) {
    return '$n fanovana miandry';
  }

  @override
  String perMonthNeeded(String amount) {
    return 'Ilaina tehirizina: $amount isam-bolana';
  }

  @override
  String get personal => 'Manokana';

  @override
  String get pinHint => 'Isa 4 ka hatramin’ny 8';

  @override
  String get pinMismatch => 'Tsy mitovy ny kaody roa';

  @override
  String get pinTooShort => 'Isa 4 farafahakeliny';

  @override
  String get previousMonth => 'Volana teo aloha';

  @override
  String get projectedEndOfMonth => 'Vinavina amin’ny faran’ny volana';

  @override
  String get projectionEarly =>
      'vinavina tsy azo antoka (vao manomboka ny volana)';

  @override
  String get quickEntryBody => 'Tsindrio mba hanampy fandaniana';

  @override
  String get quickEntryHelp =>
      'Fampandrenesana maharitra: tsindrio dia misokatra ny fampidirana fandaniana';

  @override
  String get quickEntryNotification => 'Fampandrenesana fampidirana haingana';

  @override
  String get quickEntryTitle => 'KaraBudget';

  @override
  String get quickTemplates => 'Môdely fampidirana haingana';

  @override
  String get rateFrom => 'Avy amin’ny';

  @override
  String get rateHelp => 'Ohatra: 4800 raha 1 EUR = 4 800 MGA';

  @override
  String get rateTo => 'Ho amin’ny';

  @override
  String rateValue(String from, String to) {
    return 'Sandan’ny 1 $from amin’ny $to';
  }

  @override
  String ratesIntro(String currency) {
    return 'Ampidiro ny tahany mba hiovaovana ho $currency ny fandaniana amin’ny moneta hafa ao amin’ny fitambarana, tetibola ary statistika.';
  }

  @override
  String get readOnlyBanner => 'Famakiana fotsiny ianao amin’ity toerana ity.';

  @override
  String get receipt => 'Rosia';

  @override
  String get recurring => 'Miverimberina';

  @override
  String get recurringExpenses => 'Fandaniana miverimberina';

  @override
  String get recurringReminderTitle => 'Fandaniana miverimberina';

  @override
  String get regenerateCode => 'Hamorona kaody vaovao';

  @override
  String get regenerateConfirm =>
      'Tsy hampiasa intsony ny kaody taloha. Hamorona kaody vaovao ve?';

  @override
  String get removeMember => 'Esory amin’ny toerana';

  @override
  String removeMemberConfirm(String email) {
    return 'Esorina ve i $email amin’ny toerana?';
  }

  @override
  String get removePhoto => 'Esory ny sary';

  @override
  String get repayments => 'Famerenana vola';

  @override
  String get restartToFinish =>
      'Akatony dia sokafy indray ny KaraBudget mba hamitana ny famerenana ny angona.';

  @override
  String get restoreConfirm =>
      'Hosoloana ny angona rehetra eto amin’ity fitaovana ity ny kopia fiarovana. Hotohizana ve?';

  @override
  String get restoreDatabase => 'Hamerina avy amin’ny kopia fiarovana';

  @override
  String get restorePrepared => 'Vonona ny famerenana';

  @override
  String resultsCount(int n) {
    return 'Valiny $n';
  }

  @override
  String get roleEditor => 'Mpanova';

  @override
  String get roleOwner => 'Tompony';

  @override
  String get roleViewer => 'Mpamaky';

  @override
  String get rolloverHelp =>
      'Ampiana amin’ity tetibola ity ny sisa (na ny fihoaran’ny) tamin’ny volana teo aloha';

  @override
  String get rolloverTitle => 'Afindra ny sisa';

  @override
  String get save => 'Tehirizina';

  @override
  String get saveAsTemplate => 'Tehirizina ho môdely';

  @override
  String get savingsGoals => 'Tanjona fitsitsiana';

  @override
  String scanFailed(String error) {
    return 'Tsy nahomby ny skana: $error';
  }

  @override
  String get scanReceipt => 'Skanina ny rosia';

  @override
  String get search => 'Karohy';

  @override
  String get searchHint => 'Karohy fandaniana…';

  @override
  String get searchPrompt => 'Soraty teny na fidio sivana';

  @override
  String get security => 'Fiarovana';

  @override
  String get serverAddress => 'Adiresin’ny serivera';

  @override
  String get settings => 'Fandrindrana';

  @override
  String get sharedOnly =>
      'Azo ampiasaina amin’ny toerana iombonana. Mifidiana iray ao amin’ny fandrindrana.';

  @override
  String get sharesMustEqualTotal =>
      'Tsy maintsy mitovy amin’ny vola ny fitambaran’ny anjara';

  @override
  String get signAbsolute => 'Raiso ho fandaniana daholo';

  @override
  String get signAuto => 'Mitady ho azy';

  @override
  String get signIn => 'Fidirana';

  @override
  String get signInAction => 'Hiditra';

  @override
  String get signMode => 'Dikan’ny famantarana (+/−)';

  @override
  String get signNegative => 'Ny negatifa dia fandaniana';

  @override
  String get signOut => 'Hiala';

  @override
  String get signPositive => 'Ny positifa dia fandaniana';

  @override
  String get signedIn => 'Niditra';

  @override
  String get spaceName => 'Anaran’ny toerana';

  @override
  String get spaceNameHint => 'Mpivady, mpiara-monina…';

  @override
  String get spacesTitle => 'Toerana (tetibola iombonana)';

  @override
  String get splitEqual => 'Mitovy';

  @override
  String get splitExact => 'Araka ny vola';

  @override
  String get splitNeedsPeople => 'Fidio farafahakeliny olona iray';

  @override
  String get splitNone => 'Tsy zarazara';

  @override
  String get statistics => 'Statistika';

  @override
  String get statsShort => 'Stats';

  @override
  String get syncNow => 'Ampifanaraho izao';

  @override
  String get synced => 'Voafanaraka';

  @override
  String get syncing => 'Mampifanaraka…';

  @override
  String get tags => 'Marika';

  @override
  String get tagsHint => 'sakafo, fitaterana';

  @override
  String get targetAmount => 'Vola tanjona';

  @override
  String get templateName => 'Anaran’ny môdely';

  @override
  String get templateSaved => 'Voatahiry ny môdely';

  @override
  String get theme => 'Lohahevitra';

  @override
  String get themeDark => 'Maizina';

  @override
  String get themeLight => 'Mazava';

  @override
  String get themeSystem => 'Araka ny rafitra';

  @override
  String get toDate => 'Hatramin’ny…';

  @override
  String get tooManyAttempts => 'Fanandramana be loatra. Andraso segondra 30.';

  @override
  String get totalDetected => 'Hita ny totalin’ny rosia: jereo azafady';

  @override
  String transferLine(String from, String to, String amount) {
    return '$from → $to: $amount';
  }

  @override
  String unconvertedWarning(int n) {
    return 'Fandaniana $n tsy tafiditra: tsy misy tahan’ny fifanakalozam-bola';
  }

  @override
  String get unlock => 'Sokafy';

  @override
  String get unlockReason => 'Sokafy ny KaraBudget';

  @override
  String get useBiometrics => 'Ampiasaina ny rantsantanana / endrika';

  @override
  String get vsPreviousMonth => 'vs volana teo aloha';

  @override
  String get withdraw => 'Hanala vola';

  @override
  String get wrongPin => 'Diso ny kaody PIN';

  @override
  String get yes => 'Eny';

  @override
  String youLabel(String email) {
    return '$email (ianao)';
  }

  @override
  String get zeroDecimalHint =>
      'Tsy misy faingo ny moneta ity: « 1 500 » dia 1 500.';
}
