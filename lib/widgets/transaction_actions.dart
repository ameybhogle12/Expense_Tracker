import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import 'add_expense_form.dart';

/// Shared confirm dialog used before deleting a transaction (tap or swipe).
Future<bool?> confirmDeleteTransaction(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete transaction?'),
      content: const Text('This transaction will be removed and your wallet balance updated.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

/// Bottom sheet offering Edit / Delete for a transaction.
/// Transfers are paired entries, so they can only be deleted, not edited here.
void showTransactionActions(BuildContext context, ExpenseModel tx) {
  final isTransfer = tx.category == 'Transfer';
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isTransfer)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => AddExpenseForm(existing: tx),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              final ok = await confirmDeleteTransaction(context);
              if (ok == true && context.mounted) {
                context.read<ExpenseProvider>().deleteExpense(tx);
              }
            },
          ),
        ],
      ),
    ),
  );
}
