import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/split_provider.dart';
import '../models/split_trip_model.dart';
import '../models/split_expense_model.dart';
import 'settlement_screen.dart';

class SplitDetailScreen extends StatelessWidget {
  final String tripId;
  const SplitDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitProvider>();
    final trip = provider.trips.firstWhere((t) => t.id == tripId);
    final expenses = provider.getExpensesForTrip(tripId);
    final balances = provider.getBalances(tripId);
    final total = provider.getTripTotal(tripId);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: expenses.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettlementScreen(tripId: tripId),
                      ),
                    );
                  },
            icon: const Icon(Icons.handshake_outlined, size: 18),
            label: const Text('Settle'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_member') {
                _showAddMemberDialog(context, trip);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'add_member',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Add Member'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Summary Header ───────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Total Spent',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trip.members.length} members · ${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ─── Balance Bars ─────────────────────────────────
          if (balances.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balances',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...trip.members.map((member) {
                    final balance = balances[member] ?? 0;
                    final maxBalance = balances.values
                        .map((v) => v.abs())
                        .fold(0.0, (a, b) => a > b ? a : b);
                    final ratio = maxBalance > 0 ? (balance.abs() / maxBalance) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: _getAvatarColor(member, colorScheme),
                            child: Text(
                              member[0].toUpperCase(),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: Text(
                              member,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  balance >= 0 ? Colors.green : colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 75,
                            child: Text(
                              '${balance >= 0 ? '+' : ''}₹${balance.toStringAsFixed(0)}',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: balance >= 0 ? Colors.green : colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  const Divider(),
                ],
              ),
            ),

          // ─── Expense List ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Expenses',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Text(
                      'No expenses yet.\nTap + to add the first one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Dismissible(
                        key: ValueKey(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.delete_outline, color: colorScheme.onError),
                        ),
                        onDismissed: (_) => provider.deleteExpense(expense.id),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getAvatarColor(expense.paidBy, colorScheme),
                              child: Text(
                                expense.paidBy[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            title: Text(
                              expense.description,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Paid by ${expense.paidBy} · Split ${expense.splitAmong.length}',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${expense.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM dd').format(expense.date),
                                  style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.4)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context, trip),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, SplitTripModel trip) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String paidBy = trip.members.first;
    List<String> splitAmong = List.from(trip.members);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g. Toll booth',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paidBy,
                      decoration: const InputDecoration(
                        labelText: 'Paid by',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: trip.members
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() => paidBy = val!);
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Split among:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...trip.members.map((member) {
                      return CheckboxListTile(
                        value: splitAmong.contains(member),
                        title: Text(member, style: const TextStyle(fontSize: 14)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              splitAmong.add(member);
                            } else {
                              splitAmong.remove(member);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text.trim());
                    final desc = descController.text.trim();

                    if (amount == null || amount <= 0 || desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fill in all fields properly!')),
                      );
                      return;
                    }
                    if (splitAmong.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select at least 1 person to split with!')),
                      );
                      return;
                    }

                    final expense = SplitExpenseModel(
                      id: 'se_${DateTime.now().microsecondsSinceEpoch}',
                      tripId: tripId,
                      amount: amount,
                      description: desc,
                      paidBy: paidBy,
                      splitAmong: splitAmong,
                      date: DateTime.now(),
                    );

                    context.read<SplitProvider>().addExpense(expense);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, SplitTripModel trip) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              if (trip.members.contains(name)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name is already in the trip!')),
                );
                return;
              }
              context.read<SplitProvider>().addMemberToTrip(trip.id, name);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name, ColorScheme colorScheme) {
    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
