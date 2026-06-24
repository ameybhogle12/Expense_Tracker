import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

enum TransactionType { expense, income, transfer }

class AddExpenseForm extends StatefulWidget {
  /// When provided, the form opens in edit mode for this transaction.
  final ExpenseModel? existing;
  const AddExpenseForm({super.key, this.existing});

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  TransactionType _transactionType = TransactionType.expense;

  late String _paymentMethod;
  late String _transferToWallet;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExpenseProvider>();
    final wallets = provider.wallets.map((w) => w.name).toList();
    if (wallets.isNotEmpty) {
      _paymentMethod = wallets.first;
      if (wallets.length > 1) {
        _transferToWallet = wallets[1];
      } else {
        _transferToWallet = wallets.first;
      }
      _paymentMethod = wallets.first;
      _transferToWallet = wallets.length > 1 ? wallets[1] : wallets.first;
    } else {
      _paymentMethod = 'Main Bank';
      _transferToWallet = 'Cash';
    }

    // Prefill from the existing transaction when editing.
    final existing = widget.existing;
    if (existing != null) {
      _transactionType =
          existing.isIncome ? TransactionType.income : TransactionType.expense;
      _amountController.text = existing.amount.toStringAsFixed(
          existing.amount == existing.amount.roundToDouble() ? 0 : 2);
      _noteController.text = existing.note;
      _selectedDate = existing.date;
      _paymentMethod = existing.paymentMethod;
      if (!existing.isIncome) {
        _selectedCategory = existing.category;
      }
    }
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitData() async {
    try {
      final enteredAmount = double.tryParse(_amountController.text.trim().replaceAll(',', ''));
      if (enteredAmount == null || enteredAmount <= 0) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.validAmountPrompt)),
          );
        }
        return;
      }

      // Edit mode: update the existing transaction in place (expense/income only).
      if (_isEditing) {
        final existing = widget.existing!;
        await context.read<ExpenseProvider>().updateExpense(
              existing,
              amount: enteredAmount,
              category: existing.isIncome
                  ? existing.category
                  : (_selectedCategory ??
                      context.read<ExpenseProvider>().categories.first.name),
              paymentMethod: _paymentMethod,
              date: _selectedDate,
              note: _noteController.text.trim(),
            );
        if (mounted) Navigator.pop(context);
        return;
      }

      if (_transactionType == TransactionType.transfer) {
        if (_paymentMethod == _transferToWallet) {
           if (mounted) {
             final l10n = AppLocalizations.of(context)!;
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cannotTransferToSameWallet)));
           }
           return;
        }

        final l10n = AppLocalizations.of(context)!;
        final idPrefix = DateTime.now().microsecondsSinceEpoch.toString();
        
        final debitTx = ExpenseModel(
          id: '${idPrefix}_out',
          amount: enteredAmount,
          category: l10n.transfer,
          date: _selectedDate,
          note: l10n.transferTo(_transferToWallet),
          paymentMethod: _paymentMethod,
          isIncome: false,
        );

        final creditTx = ExpenseModel(
          id: '${idPrefix}_in',
          amount: enteredAmount,
          category: l10n.transfer,
          date: _selectedDate,
          note: l10n.transferFrom(_paymentMethod),
          paymentMethod: _transferToWallet,
          isIncome: true,
        );

        await context.read<ExpenseProvider>().addExpense(debitTx);
        await context.read<ExpenseProvider>().addExpense(creditTx);

      } else {
        final l10n = AppLocalizations.of(context)!;
        final newTransaction = ExpenseModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          amount: enteredAmount,
          category: _transactionType == TransactionType.income ? l10n.allowanceIncome : (_selectedCategory ?? context.read<ExpenseProvider>().categories.first.name),
          date: _selectedDate,
          note: _noteController.text.trim(),
          paymentMethod: _paymentMethod,
          isIncome: _transactionType == TransactionType.income,
        );
        await context.read<ExpenseProvider>().addExpense(newTransaction);
      }
      
      if (mounted) {
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.systemError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final wallets = context.watch<ExpenseProvider>().wallets.map((w) => w.name).toList();
    final currencyProvider = context.watch<CurrencyProvider>();

    // Resilient fallback logic
    if (wallets.isNotEmpty) {
      if (!wallets.contains(_paymentMethod)) {
        _paymentMethod = wallets.first;
      }
      if (!wallets.contains(_transferToWallet)) {
        _transferToWallet = wallets.length > 1 ? wallets[1] : wallets.first;
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing
                ? (_transactionType == TransactionType.income ? l10n.editIncome : l10n.editExpense)
                : _transactionType == TransactionType.income ? l10n.addFundsToWallet
                : _transactionType == TransactionType.transfer ? l10n.transferFunds
                : l10n.addNewExpense,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Type can't be switched while editing an existing transaction.
            if (!_isEditing) ...[
              SegmentedButton<TransactionType>(
                style: SegmentedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                ),
                segments: [
                  ButtonSegment(value: TransactionType.expense, label: Text(l10n.expense), icon: const Icon(Icons.money_off, size: 16)),
                  ButtonSegment(value: TransactionType.income, label: Text(l10n.income), icon: const Icon(Icons.attach_money, size: 16)),
                  ButtonSegment(value: TransactionType.transfer, label: Text(l10n.transfer), icon: const Icon(Icons.swap_horiz, size: 16)),
                ],
                selected: {_transactionType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() => _transactionType = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_transactionType == TransactionType.transfer) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(labelText: l10n.fromWallet, border: const OutlineInputBorder()),
                      items: wallets.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.arrow_forward),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _transferToWallet,
                      decoration: InputDecoration(labelText: l10n.toWallet, border: const OutlineInputBorder()),
                      items: wallets.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) => setState(() => _transferToWallet = val!),
                    ),
                  ),
                ],
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: InputDecoration(
                  labelText: l10n.walletPaymentMethod,
                  border: const OutlineInputBorder(),
                ),
                items: wallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
            ],
            const SizedBox(height: 16),
            if (_transactionType == TransactionType.expense) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory ?? context.watch<ExpenseProvider>().categories.first.name,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      isExpanded: true,
                      items: context.watch<ExpenseProvider>().categories.map((catObj) {
                        return DropdownMenuItem(
                          value: catObj.name,
                          child: Row(
                            children: [
                              Icon(IconData(catObj.iconCodePoint, fontFamily: 'MaterialIcons'), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  catObj.name, 
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), 
                      ),
                      onPressed: _presentDatePicker,
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(DateFormat('MMM dd, yyy').format(_selectedDate), style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
               OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), 
                ),
                onPressed: _presentDatePicker,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(DateFormat('MMM dd, yyy').format(_selectedDate), style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 16),
            ],
            if (_transactionType != TransactionType.transfer) ...[
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.noteOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
            ] else const SizedBox(height: 8),
            FilledButton(
              onPressed: _submitData,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditing ? l10n.updateTransaction : l10n.saveTransaction, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
