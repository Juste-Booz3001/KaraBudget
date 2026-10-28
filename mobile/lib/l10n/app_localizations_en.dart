// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountAndSync => 'Account and sync';

  @override
  String get activity => 'Activity';

  @override
  String activityCreate(String who, String entity, String label) {
    return '$who added $entity $label';
  }

  @override
  String activityUpdate(String who, String entity, String label) {
    return '$who edited $entity $label';
  }

  @override
  String activityDelete(String who, String entity, String label) {
    return '$who deleted $entity $label';
  }

  @override
  String get addContribution => 'Add a deposit';

  @override
  String get allSettled => 'All settled up: nobody owes anything.';

  @override
  String get alreadyPresent => 'already present';

  @override
  String get amount => 'Amount';

  @override
  String get amountOptional => 'Amount (optional)';

  @override
  String andMore(int n) {
    return '… and $n more rows';
  }

  @override
  String get appLockHelp =>
      'Asks for a PIN when opening the app and after 30 s in the background';

  @override
  String get appLocked => 'KaraBudget is locked';

  @override
  String get appearance => 'Appearance and language';

  @override
  String get atCurrentPace => 'at the current pace';

  @override
  String get attachPhoto => 'Attach a photo';

  @override
  String get autoSyncActive => 'Automatic sync is on';

  @override
  String get averagePerDay => 'Average per day';

  @override
  String get backupCreated => 'Backup created';

  @override
  String get backupDatabase => 'Back up the database';

  @override
  String get backupHelp =>
      'Creates a SQLite file to save or share (receipt photos are not included)';

  @override
  String get balances => 'Balances';

  @override
  String get budgetAlmostReached => 'Budget almost reached';

  @override
  String get budgetAndData => 'Budget and data';

  @override
  String get budgetExceeded => 'Budget exceeded';

  @override
  String budgetOf(String name) {
    return 'Budget “$name”';
  }

  @override
  String get budgets => 'Budgets';

  @override
  String get byCategory => 'By category';

  @override
  String get cancel => 'Cancel';

  @override
  String carryNegative(String amount) {
    return 'Overspend carried over from last month: −$amount';
  }

  @override
  String carryPositive(String amount) {
    return 'Carried over from last month: +$amount';
  }

  @override
  String get categories => 'Categories';

  @override
  String get category => 'Category';

  @override
  String get changePin => 'Change PIN';

  @override
  String get changesVsPrevious => 'Change compared with last month';

  @override
  String get chooseColumns =>
      'Pick at least the date column and the amount (or debit) column.';

  @override
  String get chooseFile => 'Choose a file';

  @override
  String get choosePin => 'Choose a PIN (4 to 8 digits)';

  @override
  String get clearDates => 'Clear dates';

  @override
  String get closeApp => 'Close the app';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get colAmount => 'Amount';

  @override
  String get colCategory => 'Category';

  @override
  String get colDate => 'Date';

  @override
  String get colDebit => 'Debit';

  @override
  String get colNote => 'Description';

  @override
  String get confirmPin => 'Confirm the PIN';

  @override
  String get create => 'Create';

  @override
  String get createAccount => 'Create an account';

  @override
  String get createSharedSpace => 'Create a shared space';

  @override
  String get csvEmpty => 'The CSV is empty or unreadable';

  @override
  String get currency => 'Currency';

  @override
  String get dataStaysOnDevice => 'Your data stays on this device';

  @override
  String get dayFirst => 'Dates are day/month/year';

  @override
  String get defaultCurrency => 'Default currency';

  @override
  String get delete => 'Delete';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Delete “$name”? Expenses are kept, without a category.';
  }

  @override
  String get deleteGoalConfirm => 'Delete this goal and all its deposits?';

  @override
  String get disableAppLock => 'Turn off app lock';

  @override
  String get dueDate => 'Due date';

  @override
  String get edit => 'Edit';

  @override
  String get editCategory => 'Edit category';

  @override
  String get editGoal => 'Edit goal';

  @override
  String get editRate => 'Edit rate';

  @override
  String get editTemplate => 'Edit template';

  @override
  String get email => 'Email';

  @override
  String get enableAppLock => 'Lock the app';

  @override
  String get entBudget => 'budget';

  @override
  String get entCategory => 'category';

  @override
  String get entContribution => 'deposit';

  @override
  String get entExpense => 'expense';

  @override
  String get entGoal => 'goal';

  @override
  String get entRate => 'exchange rate';

  @override
  String get entRecurring => 'recurring expense';

  @override
  String get entSettlement => 'repayment';

  @override
  String get enterCurrentPin => 'Enter the current PIN';

  @override
  String get enterPin => 'PIN';

  @override
  String get everyDay => 'Every day';

  @override
  String get everyMonth => 'Every month';

  @override
  String get everyWeek => 'Every week';

  @override
  String exceededBy(String amount) {
    return 'over by $amount';
  }

  @override
  String get exchangeRates => 'Exchange rates';

  @override
  String get expense => 'Expense';

  @override
  String get expenses => 'Expenses';

  @override
  String get exportCsv => 'Export to CSV (shown month)';

  @override
  String get exportPdf => 'Export to PDF (shown month)';

  @override
  String get filters => 'Filters';

  @override
  String get firstLineIsHeader => 'First row is a header';

  @override
  String get fromDate => 'From…';

  @override
  String goalDue(String date) {
    return 'Due: $date';
  }

  @override
  String get goalName => 'Goal name';

  @override
  String get goalOverdue => 'Target date has passed';

  @override
  String get goalReached => 'Goal reached!';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get importBadAmount => 'unreadable amount';

  @override
  String get importBadDate => 'unreadable date';

  @override
  String get importCsv => 'Import a CSV';

  @override
  String importDone(int n) {
    return '$n expense(s) imported';
  }

  @override
  String importDuplicates(int n) {
    return '$n duplicate(s)';
  }

  @override
  String importErrors(int n) {
    return '$n error(s)';
  }

  @override
  String get importExportBackup => 'Import, export and backup';

  @override
  String get importIncomeSkipped => 'income skipped';

  @override
  String get importIntro =>
      'Import a bank statement or an old tracker (CSV). Rows that already exist are detected and not added twice.';

  @override
  String importLine(int n) {
    return 'Row $n';
  }

  @override
  String importN(int n) {
    return 'Import $n expense(s)';
  }

  @override
  String importNew(int n) {
    return '$n new';
  }

  @override
  String importSkipped(int n) {
    return '$n skipped';
  }

  @override
  String get importZeroSkipped => 'zero amount skipped';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get invalidRate => 'Invalid rate';

  @override
  String get inviteCode => 'Invitation code';

  @override
  String inviteCodeLabel(String code) {
    return 'Invitation code: $code';
  }

  @override
  String get inviteHelp => 'Share it with the people you want to invite';

  @override
  String get isOwed => 'Is owed money';

  @override
  String get joinSpace => 'Join a shared space';

  @override
  String get language => 'Language';

  @override
  String get lastSixMonths => 'Last 6 months';

  @override
  String lastSync(String time) {
    return 'last sync $time';
  }

  @override
  String get leaveConfirm =>
      'Leave this space? You will lose access to its data.';

  @override
  String get leaveSpace => 'Leave the space';

  @override
  String get localModeHint => 'Local mode — sign in to sync';

  @override
  String get lockEnabled => 'App lock is on';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get markRepaid => 'Mark as repaid';

  @override
  String get maxAmount => 'Max amount';

  @override
  String get members => 'Members';

  @override
  String get membersBalancesActivity => 'Members, balances and activity';

  @override
  String get minAmount => 'Min amount';

  @override
  String missingRates(String list, String currency) {
    return 'No rate for $list to $currency: those expenses are left out of totals.';
  }

  @override
  String get monthTotal => 'Month total';

  @override
  String get monthlyAmount => 'Monthly amount';

  @override
  String get name => 'Name';

  @override
  String get newCategory => 'New category';

  @override
  String get newExpense => 'New expense';

  @override
  String get newGoal => 'New goal';

  @override
  String get newRate => 'New rate';

  @override
  String get newRecurring => 'New recurring expense';

  @override
  String get newTemplate => 'New template';

  @override
  String nextDue(String date) {
    return 'Next due: $date';
  }

  @override
  String get no => 'No';

  @override
  String get noActivity => 'No activity yet';

  @override
  String get noAmountDetected => 'Total not found: enter the amount.';

  @override
  String get noBudgetSet => 'No budget set';

  @override
  String get noCategory => 'No category';

  @override
  String get noDataThisMonth => 'No data this month';

  @override
  String get noExpensesThisMonth => 'No expenses this month';

  @override
  String get noGoals => 'No savings goals yet';

  @override
  String get noPreviousData => 'no comparison';

  @override
  String noRateFor(String from, String to) {
    return 'No rate for $from → $to';
  }

  @override
  String get noRecurring => 'No recurring expenses';

  @override
  String get noResults => 'No results';

  @override
  String get noTargetDate => 'No target date';

  @override
  String get noTemplates =>
      'Create templates (amount, category, note) to add frequent expenses in one tap.';

  @override
  String get none => 'None';

  @override
  String get notABackup => 'This file is not a KaraBudget backup';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get note => 'Note';

  @override
  String get noteRecurringHint => 'Note (rent, subscription…)';

  @override
  String get nothingToExport => 'Nothing to export for this month';

  @override
  String ofTarget(String amount) {
    return 'of $amount';
  }

  @override
  String get ok => 'OK';

  @override
  String get onlyWithReceipt => 'Only with a receipt';

  @override
  String get owes => 'Owes money';

  @override
  String get paidBy => 'Paid by';

  @override
  String paidByName(String name) {
    return 'paid by $name';
  }

  @override
  String get passwordHint => 'Password (8+ characters)';

  @override
  String get pasteFromClipboard => 'Paste from clipboard';

  @override
  String pendingChanges(int n) {
    return '$n pending change(s)';
  }

  @override
  String perMonthNeeded(String amount) {
    return 'To save: $amount per month';
  }

  @override
  String get personal => 'Personal';

  @override
  String get pinHint => '4 to 8 digits';

  @override
  String get pinMismatch => 'The PINs do not match';

  @override
  String get pinTooShort => 'At least 4 digits';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get projectedEndOfMonth => 'Projected month end';

  @override
  String get projectionEarly => 'rough estimate (early in the month)';

  @override
  String get quickEntryBody => 'Tap to add an expense';

  @override
  String get quickEntryHelp =>
      'Persistent notification: one tap opens the add-expense screen';

  @override
  String get quickEntryNotification => 'Quick-entry notification';

  @override
  String get quickEntryTitle => 'KaraBudget';

  @override
  String get quickTemplates => 'Quick-entry templates';

  @override
  String get rateFrom => 'From';

  @override
  String get rateHelp => 'Example: 4800 if 1 EUR = 4,800 MGA';

  @override
  String get rateTo => 'To';

  @override
  String rateValue(String from, String to) {
    return 'Value of 1 $from in $to';
  }

  @override
  String ratesIntro(String currency) {
    return 'Enter your rates to convert expenses in other currencies to $currency in totals, budgets and statistics.';
  }

  @override
  String get readOnlyBanner => 'You have read-only access in this space.';

  @override
  String get receipt => 'Receipt';

  @override
  String get recurring => 'Recurring';

  @override
  String get recurringExpenses => 'Recurring expenses';

  @override
  String get recurringReminderTitle => 'Recurring expense';

  @override
  String get regenerateCode => 'Generate a new code';

  @override
  String get regenerateConfirm =>
      'The old code will stop working. Generate a new code?';

  @override
  String get removeMember => 'Remove from space';

  @override
  String removeMemberConfirm(String email) {
    return 'Remove $email from the space?';
  }

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get repayments => 'Repayments';

  @override
  String get restartToFinish =>
      'Close and reopen KaraBudget to finish restoring your data.';

  @override
  String get restoreConfirm =>
      'The backup will replace all data on this device. Continue?';

  @override
  String get restoreDatabase => 'Restore a backup';

  @override
  String get restorePrepared => 'Restore is ready';

  @override
  String resultsCount(int n) {
    return '$n result(s)';
  }

  @override
  String get roleEditor => 'Editor';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get rolloverHelp =>
      'Last month’s leftover (or overspend) is added to this budget';

  @override
  String get rolloverTitle => 'Roll over the balance';

  @override
  String get save => 'Save';

  @override
  String get saveAsTemplate => 'Save as template';

  @override
  String get savingsGoals => 'Savings goals';

  @override
  String scanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String get scanReceipt => 'Scan a receipt';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search expenses…';

  @override
  String get searchPrompt => 'Type a word or pick filters';

  @override
  String get security => 'Security';

  @override
  String get serverAddress => 'Server address';

  @override
  String get settings => 'Settings';

  @override
  String get sharedOnly => 'Available in a shared space. Pick one in Settings.';

  @override
  String get sharesMustEqualTotal => 'The shares must add up to the amount';

  @override
  String get signAbsolute => 'Everything is an expense (absolute value)';

  @override
  String get signAuto => 'Automatic';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInAction => 'Sign in';

  @override
  String get signMode => 'Amount sign';

  @override
  String get signNegative => 'Negatives are expenses';

  @override
  String get signOut => 'Sign out';

  @override
  String get signPositive => 'Positives are expenses';

  @override
  String get signedIn => 'Signed in';

  @override
  String get spaceName => 'Space name';

  @override
  String get spaceNameHint => 'Couple, flatmates…';

  @override
  String get spacesTitle => 'Spaces (shared budget)';

  @override
  String get splitEqual => 'Equal';

  @override
  String get splitExact => 'Exact';

  @override
  String get splitNeedsPeople => 'Pick at least one person';

  @override
  String get splitNone => 'Not shared';

  @override
  String get statistics => 'Statistics';

  @override
  String get statsShort => 'Stats';

  @override
  String get syncNow => 'Sync now';

  @override
  String get synced => 'Synced';

  @override
  String get syncing => 'Syncing…';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'groceries, dining';

  @override
  String get targetAmount => 'Target amount';

  @override
  String get templateName => 'Template name';

  @override
  String get templateSaved => 'Template saved';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get toDate => 'To…';

  @override
  String get tooManyAttempts => 'Too many attempts. Wait 30 seconds.';

  @override
  String get totalDetected => 'Total found on the receipt: please check it';

  @override
  String transferLine(String from, String to, String amount) {
    return '$from → $to: $amount';
  }

  @override
  String unconvertedWarning(int n) {
    return '$n expense(s) left out: missing exchange rate';
  }

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockReason => 'Unlock KaraBudget';

  @override
  String get useBiometrics => 'Use fingerprint / face';

  @override
  String get vsPreviousMonth => 'vs last month';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get yes => 'Yes';

  @override
  String youLabel(String email) {
    return '$email (you)';
  }

  @override
  String get zeroDecimalHint =>
      'This currency has no decimals: “1,500” means 1500.';
}
