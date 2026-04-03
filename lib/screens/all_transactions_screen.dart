import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/category_constants.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<ExpenseProvider>().allTransactions;
    final currencyFormat = NumberFormat.currency(name: 'INR', locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions to show.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final t = transactions[index];
                final color = t.isIncome ? Colors.green : CategoryConstants.getColorForCategory(t.category);
                final title = t.note.isNotEmpty ? t.note : (t.isIncome ? 'Added Funds' : t.category);
                final icon = t.isIncome ? Icons.account_balance_wallet : CategoryConstants.getIconForCategory(t.category);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: Key(t.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      context.read<ExpenseProvider>().deleteExpense(t);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${dateFormat.format(t.date)} • ${t.paymentMethod}'),
                      trailing: Text(
                        '${t.isIncome ? '+' : '-'} ${currencyFormat.format(t.amount)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: t.isIncome ? Colors.green : Colors.red),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
