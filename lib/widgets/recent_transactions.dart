import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../screens/all_transactions_screen.dart';
import 'transaction_actions.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final transactions = provider.allTransactions.take(5).toList();
    final currencyProvider = context.watch<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;
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
              l10n.recentTransactions,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllTransactionsScreen()),
                );
              },
              child: Text(l10n.seeAll),
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
            final title = t.note.isNotEmpty ? t.note : (t.isIncome ? l10n.addedFunds : t.category);
            final icon = t.isIncome ? Icons.account_balance_wallet : (catObj != null ? IconData(catObj.iconCodePoint, fontFamily: 'MaterialIcons') : Icons.attach_money);
            
            // Staggered premium slide-and-fade animation
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 80)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                );
              },
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
      ],
    );
  }
}
