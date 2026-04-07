import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/budgets_overview.dart';
import '../widgets/recent_transactions.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      final transactions = context.read<ExpenseProvider>().allTransactions;
      
      List<List<dynamic>> rows = [
        ['ID', 'Date', 'Category', 'Type', 'Wallet', 'Amount', 'Note']
      ];

      for (var t in transactions) {
        rows.add([
          t.id,
          t.date.toIso8601String(),
          t.category,
          t.isIncome ? 'Income' : 'Expense',
          t.paymentMethod,
          t.amount,
          t.note,
        ]);
      }

      // String csvData = const ListToCsvConverter().convert(rows);
      String csvData = ListToCsvConverter().convert(rows);
      
      Directory? dir = await getDownloadsDirectory();
      dir ??= await getApplicationDocumentsDirectory();
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/ExpenseTracker_Export_$timestamp.csv';
      
      final file = File(path);
      await file.writeAsString(csvData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Success! Exported to: $path'), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: () => _exportToCSV(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(),
              SizedBox(height: 24),
              BudgetsOverview(),
              SizedBox(height: 24),
              RecentTransactions(),
              SizedBox(height: 80), // Padding for bottom nav and FAB
            ],
          ),
        ),
      ),
    );
  }
}
