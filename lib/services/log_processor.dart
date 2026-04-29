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
