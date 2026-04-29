import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:telephony/telephony.dart' hide NetworkType;

import 'services/notification_service.dart';
import 'services/log_processor.dart';
import 'services/sms_processor.dart';

import 'models/expense_model.dart';
import 'models/budget_model.dart';
import 'models/subscription_model.dart';
import 'models/category_model.dart';
import 'models/goal_model.dart';
import 'models/emi_model.dart';
import 'models/split_trip_model.dart';
import 'models/split_expense_model.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/split_provider.dart';
import 'screens/auth_wrapper.dart';

@pragma('vm:entry-point') // Mandatory for Workmanager
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Hive.initFlutter();
      // Register all adapters again for the background isolate
      if (!Hive.isAdapterRegistered(0))
        Hive.registerAdapter(ExpenseModelAdapter());
      if (!Hive.isAdapterRegistered(1))
        Hive.registerAdapter(BudgetModelAdapter());
      if (!Hive.isAdapterRegistered(2))
        Hive.registerAdapter(SubscriptionModelAdapter());
      if (!Hive.isAdapterRegistered(3))
        Hive.registerAdapter(CategoryModelAdapter());
      if (!Hive.isAdapterRegistered(4))
        Hive.registerAdapter(GoalModelAdapter());
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(EmiModelAdapter());

      await NotificationService().init();
      await LogProcessor.processAll(isBackground: true);

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

// Telephony Background Handler
@pragma('vm:entry-point')
backgroundMessageHandler(SmsMessage message) async {
  await NotificationService().init();
  await SmsProcessor.processSms(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await NotificationService().init();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // Register the periodic task for closed-app logging
  await Workmanager().registerPeriodicTask(
    "1",
    "background_log_check",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
    ),
  );

  // SMS listening is initialized in AuthWrapper after UI loads

  // Register Adapters
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(SubscriptionModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(EmiModelAdapter());
  Hive.registerAdapter(SplitTripModelAdapter());
  Hive.registerAdapter(SplitExpenseModelAdapter());

  // Open Boxes
  await Hive.openBox<ExpenseModel>(ExpenseProvider.expenseBoxName);
  await Hive.openBox<BudgetModel>(ExpenseProvider.budgetBoxName);
  await Hive.openBox<SubscriptionModel>(ExpenseProvider.subscriptionBoxName);
  await Hive.openBox<CategoryModel>(ExpenseProvider.categoryBoxName);
  await Hive.openBox<GoalModel>(ExpenseProvider.goalBoxName);
  await Hive.openBox<EmiModel>(ExpenseProvider.emiBoxName);
  await Hive.openBox<SplitTripModel>(SplitProvider.tripBoxName);
  await Hive.openBox<SplitExpenseModel>(SplitProvider.expenseBoxName);
  await Hive.openBox('settings_v1');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()..loadData()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => SplitProvider()..loadData()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}
