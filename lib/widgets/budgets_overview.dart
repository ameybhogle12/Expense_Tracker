import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../screens/manage_budgets_screen.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';

class BudgetsOverview extends StatelessWidget {
  const BudgetsOverview({super.key});

  void _showEditBudgetBottomSheet(
    BuildContext context,
    ExpenseProvider provider,
    CategoryModel category,
    double currentLimit,
  ) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();
    final isCustomized = provider.getBudgetForCategory(category.name) != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(category.colorValue).withOpacity(0.15),
                      radius: 20,
                      child: Icon(
                        IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                        color: Color(category.colorValue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Budget: ${category.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Budget Limit',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (isCustomized)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.deleteBudget(category.name);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Budget for ${category.name} cleared.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                    if (isCustomized) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final amount = double.parse(controller.text.trim());
                            provider.setBudget(
                              BudgetModel(category: category.name, monthlyLimit: amount),
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Budget for ${category.name} set to ₹${amount.toStringAsFixed(0)}.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budgets',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageBudgetsScreen()),
                );
              },
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeCategories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No budgets configured or expenses recorded yet. Tap Manage to customize!'),
          ),
        ...activeCategories.map((category) {
          final spent = provider.getCategorySpending(category);
          final budgetObj = provider.getBudgetForCategory(category);
          final budget = budgetObj?.monthlyLimit ?? 500.0; // Default budget if unset
          final progress = (spent / budget).clamp(0.0, 1.0);
          final catObj = provider.getCategoryByName(category);
          final color = catObj != null ? Color(catObj.colorValue) : Colors.grey;

          final isOverspent = spent >= budget;
          final isWarning = spent >= budget * 0.8;
          final progressColor = isOverspent 
              ? Colors.red 
              : (isWarning ? Colors.orange : color);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05)),
            ),
            child: InkWell(
              onTap: () {
                if (catObj != null) {
                  _showEditBudgetBottomSheet(context, provider, catObj, budget);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              catObj != null
                                  ? IconData(catObj.iconCodePoint, fontFamily: 'MaterialIcons')
                                  : Icons.category,
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Text(
                          '${currencyFormat.format(spent)} / ${currencyFormat.format(budget)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isOverspent ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: progressColor.withOpacity(0.15),
                      color: progressColor,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isOverspent
                              ? '${currencyFormat.format(spent - budget)} over budget'
                              : '${currencyFormat.format(budget - spent)} remaining',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isOverspent 
                                ? Colors.red 
                                : (isWarning ? Colors.orange : Colors.grey),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
