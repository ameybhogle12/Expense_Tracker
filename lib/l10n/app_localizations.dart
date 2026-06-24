import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ja')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @requireAuth.
  ///
  /// In en, this message translates to:
  /// **'Require Authentication'**
  String get requireAuth;

  /// No description provided for @requireAuthDesc.
  ///
  /// In en, this message translates to:
  /// **'Lock app with Fingerprint or PIN'**
  String get requireAuthDesc;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @currentTheme.
  ///
  /// In en, this message translates to:
  /// **'Current: {mode}'**
  String currentTheme(String mode);

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @currentCurrency.
  ///
  /// In en, this message translates to:
  /// **'Current: {name} ({code} {symbol})'**
  String currentCurrency(String name, String code, String symbol);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @restartTour.
  ///
  /// In en, this message translates to:
  /// **'Restart Guided Tour'**
  String get restartTour;

  /// No description provided for @restartTourDesc.
  ///
  /// In en, this message translates to:
  /// **'Replay the step-by-step feature tour'**
  String get restartTourDesc;

  /// No description provided for @shareFeedback.
  ///
  /// In en, this message translates to:
  /// **'Share Feedback & Suggestions'**
  String get shareFeedback;

  /// No description provided for @shareFeedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience and vote on features'**
  String get shareFeedbackDesc;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backupData;

  /// No description provided for @backupDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Save all your data to a file you can keep safe'**
  String get backupDataDesc;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get restoreData;

  /// No description provided for @restoreDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Replace current data with a backup file'**
  String get restoreDataDesc;

  /// No description provided for @manageWallets.
  ///
  /// In en, this message translates to:
  /// **'Manage Wallets'**
  String get manageWallets;

  /// No description provided for @manageWalletsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure accounts and starting balances'**
  String get manageWalletsDesc;

  /// No description provided for @manageBudgets.
  ///
  /// In en, this message translates to:
  /// **'Manage Budgets'**
  String get manageBudgets;

  /// No description provided for @manageBudgetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Set custom monthly limits for categories'**
  String get manageBudgetsDesc;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @manageCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add or remove custom categories'**
  String get manageCategoriesDesc;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup saved. Keep this file safe to restore later.'**
  String get backupSuccess;

  /// No description provided for @backupCancelled.
  ///
  /// In en, this message translates to:
  /// **'Backup cancelled.'**
  String get backupCancelled;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @restoreDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup?'**
  String get restoreDialogTitle;

  /// No description provided for @restoreDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This replaces ALL current data in the app with the contents of the backup file. This cannot be undone.'**
  String get restoreDialogContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully.'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @tourStarted.
  ///
  /// In en, this message translates to:
  /// **'Guided tour started!'**
  String get tourStarted;

  /// No description provided for @feedbackError.
  ///
  /// In en, this message translates to:
  /// **'Could not open feedback form'**
  String get feedbackError;

  /// No description provided for @myWallets.
  ///
  /// In en, this message translates to:
  /// **'My Wallets'**
  String get myWallets;

  /// No description provided for @noWalletsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No wallets configured'**
  String get noWalletsConfigured;

  /// No description provided for @totalSpentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Total Spent This Month'**
  String get totalSpentThisMonth;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @percentSaved.
  ///
  /// In en, this message translates to:
  /// **'{percent}% saved'**
  String percentSaved(String percent);

  /// No description provided for @overspent.
  ///
  /// In en, this message translates to:
  /// **'Overspent'**
  String get overspent;

  /// No description provided for @upcomingBills.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get upcomingBills;

  /// No description provided for @pendingBills.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingBills(String count);

  /// No description provided for @noUpcomingBills.
  ///
  /// In en, this message translates to:
  /// **'No upcoming bills for the rest of this month. 🎉'**
  String get noUpcomingBills;

  /// No description provided for @emi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get emi;

  /// No description provided for @sub.
  ///
  /// In en, this message translates to:
  /// **'Sub'**
  String get sub;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due on {date}'**
  String dueOn(String date);

  /// No description provided for @totalCommitted.
  ///
  /// In en, this message translates to:
  /// **'Total Committed'**
  String get totalCommitted;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @addedFunds.
  ///
  /// In en, this message translates to:
  /// **'Added Funds'**
  String get addedFunds;

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget: {categoryName}'**
  String editBudget(String categoryName);

  /// No description provided for @monthlyBudgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget Limit'**
  String get monthlyBudgetLimit;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @budgetCleared.
  ///
  /// In en, this message translates to:
  /// **'Budget for {categoryName} cleared.'**
  String budgetCleared(String categoryName);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @budgetSet.
  ///
  /// In en, this message translates to:
  /// **'Budget for {categoryName} set to {amount}.'**
  String budgetSet(String categoryName, String amount);

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @noBudgetsSet.
  ///
  /// In en, this message translates to:
  /// **'No budgets set yet. Tap Manage to set monthly limits for the categories you want to track.'**
  String get noBudgetsSet;

  /// No description provided for @overBudget.
  ///
  /// In en, this message translates to:
  /// **'{amount} over budget'**
  String overBudget(String amount);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String remaining(String amount);

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategory;

  /// No description provided for @noSpendingData.
  ///
  /// In en, this message translates to:
  /// **'No spending data for this month.'**
  String get noSpendingData;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @savingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get savingsGoals;

  /// No description provided for @noSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'No savings goals set yet.\nHead to the Goals tab to create one!'**
  String get noSavingsGoals;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed! 🎉'**
  String get completed;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get onTrack;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @justStarted.
  ///
  /// In en, this message translates to:
  /// **'Just started'**
  String get justStarted;

  /// No description provided for @notEnoughDataForChart.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for trend chart.'**
  String get notEnoughDataForChart;

  /// No description provided for @incomeVsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expenses'**
  String get incomeVsExpenses;

  /// No description provided for @mainBank.
  ///
  /// In en, this message translates to:
  /// **'Main Bank'**
  String get mainBank;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @validAmountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount. (e.g. 2000)'**
  String get validAmountPrompt;

  /// No description provided for @cannotTransferToSameWallet.
  ///
  /// In en, this message translates to:
  /// **'Cannot transfer to the same wallet.'**
  String get cannotTransferToSameWallet;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transferTo.
  ///
  /// In en, this message translates to:
  /// **'To {walletName}'**
  String transferTo(String walletName);

  /// No description provided for @transferFrom.
  ///
  /// In en, this message translates to:
  /// **'From {walletName}'**
  String transferFrom(String walletName);

  /// No description provided for @allowanceIncome.
  ///
  /// In en, this message translates to:
  /// **'Allowance/Income'**
  String get allowanceIncome;

  /// No description provided for @systemError.
  ///
  /// In en, this message translates to:
  /// **'System Error: {error}'**
  String systemError(String error);

  /// No description provided for @editIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get editIncome;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @addFundsToWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Funds to Wallet'**
  String get addFundsToWallet;

  /// No description provided for @transferFunds.
  ///
  /// In en, this message translates to:
  /// **'Transfer Funds'**
  String get transferFunds;

  /// No description provided for @addNewExpense.
  ///
  /// In en, this message translates to:
  /// **'Add New Expense'**
  String get addNewExpense;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @fromWallet.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromWallet;

  /// No description provided for @toWallet.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toWallet;

  /// No description provided for @walletPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Wallet / Payment Method'**
  String get walletPaymentMethod;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get noteOptional;

  /// No description provided for @updateTransaction.
  ///
  /// In en, this message translates to:
  /// **'Update Transaction'**
  String get updateTransaction;

  /// No description provided for @saveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get saveTransaction;

  /// No description provided for @createWallet.
  ///
  /// In en, this message translates to:
  /// **'Create Wallet'**
  String get createWallet;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletName;

  /// No description provided for @walletNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. HDFC Credit Card'**
  String get walletNameHint;

  /// No description provided for @pleaseEnterWalletName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a wallet name'**
  String get pleaseEnterWalletName;

  /// No description provided for @walletNameExists.
  ///
  /// In en, this message translates to:
  /// **'Wallet name already exists'**
  String get walletNameExists;

  /// No description provided for @startingBalanceOptional.
  ///
  /// In en, this message translates to:
  /// **'Starting Balance (Optional)'**
  String get startingBalanceOptional;

  /// No description provided for @pleaseEnterValidBalance.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid starting balance'**
  String get pleaseEnterValidBalance;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @walletCreated.
  ///
  /// In en, this message translates to:
  /// **'Wallet \"{walletName}\" created successfully.'**
  String walletCreated(String walletName);

  /// No description provided for @renameWallet.
  ///
  /// In en, this message translates to:
  /// **'Rename Wallet'**
  String get renameWallet;

  /// No description provided for @walletRenamed.
  ///
  /// In en, this message translates to:
  /// **'Wallet renamed to \"{walletName}\".'**
  String walletRenamed(String walletName);

  /// No description provided for @cannotDelete.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete'**
  String get cannotDelete;

  /// No description provided for @mustKeepOneWallet.
  ///
  /// In en, this message translates to:
  /// **'You must keep at least one active wallet in the app.'**
  String get mustKeepOneWallet;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteWalletMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{walletName}\"?\n\nNote: Transactions previously linked to this wallet will remain in history, but they won\'t affect any active wallet balances.'**
  String confirmDeleteWalletMsg(String walletName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @walletDeleted.
  ///
  /// In en, this message translates to:
  /// **'Wallet \"{walletName}\" deleted.'**
  String walletDeleted(String walletName);

  /// No description provided for @totalNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Total Net Worth'**
  String get totalNetWorth;

  /// No description provided for @balanceOverdrawn.
  ///
  /// In en, this message translates to:
  /// **'Balance Overdrawn'**
  String get balanceOverdrawn;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @addWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWallet;

  /// No description provided for @setBudgetFor.
  ///
  /// In en, this message translates to:
  /// **'Set Budget: {categoryName}'**
  String setBudgetFor(String categoryName);

  /// No description provided for @enterMonthlyBudgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Enter the monthly budget limit for this category. The app will track your spending against this limit.'**
  String get enterMonthlyBudgetLimit;

  /// No description provided for @budgetLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Limit'**
  String get budgetLimitTitle;

  /// No description provided for @budgetLimitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1000'**
  String get budgetLimitHint;

  /// No description provided for @clearBudget.
  ///
  /// In en, this message translates to:
  /// **'Clear Budget'**
  String get clearBudget;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found.'**
  String get noCategoriesFound;

  /// No description provided for @customizedBudgetsCount.
  ///
  /// In en, this message translates to:
  /// **'Customized Budgets: {count}'**
  String customizedBudgetsCount(String count);

  /// No description provided for @tapCategoryToSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Tap any category to set or edit its custom monthly budget limit.'**
  String get tapCategoryToSetBudget;

  /// No description provided for @usingDefaultLimit.
  ///
  /// In en, this message translates to:
  /// **'Using default limit ({amount})'**
  String usingDefaultLimit(String amount);

  /// No description provided for @confirmDeleteCategoryMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{categoryName}\'?'**
  String confirmDeleteCategoryMsg(String categoryName);

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'{categoryName} deleted'**
  String categoryDeleted(String categoryName);

  /// No description provided for @customCategory.
  ///
  /// In en, this message translates to:
  /// **'Custom Category'**
  String get customCategory;

  /// No description provided for @defaultCategory.
  ///
  /// In en, this message translates to:
  /// **'Default Category'**
  String get defaultCategory;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get selectIcon;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @categoryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Category already exists'**
  String get categoryAlreadyExists;

  /// No description provided for @tripSplits.
  ///
  /// In en, this message translates to:
  /// **'Trip Splits'**
  String get tripSplits;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @tapToCreateTrip.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first group trip!'**
  String get tapToCreateTrip;

  /// No description provided for @deleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete Trip?'**
  String get deleteTrip;

  /// No description provided for @confirmDeleteTripMsg.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{tripName}\" and all its expenses.'**
  String confirmDeleteTripMsg(String tripName);

  /// No description provided for @expenseCountString.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expense} other{{count} expenses}}'**
  String expenseCountString(int count);

  /// No description provided for @newTrip.
  ///
  /// In en, this message translates to:
  /// **'New Trip'**
  String get newTrip;

  /// No description provided for @tripNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Name'**
  String get tripNameTitle;

  /// No description provided for @tripNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lonavala Day Trip'**
  String get tripNameHint;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @memberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rahul'**
  String get memberHint;

  /// No description provided for @typeNameToAdd.
  ///
  /// In en, this message translates to:
  /// **'Type a name and press Enter to add'**
  String get typeNameToAdd;

  /// No description provided for @membersAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member added} other{{count} members added}}'**
  String membersAddedCount(int count);

  /// No description provided for @enterTripName.
  ///
  /// In en, this message translates to:
  /// **'Enter a trip name!'**
  String get enterTripName;

  /// No description provided for @addAtLeastTwoMembers.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 members!'**
  String get addAtLeastTwoMembers;

  /// No description provided for @memberAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} is already added!'**
  String memberAlreadyAdded(String name);

  /// No description provided for @settle.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get settle;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @tripMembersAndExpenses.
  ///
  /// In en, this message translates to:
  /// **'{membersCount, plural, =1{1 member} other{{membersCount} members}} · {expensesCount, plural, =1{1 expense} other{{expensesCount} expenses}}'**
  String tripMembersAndExpenses(int membersCount, int expensesCount);

  /// No description provided for @balances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get balances;

  /// No description provided for @noExpensesYetTapPlus.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet.\nTap + to add the first one!'**
  String get noExpensesYetTapPlus;

  /// No description provided for @paidByAndSplit.
  ///
  /// In en, this message translates to:
  /// **'Paid by {payer} · Split {splitCount}'**
  String paidByAndSplit(String payer, int splitCount);

  /// No description provided for @addExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpenseTitle;

  /// No description provided for @editExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpenseTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @expenseDescHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Toll booth'**
  String get expenseDescHint;

  /// No description provided for @paidByLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidByLabel;

  /// No description provided for @splitAmong.
  ///
  /// In en, this message translates to:
  /// **'Split among:'**
  String get splitAmong;

  /// No description provided for @fillInAllFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in all fields properly!'**
  String get fillInAllFields;

  /// No description provided for @selectAtLeastOnePerson.
  ///
  /// In en, this message translates to:
  /// **'Select at least 1 person to split with!'**
  String get selectAtLeastOnePerson;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @memberAlreadyInTrip.
  ///
  /// In en, this message translates to:
  /// **'{name} is already in the trip!'**
  String memberAlreadyInTrip(String name);

  /// No description provided for @tripNeedsTwoMembers.
  ///
  /// In en, this message translates to:
  /// **'A trip needs at least 2 members!'**
  String get tripNeedsTwoMembers;

  /// No description provided for @tapMemberToRemove.
  ///
  /// In en, this message translates to:
  /// **'Tap a member to remove them.'**
  String get tapMemberToRemove;

  /// No description provided for @inCountExpenses.
  ///
  /// In en, this message translates to:
  /// **'In {count, plural, =1{1 expense} other{{count} expenses}}'**
  String inCountExpenses(int count);

  /// No description provided for @notInAnyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Not in any expenses'**
  String get notInAnyExpenses;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {member}?'**
  String removeMemberTitle(String member);

  /// No description provided for @willAffectCountExpenses.
  ///
  /// In en, this message translates to:
  /// **'This will affect {count, plural, =1{1 expense} other{{count} expenses}}.'**
  String willAffectCountExpenses(int count);

  /// No description provided for @removeMemberWarningBody.
  ///
  /// In en, this message translates to:
  /// **'• Expenses they paid for will be deleted\n• They will be removed from all splits\n• Remaining members\' shares will change'**
  String get removeMemberWarningBody;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'{member} removed'**
  String memberRemoved(String member);

  /// No description provided for @memberRemovedWithUpdates.
  ///
  /// In en, this message translates to:
  /// **'{member} removed · {count, plural, =1{1 expense} other{{count} expenses}} updated'**
  String memberRemovedWithUpdates(String member, int count);

  /// No description provided for @analyzingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Analyzing expenses...'**
  String get analyzingExpenses;

  /// No description provided for @calculatingBalances.
  ///
  /// In en, this message translates to:
  /// **'Calculating balances...'**
  String get calculatingBalances;

  /// No description provided for @optimizingTransfers.
  ///
  /// In en, this message translates to:
  /// **'Optimizing transfers...'**
  String get optimizingTransfers;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get done;

  /// No description provided for @calculatingSplits.
  ///
  /// In en, this message translates to:
  /// **'Calculating Splits...'**
  String get calculatingSplits;

  /// No description provided for @runningDebtOptimization.
  ///
  /// In en, this message translates to:
  /// **'Running debt optimization algorithm'**
  String get runningDebtOptimization;

  /// No description provided for @settleUp.
  ///
  /// In en, this message translates to:
  /// **'Settle Up'**
  String get settleUp;

  /// No description provided for @allSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled!'**
  String get allSettled;

  /// No description provided for @noOneOwesAnything.
  ///
  /// In en, this message translates to:
  /// **'No one owes anyone anything.'**
  String get noOneOwesAnything;

  /// No description provided for @allPaymentsDone.
  ///
  /// In en, this message translates to:
  /// **'🎉 All payments done!'**
  String get allPaymentsDone;

  /// No description provided for @paidOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{paidCount} of {totalCount} paid'**
  String paidOfTotal(int paidCount, int totalCount);

  /// No description provided for @everyoneSquaredUp.
  ///
  /// In en, this message translates to:
  /// **'Everyone is squared up!'**
  String get everyoneSquaredUp;

  /// No description provided for @optimizedForMinimumTransfers.
  ///
  /// In en, this message translates to:
  /// **'Optimized for minimum transfers'**
  String get optimizedForMinimumTransfers;

  /// No description provided for @pays.
  ///
  /// In en, this message translates to:
  /// **'pays'**
  String get pays;

  /// No description provided for @receives.
  ///
  /// In en, this message translates to:
  /// **'receives'**
  String get receives;

  /// No description provided for @paidTapToUndo.
  ///
  /// In en, this message translates to:
  /// **'Paid ✓  (tap to undo)'**
  String get paidTapToUndo;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @individualBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Individual Breakdown'**
  String get individualBreakdown;

  /// No description provided for @paidCheck.
  ///
  /// In en, this message translates to:
  /// **'Paid ✓'**
  String get paidCheck;

  /// No description provided for @getsBackAmount.
  ///
  /// In en, this message translates to:
  /// **'Gets back {amount}'**
  String getsBackAmount(String amount);

  /// No description provided for @owesAmount.
  ///
  /// In en, this message translates to:
  /// **'Owes {amount}'**
  String owesAmount(String amount);

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @notInAnySplits.
  ///
  /// In en, this message translates to:
  /// **'Not in any splits'**
  String get notInAnySplits;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @hasPaidPart.
  ///
  /// In en, this message translates to:
  /// **' has paid '**
  String get hasPaidPart;

  /// No description provided for @toPart.
  ///
  /// In en, this message translates to:
  /// **' to '**
  String get toPart;

  /// No description provided for @questionMarkPart.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get questionMarkPart;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @yesPaid.
  ///
  /// In en, this message translates to:
  /// **'Yes, Paid!'**
  String get yesPaid;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deleteSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete subscription?'**
  String get deleteSubscriptionTitle;

  /// No description provided for @deleteSubscriptionWarning.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed. This won\'t delete transactions already logged.'**
  String deleteSubscriptionWarning(String name);

  /// No description provided for @recurringSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Recurring Subscriptions'**
  String get recurringSubscriptions;

  /// No description provided for @noActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No active subscriptions.'**
  String get noActiveSubscriptions;

  /// No description provided for @billedOnDay.
  ///
  /// In en, this message translates to:
  /// **'Billed on day {day} • {method}'**
  String billedOnDay(int day, String method);

  /// No description provided for @newSubscription.
  ///
  /// In en, this message translates to:
  /// **'New Subscription'**
  String get newSubscription;

  /// No description provided for @editSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Subscription'**
  String get editSubscriptionTitle;

  /// No description provided for @addSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get addSubscriptionTitle;

  /// No description provided for @payFrom.
  ///
  /// In en, this message translates to:
  /// **'Pay From'**
  String get payFrom;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of Month'**
  String get dayOfMonth;

  /// No description provided for @subscriptionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Subscription Name (e.g. Netflix)'**
  String get subscriptionNameHint;

  /// No description provided for @updateSubscription.
  ///
  /// In en, this message translates to:
  /// **'Update Subscription'**
  String get updateSubscription;

  /// No description provided for @saveSubscription.
  ///
  /// In en, this message translates to:
  /// **'Save Subscription'**
  String get saveSubscription;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @thisRecurringCharge.
  ///
  /// In en, this message translates to:
  /// **'this recurring charge'**
  String get thisRecurringCharge;

  /// No description provided for @formattedNote.
  ///
  /// In en, this message translates to:
  /// **'\"{note}\"'**
  String formattedNote(String note);

  /// No description provided for @possibleDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get possibleDuplicateTitle;

  /// No description provided for @possibleDuplicateWarning.
  ///
  /// In en, this message translates to:
  /// **'You already have a subscription that matches {label}. Add it anyway?'**
  String possibleDuplicateWarning(String label);

  /// No description provided for @addAnyway.
  ///
  /// In en, this message translates to:
  /// **'Add Anyway'**
  String get addAnyway;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(String error);

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {type}?'**
  String deleteItemTitle(String type);

  /// No description provided for @itemWillBeRemovedPermanently.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed permanently.'**
  String itemWillBeRemovedPermanently(String name);

  /// No description provided for @goalsAndEmis.
  ///
  /// In en, this message translates to:
  /// **'Goals & EMIs'**
  String get goalsAndEmis;

  /// No description provided for @noCostEmisAndDebt.
  ///
  /// In en, this message translates to:
  /// **'No-Cost EMIs & Debt'**
  String get noCostEmisAndDebt;

  /// No description provided for @noGoalsSetTapPlus.
  ///
  /// In en, this message translates to:
  /// **'No goals set yet. Tap + to set one!'**
  String get noGoalsSetTapPlus;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get editGoal;

  /// No description provided for @deleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get deleteGoal;

  /// No description provided for @amountSaved.
  ///
  /// In en, this message translates to:
  /// **'{amount} saved'**
  String amountSaved(String amount);

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target: {amount}'**
  String targetAmount(String amount);

  /// No description provided for @addFunds.
  ///
  /// In en, this message translates to:
  /// **'Add Funds'**
  String get addFunds;

  /// No description provided for @noActiveEmisOrDebts.
  ///
  /// In en, this message translates to:
  /// **'No active EMIs or debts.'**
  String get noActiveEmisOrDebts;

  /// No description provided for @editEmi.
  ///
  /// In en, this message translates to:
  /// **'Edit EMI'**
  String get editEmi;

  /// No description provided for @deleteEmi.
  ///
  /// In en, this message translates to:
  /// **'Delete EMI'**
  String get deleteEmi;

  /// No description provided for @monthlyInstallmentDay.
  ///
  /// In en, this message translates to:
  /// **'{installment} / mo • Day {day}'**
  String monthlyInstallmentDay(String installment, int day);

  /// No description provided for @monthsPaidOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{paid} / {total} months paid'**
  String monthsPaidOfTotal(int paid, int total);

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String totalAmountLabel(String amount);

  /// No description provided for @editSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Savings Goal'**
  String get editSavingsGoal;

  /// No description provided for @newSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'New Savings Goal'**
  String get newSavingsGoal;

  /// No description provided for @goalNameHint.
  ///
  /// In en, this message translates to:
  /// **'Goal Name (e.g. iPhone)'**
  String get goalNameHint;

  /// No description provided for @targetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get targetAmountLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color:'**
  String get colorLabel;

  /// No description provided for @updateGoal.
  ///
  /// In en, this message translates to:
  /// **'Update Goal'**
  String get updateGoal;

  /// No description provided for @createGoal.
  ///
  /// In en, this message translates to:
  /// **'Create Goal'**
  String get createGoal;

  /// No description provided for @editNoCostEmi.
  ///
  /// In en, this message translates to:
  /// **'Edit No-Cost EMI'**
  String get editNoCostEmi;

  /// No description provided for @newNoCostEmi.
  ///
  /// In en, this message translates to:
  /// **'New No-Cost EMI'**
  String get newNoCostEmi;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Item Name (e.g. iPhone)'**
  String get itemNameHint;

  /// No description provided for @totalBillAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Bill Amount'**
  String get totalBillAmount;

  /// No description provided for @totalDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'Total Duration (Months)'**
  String get totalDurationMonths;

  /// No description provided for @paymentDay.
  ///
  /// In en, this message translates to:
  /// **'Payment Day'**
  String get paymentDay;

  /// No description provided for @payFromWallet.
  ///
  /// In en, this message translates to:
  /// **'Pay From Wallet'**
  String get payFromWallet;

  /// No description provided for @updateEmi.
  ///
  /// In en, this message translates to:
  /// **'Update EMI'**
  String get updateEmi;

  /// No description provided for @addEmiTracker.
  ///
  /// In en, this message translates to:
  /// **'Add EMI Tracker'**
  String get addEmiTracker;

  /// No description provided for @depositToGoal.
  ///
  /// In en, this message translates to:
  /// **'Deposit to {goalName}'**
  String depositToGoal(String goalName);

  /// No description provided for @amountToMoveToSavings.
  ///
  /// In en, this message translates to:
  /// **'Amount to move to savings'**
  String get amountToMoveToSavings;

  /// No description provided for @withdrawFromWallet.
  ///
  /// In en, this message translates to:
  /// **'Withdraw From (Wallet)'**
  String get withdrawFromWallet;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get navCharts;

  /// No description provided for @navSubs.
  ///
  /// In en, this message translates to:
  /// **'Subs'**
  String get navSubs;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get navSplit;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @last3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get last3Months;

  /// No description provided for @yearToDate.
  ///
  /// In en, this message translates to:
  /// **'Year to Date'**
  String get yearToDate;

  /// No description provided for @editWallet.
  ///
  /// In en, this message translates to:
  /// **'Edit Wallet'**
  String get editWallet;

  /// No description provided for @adjustBalance.
  ///
  /// In en, this message translates to:
  /// **'Adjust Balance'**
  String get adjustBalance;

  /// No description provided for @adjustBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep current balance'**
  String get adjustBalanceHint;

  /// No description provided for @newBalance.
  ///
  /// In en, this message translates to:
  /// **'New Balance'**
  String get newBalance;

  /// No description provided for @balanceAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Balance adjusted for {walletName}'**
  String balanceAdjusted(String walletName);

  /// No description provided for @deleteWalletWarning.
  ///
  /// In en, this message translates to:
  /// **'This will also delete all {count} transaction(s) linked to this wallet. This cannot be undone.'**
  String deleteWalletWarning(String count);
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
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
