import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../screens/all_transactions_screen.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final transactions = provider.allTransactions.take(5).toList();
    final currencyFormat = NumberFormat.currency(name: 'INR', locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');

    if (transactions.isEmpty) {
      return const SizedBox.shrink(); 
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllTransactionsScreen()),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final t = transactions[index];
            final catObj = provider.getCategoryByName(t.category);
            final color = t.isIncome ? Colors.green : (catObj != null ? Color(catObj.colorValue) : Colors.grey);
            final title = t.note.isNotEmpty ? t.note : (t.isIncome ? 'Added Funds' : t.category);
            final icon = t.isIncome ? Icons.account_balance_wallet : (catObj != null ? IconData(catObj.iconCodePoint, fontFamily: 'MaterialIcons') : Icons.attach_money);
            
            return Dismissible(
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
            );
          },
        ),
      ],
    );
  }
}
