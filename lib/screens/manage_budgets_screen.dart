import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';

class ManageBudgetsScreen extends StatefulWidget {
  const ManageBudgetsScreen({super.key});

  @override
  State<ManageBudgetsScreen> createState() => _ManageBudgetsScreenState();
}

class _ManageBudgetsScreenState extends State<ManageBudgetsScreen> {
  final _currencyFormat = NumberFormat.currency(name: 'INR', locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  void _showSetBudgetDialog(BuildContext context, CategoryModel category, double? currentBudget) {
    final controller = TextEditingController(
      text: currentBudget != null ? currentBudget.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(category.colorValue).withOpacity(0.2),
              radius: 18,
              child: Icon(
                IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: Color(category.colorValue),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Set Budget: ${category.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the monthly budget limit for this category. The app will track your spending against this limit.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                decoration: const InputDecoration(
                  labelText: 'Budget Limit',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 1000',
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (currentBudget != null)
            TextButton(
              onPressed: () {
                final provider = context.read<ExpenseProvider>();
                provider.deleteBudget(category.name);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Budget for ${category.name} cleared.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Clear Budget', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(controller.text.trim());
                final provider = context.read<ExpenseProvider>();
                provider.setBudget(
                  BudgetModel(category: category.name, monthlyLimit: amount),
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Budget for ${category.name} set to ${_currencyFormat.format(amount)}.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Budgets', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;

          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          final customBudgetsCount = provider.budgets.length;

          return Column(
            children: [
              // Premium Info Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customized Budgets: $customBudgetsCount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap any category to set or edit its custom monthly budget limit.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final budgetObj = provider.getBudgetForCategory(category.name);
                    final customBudget = budgetObj?.monthlyLimit;
                    final isCustomized = customBudget != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isCustomized ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCustomized
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                              : Theme.of(context).dividerColor.withOpacity(0.1),
                          width: isCustomized ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _showSetBudgetDialog(context, category, customBudget),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Color(category.colorValue).withOpacity(0.15),
                          radius: 22,
                          child: Icon(
                            IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                            color: Color(category.colorValue),
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            isCustomized
                                ? 'Monthly Limit: ${_currencyFormat.format(customBudget)}'
                                : 'Using default limit (₹500)',
                            style: TextStyle(
                              color: isCustomized
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                              fontWeight: isCustomized ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCustomized)
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                tooltip: 'Clear Budget',
                                onPressed: () {
                                  provider.deleteBudget(category.name);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Budget for ${category.name} cleared.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            const Icon(Icons.edit, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
