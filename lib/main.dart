import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/expense_model.dart';
import 'models/budget_model.dart';
import 'models/subscription_model.dart';
import 'models/category_model.dart';
import 'models/goal_model.dart';
import 'models/emi_model.dart';
import 'providers/expense_provider.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(SubscriptionModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(EmiModelAdapter());
  
  // Open Boxes
  await Hive.openBox<ExpenseModel>(ExpenseProvider.expenseBoxName);
  await Hive.openBox<BudgetModel>(ExpenseProvider.budgetBoxName);
  await Hive.openBox<SubscriptionModel>(ExpenseProvider.subscriptionBoxName);
  await Hive.openBox<CategoryModel>(ExpenseProvider.categoryBoxName);
  await Hive.openBox<GoalModel>(ExpenseProvider.goalBoxName);
  await Hive.openBox<EmiModel>(ExpenseProvider.emiBoxName);
  await Hive.openBox('settings_v1');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()..loadData()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
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
  }
}
