import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/split_trip_model.dart';
import '../models/split_expense_model.dart';

class Settlement {
  final String from;
  final String to;
  final double amount;

  Settlement({required this.from, required this.to, required this.amount});
}

class SplitProvider extends ChangeNotifier {
  static const String tripBoxName = 'split_trips_v1';
  static const String expenseBoxName = 'split_expenses_v1';

  List<SplitTripModel> _trips = [];
  List<SplitExpenseModel> _expenses = [];

  List<SplitTripModel> get trips => _trips;
  List<SplitExpenseModel> get expenses => _expenses;

  // Load all data from Hive
  Future<void> loadData() async {
    final tripBox = Hive.box<SplitTripModel>(tripBoxName);
    final expenseBox = Hive.box<SplitExpenseModel>(expenseBoxName);
    _trips = tripBox.values.toList();
    _expenses = expenseBox.values.toList();
    // Sort trips newest first
    _trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // ─── Trip CRUD ──────────────────────────────────────────────

  Future<void> addTrip(SplitTripModel trip) async {
    final box = Hive.box<SplitTripModel>(tripBoxName);
    await box.add(trip);
    await loadData();
  }

  Future<void> deleteTrip(String tripId) async {
    final tripBox = Hive.box<SplitTripModel>(tripBoxName);
    final expenseBox = Hive.box<SplitExpenseModel>(expenseBoxName);

    // Delete all expenses linked to this trip
    final tripExpenses = expenseBox.values.where((e) => e.tripId == tripId).toList();
    for (final expense in tripExpenses) {
      await expense.delete();
    }

    // Delete the trip itself
    final trip = tripBox.values.firstWhere((t) => t.id == tripId);
    await trip.delete();
    await loadData();
  }

  Future<void> addMemberToTrip(String tripId, String memberName) async {
    final tripBox = Hive.box<SplitTripModel>(tripBoxName);
    final trip = tripBox.values.firstWhere((t) => t.id == tripId);
    final updatedMembers = List<String>.from(trip.members)..add(memberName);
    final updatedTrip = SplitTripModel(
      id: trip.id,
      name: trip.name,
      members: updatedMembers,
      createdAt: trip.createdAt,
    );
    await trip.delete();
    await tripBox.add(updatedTrip);
    await loadData();
  }

  // ─── Expense CRUD ───────────────────────────────────────────

  Future<void> addExpense(SplitExpenseModel expense) async {
    final box = Hive.box<SplitExpenseModel>(expenseBoxName);
    await box.add(expense);
    await loadData();
  }

  Future<void> deleteExpense(String expenseId) async {
    final box = Hive.box<SplitExpenseModel>(expenseBoxName);
    final expense = box.values.firstWhere((e) => e.id == expenseId);
    await expense.delete();
    await loadData();
  }

  // ─── Query Helpers ──────────────────────────────────────────

  List<SplitExpenseModel> getExpensesForTrip(String tripId) {
    return _expenses.where((e) => e.tripId == tripId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTripTotal(String tripId) {
    return getExpensesForTrip(tripId).fold(0.0, (sum, e) => sum + e.amount);
  }

  // ─── Balance Calculation ────────────────────────────────────

  /// Returns a map of member -> net balance.
  /// Positive = person is owed money (they overpaid).
  /// Negative = person owes money (they underpaid).
  Map<String, double> getBalances(String tripId) {
    final tripExpenses = getExpensesForTrip(tripId);
    final Map<String, double> balances = {};

    for (final expense in tripExpenses) {
      final perPerson = expense.amount / expense.splitAmong.length;

      // The payer paid the full amount
      balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) + expense.amount;

      // Each person in the split owes their share
      for (final person in expense.splitAmong) {
        balances[person] = (balances[person] ?? 0) - perPerson;
      }
    }

    return balances;
  }

  // ─── Settlement Algorithm (Greedy) ──────────────────────────

  /// Returns the minimum list of transactions to settle all debts.
  List<Settlement> getSettlements(String tripId) {
    final balances = getBalances(tripId);
    final List<Settlement> settlements = [];

    // Separate into creditors (+ve balance) and debtors (-ve balance)
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    for (final entry in balances.entries) {
      if (entry.value > 0.01) {
        creditors.add(entry);
      } else if (entry.value < -0.01) {
        debtors.add(MapEntry(entry.key, -entry.value)); // make positive
      }
    }

    // Sort descending by amount
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    // Greedy matching
    int i = 0, j = 0;
    final cAmounts = creditors.map((e) => e.value).toList();
    final dAmounts = debtors.map((e) => e.value).toList();

    while (i < creditors.length && j < debtors.length) {
      final transfer = cAmounts[i] < dAmounts[j] ? cAmounts[i] : dAmounts[j];

      settlements.add(Settlement(
        from: debtors[j].key,
        to: creditors[i].key,
        amount: double.parse(transfer.toStringAsFixed(2)),
      ));

      cAmounts[i] -= transfer;
      dAmounts[j] -= transfer;

      if (cAmounts[i] < 0.01) i++;
      if (dAmounts[j] < 0.01) j++;
    }

    return settlements;
  }
}
