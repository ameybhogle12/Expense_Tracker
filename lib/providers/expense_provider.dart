import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../models/subscription_model.dart';

class ExpenseProvider with ChangeNotifier, WidgetsBindingObserver {
  static const String expenseBoxName = 'transactions_v2'; 
  static const String budgetBoxName = 'budgets_v2';
  static const String subscriptionBoxName = 'subscriptions_v1';

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
    }
  }

  List<ExpenseModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<SubscriptionModel> _subscriptions = [];

  List<ExpenseModel> get expenses => _transactions.where((t) => !t.isIncome).toList();
  List<ExpenseModel> get incomes => _transactions.where((t) => t.isIncome).toList();
  List<ExpenseModel> get allTransactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  List<SubscriptionModel> get subscriptions => _subscriptions;

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
    
    _transactions = expenseBox.values.toList();
    _budgets = budgetBox.values.toList();
    _subscriptions = subscriptionBox.values.toList();
    
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    
    await _processSubscriptions();
    
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
}
