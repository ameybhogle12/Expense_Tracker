import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';

/// First-launch sheet that lets the user set starting balances for their
/// wallets, so wallet totals don't start in the negative once they begin
/// logging expenses. Returns when dismissed via "Save" or "Skip".
class OnboardingBalanceSheet extends StatefulWidget {
  const OnboardingBalanceSheet({super.key});

  @override
  State<OnboardingBalanceSheet> createState() => _OnboardingBalanceSheetState();
}

class _OnboardingBalanceSheetState extends State<OnboardingBalanceSheet> {
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  /// Wallets load asynchronously at startup, so create controllers lazily as
  /// wallets appear rather than once in initState (which could see an empty list).
  TextEditingController _controllerFor(String walletName) {
    return _controllers.putIfAbsent(walletName, () => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = context.read<ExpenseProvider>();

    for (final entry in _controllers.entries) {
      final amount = double.tryParse(entry.value.text.trim().replaceAll(',', ''));
      if (amount != null && amount > 0) {
        await provider.addExpense(
          ExpenseModel(
            id: '${DateTime.now().microsecondsSinceEpoch}_${entry.key}',
            amount: amount,
            category: 'Allowance/Income',
            date: DateTime.now(),
            note: 'Initial Balance',
            paymentMethod: entry.key,
            isIncome: true,
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final provider = context.watch<ExpenseProvider>();
    final wallets = provider.wallets;
    final currencyProvider = context.watch<CurrencyProvider>();

    return PopScope(
      // Prevent dismissing with the back button; force a choice.
      canPop: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, keyboardSpace + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.account_balance_wallet,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              const Text(
                'Set your starting balances',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter how much money each wallet currently has. This keeps your '
                'totals accurate so balances don\'t go negative as you log expenses. '
                'You can change these any time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 24),
              ...wallets.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _controllerFor(w.name),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: w.name,
                      prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ',
                      hintText: '0',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save & Continue', style: TextStyle(fontSize: 16)),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
