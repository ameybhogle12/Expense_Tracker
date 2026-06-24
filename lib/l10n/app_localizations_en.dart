// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expense Tracker';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get requireAuth => 'Require Authentication';

  @override
  String get requireAuthDesc => 'Lock app with Fingerprint or PIN';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String currentTheme(String mode) {
    return 'Current: $mode';
  }

  @override
  String get currency => 'Currency';

  @override
  String currentCurrency(String name, String code, String symbol) {
    return 'Current: $name ($code $symbol)';
  }

  @override
  String get language => 'Language';

  @override
  String get restartTour => 'Restart Guided Tour';

  @override
  String get restartTourDesc => 'Replay the step-by-step feature tour';

  @override
  String get shareFeedback => 'Share Feedback & Suggestions';

  @override
  String get shareFeedbackDesc => 'Rate your experience and vote on features';

  @override
  String get backupData => 'Backup Data';

  @override
  String get backupDataDesc => 'Save all your data to a file you can keep safe';

  @override
  String get restoreData => 'Restore Data';

  @override
  String get restoreDataDesc => 'Replace current data with a backup file';

  @override
  String get manageWallets => 'Manage Wallets';

  @override
  String get manageWalletsDesc => 'Configure accounts and starting balances';

  @override
  String get manageBudgets => 'Manage Budgets';

  @override
  String get manageBudgetsDesc => 'Set custom monthly limits for categories';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get manageCategoriesDesc => 'Add or remove custom categories';

  @override
  String get backupSuccess =>
      'Backup saved. Keep this file safe to restore later.';

  @override
  String get backupCancelled => 'Backup cancelled.';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get restoreDialogTitle => 'Restore from backup?';

  @override
  String get restoreDialogContent =>
      'This replaces ALL current data in the app with the contents of the backup file. This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get restore => 'Restore';

  @override
  String get restoreSuccess => 'Backup restored successfully.';

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get tourStarted => 'Guided tour started!';

  @override
  String get feedbackError => 'Could not open feedback form';

  @override
  String get myWallets => 'My Wallets';

  @override
  String get noWalletsConfigured => 'No wallets configured';

  @override
  String get totalSpentThisMonth => 'Total Spent This Month';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get savings => 'Savings';

  @override
  String percentSaved(String percent) {
    return '$percent% saved';
  }

  @override
  String get overspent => 'Overspent';

  @override
  String get upcomingBills => 'Upcoming Bills';

  @override
  String pendingBills(String count) {
    return '$count pending';
  }

  @override
  String get noUpcomingBills =>
      'No upcoming bills for the rest of this month. 🎉';

  @override
  String get emi => 'EMI';

  @override
  String get sub => 'Sub';

  @override
  String get dueToday => 'Due today';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String dueOn(String date) {
    return 'Due on $date';
  }

  @override
  String get totalCommitted => 'Total Committed';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get seeAll => 'See All';

  @override
  String get addedFunds => 'Added Funds';

  @override
  String editBudget(String categoryName) {
    return 'Edit Budget: $categoryName';
  }

  @override
  String get monthlyBudgetLimit => 'Monthly Budget Limit';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid positive number';

  @override
  String get clear => 'Clear';

  @override
  String budgetCleared(String categoryName) {
    return 'Budget for $categoryName cleared.';
  }

  @override
  String get save => 'Save';

  @override
  String budgetSet(String categoryName, String amount) {
    return 'Budget for $categoryName set to $amount.';
  }

  @override
  String get budgets => 'Budgets';

  @override
  String get manage => 'Manage';

  @override
  String get noBudgetsSet =>
      'No budgets set yet. Tap Manage to set monthly limits for the categories you want to track.';

  @override
  String overBudget(String amount) {
    return '$amount over budget';
  }

  @override
  String remaining(String amount) {
    return '$amount remaining';
  }

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get noSpendingData => 'No spending data for this month.';

  @override
  String get total => 'Total';

  @override
  String get savingsGoals => 'Savings Goals';

  @override
  String get noSavingsGoals =>
      'No savings goals set yet.\nHead to the Goals tab to create one!';

  @override
  String get overdue => 'Overdue';

  @override
  String get completed => 'Completed! 🎉';

  @override
  String get onTrack => 'On track';

  @override
  String get inProgress => 'In progress';

  @override
  String get justStarted => 'Just started';

  @override
  String get notEnoughDataForChart => 'Not enough data for trend chart.';

  @override
  String get incomeVsExpenses => 'Income vs Expenses';

  @override
  String get mainBank => 'Main Bank';

  @override
  String get cash => 'Cash';

  @override
  String get validAmountPrompt => 'Please enter a valid amount. (e.g. 2000)';

  @override
  String get cannotTransferToSameWallet =>
      'Cannot transfer to the same wallet.';

  @override
  String get transfer => 'Transfer';

  @override
  String transferTo(String walletName) {
    return 'To $walletName';
  }

  @override
  String transferFrom(String walletName) {
    return 'From $walletName';
  }

  @override
  String get allowanceIncome => 'Allowance/Income';

  @override
  String systemError(String error) {
    return 'System Error: $error';
  }

  @override
  String get editIncome => 'Edit Income';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get addFundsToWallet => 'Add Funds to Wallet';

  @override
  String get transferFunds => 'Transfer Funds';

  @override
  String get addNewExpense => 'Add New Expense';

  @override
  String get expense => 'Expense';

  @override
  String get amount => 'Amount';

  @override
  String get fromWallet => 'From';

  @override
  String get toWallet => 'To';

  @override
  String get walletPaymentMethod => 'Wallet / Payment Method';

  @override
  String get category => 'Category';

  @override
  String get noteOptional => 'Note (Optional)';

  @override
  String get updateTransaction => 'Update Transaction';

  @override
  String get saveTransaction => 'Save Transaction';

  @override
  String get createWallet => 'Create Wallet';

  @override
  String get walletName => 'Wallet Name';

  @override
  String get walletNameHint => 'e.g. HDFC Credit Card';

  @override
  String get pleaseEnterWalletName => 'Please enter a wallet name';

  @override
  String get walletNameExists => 'Wallet name already exists';

  @override
  String get startingBalanceOptional => 'Starting Balance (Optional)';

  @override
  String get pleaseEnterValidBalance => 'Please enter a valid starting balance';

  @override
  String get create => 'Create';

  @override
  String walletCreated(String walletName) {
    return 'Wallet \"$walletName\" created successfully.';
  }

  @override
  String get renameWallet => 'Rename Wallet';

  @override
  String walletRenamed(String walletName) {
    return 'Wallet renamed to \"$walletName\".';
  }

  @override
  String get cannotDelete => 'Cannot Delete';

  @override
  String get mustKeepOneWallet =>
      'You must keep at least one active wallet in the app.';

  @override
  String get ok => 'OK';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String confirmDeleteWalletMsg(String walletName) {
    return 'Are you sure you want to delete \"$walletName\"?\n\nNote: Transactions previously linked to this wallet will remain in history, but they won\'t affect any active wallet balances.';
  }

  @override
  String get delete => 'Delete';

  @override
  String walletDeleted(String walletName) {
    return 'Wallet \"$walletName\" deleted.';
  }

  @override
  String get totalNetWorth => 'Total Net Worth';

  @override
  String get balanceOverdrawn => 'Balance Overdrawn';

  @override
  String get availableBalance => 'Available Balance';

  @override
  String get addWallet => 'Add Wallet';

  @override
  String setBudgetFor(String categoryName) {
    return 'Set Budget: $categoryName';
  }

  @override
  String get enterMonthlyBudgetLimit =>
      'Enter the monthly budget limit for this category. The app will track your spending against this limit.';

  @override
  String get budgetLimitTitle => 'Budget Limit';

  @override
  String get budgetLimitHint => 'e.g. 1000';

  @override
  String get clearBudget => 'Clear Budget';

  @override
  String get noCategoriesFound => 'No categories found.';

  @override
  String customizedBudgetsCount(String count) {
    return 'Customized Budgets: $count';
  }

  @override
  String get tapCategoryToSetBudget =>
      'Tap any category to set or edit its custom monthly budget limit.';

  @override
  String usingDefaultLimit(String amount) {
    return 'Using default limit ($amount)';
  }

  @override
  String confirmDeleteCategoryMsg(String categoryName) {
    return 'Are you sure you want to delete \'$categoryName\'?';
  }

  @override
  String categoryDeleted(String categoryName) {
    return '$categoryName deleted';
  }

  @override
  String get customCategory => 'Custom Category';

  @override
  String get defaultCategory => 'Default Category';

  @override
  String get newCategory => 'New Category';

  @override
  String get createCategory => 'Create Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get selectColor => 'Select Color';

  @override
  String get selectIcon => 'Select Icon';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get categoryAlreadyExists => 'Category already exists';

  @override
  String get tripSplits => 'Trip Splits';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get tapToCreateTrip => 'Tap + to create your first group trip!';

  @override
  String get deleteTrip => 'Delete Trip?';

  @override
  String confirmDeleteTripMsg(String tripName) {
    return 'This will permanently delete \"$tripName\" and all its expenses.';
  }

  @override
  String expenseCountString(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String get newTrip => 'New Trip';

  @override
  String get tripNameTitle => 'Trip Name';

  @override
  String get tripNameHint => 'e.g. Lonavala Day Trip';

  @override
  String get addMember => 'Add Member';

  @override
  String get memberHint => 'e.g. Rahul';

  @override
  String get typeNameToAdd => 'Type a name and press Enter to add';

  @override
  String membersAddedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members added',
      one: '1 member added',
    );
    return '$_temp0';
  }

  @override
  String get enterTripName => 'Enter a trip name!';

  @override
  String get addAtLeastTwoMembers => 'Add at least 2 members!';

  @override
  String memberAlreadyAdded(String name) {
    return '$name is already added!';
  }

  @override
  String get settle => 'Settle';

  @override
  String get removeMember => 'Remove Member';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String tripMembersAndExpenses(int membersCount, int expensesCount) {
    String _temp0 = intl.Intl.pluralLogic(
      membersCount,
      locale: localeName,
      other: '$membersCount members',
      one: '1 member',
    );
    String _temp1 = intl.Intl.pluralLogic(
      expensesCount,
      locale: localeName,
      other: '$expensesCount expenses',
      one: '1 expense',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get balances => 'Balances';

  @override
  String get noExpensesYetTapPlus =>
      'No expenses yet.\nTap + to add the first one!';

  @override
  String paidByAndSplit(String payer, int splitCount) {
    return 'Paid by $payer · Split $splitCount';
  }

  @override
  String get addExpenseTitle => 'Add Expense';

  @override
  String get editExpenseTitle => 'Edit Expense';

  @override
  String get description => 'Description';

  @override
  String get expenseDescHint => 'e.g. Toll booth';

  @override
  String get paidByLabel => 'Paid by';

  @override
  String get splitAmong => 'Split among:';

  @override
  String get fillInAllFields => 'Fill in all fields properly!';

  @override
  String get selectAtLeastOnePerson =>
      'Select at least 1 person to split with!';

  @override
  String get add => 'Add';

  @override
  String get update => 'Update';

  @override
  String get nameLabel => 'Name';

  @override
  String memberAlreadyInTrip(String name) {
    return '$name is already in the trip!';
  }

  @override
  String get tripNeedsTwoMembers => 'A trip needs at least 2 members!';

  @override
  String get tapMemberToRemove => 'Tap a member to remove them.';

  @override
  String inCountExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return 'In $_temp0';
  }

  @override
  String get notInAnyExpenses => 'Not in any expenses';

  @override
  String removeMemberTitle(String member) {
    return 'Remove $member?';
  }

  @override
  String willAffectCountExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return 'This will affect $_temp0.';
  }

  @override
  String get removeMemberWarningBody =>
      '• Expenses they paid for will be deleted\n• They will be removed from all splits\n• Remaining members\' shares will change';

  @override
  String get remove => 'Remove';

  @override
  String memberRemoved(String member) {
    return '$member removed';
  }

  @override
  String memberRemovedWithUpdates(String member, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$member removed · $_temp0 updated';
  }

  @override
  String get analyzingExpenses => 'Analyzing expenses...';

  @override
  String get calculatingBalances => 'Calculating balances...';

  @override
  String get optimizingTransfers => 'Optimizing transfers...';

  @override
  String get done => 'Done!';

  @override
  String get calculatingSplits => 'Calculating Splits...';

  @override
  String get runningDebtOptimization => 'Running debt optimization algorithm';

  @override
  String get settleUp => 'Settle Up';

  @override
  String get allSettled => 'All settled!';

  @override
  String get noOneOwesAnything => 'No one owes anyone anything.';

  @override
  String get allPaymentsDone => '🎉 All payments done!';

  @override
  String paidOfTotal(int paidCount, int totalCount) {
    return '$paidCount of $totalCount paid';
  }

  @override
  String get everyoneSquaredUp => 'Everyone is squared up!';

  @override
  String get optimizedForMinimumTransfers => 'Optimized for minimum transfers';

  @override
  String get pays => 'pays';

  @override
  String get receives => 'receives';

  @override
  String get paidTapToUndo => 'Paid ✓  (tap to undo)';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get individualBreakdown => 'Individual Breakdown';

  @override
  String get paidCheck => 'Paid ✓';

  @override
  String getsBackAmount(String amount) {
    return 'Gets back $amount';
  }

  @override
  String owesAmount(String amount) {
    return 'Owes $amount';
  }

  @override
  String get settled => 'Settled';

  @override
  String get notInAnySplits => 'Not in any splits';

  @override
  String get confirmPayment => 'Confirm Payment';

  @override
  String get hasPaidPart => ' has paid ';

  @override
  String get toPart => ' to ';

  @override
  String get questionMarkPart => '?';

  @override
  String get notYet => 'Not yet';

  @override
  String get yesPaid => 'Yes, Paid!';

  @override
  String get edit => 'Edit';

  @override
  String get deleteSubscriptionTitle => 'Delete subscription?';

  @override
  String deleteSubscriptionWarning(String name) {
    return '\"$name\" will be removed. This won\'t delete transactions already logged.';
  }

  @override
  String get recurringSubscriptions => 'Recurring Subscriptions';

  @override
  String get noActiveSubscriptions => 'No active subscriptions.';

  @override
  String billedOnDay(int day, String method) {
    return 'Billed on day $day • $method';
  }

  @override
  String get newSubscription => 'New Subscription';

  @override
  String get editSubscriptionTitle => 'Edit Subscription';

  @override
  String get addSubscriptionTitle => 'Add Subscription';

  @override
  String get payFrom => 'Pay From';

  @override
  String get dayOfMonth => 'Day of Month';

  @override
  String get subscriptionNameHint => 'Subscription Name (e.g. Netflix)';

  @override
  String get updateSubscription => 'Update Subscription';

  @override
  String get saveSubscription => 'Save Subscription';

  @override
  String get enterValidAmount => 'Please enter a valid amount.';

  @override
  String get thisRecurringCharge => 'this recurring charge';

  @override
  String formattedNote(String note) {
    return '\"$note\"';
  }

  @override
  String get possibleDuplicateTitle => 'Possible duplicate';

  @override
  String possibleDuplicateWarning(String label) {
    return 'You already have a subscription that matches $label. Add it anyway?';
  }

  @override
  String get addAnyway => 'Add Anyway';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String deleteItemTitle(String type) {
    return 'Delete $type?';
  }

  @override
  String itemWillBeRemovedPermanently(String name) {
    return '\"$name\" will be removed permanently.';
  }

  @override
  String get goalsAndEmis => 'Goals & EMIs';

  @override
  String get noCostEmisAndDebt => 'No-Cost EMIs & Debt';

  @override
  String get noGoalsSetTapPlus => 'No goals set yet. Tap + to set one!';

  @override
  String get editGoal => 'Edit goal';

  @override
  String get deleteGoal => 'Delete goal';

  @override
  String amountSaved(String amount) {
    return '$amount saved';
  }

  @override
  String targetAmount(String amount) {
    return 'Target: $amount';
  }

  @override
  String get addFunds => 'Add Funds';

  @override
  String get noActiveEmisOrDebts => 'No active EMIs or debts.';

  @override
  String get editEmi => 'Edit EMI';

  @override
  String get deleteEmi => 'Delete EMI';

  @override
  String monthlyInstallmentDay(String installment, int day) {
    return '$installment / mo • Day $day';
  }

  @override
  String monthsPaidOfTotal(int paid, int total) {
    return '$paid / $total months paid';
  }

  @override
  String totalAmountLabel(String amount) {
    return 'Total: $amount';
  }

  @override
  String get editSavingsGoal => 'Edit Savings Goal';

  @override
  String get newSavingsGoal => 'New Savings Goal';

  @override
  String get goalNameHint => 'Goal Name (e.g. iPhone)';

  @override
  String get targetAmountLabel => 'Target Amount';

  @override
  String get colorLabel => 'Color:';

  @override
  String get updateGoal => 'Update Goal';

  @override
  String get createGoal => 'Create Goal';

  @override
  String get editNoCostEmi => 'Edit No-Cost EMI';

  @override
  String get newNoCostEmi => 'New No-Cost EMI';

  @override
  String get itemNameHint => 'Item Name (e.g. iPhone)';

  @override
  String get totalBillAmount => 'Total Bill Amount';

  @override
  String get totalDurationMonths => 'Total Duration (Months)';

  @override
  String get paymentDay => 'Payment Day';

  @override
  String get payFromWallet => 'Pay From Wallet';

  @override
  String get updateEmi => 'Update EMI';

  @override
  String get addEmiTracker => 'Add EMI Tracker';

  @override
  String depositToGoal(String goalName) {
    return 'Deposit to $goalName';
  }

  @override
  String get amountToMoveToSavings => 'Amount to move to savings';

  @override
  String get withdrawFromWallet => 'Withdraw From (Wallet)';

  @override
  String get deposit => 'Deposit';

  @override
  String get navHome => 'Home';

  @override
  String get navCharts => 'Charts';

  @override
  String get navSubs => 'Subs';

  @override
  String get navGoals => 'Goals';

  @override
  String get navSplit => 'Split';

  @override
  String get analytics => 'Analytics';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get last3Months => 'Last 3 Months';

  @override
  String get yearToDate => 'Year to Date';

  @override
  String get editWallet => 'Edit Wallet';

  @override
  String get adjustBalance => 'Adjust Balance';

  @override
  String get adjustBalanceHint => 'Leave empty to keep current balance';

  @override
  String get newBalance => 'New Balance';

  @override
  String balanceAdjusted(String walletName) {
    return 'Balance adjusted for $walletName';
  }

  @override
  String deleteWalletWarning(String count) {
    return 'This will also delete all $count transaction(s) linked to this wallet. This cannot be undone.';
  }
}
