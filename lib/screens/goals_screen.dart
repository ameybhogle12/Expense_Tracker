import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/goal_model.dart';
import '../models/emi_model.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & EMIs', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(context, 'Savings Goals', Icons.flag, () => _showAddGoalDialog(context)),
            const SizedBox(height: 16),
            const _GoalsList(),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'No-Cost EMIs & Debt', Icons.credit_card, () => _showAddEmiDialog(context)),
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
    final currencyFormat = NumberFormat.currency(name: 'INR', locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (goals.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No goals set yet. Tap + to set one!'),
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
                    Row(
                      children: [
                        Icon(IconData(goal.iconCodePoint, fontFamily: 'MaterialIcons'), color: color),
                        const SizedBox(width: 8),
                        Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      onPressed: () => context.read<ExpenseProvider>().deleteGoal(goal),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                      '${currencyFormat.format(goal.savedAmount)} saved',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      'Target: ${currencyFormat.format(goal.targetAmount)}',
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
                  label: const Text('Add Funds'),
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
    final currencyFormat = NumberFormat.currency(name: 'INR', locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (emis.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No active EMIs or debts.'),
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
                    Text(emi.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      onPressed: () => context.read<ExpenseProvider>().deleteEmi(emi),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${emi.monthlyInstallment.toStringAsFixed(0)} / mo • Day ${emi.paymentDay}',
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
                    Text('${emi.monthsPaid} / ${emi.totalMonths} months paid', style: const TextStyle(fontSize: 12)),
                    Text(
                      'Total: ${currencyFormat.format(emi.totalAmount)}',
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
  const _AddGoalForm();
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
  final List<IconData> _curatedIcons = [
    Icons.shopping_cart, Icons.fastfood, Icons.local_cafe, Icons.flight,
    Icons.directions_car, Icons.train, Icons.hotel, Icons.local_hospital,
    Icons.fitness_center, Icons.sports_esports, Icons.movie, Icons.music_note,
    Icons.pets, Icons.school, Icons.work, Icons.home,
    Icons.build, Icons.auto_awesome, Icons.favorite, Icons.star,
  ];

  late Color _selectedColor;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedColor = _vibrantColors[2]; // Default purple
    _selectedIcon = Icons.star;
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    final name = _nameController.text.trim();
    if (amount == null || amount <= 0 || name.isEmpty) return;

    final goal = GoalModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      targetAmount: amount,
      savedAmount: 0.0,
      colorValue: _selectedColor.value,
      iconCodePoint: _selectedIcon.codePoint,
    );

    context.read<ExpenseProvider>().addGoal(goal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New Savings Goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Goal Name (e.g. iPhone)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Amount', prefixText: '₹ ', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          const Text('Color:'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _vibrantColors.map((c) => GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: CircleAvatar(radius: 12, backgroundColor: c, child: _selectedColor == c ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
            )).toList(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('Create Goal')),
        ],
      ),
    );
  }
}

class _AddEmiForm extends StatefulWidget {
  const _AddEmiForm();
  @override
  State<_AddEmiForm> createState() => _AddEmiFormState();
}

class _AddEmiFormState extends State<_AddEmiForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _monthsController = TextEditingController();
  int _paymentDay = DateTime.now().day;
  String _paymentMethod = 'Main Bank';
  final List<String> _wallets = ['Main Bank', 'UPI Lite', 'Cash'];

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    final months = int.tryParse(_monthsController.text.trim());
    final name = _nameController.text.trim();
    if (amount == null || amount <= 0 || name.isEmpty || months == null || months <= 0) return;

    final monthlyInstallment = amount / months;

    final emi = EmiModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemName: name,
      totalAmount: amount,
      monthlyInstallment: monthlyInstallment,
      totalMonths: months,
      monthsPaid: 0,
      paymentDay: _paymentDay,
      paymentMethod: _paymentMethod,
    );

    context.read<ExpenseProvider>().addEmi(emi);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New No-Cost EMI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Item Name (e.g. iPhone)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Bill Amount', prefixText: '₹ ', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _monthsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Duration (Months)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _paymentDay,
            decoration: const InputDecoration(labelText: 'Payment Day', border: OutlineInputBorder()),
            items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
            onChanged: (val) => setState(() => _paymentDay = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(labelText: 'Pay From Wallet', border: OutlineInputBorder()),
            items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
            onChanged: (val) => setState(() => _paymentMethod = val!),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('Add EMI Tracker')),
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
  String _paymentMethod = 'Main Bank';
  final List<String> _wallets = ['Main Bank', 'UPI Lite', 'Cash'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Deposit to ${widget.goal.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount to move to savings', prefixText: '₹ ', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(labelText: 'Withdraw From (Wallet)', border: OutlineInputBorder()),
            items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
            onChanged: (val) => setState(() => _paymentMethod = val!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text.trim());
            if (amount == null || amount <= 0) return;
            context.read<ExpenseProvider>().depositToGoal(widget.goal, amount, _paymentMethod);
            Navigator.pop(context);
          },
          child: const Text('Deposit'),
        ),
      ],
    );
  }
}
