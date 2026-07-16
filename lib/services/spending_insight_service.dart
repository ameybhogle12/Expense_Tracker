import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../providers/expense_provider.dart';
import 'notification_service.dart';

/// Analyzes spending patterns and sends at most ONE insight notification per day.
///
/// Tier 1 (Budget alerts): Fires when users with budgets cross 80% or 100%.
/// Tier 2 (Smart insights): Fires for all users based on spending patterns.
class SpendingInsightService {
  // Currency code-to-symbol map for background isolate (no access to provider)
  static const Map<String, String> _currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': '\$',
    'CAD': '\$',
  };

  /// Main entry point — called from LogProcessor.processAll().
  /// Returns [true] if an insight was generated and notified, [false] otherwise.
  static Future<bool> checkAndNotify({bool force = false}) async {
    try {
      final settingsBox = await Hive.openBox('settings_v1');
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";

      // Only send one insight per day
      if (!force) {
        final lastInsightDate = settingsBox.get('lastInsightSentDate');
        if (lastInsightDate == todayStr) return false;

        // Only send insights after 6 PM for a natural "end of day recap" feel
        if (now.hour < 18) return false;
      }

      final expenseBox = await Hive.openBox<ExpenseModel>(ExpenseProvider.expenseBoxName);
      final budgetBox = await Hive.openBox<BudgetModel>(ExpenseProvider.budgetBoxName);

      // Get currency symbol
      final currencyCode = settingsBox.get('selected_currency_code', defaultValue: 'INR') as String;
      final currencySymbol = _currencySymbols[currencyCode] ?? '₹';

      final allExpenses = expenseBox.values.where((e) => !e.isIncome).toList();
      final budgets = budgetBox.values.toList();

      // Get this month's expenses
      final monthExpenses = allExpenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .toList();

      if (monthExpenses.isEmpty) return false; // No spending data, no insight

      // --- TIER 1: Budget Alerts (highest priority) ---
      final budgetInsight = _checkBudgets(monthExpenses, budgets, currencySymbol);
      if (budgetInsight != null) {
        await NotificationService().showInsightNotification(
          title: budgetInsight.title,
          body: budgetInsight.body,
        );
        if (!force) {
          await settingsBox.put('lastInsightSentDate', todayStr);
        }
        return true;
      }

      // --- TIER 2: Smart Pattern Insights ---
      final patternInsight = _analyzePatterns(allExpenses, monthExpenses, now, currencySymbol);
      if (patternInsight != null) {
        await NotificationService().showInsightNotification(
          title: patternInsight.title,
          body: patternInsight.body,
        );
        if (!force) {
          await settingsBox.put('lastInsightSentDate', todayStr);
        }
        return true;
      }
      return false;
    } catch (e) {
      // Never crash the background processor
      return false;
    }
  }

  /// Tier 1: Check budget thresholds (80% warning, 100% exceeded)
  static _InsightMessage? _checkBudgets(
    List<ExpenseModel> monthExpenses,
    List<BudgetModel> budgets,
    String currencySymbol,
  ) {
    if (budgets.isEmpty) return null;

    // Group monthly spending by category
    final Map<String, double> categorySpending = {};
    for (var expense in monthExpenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    // Check for exceeded budgets first (highest priority), then warnings
    _InsightMessage? exceededInsight;
    _InsightMessage? warningInsight;

    for (var budget in budgets) {
      final spent = categorySpending[budget.category] ?? 0;
      final percentage = (spent / budget.monthlyLimit * 100).round();

      if (percentage >= 100 && exceededInsight == null) {
        final overBy = spent - budget.monthlyLimit;
        exceededInsight = _InsightMessage(
          title: '🚨 Budget Exceeded!',
          body: 'You\'ve spent $currencySymbol${_formatAmount(spent)} on ${budget.category} — $currencySymbol${_formatAmount(overBy)} over your $currencySymbol${_formatAmount(budget.monthlyLimit)} limit.',
        );
      } else if (percentage >= 80 && percentage < 100 && warningInsight == null) {
        warningInsight = _InsightMessage(
          title: '⚠️ Budget Alert',
          body: 'Heads up! You\'ve used $percentage% of your ${budget.category} budget ($currencySymbol${_formatAmount(spent)} of $currencySymbol${_formatAmount(budget.monthlyLimit)}).',
        );
      }
    }

    return exceededInsight ?? warningInsight;
  }

  /// Tier 2: Analyze spending patterns for users without budgets (or no budget alerts)
  static _InsightMessage? _analyzePatterns(
    List<ExpenseModel> allExpenses,
    List<ExpenseModel> monthExpenses,
    DateTime now,
    String currencySymbol,
  ) {
    // --- Check 1: Week-over-week spike ---
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart;

    final thisWeekExpenses = monthExpenses
        .where((e) => e.date.isAfter(thisWeekStart.subtract(const Duration(days: 1))))
        .toList();
    final lastWeekExpenses = allExpenses
        .where((e) =>
            !e.isIncome &&
            e.date.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
            e.date.isBefore(lastWeekEnd))
        .toList();

    final thisWeekTotal = thisWeekExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final lastWeekTotal = lastWeekExpenses.fold(0.0, (sum, e) => sum + e.amount);

    if (lastWeekTotal > 0 && thisWeekTotal > lastWeekTotal * 1.3) {
      final increase = ((thisWeekTotal - lastWeekTotal) / lastWeekTotal * 100).round();
      return _InsightMessage(
        title: '📈 Spending Spike',
        body: 'Your spending this week ($currencySymbol${_formatAmount(thisWeekTotal)}) is $increase% higher than last week. Want to review?',
      );
    }

    // --- Check 2: Top category this week ---
    if (thisWeekExpenses.isNotEmpty) {
      final Map<String, double> weekCategorySpend = {};
      for (var e in thisWeekExpenses) {
        weekCategorySpend[e.category] = (weekCategorySpend[e.category] ?? 0) + e.amount;
      }

      final topCategory = weekCategorySpend.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      // Only show if spending is significant (at least 3 transactions in the category)
      final topCategoryCount = thisWeekExpenses.where((e) => e.category == topCategory.key).length;
      if (topCategoryCount >= 3) {
        return _InsightMessage(
          title: '📊 Weekly Spending Insight',
          body: 'This week you spent $currencySymbol${_formatAmount(topCategory.value)} on ${topCategory.key} — your biggest category. Consider setting a budget!',
        );
      }
    }

    // --- Check 3: Monthly pace warning (only after day 7) ---
    if (now.day >= 7) {
      final monthTotal = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final projectedTotal = (monthTotal / now.day) * daysInMonth;

      // Only warn if projected is significantly higher than actual so far
      if (projectedTotal > monthTotal * 1.5 && monthTotal > 0) {
        return _InsightMessage(
          title: '💡 Monthly Pace',
          body: 'You\'ve spent $currencySymbol${_formatAmount(monthTotal)} in the first ${now.day} days. At this pace, you\'ll spend $currencySymbol${_formatAmount(projectedTotal)} this month.',
        );
      }
    }

    return null;
  }

  /// Format amount nicely (no decimals for whole numbers, max 2 decimals otherwise)
  static String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0').format(amount);
    }
    return NumberFormat('#,##0.00').format(amount);
  }
}

class _InsightMessage {
  final String title;
  final String body;

  _InsightMessage({required this.title, required this.body});
}
