import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';

class ExpenseProvider with ChangeNotifier {
  static const String expenseBoxName = 'expenses';
  static const String budgetBoxName = 'budgets';

  List<ExpenseModel> _expenses = [];
  List<BudgetModel> _budgets = [];

  List<ExpenseModel> get expenses => _expenses;
  List<BudgetModel> get budgets => _budgets;

  double get totalMonthlySpending {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> loadData() async {
    final expenseBox = Hive.box<ExpenseModel>(expenseBoxName);
    final budgetBox = Hive.box<BudgetModel>(budgetBoxName);
    
    _expenses = expenseBox.values.toList();
    _budgets = budgetBox.values.toList();
    
    // Sort expenses by date descending
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    
    notifyListeners();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final box = Hive.box<ExpenseModel>(expenseBoxName);
    await box.add(expense);
    _expenses.insert(0, expense); // Add to beginning since it's most recent
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }
  
  Future<void> setBudget(BudgetModel budget) async {
    final box = Hive.box<BudgetModel>(budgetBoxName);
    
    // Check if budget for this category already exists
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
    return _expenses
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
