import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../models/subscription_model.dart';
import '../models/emi_model.dart';
import '../services/notification_service.dart';
import '../providers/expense_provider.dart';

class LogProcessor {
  static Future<void> processAll({bool isBackground = true}) async {
    final now = DateTime.now();
    
    // Open boxes if they aren't open (essential for background isolates)
    final expenseBox = await Hive.openBox<ExpenseModel>(ExpenseProvider.expenseBoxName);
    final subscriptionBox = await Hive.openBox<SubscriptionModel>(ExpenseProvider.subscriptionBoxName);
    final emiBox = await Hive.openBox<EmiModel>(ExpenseProvider.emiBoxName);

    // Daily Spend Reminder check
    try {
      final settingsBox = await Hive.openBox('settings_v1');
      final todayStr = "${now.year}-${now.month}-${now.day}";
      final lastReminderDate = settingsBox.get('lastReminderSentDate');
      
      if (lastReminderDate != todayStr) {
        bool hasRecentTransaction = false;
        final oneDayAgo = now.subtract(const Duration(hours: 24));
        
        for (var expense in expenseBox.values) {
          if (expense.date.isAfter(oneDayAgo)) {
            hasRecentTransaction = true;
            break;
          }
        }
        
        if (!hasRecentTransaction) {
          final funnyReminders = [
            "🧪 Test Subject Alert! Your friend needs your feedback. Did you log any expenses or test the Split Settlement room today? 😉",
            "👀 Psst... your wallets are feeling lonely! Did you forget to record your snack spending today?",
            "💸 Did you spend 0 rupees today, or are you just hiding your transactions from me? Tap to log them!",
            "🕵️‍♂️ Friend Check: Your split-expense friends are waiting for splits! Tap to record split expenses and test!",
          ];
          
          final index = now.minute % funnyReminders.length;
          final reminderBody = funnyReminders[index];
          
          await NotificationService().showNotification(
            title: '💸 Forgot to record money?',
            body: reminderBody,
          );
          
          await settingsBox.put('lastReminderSentDate', todayStr);
        }
      }
    } catch (e) {
      // Don't interrupt background processing if reminder fails
    }

    // Process Subscriptions
    for (var sub in subscriptionBox.values) {
      if (now.day >= sub.paymentDay) {
        if (now.day > sub.paymentDay || (now.day == sub.paymentDay && now.hour * 60 + now.minute >= sub.paymentHour * 60 + sub.paymentMinute)) {
          if (sub.lastProcessed == null || sub.lastProcessed!.year != now.year || sub.lastProcessed!.month != now.month) {
            final newTransaction = ExpenseModel(
              id: 'sub_${sub.id}_${now.year}${now.month}',
              amount: sub.amount,
              category: sub.category,
              date: DateTime(now.year, now.month, sub.paymentDay, sub.paymentHour, sub.paymentMinute),
              note: sub.note,
              paymentMethod: sub.paymentMethod,
              isIncome: false,
            );
            
            await expenseBox.add(newTransaction);
            sub.lastProcessed = now;
            await sub.save();

            if (isBackground) {
              await NotificationService().showNotification(
                title: 'Subscription Logged',
                body: '${sub.note} has been auto-logged.',
              );
            }
          }
        }
      }
    }

    // Process EMIs
    for (var emi in emiBox.values) {
      if (emi.monthsPaid < emi.totalMonths) {
        if (now.day >= emi.paymentDay) {
          if (emi.lastProcessed == null || emi.lastProcessed!.year != now.year || emi.lastProcessed!.month != now.month) {
            final newTransaction = ExpenseModel(
              id: 'emi_${emi.id}_${now.year}${now.month}',
              amount: emi.monthlyInstallment,
              category: 'Other', 
              date: DateTime(now.year, now.month, emi.paymentDay),
              note: 'EMI: ${emi.itemName} (${emi.monthsPaid + 1}/${emi.totalMonths})',
              paymentMethod: emi.paymentMethod,
              isIncome: false,
            );
            
            await expenseBox.add(newTransaction);
            emi.monthsPaid += 1;
            emi.lastProcessed = now;
            await emi.save();

            if (isBackground) {
              await NotificationService().showNotification(
                title: 'EMI Logged',
                body: 'EMI for ${emi.itemName} logged.',
              );
            }
          }
        }
      }
    }
  }
}
