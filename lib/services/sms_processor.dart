import 'package:telephony/telephony.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import 'notification_service.dart';

class SmsProcessor {
  static Future<void> processSms(SmsMessage message) async {
    final body = message.body?.toLowerCase() ?? '';
    
    // DEBUG: Inform the user exactly what text we processed
    await NotificationService().showNotification(
      title: 'SMS Debug',
      body: 'Raw: ${body.length > 30 ? body.substring(0, 30) : body}...',
    );
    
    // Check if it's a financial transaction text
    // Ex: "rs. 250.00 debited from a/c for upi"
    if (body.contains('debited') || body.contains('sent') || body.contains('paid')) {
      if (body.contains('rs') || body.contains('inr') || body.contains('₹')) {
        
        // Extract amount using a regex (supports "Rs. 500", "₹500", "500 rs", "500 inr")
        final RegExp amountRegex = RegExp(r'(?:(?:rs\.?|inr|₹)\s?(\d+(?:\.\d{1,2})?))|(?:(\d+(?:\.\d{1,2})?)\s?(?:rs\.?|inr|₹))', caseSensitive: false);
        final match = amountRegex.firstMatch(body);
        
        if (match != null) {
          final String amountStr = match.group(1) ?? match.group(2) ?? '0';
          final double amount = double.tryParse(amountStr) ?? 0.0;
          
          if (amount > 0) {
            await _logAutoExpense(amount, body);
          }
        }
      }
    }
  }

  static Future<void> _logAutoExpense(double amount, String rawBody) async {
    // We assume Hive might not be fully initialized if coming from a background isolate
    if (!Hive.isBoxOpen(ExpenseProvider.expenseBoxName)) {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseModelAdapter());
      await Hive.openBox<ExpenseModel>(ExpenseProvider.expenseBoxName);
    }
    
    final expenseBox = Hive.box<ExpenseModel>(ExpenseProvider.expenseBoxName);
    
    // Attempt to extract a decent note/merchant name (limit to 30 chars)
    String note = "Auto-UPI: $rawBody";
    if (note.length > 30) note = "${note.substring(0, 27)}...";

    final newExpense = ExpenseModel(
      id: "sms_${DateTime.now().microsecondsSinceEpoch}",
      amount: amount,
      category: 'Other', // Hardcode default category for auto-logs
      date: DateTime.now(),
      note: note,
      paymentMethod: 'UPI',
      isIncome: false,
    );
    
    await expenseBox.add(newExpense);
    
    await NotificationService().showNotification(
      title: 'UPI Payment Auto-Logged',
      body: 'Verified deduction of ₹$amount. Added to expenses.',
    );
  }
}
