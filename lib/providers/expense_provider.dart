import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../models/subscription_model.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../models/emi_model.dart';

class ExpenseProvider with ChangeNotifier, WidgetsBindingObserver {
  static const String expenseBoxName = 'transactions_v2'; 
  static const String budgetBoxName = 'budgets_v2';
  static const String subscriptionBoxName = 'subscriptions_v1';
  static const String categoryBoxName = 'categories_v1';
  static const String goalBoxName = 'goals_v1';
  static const String emiBoxName = 'emis_v1';

  ExpenseProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processSubscriptions();
      _processEMIs();
    }
  }

  List<ExpenseModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<SubscriptionModel> _subscriptions = [];
  List<CategoryModel> _categories = [];
  List<GoalModel> _goals = [];
  List<EmiModel> _emis = [];

  List<ExpenseModel> get expenses => _transactions.where((t) => !t.isIncome).toList();
  List<ExpenseModel> get incomes => _transactions.where((t) => t.isIncome).toList();
  List<ExpenseModel> get allTransactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  List<SubscriptionModel> get subscriptions => _subscriptions;
  List<CategoryModel> get categories => _categories;
  List<GoalModel> get goals => _goals;
  List<EmiModel> get emis => _emis;

  double get totalMonthlySpending {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getWalletBalance(String walletName) {
    double income = incomes.where((t) => t.paymentMethod == walletName).fold(0.0, (sum, item) => sum + item.amount);
    double expense = expenses.where((t) => t.paymentMethod == walletName).fold(0.0, (sum, item) => sum + item.amount);
    return income - expense;
  }

  Future<void> loadData() async {
    final expenseBox = Hive.box<ExpenseModel>(expenseBoxName);
    final budgetBox = Hive.box<BudgetModel>(budgetBoxName);
    final subscriptionBox = Hive.box<SubscriptionModel>(subscriptionBoxName);
    final categoryBox = Hive.box<CategoryModel>(categoryBoxName);
    final goalBox = Hive.box<GoalModel>(goalBoxName);
    final emiBox = Hive.box<EmiModel>(emiBoxName);

    if (categoryBox.isEmpty) {
      final defaultCategories = [
        CategoryModel(id: 'cat_1', name: 'Food', colorValue: Colors.orange.value, iconCodePoint: Icons.restaurant.codePoint, isCustom: false),
        CategoryModel(id: 'cat_2', name: 'Transport', colorValue: Colors.blue.value, iconCodePoint: Icons.directions_car.codePoint, isCustom: false),
        CategoryModel(id: 'cat_3', name: 'Bills', colorValue: Colors.red.value, iconCodePoint: Icons.receipt.codePoint, isCustom: false),
        CategoryModel(id: 'cat_4', name: 'Entertainment', colorValue: Colors.purple.value, iconCodePoint: Icons.movie.codePoint, isCustom: false),
        CategoryModel(id: 'cat_5', name: 'Shopping', colorValue: Colors.pink.value, iconCodePoint: Icons.shopping_bag.codePoint, isCustom: false),
        CategoryModel(id: 'cat_6', name: 'Health', colorValue: Colors.teal.value, iconCodePoint: Icons.medical_services.codePoint, isCustom: false),
        CategoryModel(id: 'cat_7', name: 'Other', colorValue: Colors.grey.value, iconCodePoint: Icons.more_horiz.codePoint, isCustom: false),
      ];
      await categoryBox.addAll(defaultCategories);
    }
    
    _transactions = expenseBox.values.toList();
    _budgets = budgetBox.values.toList();
    _subscriptions = subscriptionBox.values.toList();
    _categories = categoryBox.values.toList();
    _goals = goalBox.values.toList();
    _emis = emiBox.values.toList();
    
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    
    await _processSubscriptions();
    await _processEMIs();
    
    notifyListeners();
  }

  Future<void> _processSubscriptions() async {
    final now = DateTime.now();
    bool addedAny = false;
    final box = Hive.box<ExpenseModel>(expenseBoxName);

    for (var sub in _subscriptions) {
      if (now.day >= sub.paymentDay) {
        if (now.day > sub.paymentDay || (now.day == sub.paymentDay && now.hour * 60 + now.minute >= sub.paymentHour * 60 + sub.paymentMinute)) {
          if (sub.lastProcessed == null || sub.lastProcessed!.year != now.year || sub.lastProcessed!.month != now.month) {
            final newTransaction = ExpenseModel(
              id: 'sub_${sub.id}_${now.year}${now.month}',
              amount: sub.amount,
              category: sub.category,
              date: DateTime(now.year, now.month, sub.paymentDay, sub.paymentHour, sub.paymentMinute),
              note: sub.note,
              paymentMethod: sub.paymentMethod,
              isIncome: false,
            );
            
            await box.add(newTransaction);
            _transactions.insert(0, newTransaction);
            addedAny = true;
            
            sub.lastProcessed = now;
            await sub.save();
          }
        }
      }
    }
    
    if (addedAny) {
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  Future<void> _processEMIs() async {
    final now = DateTime.now();
    bool addedAny = false;
    final box = Hive.box<ExpenseModel>(expenseBoxName);

    for (var emi in _emis) {
      if (emi.monthsPaid < emi.totalMonths) {
        if (now.day >= emi.paymentDay) {
          if (emi.lastProcessed == null || emi.lastProcessed!.year != now.year || emi.lastProcessed!.month != now.month) {
            final newTransaction = ExpenseModel(
              id: 'emi_${emi.id}_${now.year}${now.month}',
              amount: emi.monthlyInstallment,
              category: 'Other', 
              date: DateTime(now.year, now.month, emi.paymentDay),
              note: 'EMI: ${emi.itemName} (${emi.monthsPaid + 1}/${emi.totalMonths})',
              paymentMethod: emi.paymentMethod,
              isIncome: false,
            );
            
            await box.add(newTransaction);
            _transactions.insert(0, newTransaction);
            addedAny = true;
            
            emi.monthsPaid += 1;
            emi.lastProcessed = now;
            await emi.save();
          }
        }
      }
    }
    
    if (addedAny) {
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }
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
    await _processSubscriptions(); 
    notifyListeners();
  }

  Future<void> deleteSubscription(SubscriptionModel sub) async {
    await sub.delete();
    _subscriptions.remove(sub);
    notifyListeners();
  }
  
  Future<void> setBudget(BudgetModel budget) async {
    final box = Hive.box<BudgetModel>(budgetBoxName);
    
    int existingIndex = _budgets.indexWhere((b) => b.category == budget.category);
    
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

  double getCategorySpending(String category) {
    final now = DateTime.now();
    return expenses
        .where((e) => e.category == category && e.date.year == now.year && e.date.month == now.month)
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

  Future<void> depositToGoal(GoalModel goal, double amount, String sourceWallet) async {
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
    await _processEMIs();
    notifyListeners();
  }

  Future<void> deleteEmi(EmiModel emi) async {
    await emi.delete();
    _emis.remove(emi);
    notifyListeners();
  }
}
