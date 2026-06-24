import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/transaction_actions.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<ExpenseProvider>().allTransactions;
    final currencyProvider = context.watch<CurrencyProvider>();
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
                final catObj = context.read<ExpenseProvider>().getCategoryByName(t.category);
                final color = t.isIncome ? Colors.green : (catObj != null ? Color(catObj.colorValue) : Colors.grey);
                final title = t.note.isNotEmpty ? t.note : (t.isIncome ? 'Added Funds' : t.category);
                final icon = t.isIncome ? Icons.account_balance_wallet : (catObj != null ? IconData(catObj.iconCodePoint, fontFamily: 'MaterialIcons') : Icons.attach_money);

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
                    confirmDismiss: (direction) => confirmDeleteTransaction(context),
                    onDismissed: (direction) {
                      context.read<ExpenseProvider>().deleteExpense(t);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => showTransactionActions(context, t),
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${dateFormat.format(t.date)} • ${t.paymentMethod}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${t.isIncome ? '+' : '-'} ${currencyProvider.format(t.amount)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: t.isIncome ? Colors.green : Colors.red),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
