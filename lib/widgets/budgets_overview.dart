import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class BudgetsOverview extends StatelessWidget {
  const BudgetsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currencyFormat = NumberFormat.currency(name: 'INR', locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final activeCategories = provider.categories
        .map((c) => c.name)
        .where((c) => provider.getCategorySpending(c) > 0 || provider.getBudgetForCategory(c) != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budgets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (activeCategories.isEmpty)
          const Text('No expenses recorded yet. Start adding expenses to see your budgets!'),
        ...activeCategories.map((category) {
          final spent = provider.getCategorySpending(category);
          final budget = provider.getBudgetForCategory(category)?.monthlyLimit ?? 500.0; // Default budget if unset
          final progress = (spent / budget).clamp(0.0, 1.0);
          final catObj = provider.getCategoryByName(category);
          final color = catObj != null ? Color(catObj.colorValue) : Colors.grey;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(catObj != null ? IconData(catObj.iconCodePoint, fontFamily: 'MaterialIcons') : Icons.category, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(category, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text('${currencyFormat.format(spent)} / ${currencyFormat.format(budget)}'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.2),
                  color: color,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
