import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/log_processor.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../models/subscription_model.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../models/emi_model.dart';
import '../models/wallet_model.dart';

class ExpenseProvider with ChangeNotifier, WidgetsBindingObserver {
  static const String expenseBoxName = 'transactions_v2';
  static const String budgetBoxName = 'budgets_v2';
  static const String subscriptionBoxName = 'subscriptions_v1';
  static const String categoryBoxName = 'categories_v1';
  static const String goalBoxName = 'goals_v1';
  static const String emiBoxName = 'emis_v1';
  static const String walletBoxName = 'wallets_v1';

  Timer? _liveTimer;

  ExpenseProvider() {
    WidgetsBinding.instance.addObserver(this);
    _startLiveTimer();
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _syncAutomatedLogs(isBackground: false);
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAutomatedLogs(isBackground: false);
      _startLiveTimer(); // Restart timer on resume
    } else if (state == AppLifecycleState.paused) {
      _liveTimer?.cancel();
    }
  }

  List<ExpenseModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<SubscriptionModel> _subscriptions = [];
  List<CategoryModel> _categories = [];
  List<GoalModel> _goals = [];
  List<EmiModel> _emis = [];
  List<WalletModel> _wallets = [];

  List<ExpenseModel> get expenses =>
      _transactions.where((t) => !t.isIncome).toList();
  List<ExpenseModel> get incomes =>
      _transactions.where((t) => t.isIncome).toList();
  List<ExpenseModel> get allTransactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  List<SubscriptionModel> get subscriptions => _subscriptions;
  List<CategoryModel> get categories => _categories;
  List<GoalModel> get goals => _goals;
  List<EmiModel> get emis => _emis;
  List<WalletModel> get wallets => _wallets;

  double get totalMonthlySpending {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getWalletBalance(String walletName) {
    double income = incomes
        .where((t) => t.paymentMethod == walletName)
        .fold(0.0, (sum, item) => sum + item.amount);
    double expense = expenses
        .where((t) => t.paymentMethod == walletName)
        .fold(0.0, (sum, item) => sum + item.amount);
    return income - expense;
  }

  Future<void> loadData() async {
    final expenseBox = Hive.box<ExpenseModel>(expenseBoxName);
    final budgetBox = Hive.box<BudgetModel>(budgetBoxName);
    final subscriptionBox = Hive.box<SubscriptionModel>(subscriptionBoxName);
    final categoryBox = Hive.box<CategoryModel>(categoryBoxName);
    final goalBox = Hive.box<GoalModel>(goalBoxName);
    final emiBox = Hive.box<EmiModel>(emiBoxName);
    final walletBox = Hive.box<WalletModel>(walletBoxName);

    if (categoryBox.isEmpty) {
      final defaultCategories = [
        CategoryModel(
            id: 'cat_1',
            name: 'Food',
            colorValue: Colors.orange.value,
            iconCodePoint: Icons.restaurant.codePoint,
            isCustom: false),
        CategoryModel(
            id: 'cat_2',
            name: 'Transport',
            colorValue: Colors.blue.value,
            iconCodePoint: Icons.directions_car.codePoint,
            isCustom: false),
        CategoryModel(
            id: 'cat_3',
            name: 'Bills',
            colorValue: Colors.red.value,
            iconCodePoint: Icons.receipt.codePoint,
            isCustom: false),
        CategoryModel(
            id: 'cat_4',
            name: 'Entertainment',
            colorValue: Colors.purple.value,
            iconCodePoint: Icons.movie.codePoint,
            isCustom: false),
        CategoryModel(
            id: 'cat_5',
            name: 'Shopping',
            colorValue: Colors.pink.value,
            iconCodePoint: Icons.shopping_bag.codePoint,
            isCustom: false),
        CategoryModel(
            id: 'cat_6',
            name: 'Health',
            colorValue: Colors.teal.value,
            iconCodePoint: Icons.medical_services.codePoint,
            isCustom: false),
        CategoryModel(
            id: 'cat_7',
            name: 'Other',
            colorValue: Colors.grey.value,
            iconCodePoint: Icons.more_horiz.codePoint,
            isCustom: false),
      ];
      await categoryBox.addAll(defaultCategories);
    }

    if (walletBox.isEmpty) {
      final defaultWallets = [
        WalletModel(id: 'w_1', name: 'Main Bank'),
        WalletModel(id: 'w_2', name: 'UPI Lite'),
        WalletModel(id: 'w_3', name: 'Cash'),
      ];
      await walletBox.addAll(defaultWallets);
    }

    _transactions = expenseBox.values.toList();
    _budgets = budgetBox.values.toList();
    _subscriptions = subscriptionBox.values.toList();
    _categories = categoryBox.values.toList();
    _goals = goalBox.values.toList();
    _emis = emiBox.values.toList();
    _wallets = walletBox.values.toList();

    _transactions.sort((a, b) => b.date.compareTo(a.date));

    await LogProcessor.processAll(isBackground: false);
    // Reload transactions after processing
    _transactions = expenseBox.values.toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  /// Reloads every list straight from Hive. Used after a backup restore,
  /// which rewrites the boxes underneath the provider.
  Future<void> reloadAll() async {
    _transactions = Hive.box<ExpenseModel>(expenseBoxName).values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _budgets = Hive.box<BudgetModel>(budgetBoxName).values.toList();
    _subscriptions =
        Hive.box<SubscriptionModel>(subscriptionBoxName).values.toList();
    _categories = Hive.box<CategoryModel>(categoryBoxName).values.toList();
    _goals = Hive.box<GoalModel>(goalBoxName).values.toList();
    _emis = Hive.box<EmiModel>(emiBoxName).values.toList();
    _wallets = Hive.box<WalletModel>(walletBoxName).values.toList();
    notifyListeners();
  }

  Future<void> _syncAutomatedLogs({bool isBackground = true}) async {
    await LogProcessor.processAll(isBackground: isBackground);

    // Crucial: Reload transactions from the database so the UI actually sees them!
    final expenseBox = Hive.box<ExpenseModel>(expenseBoxName);
    _transactions = expenseBox.values.toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  Future<void> addExpense(ExpenseModel transaction) async {
    final box = Hive.box<ExpenseModel>(expenseBoxName);
    await box.add(transaction);
    _transactions.insert(0, transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> updateExpense(
    ExpenseModel transaction, {
    required double amount,
    required String category,
    required String paymentMethod,
    required DateTime date,
    required String note,
  }) async {
    transaction.amount = amount;
    transaction.category = category;
    transaction.paymentMethod = paymentMethod;
    transaction.date = date;
    transaction.note = note;
    await transaction.save();
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteExpense(ExpenseModel transaction) async {
    await transaction.delete();
    _transactions.remove(transaction);
    notifyListeners();
  }

  Future<void> addSubscription(SubscriptionModel sub) async {
    final box = Hive.box<SubscriptionModel>(subscriptionBoxName);
    await box.add(sub);
    _subscriptions.add(sub);
    await _syncAutomatedLogs(isBackground: false);
    notifyListeners();
  }

  Future<void> updateSubscription(
    SubscriptionModel sub, {
    required double amount,
    required String category,
    required String paymentMethod,
    required String note,
    required int paymentDay,
    required int paymentHour,
    required int paymentMinute,
  }) async {
    sub.amount = amount;
    sub.category = category;
    sub.paymentMethod = paymentMethod;
    sub.note = note;
    sub.paymentDay = paymentDay;
    sub.paymentHour = paymentHour;
    sub.paymentMinute = paymentMinute;
    await sub.save();
    notifyListeners();
  }

  /// Returns true if a subscription looks like a duplicate of the one being
  /// added/edited. Matches on name when a name is given; otherwise falls back
  /// to the recurring-charge signature (amount + category + billing day) so
  /// unnamed duplicates are still caught. Pass [excludeId] when editing.
  bool isLikelyDuplicateSubscription({
    required String note,
    required double amount,
    required String category,
    required int paymentDay,
    String? excludeId,
  }) {
    final name = note.trim().toLowerCase();
    return _subscriptions.any((s) {
      if (s.id == excludeId) return false;
      if (name.isNotEmpty) {
        return s.note.trim().toLowerCase() == name;
      }
      // No name to compare — treat same amount/category/day as a duplicate.
      return s.amount == amount &&
          s.category == category &&
          s.paymentDay == paymentDay;
    });
  }

  Future<void> deleteSubscription(SubscriptionModel sub) async {
    await sub.delete();
    _subscriptions.remove(sub);
    notifyListeners();
  }

  Future<void> setBudget(BudgetModel budget) async {
    final box = Hive.box<BudgetModel>(budgetBoxName);

    int existingIndex =
        _budgets.indexWhere((b) => b.category == budget.category);

    if (existingIndex >= 0) {
      final existingBudget = _budgets[existingIndex];
      existingBudget.monthlyLimit = budget.monthlyLimit;
      await existingBudget.save();
    } else {
      await box.add(budget);
      _budgets.add(budget);
    }
    notifyListeners();
  }

  Future<void> deleteBudget(String category) async {
    int existingIndex = _budgets.indexWhere((b) => b.category == category);
    if (existingIndex >= 0) {
      final budget = _budgets[existingIndex];
      await budget.delete();
      _budgets.removeAt(existingIndex);
      notifyListeners();
    }
  }

  double getCategorySpending(String category) {
    final now = DateTime.now();
    return expenses
        .where((e) =>
            e.category == category &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  BudgetModel? getBudgetForCategory(String category) {
    try {
      return _budgets.firstWhere((b) => b.category == category);
    } catch (_) {
      return null;
    }
  }

  CategoryModel? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    final box = Hive.box<CategoryModel>(categoryBoxName);
    await box.add(category);
    _categories.add(category);
    notifyListeners();
  }

  Future<void> deleteCategory(CategoryModel category) async {
    await category.delete();
    _categories.remove(category);
    notifyListeners();
  }

  Future<void> addGoal(GoalModel goal) async {
    final box = Hive.box<GoalModel>(goalBoxName);
    await box.add(goal);
    _goals.add(goal);
    notifyListeners();
  }

  Future<void> updateGoal(
    GoalModel goal, {
    required String name,
    required double targetAmount,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    goal.name = name;
    goal.targetAmount = targetAmount;
    goal.colorValue = colorValue;
    goal.iconCodePoint = iconCodePoint;
    await goal.save();
    notifyListeners();
  }

  Future<void> deleteGoal(GoalModel goal) async {
    await goal.delete();
    _goals.remove(goal);
    notifyListeners();
  }

  Future<void> depositToGoal(
      GoalModel goal, double amount, String sourceWallet) async {
    final transaction = ExpenseModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      category: 'Other',
      date: DateTime.now(),
      note: 'Deposit to ${goal.name}',
      paymentMethod: sourceWallet,
      isIncome: false,
    );

    await addExpense(transaction);

    goal.savedAmount += amount;
    await goal.save();
    notifyListeners();
  }

  Future<void> addEmi(EmiModel emi) async {
    final box = Hive.box<EmiModel>(emiBoxName);
    await box.add(emi);
    _emis.add(emi);
    await _syncAutomatedLogs(isBackground: false);
    notifyListeners();
  }

  Future<void> updateEmi(
    EmiModel emi, {
    required String itemName,
    required double totalAmount,
    required int totalMonths,
    required int paymentDay,
    required String paymentMethod,
  }) async {
    emi.itemName = itemName;
    emi.totalAmount = totalAmount;
    emi.totalMonths = totalMonths;
    emi.monthlyInstallment = totalMonths > 0 ? totalAmount / totalMonths : totalAmount;
    emi.paymentDay = paymentDay;
    emi.paymentMethod = paymentMethod;
    await emi.save();
    notifyListeners();
  }

  Future<void> deleteEmi(EmiModel emi) async {
    await emi.delete();
    _emis.remove(emi);
    notifyListeners();
  }

  // --- Wallet Operations ---
  Future<void> addWallet(WalletModel wallet,
      {double initialBalance = 0.0}) async {
    final box = Hive.box<WalletModel>(walletBoxName);
    await box.add(wallet);
    _wallets.add(wallet);

    if (initialBalance > 0) {
      final adjustment = ExpenseModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: initialBalance,
        category: 'Other',
        date: DateTime.now(),
        note: 'Initial Balance',
        paymentMethod: wallet.name,
        isIncome: true,
      );
      await addExpense(adjustment);
    } else {
      notifyListeners();
    }
  }

  Future<void> deleteWallet(WalletModel wallet) async {
    // Remove all transactions tied to this wallet
    final expenseBox = Hive.box<ExpenseModel>(expenseBoxName);
    final toDelete = expenseBox.values
        .where((tx) => tx.paymentMethod == wallet.name)
        .toList();
    for (var tx in toDelete) {
      await tx.delete();
    }
    _transactions.removeWhere((tx) => tx.paymentMethod == wallet.name);

    await wallet.delete();
    _wallets.remove(wallet);
    notifyListeners();
  }

  Future<void> updateWallet(WalletModel wallet, String newName) async {
    final oldName = wallet.name;
    wallet.name = newName;
    await wallet.save();

    // Rename paymentMethod in all historical transactions to preserve balance calculations
    final expenseBox = Hive.box<ExpenseModel>(expenseBoxName);
    for (var tx in expenseBox.values) {
      if (tx.paymentMethod == oldName) {
        tx.paymentMethod = newName;
        await tx.save();
      }
    }

    // Reload transactions and sort
    _transactions = expenseBox.values.toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  /// Returns the number of transactions linked to a wallet.
  int getWalletTransactionCount(String walletName) {
    return _transactions.where((tx) => tx.paymentMethod == walletName).length;
  }

  /// Adjusts a wallet's balance to match a desired [newBalance] by inserting
  /// a correction income or expense transaction.
  Future<void> adjustWalletBalance(String walletName, double newBalance) async {
    final currentBalance = getWalletBalance(walletName);
    final diff = newBalance - currentBalance;
    if (diff == 0) return;

    final adjustment = ExpenseModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: diff.abs(),
      category: 'Other',
      date: DateTime.now(),
      note: 'Balance Adjustment',
      paymentMethod: walletName,
      isIncome: diff > 0, // positive diff → income, negative → expense
    );
    await addExpense(adjustment);
  }

  // ─── Dashboard Analytics Helpers ─────────────────────────────

  /// Total income for a specific month.
  double getMonthlyIncome(int year, int month) {
    return incomes
        .where((t) => t.date.year == year && t.date.month == month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total expenses for a specific month.
  double getMonthlyExpense(int year, int month) {
    return expenses
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Spending for a single category in a specific month.
  double getCategorySpendingForMonth(String category, int year, int month) {
    return expenses
        .where((e) =>
            e.category == category &&
            e.date.year == year &&
            e.date.month == month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Returns income & expense totals for the last [numMonths] months
  /// (including the current month), ordered oldest-first.
  List<Map<String, dynamic>> getMonthlyTrend(int numMonths) {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    for (int i = numMonths - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      result.add({
        'year': date.year,
        'month': date.month,
        'income': getMonthlyIncome(date.year, date.month),
        'expense': getMonthlyExpense(date.year, date.month),
      });
    }
    return result;
  }

  /// Upcoming subscription and EMI bills for the rest of the current month,
  /// sorted by payment day.
  List<Map<String, dynamic>> getUpcomingBills() {
    final now = DateTime.now();
    final today = now.day;
    final bills = <Map<String, dynamic>>[];

    for (final sub in _subscriptions) {
      if (sub.paymentDay >= today) {
        bills.add({
          'type': 'subscription',
          'name': sub.note.isNotEmpty ? sub.note : sub.category,
          'amount': sub.amount,
          'dueDay': sub.paymentDay,
          'category': sub.category,
          'paymentMethod': sub.paymentMethod,
        });
      }
    }

    for (final emi in _emis) {
      if (emi.paymentDay >= today && emi.monthsPaid < emi.totalMonths) {
        bills.add({
          'type': 'emi',
          'name': emi.itemName,
          'amount': emi.monthlyInstallment,
          'dueDay': emi.paymentDay,
          'category': 'Bills',
          'paymentMethod': emi.paymentMethod,
        });
      }
    }

    bills.sort((a, b) => (a['dueDay'] as int).compareTo(b['dueDay'] as int));
    return bills;
  }
}
