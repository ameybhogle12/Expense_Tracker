import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/subscription_model.dart';
import 'package:intl/intl.dart';

class SubscriptionHistoryScreen extends StatelessWidget {
  final SubscriptionModel subscription;

  const SubscriptionHistoryScreen({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);

    // Try to match transactions based on note or category and exact amount
    // Since auto-logged subscriptions have the same amount and note/category
    final transactions = provider.expenses.where((e) {
      final matchesNote = subscription.note.isNotEmpty && e.note.contains(subscription.note);
      final matchesCategory = e.category == subscription.category;
      // We look for same category and (same note OR same amount)
      return matchesCategory && (matchesNote || e.amount == subscription.amount);
    }).toList();

    transactions.sort((a, b) => b.date.compareTo(a.date));

    final total = transactions.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(subscription.note.isNotEmpty ? subscription.note : subscription.category),
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
                  'Lifetime Cost',
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
                ? const Center(child: Text('No transaction history found.'))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.history, color: theme.colorScheme.onPrimaryContainer),
                        ),
                        title: Text(DateFormat('MMMM dd, yyyy').format(tx.date)),
                        subtitle: Text(tx.paymentMethod),
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
