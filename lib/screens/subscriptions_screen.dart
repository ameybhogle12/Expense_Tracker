import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/subscription_model.dart';
import '../models/category_constants.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  void _showAddSubscriptionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const AddSubscriptionForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = context.watch<ExpenseProvider>().subscriptions;
    final currencyFormat = NumberFormat.currency(name: 'INR', locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
                final color = CategoryConstants.getColorForCategory(sub.category);
                
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
                    onDismissed: (direction) {
                      context.read<ExpenseProvider>().deleteSubscription(sub);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(CategoryConstants.getIconForCategory(sub.category), color: color),
                      ),
                      title: Text(sub.note.isNotEmpty ? sub.note : sub.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Billed on day ${sub.paymentDay} • ${sub.paymentMethod}'),
                      trailing: Text(
                        currencyFormat.format(sub.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubscriptionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Subscription'),
      ),
    );
  }
}

class AddSubscriptionForm extends StatefulWidget {
  const AddSubscriptionForm({super.key});

  @override
  State<AddSubscriptionForm> createState() => _AddSubscriptionFormState();
}

class _AddSubscriptionFormState extends State<AddSubscriptionForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = CategoryConstants.categories.first;
  String _paymentMethod = 'Main Bank'; 
  int _paymentDay = DateTime.now().day; 
  TimeOfDay _paymentTime = const TimeOfDay(hour: 9, minute: 0); 

  final List<String> _wallets = ['Main Bank', 'UPI Lite', 'Cash'];

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
      final enteredAmount = double.tryParse(_amountController.text.trim().replaceAll(',', ''));
      if (enteredAmount == null || enteredAmount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount.')));
        }
        return;
      }

      final newSub = SubscriptionModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: enteredAmount,
        category: _selectedCategory,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim(),
        paymentDay: _paymentDay,
        paymentHour: _paymentTime.hour,
        paymentMinute: _paymentTime.minute,
        lastProcessed: null, 
      );

      await context.read<ExpenseProvider>().addSubscription(newSub);
      
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

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Subscription', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Pay From', border: OutlineInputBorder()),
              items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
              onChanged: (val) => setState(() => _paymentMethod = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
              items: CategoryConstants.categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
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
              child: const Text('Save Subscription', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
