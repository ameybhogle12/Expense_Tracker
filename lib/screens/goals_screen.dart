import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/goal_model.dart';
import '../models/emi_model.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

Future<bool?> _confirmDelete(BuildContext context, String type, String name) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteItemTitle(type)),
      content: Text(l10n.itemWillBeRemovedPermanently(name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalsAndEmis, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(context, l10n.savingsGoals, Icons.flag, () => _showAddGoalDialog(context)),
            const SizedBox(height: 16),
            const _GoalsList(),
            const SizedBox(height: 32),
            _buildSectionHeader(context, l10n.noCostEmisAndDebt, Icons.credit_card, () => _showAddEmiDialog(context)),
            const SizedBox(height: 16),
            const _EmisList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline),
          color: Theme.of(context).colorScheme.primary,
        )
      ],
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _AddGoalForm(),
    );
  }

  void _showAddEmiDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _AddEmiForm(),
    );
  }
}

class _GoalsList extends StatelessWidget {
  const _GoalsList();

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<ExpenseProvider>().goals;
    final currencyProvider = context.watch<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (goals.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(l10n.noGoalsSetTapPlus),
      ));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        final progress = (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
        final color = Color(goal.colorValue);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(IconData(goal.iconCodePoint, fontFamily: 'MaterialIcons'), color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                          tooltip: l10n.editGoal,
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (ctx) => _AddGoalForm(existing: goal),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          tooltip: l10n.deleteGoal,
                          onPressed: () async {
                            final ok = await _confirmDelete(context, 'goal', goal.name);
                            if (ok == true && context.mounted) {
                              context.read<ExpenseProvider>().deleteGoal(goal);
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.2),
                  color: color,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.amountSaved(currencyProvider.format(goal.savedAmount)),
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      l10n.targetAmount(currencyProvider.format(goal.targetAmount)),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(context: context, builder: (ctx) => _AddFundsToGoalDialog(goal: goal));
                  },
                  icon: const Icon(Icons.savings, size: 16),
                  label: Text(l10n.addFunds),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmisList extends StatelessWidget {
  const _EmisList();

  @override
  Widget build(BuildContext context) {
    final emis = context.watch<ExpenseProvider>().emis;
    final currencyProvider = context.watch<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (emis.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(l10n.noActiveEmisOrDebts),
      ));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emis.length,
      itemBuilder: (context, index) {
        final emi = emis[index];
        final progress = (emi.monthsPaid / emi.totalMonths).clamp(0.0, 1.0);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(emi.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                          tooltip: l10n.editEmi,
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (ctx) => _AddEmiForm(existing: emi),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          tooltip: l10n.deleteEmi,
                          onPressed: () async {
                            final ok = await _confirmDelete(context, 'EMI', emi.itemName);
                            if (ok == true && context.mounted) {
                              context.read<ExpenseProvider>().deleteEmi(emi);
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.monthlyInstallmentDay(currencyProvider.format(emi.monthlyInstallment), emi.paymentDay),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.blueGrey.withOpacity(0.2),
                  color: Colors.blueGrey,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.monthsPaidOfTotal(emi.monthsPaid, emi.totalMonths), style: const TextStyle(fontSize: 12)),
                    Text(
                      l10n.totalAmountLabel(currencyProvider.format(emi.totalAmount)),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddGoalForm extends StatefulWidget {
  final GoalModel? existing;
  const _AddGoalForm({this.existing});
  @override
  State<_AddGoalForm> createState() => _AddGoalFormState();
}

class _AddGoalFormState extends State<_AddGoalForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  
  final List<Color> _vibrantColors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.orange, Colors.deepOrange, Colors.brown, Colors.blueGrey,
  ];
  late Color _selectedColor;
  late IconData _selectedIcon;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = existing.targetAmount.toStringAsFixed(
          existing.targetAmount == existing.targetAmount.roundToDouble() ? 0 : 2);
      _selectedColor = Color(existing.colorValue);
      _selectedIcon = IconData(existing.iconCodePoint, fontFamily: 'MaterialIcons');
    } else {
      _selectedColor = _vibrantColors[2]; // Default purple
      _selectedIcon = Icons.star;
    }
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    final name = _nameController.text.trim();
    if (amount == null || amount <= 0 || name.isEmpty) return;

    if (_isEditing) {
      context.read<ExpenseProvider>().updateGoal(
            widget.existing!,
            name: name,
            targetAmount: amount,
            colorValue: _selectedColor.value,
            iconCodePoint: _selectedIcon.codePoint,
          );
    } else {
      final goal = GoalModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        targetAmount: amount,
        savedAmount: 0.0,
        colorValue: _selectedColor.value,
        iconCodePoint: _selectedIcon.codePoint,
      );
      context.read<ExpenseProvider>().addGoal(goal);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final currencyProvider = context.watch<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEditing ? l10n.editSavingsGoal : l10n.newSavingsGoal, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameController, decoration: InputDecoration(labelText: l10n.goalNameHint, border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.targetAmountLabel, prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ', border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          Text(l10n.colorLabel),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _vibrantColors.map((c) => GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: CircleAvatar(radius: 12, backgroundColor: c, child: _selectedColor == c ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
            )).toList(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: Text(_isEditing ? l10n.updateGoal : l10n.createGoal)),
        ],
      ),
    );
  }
}

class _AddEmiForm extends StatefulWidget {
  final EmiModel? existing;
  const _AddEmiForm({this.existing});
  @override
  State<_AddEmiForm> createState() => _AddEmiFormState();
}

class _AddEmiFormState extends State<_AddEmiForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _monthsController = TextEditingController();
  int _paymentDay = DateTime.now().day;
  late String _paymentMethod;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final wallets = context.read<ExpenseProvider>().wallets.map((w) => w.name).toList();
    _paymentMethod = wallets.isNotEmpty ? wallets.first : 'Main Bank';

    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.itemName;
      _amountController.text = existing.totalAmount.toStringAsFixed(
          existing.totalAmount == existing.totalAmount.roundToDouble() ? 0 : 2);
      _monthsController.text = existing.totalMonths.toString();
      _paymentDay = existing.paymentDay;
      _paymentMethod = existing.paymentMethod;
    }
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    final months = int.tryParse(_monthsController.text.trim());
    final name = _nameController.text.trim();
    if (amount == null || amount <= 0 || name.isEmpty || months == null || months <= 0) return;

    if (_isEditing) {
      context.read<ExpenseProvider>().updateEmi(
            widget.existing!,
            itemName: name,
            totalAmount: amount,
            totalMonths: months,
            paymentDay: _paymentDay,
            paymentMethod: _paymentMethod,
          );
    } else {
      final emi = EmiModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        itemName: name,
        totalAmount: amount,
        monthlyInstallment: amount / months,
        totalMonths: months,
        monthsPaid: 0,
        paymentDay: _paymentDay,
        paymentMethod: _paymentMethod,
      );
      context.read<ExpenseProvider>().addEmi(emi);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final currencyProvider = context.watch<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEditing ? l10n.editNoCostEmi : l10n.newNoCostEmi, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameController, decoration: InputDecoration(labelText: l10n.itemNameHint, border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.totalBillAmount, prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ', border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _monthsController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.totalDurationMonths, border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _paymentDay,
            decoration: InputDecoration(labelText: l10n.paymentDay, border: const OutlineInputBorder()),
            items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
            onChanged: (val) => setState(() => _paymentDay = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: InputDecoration(labelText: l10n.payFromWallet, border: const OutlineInputBorder()),
            items: context.watch<ExpenseProvider>().wallets.map((w) => DropdownMenuItem(value: w.name, child: Text(w.name))).toList(),
            onChanged: (val) => setState(() => _paymentMethod = val!),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: Text(_isEditing ? l10n.updateEmi : l10n.addEmiTracker)),
        ],
      ),
    );
  }
}

class _AddFundsToGoalDialog extends StatefulWidget {
  final GoalModel goal;
  const _AddFundsToGoalDialog({required this.goal});
  @override
  State<_AddFundsToGoalDialog> createState() => _AddFundsToGoalDialogState();
}

class _AddFundsToGoalDialogState extends State<_AddFundsToGoalDialog> {
  final _amountController = TextEditingController();
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    final wallets = context.read<ExpenseProvider>().wallets.map((w) => w.name).toList();
    _paymentMethod = wallets.isNotEmpty ? wallets.first : 'Main Bank';
  }

  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.depositToGoal(widget.goal.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.amountToMoveToSavings, prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ', border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: InputDecoration(labelText: l10n.withdrawFromWallet, border: const OutlineInputBorder()),
            items: context.watch<ExpenseProvider>().wallets.map((w) => DropdownMenuItem(value: w.name, child: Text(w.name))).toList(),
            onChanged: (val) => setState(() => _paymentMethod = val!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text.trim());
            if (amount == null || amount <= 0) return;
            context.read<ExpenseProvider>().depositToGoal(widget.goal, amount, _paymentMethod);
            Navigator.pop(context);
          },
          child: Text(l10n.deposit),
        ),
      ],
    );
  }
}
