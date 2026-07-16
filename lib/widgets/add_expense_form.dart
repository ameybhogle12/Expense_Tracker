import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
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
  final _categoryDropdownKey = GlobalKey<FormFieldState<String>>();

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

  void _showQuickAddCategoryDialog() {
    final nameController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    final List<Color> vibrantColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
    ];

    final List<IconData> curatedIcons = [
      Icons.shopping_cart,
      Icons.fastfood,
      Icons.local_cafe,
      Icons.flight,
      Icons.directions_car,
      Icons.train,
      Icons.hotel,
      Icons.local_hospital,
      Icons.fitness_center,
      Icons.sports_esports,
      Icons.movie,
      Icons.music_note,
      Icons.pets,
      Icons.school,
      Icons.work,
      Icons.home,
      Icons.build,
      Icons.auto_awesome,
      Icons.favorite,
      Icons.star,
    ];

    Color selectedColor = vibrantColors[0];
    IconData selectedIcon = curatedIcons[0];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.createCategory),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.categoryName,
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.selectColor,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: vibrantColors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedColor = color),
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: 16,
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.selectIcon,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: curatedIcons.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isSelected
                                      ? selectedColor
                                      : Colors.grey.shade300),
                            ),
                            child: Icon(icon,
                                color:
                                    isSelected ? selectedColor : Colors.grey),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final provider = context.read<ExpenseProvider>();
                    final prevVal = _selectedCategory ??
                        (provider.categories.isNotEmpty
                            ? provider.categories.first.name
                            : null);
                    _categoryDropdownKey.currentState?.didChange(prevVal);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.pleaseEnterName)));
                      return;
                    }

                    final provider = context.read<ExpenseProvider>();
                    if (provider.getCategoryByName(name) != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.categoryAlreadyExists)));
                      return;
                    }

                    final newCategory = CategoryModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      colorValue: selectedColor.value,
                      iconCodePoint: selectedIcon.codePoint,
                      isCustom: true,
                    );

                    // Pop dialog first to avoid route conflicts during rebuild
                    Navigator.of(dialogContext).pop();

                    // Defer all state changes until the dialog route is fully dismissed
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedCategory = name;
                      });
                      provider.addCategory(newCategory);
                      _categoryDropdownKey.currentState?.didChange(name);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.categoryAddedToast(name)),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    });
                  },
                  child: Text(l10n.create),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitData() async {
    try {
      final enteredAmount =
          double.tryParse(_amountController.text.trim().replaceAll(',', ''));
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
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.cannotTransferToSameWallet)));
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
          category: _transactionType == TransactionType.income
              ? l10n.allowanceIncome
              : (_selectedCategory ??
                  context.read<ExpenseProvider>().categories.first.name),
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
          SnackBar(
              content: Text(l10n.systemError(e.toString())),
              backgroundColor: Colors.red),
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
    final wallets =
        context.watch<ExpenseProvider>().wallets.map((w) => w.name).toList();
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
                  ? (_transactionType == TransactionType.income
                      ? l10n.editIncome
                      : l10n.editExpense)
                  : _transactionType == TransactionType.income
                      ? l10n.addFundsToWallet
                      : _transactionType == TransactionType.transfer
                          ? l10n.transferFunds
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
                  ButtonSegment(
                      value: TransactionType.expense,
                      label: Text(l10n.expense),
                      icon: const Icon(Icons.money_off, size: 16)),
                  ButtonSegment(
                      value: TransactionType.income,
                      label: Text(l10n.income),
                      icon: Text(currencyProvider.symbol,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16))),
                  ButtonSegment(
                      value: TransactionType.transfer,
                      label: Text(l10n.transfer),
                      icon: const Icon(Icons.swap_horiz, size: 16)),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixText:
                    '${currencyProvider.code} ${currencyProvider.symbol} ',
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
                      decoration: InputDecoration(
                          labelText: l10n.fromWallet,
                          border: const OutlineInputBorder()),
                      items: wallets
                          .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text(w,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
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
                      decoration: InputDecoration(
                          labelText: l10n.toWallet,
                          border: const OutlineInputBorder()),
                      items: wallets
                          .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text(w,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _transferToWallet = val!),
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
                items: wallets
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
            ],
            const SizedBox(height: 16),
            if (_transactionType == TransactionType.expense) ...[
              Row(
                children: [
                  Expanded(
                    child: Consumer<ExpenseProvider>(
                      builder: (context, provider, _) {
                        final categories = provider.categories;
                        // Ensure selected category is still valid
                        if (_selectedCategory != null &&
                            !categories
                                .any((c) => c.name == _selectedCategory)) {
                          _selectedCategory = null;
                        }
                        final currentValue =
                            _selectedCategory ?? categories.first.name;

                        return DropdownButtonFormField<String>(
                          key: _categoryDropdownKey,
                          value: currentValue,
                          decoration: InputDecoration(
                            labelText: l10n.category,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                          ),
                          isExpanded: true,
                          items: [
                            ...categories.map((catObj) {
                              return DropdownMenuItem(
                                value: catObj.name,
                                child: Row(
                                  children: [
                                    Icon(
                                        IconData(catObj.iconCodePoint,
                                            fontFamily: 'MaterialIcons'),
                                        size: 16),
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
                            }),
                            DropdownMenuItem(
                              value: '__add_new_category__',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.addCategoryInline,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            if (value == '__add_new_category__') {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _showQuickAddCategoryDialog();
                              });
                              return;
                            }
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: _presentDatePicker,
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(
                          DateFormat('MMM dd, yyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _presentDatePicker,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(DateFormat('MMM dd, yyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 14)),
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
            ] else
              const SizedBox(height: 8),
            FilledButton(
              onPressed: _submitData,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                  _isEditing ? l10n.updateTransaction : l10n.saveTransaction,
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
