import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class ManageBudgetsScreen extends StatefulWidget {
  const ManageBudgetsScreen({super.key});

  @override
  State<ManageBudgetsScreen> createState() => _ManageBudgetsScreenState();
}

class _ManageBudgetsScreenState extends State<ManageBudgetsScreen> {

  void _showSetBudgetDialog(BuildContext context, CategoryModel category, double? currentBudget) {
    final controller = TextEditingController(
      text: currentBudget != null ? currentBudget.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();
    final currencyProvider = context.read<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;

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
                l10n.setBudgetFor(category.name),
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
              Text(
                l10n.enterMonthlyBudgetLimit,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                decoration: InputDecoration(
                  labelText: l10n.budgetLimitTitle,
                  prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ',
                  border: const OutlineInputBorder(),
                  hintText: l10n.budgetLimitHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return l10n.pleaseEnterValidNumber;
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
            child: Text(l10n.cancel),
          ),
          if (currentBudget != null)
            TextButton(
              onPressed: () {
                final provider = context.read<ExpenseProvider>();
                provider.deleteBudget(category.name);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.budgetCleared(category.name)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(l10n.clearBudget, style: const TextStyle(color: Colors.red)),
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
                    content: Text(l10n.budgetSet(category.name, currencyProvider.format(amount))),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageBudgets, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;
          final currencyProvider = context.watch<CurrencyProvider>();

          if (categories.isEmpty) {
            return Center(child: Text(l10n.noCategoriesFound));
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
                            l10n.customizedBudgetsCount(customBudgetsCount.toString()),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.tapCategoryToSetBudget,
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
                                ? '${l10n.monthlyBudgetLimit}: ${currencyProvider.format(customBudget)}'
                                : l10n.usingDefaultLimit(currencyProvider.format(500)),
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
                                tooltip: l10n.clearBudget,
                                onPressed: () {
                                  provider.deleteBudget(category.name);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.budgetCleared(category.name)),
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
