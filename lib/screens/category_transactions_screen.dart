import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/expense_model.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CategoryTransactionsScreen extends StatelessWidget {
  final String categoryName;
  final int year;
  final int month;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryName,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);

    final transactions = provider.expenses.where((e) =>
        e.category == categoryName &&
        e.date.year == year &&
        e.date.month == month).toList();

    transactions.sort((a, b) => b.date.compareTo(a.date));

    final total = transactions.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Spent',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  currencyProvider.format(total),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.receipt_long, color: theme.colorScheme.onPrimaryContainer),
                        ),
                        title: Text(tx.note.isNotEmpty ? tx.note : tx.category, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(tx.date)),
                        trailing: Text(
                          currencyProvider.format(tx.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
