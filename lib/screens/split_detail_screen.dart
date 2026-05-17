import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/split_provider.dart';
import '../models/split_trip_model.dart';
import '../models/split_expense_model.dart';
import '../widgets/animations.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.tonalIcon(
              onPressed: expenses.isEmpty
                  ? null
                  : () => _showCalculatingAnimation(context, tripId),
              icon: const Icon(Icons.handshake_outlined, size: 16),
              label: const Text('Settle'),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_member') {
                _showAddMemberDialog(context, trip);
              } else if (value == 'remove_member') {
                _showRemoveMemberDialog(context, trip);
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
              const PopupMenuItem(
                value: 'remove_member',
                child: ListTile(
                  leading: Icon(Icons.person_remove, color: Colors.red),
                  title: Text('Remove Member', style: TextStyle(color: Colors.red)),
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
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.tertiaryContainer
                ],
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
                    final ratio =
                        maxBalance > 0 ? (balance.abs() / maxBalance) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                _getAvatarColor(member, colorScheme),
                            child: Text(
                              member[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
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
                            child: AnimatedBalanceBar(
                              ratio: ratio,
                              isPositive: balance >= 0,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              barColor: balance >= 0
                                  ? Colors.green
                                  : colorScheme.error,
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
                                color: balance >= 0
                                    ? Colors.green
                                    : colorScheme.error,
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
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4)),
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
                          child: Icon(Icons.delete_outline,
                              color: colorScheme.onError),
                        ),
                        onDismissed: (_) => provider.deleteExpense(expense.id),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showAddExpenseDialog(context, trip,
                                existingExpense: expense),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getAvatarColor(
                                    expense.paidBy, colorScheme),
                                child: Text(
                                  expense.paidBy[0].toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              title: Text(
                                expense.description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Paid by ${expense.paidBy} · Split ${expense.splitAmong.length}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.5)),
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
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.4)),
                                  ),
                                ],
                              ),
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

  void _showCalculatingAnimation(BuildContext context, String tripId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return _CalculatingOverlay(
          onDone: () {
            Navigator.pop(context); // close overlay
            Navigator.push(
              context,
              SmoothPageRoute(page: SettlementScreen(tripId: tripId)),
            );
          },
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, SplitTripModel trip,
      {SplitExpenseModel? existingExpense}) {
    final amountController =
        TextEditingController(text: existingExpense?.amount.toString() ?? '');
    final descController =
        TextEditingController(text: existingExpense?.description ?? '');
    String paidBy = existingExpense?.paidBy ?? trip.members.first;
    List<String> splitAmong = existingExpense != null
        ? List<String>.from(existingExpense.splitAmong)
        : List<String>.from(trip.members);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                  existingExpense == null ? 'Add Expense' : 'Edit Expense'),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...trip.members.map((member) {
                      return CheckboxListTile(
                        value: splitAmong.contains(member),
                        title:
                            Text(member, style: const TextStyle(fontSize: 14)),
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
                    final amount =
                        double.tryParse(amountController.text.trim());
                    final desc = descController.text.trim();

                    if (amount == null || amount <= 0 || desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Fill in all fields properly!')),
                      );
                      return;
                    }
                    if (splitAmong.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Select at least 1 person to split with!')),
                      );
                      return;
                    }

                    if (existingExpense == null) {
                      // New Expense
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
                    } else {
                      // Update Existing Expense
                      final updatedExpense = SplitExpenseModel(
                        id: existingExpense.id,
                        tripId: existingExpense.tripId,
                        amount: amount,
                        description: desc,
                        paidBy: paidBy,
                        splitAmong: splitAmong,
                        date: existingExpense.date,
                      );

                      // Using the hive_object save() is better, but since we recreate
                      // the model instance to keep it clean, we'll swap it in the box.
                      final box = Hive.box<SplitExpenseModel>(
                          SplitProvider.expenseBoxName);
                      final key = box.keys.firstWhere(
                          (k) => box.get(k)?.id == existingExpense.id);
                      box.put(key, updatedExpense);
                      context.read<SplitProvider>().loadData();
                    }

                    Navigator.pop(ctx);
                  },
                  child: Text(existingExpense == null ? 'Add' : 'Update'),
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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

  void _showRemoveMemberDialog(BuildContext context, SplitTripModel trip) {
    if (trip.members.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A trip needs at least 2 members!')),
      );
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.read<SplitProvider>();
    final expenses = provider.getExpensesForTrip(trip.id);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tap a member to remove them.',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...trip.members.map((member) {
                // Count how many expenses involve this member
                final involvedCount = expenses.where(
                  (e) => e.paidBy == member || e.splitAmong.contains(member),
                ).length;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getAvatarColor(member, colorScheme),
                    child: Text(
                      member[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  title: Text(member),
                  subtitle: involvedCount > 0
                      ? Text(
                          'In $involvedCount expense${involvedCount == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        )
                      : const Text('Not in any expenses', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.close, color: Colors.red, size: 20),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(ctx);
                    // Show confirmation with impact warning
                    _confirmRemoveMember(context, trip, member, involvedCount);
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _confirmRemoveMember(
    BuildContext context,
    SplitTripModel trip,
    String member,
    int involvedCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $member?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (involvedCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will affect $involvedCount expense${involvedCount == 1 ? '' : 's'}.',
                        style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              '• Expenses they paid for will be deleted\n'
              '• They will be removed from all splits\n'
              '• Remaining members\' shares will change',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final affected = await context.read<SplitProvider>().removeMemberFromTrip(trip.id, member);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$member removed${affected > 0 ? ' · $affected expense${affected == 1 ? '' : 's'} updated' : ''}',
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Remove'),
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

// ─── Calculating Animation Overlay ─────────────────────────────
class _CalculatingOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _CalculatingOverlay({required this.onDone});

  @override
  State<_CalculatingOverlay> createState() => _CalculatingOverlayState();
}

class _CalculatingOverlayState extends State<_CalculatingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _progressController;
  int _stage = 0;

  final _stages = [
    {'icon': Icons.receipt_long, 'text': 'Analyzing expenses...'},
    {'icon': Icons.calculate, 'text': 'Calculating balances...'},
    {'icon': Icons.swap_horiz, 'text': 'Optimizing transfers...'},
    {'icon': Icons.check_circle, 'text': 'Done!'},
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();

    _progressController.addListener(() {
      final newStage = (_progressController.value * _stages.length)
          .floor()
          .clamp(0, _stages.length - 1);
      if (newStage != _stage) {
        setState(() => _stage = newStage);
      }
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) widget.onDone();
        });
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinning icon
            AnimatedBuilder(
              animation: _spinController,
              builder: (_, __) {
                return Transform.rotate(
                  angle: _spinController.value * 6.28 * (_stage < 3 ? 1 : 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _stages[_stage]['icon'] as IconData,
                      key: ValueKey(_stage),
                      size: 64,
                      color: _stage == 3 ? Colors.green.shade300 : colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Stage text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _stages[_stage]['text'] as String,
                key: ValueKey(_stage),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Progress bar
            SizedBox(
              width: 200,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (_, __) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressController.value,
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(
                        _stage == 3 ? Colors.green : colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
