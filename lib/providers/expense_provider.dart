import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/notification_service.dart';
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
}
