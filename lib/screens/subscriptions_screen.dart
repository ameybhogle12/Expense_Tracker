import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/subscription_model.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  void _showSubscriptionForm(BuildContext context, {SubscriptionModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => AddSubscriptionForm(existing: existing),
    );
  }

  void _showActions(BuildContext context, SubscriptionModel sub) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _showSubscriptionForm(context, existing: sub);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ExpenseProvider>().deleteSubscription(sub);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete subscription?'),
        content: Text('"$name" will be removed. This won\'t delete transactions already logged.'),
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

  @override
  Widget build(BuildContext context) {
    final subscriptions = context.watch<ExpenseProvider>().subscriptions;
    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Subscriptions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: subscriptions.isEmpty
          ? const Center(child: Text('No active subscriptions.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                final sub = subscriptions[index];
                final catObj = context.read<ExpenseProvider>().getCategoryByName(sub.category);
                final color = catObj != null ? Color(catObj.colorValue) : Colors.grey;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: Key(sub.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) => _confirmDelete(context, sub.note.isNotEmpty ? sub.note : sub.category),
                    onDismissed: (direction) {
                      context.read<ExpenseProvider>().deleteSubscription(sub);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _showActions(context, sub),
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(catObj != null ? IconData(catObj.iconCodePoint, fontFamily: 'MaterialIcons') : Icons.subscriptions, color: color),
                      ),
                      title: Text(sub.note.isNotEmpty ? sub.note : sub.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Billed on day ${sub.paymentDay} • ${sub.paymentMethod}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currencyProvider.format(sub.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubscriptionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Subscription'),
      ),
    );
  }
}

class AddSubscriptionForm extends StatefulWidget {
  /// When provided, the form opens in edit mode for this subscription.
  final SubscriptionModel? existing;
  const AddSubscriptionForm({super.key, this.existing});

  @override
  State<AddSubscriptionForm> createState() => _AddSubscriptionFormState();
}

class _AddSubscriptionFormState extends State<AddSubscriptionForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  late String _paymentMethod;
  int _paymentDay = DateTime.now().day;
  TimeOfDay _paymentTime = const TimeOfDay(hour: 9, minute: 0);

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final wallets = context.read<ExpenseProvider>().wallets.map((w) => w.name).toList();
    _paymentMethod = wallets.isNotEmpty ? wallets.first : 'Main Bank';

    final existing = widget.existing;
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(
          existing.amount == existing.amount.roundToDouble() ? 0 : 2);
      _noteController.text = existing.note;
      _selectedCategory = existing.category;
      _paymentMethod = existing.paymentMethod;
      _paymentDay = existing.paymentDay;
      _paymentTime = TimeOfDay(hour: existing.paymentHour, minute: existing.paymentMinute);
    }
  }

  void _presentTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _paymentTime,
    );
    if (pickedTime != null) {
      setState(() {
        _paymentTime = pickedTime;
      });
    }
  }

  void _submitData() async {
    try {
      final provider = context.read<ExpenseProvider>();
      final enteredAmount = double.tryParse(_amountController.text.trim().replaceAll(',', ''));
      if (enteredAmount == null || enteredAmount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount.')));
        }
        return;
      }

      final note = _noteController.text.trim();
      final category = _selectedCategory ?? provider.categories.first.name;

      // Warn (but allow) when this looks like a duplicate of an existing one.
      if (provider.isLikelyDuplicateSubscription(
        note: note,
        amount: enteredAmount,
        category: category,
        paymentDay: _paymentDay,
        excludeId: widget.existing?.id,
      )) {
        final label = note.isNotEmpty ? '"$note"' : 'this recurring charge';
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Possible duplicate'),
            content: Text('You already have a subscription that matches $label. Add it anyway?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add Anyway')),
            ],
          ),
        );
        if (proceed != true) return;
      }

      if (_isEditing) {
        await provider.updateSubscription(
          widget.existing!,
          amount: enteredAmount,
          category: category,
          paymentMethod: _paymentMethod,
          note: note,
          paymentDay: _paymentDay,
          paymentHour: _paymentTime.hour,
          paymentMinute: _paymentTime.minute,
        );
      } else {
        final newSub = SubscriptionModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          amount: enteredAmount,
          category: category,
          paymentMethod: _paymentMethod,
          note: note,
          paymentDay: _paymentDay,
          paymentHour: _paymentTime.hour,
          paymentMinute: _paymentTime.minute,
          lastProcessed: null,
        );
        await provider.addSubscription(newSub);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final currencyProvider = context.watch<CurrencyProvider>();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEditing ? 'Edit Subscription' : 'Add Subscription', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Amount', prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Pay From', border: OutlineInputBorder()),
              items: context.watch<ExpenseProvider>().wallets.map((w) => DropdownMenuItem(value: w.name, child: Text(w.name))).toList(),
              onChanged: (val) => setState(() => _paymentMethod = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory ?? context.watch<ExpenseProvider>().categories.first.name,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
              items: context.watch<ExpenseProvider>().categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _paymentDay,
                    decoration: const InputDecoration(labelText: 'Day of Month', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                    items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                    onChanged: (val) => setState(() => _paymentDay = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), 
                    ),
                    onPressed: _presentTimePicker,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_paymentTime.format(context), style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Subscription Name (e.g. Netflix)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitData,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_isEditing ? 'Update Subscription' : 'Save Subscription', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
