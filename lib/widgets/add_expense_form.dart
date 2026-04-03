import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/category_constants.dart';
import '../providers/expense_provider.dart';

enum TransactionType { expense, income, transfer }

class AddExpenseForm extends StatefulWidget {
  const AddExpenseForm({super.key});

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = CategoryConstants.categories.first;
  TransactionType _transactionType = TransactionType.expense;
  
  String _paymentMethod = 'UPI Lite'; 
  String _transferToWallet = 'Cash'; 
  final List<String> _wallets = ['Main Bank', 'UPI Lite', 'Cash'];

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid amount. (e.g. 2000)')),
          );
        }
        return;
      }

      if (_transactionType == TransactionType.transfer) {
        if (_paymentMethod == _transferToWallet) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot transfer to the same wallet.')));
           }
           return;
        }

        final idPrefix = DateTime.now().microsecondsSinceEpoch.toString();
        
        final debitTx = ExpenseModel(
          id: '${idPrefix}_out',
          amount: enteredAmount,
          category: 'Transfer',
          date: _selectedDate,
          note: 'To $_transferToWallet',
          paymentMethod: _paymentMethod,
          isIncome: false,
        );

        final creditTx = ExpenseModel(
          id: '${idPrefix}_in',
          amount: enteredAmount,
          category: 'Transfer',
          date: _selectedDate,
          note: 'From $_paymentMethod',
          paymentMethod: _transferToWallet,
          isIncome: true,
        );

        await context.read<ExpenseProvider>().addExpense(debitTx);
        await context.read<ExpenseProvider>().addExpense(creditTx);

      } else {
        final newTransaction = ExpenseModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          amount: enteredAmount,
          category: _transactionType == TransactionType.income ? 'Allowance/Income' : _selectedCategory,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('System Error: $e'), backgroundColor: Colors.red),
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
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _transactionType == TransactionType.income ? 'Add Funds to Wallet' 
                : _transactionType == TransactionType.transfer ? 'Transfer Funds' 
                : 'Add New Expense',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SegmentedButton<TransactionType>(
              style: SegmentedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 12),
              ),
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.money_off, size: 16)),
                ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.attach_money, size: 16)),
                ButtonSegment(value: TransactionType.transfer, label: Text('Transfer'), icon: Icon(Icons.swap_horiz, size: 16)),
              ],
              selected: {_transactionType},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() => _transactionType = newSelection.first);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_transactionType == TransactionType.transfer) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
                      items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 14)))).toList(),
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
                      decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()),
                      items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) => setState(() => _transferToWallet = val!),
                    ),
                  ),
                ],
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Wallet / Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
            ],
            const SizedBox(height: 16),
            if (_transactionType == TransactionType.expense) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: CategoryConstants.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(CategoryConstants.getIconForCategory(category), size: 16),
                              const SizedBox(width: 8),
                              Text(category, style: const TextStyle(fontSize: 13)),
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
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
            ] else const SizedBox(height: 8),
            FilledButton(
              onPressed: _submitData,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Transaction', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
