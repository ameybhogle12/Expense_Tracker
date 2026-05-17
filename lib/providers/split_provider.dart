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
      settledPayments: trip.settledPayments,
    );
    await trip.delete();
    await tripBox.add(updatedTrip);
    await loadData();
  }

  // ─── Settlement Payment Tracking ────────────────────────────

  /// Marks a settlement (e.g. "Sneha->Amey") as paid.
  Future<void> markSettlementPaid(String tripId, String from, String to) async {
    final tripBox = Hive.box<SplitTripModel>(tripBoxName);
    final trip = tripBox.values.firstWhere((t) => t.id == tripId);
    final key = '$from->$to';
    if (trip.settledPayments.contains(key)) return;

    final updated = SplitTripModel(
      id: trip.id,
      name: trip.name,
      members: trip.members,
      createdAt: trip.createdAt,
      settledPayments: [...trip.settledPayments, key],
    );
    final hiveKey = tripBox.keys.firstWhere((k) => tripBox.get(k)?.id == tripId);
    await tripBox.put(hiveKey, updated);
    await loadData();
  }

  /// Unmarks a settlement as paid (undo).
  Future<void> unmarkSettlementPaid(String tripId, String from, String to) async {
    final tripBox = Hive.box<SplitTripModel>(tripBoxName);
    final trip = tripBox.values.firstWhere((t) => t.id == tripId);
    final key = '$from->$to';

    final updatedPayments = List<String>.from(trip.settledPayments)..remove(key);
    final updated = SplitTripModel(
      id: trip.id,
      name: trip.name,
      members: trip.members,
      createdAt: trip.createdAt,
      settledPayments: updatedPayments,
    );
    final hiveKey = tripBox.keys.firstWhere((k) => tripBox.get(k)?.id == tripId);
    await tripBox.put(hiveKey, updated);
    await loadData();
  }

  /// Check if a specific settlement is marked as paid.
  bool isSettlementPaid(String tripId, String from, String to) {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    return trip.settledPayments.contains('$from->$to');
  }

  /// Removes a member from a trip AND scrubs them from all expense splits.
  /// Expenses they paid for are reassigned to no-one (deleted).
  /// Returns a summary of affected expenses for UI feedback.
  Future<int> removeMemberFromTrip(String tripId, String memberName) async {
    final tripBox = Hive.box<SplitTripModel>(tripBoxName);
    final expenseBox = Hive.box<SplitExpenseModel>(expenseBoxName);

    // 1. Remove from trip members list
    final trip = tripBox.values.firstWhere((t) => t.id == tripId);
    final updatedMembers = List<String>.from(trip.members)..remove(memberName);
    // Also clean out any settled payments involving this member
    final cleanedPayments = trip.settledPayments
        .where((p) => !p.contains(memberName))
        .toList();
    final updatedTrip = SplitTripModel(
      id: trip.id,
      name: trip.name,
      members: updatedMembers,
      createdAt: trip.createdAt,
      settledPayments: cleanedPayments,
    );
    await trip.delete();
    await tripBox.add(updatedTrip);

    // 2. Handle expenses this member is involved in
    final tripExpenses = expenseBox.values.where((e) => e.tripId == tripId).toList();
    int affectedCount = 0;

    for (final expense in tripExpenses) {
      if (expense.paidBy == memberName) {
        // They paid for this expense — delete it entirely
        await expense.delete();
        affectedCount++;
      } else if (expense.splitAmong.contains(memberName)) {
        // They're in the split — remove them and re-save
        final updatedSplit = List<String>.from(expense.splitAmong)..remove(memberName);
        if (updatedSplit.isEmpty) {
          await expense.delete();
        } else {
          final updatedExpense = SplitExpenseModel(
            id: expense.id,
            tripId: expense.tripId,
            amount: expense.amount,
            description: expense.description,
            paidBy: expense.paidBy,
            splitAmong: updatedSplit,
            date: expense.date,
          );
          final key = expenseBox.keys.firstWhere((k) => expenseBox.get(k)?.id == expense.id);
          await expenseBox.put(key, updatedExpense);
        }
        affectedCount++;
      }
    }

    await loadData();
    return affectedCount;
  }

  // ─── Expense CRUD ───────────────────────────────────────────

  Future<void> addExpense(SplitExpenseModel expense) async {
    final box = Hive.box<SplitExpenseModel>(expenseBoxName);
    await box.add(expense);
    await loadData();
  }

  Future<void> updateExpense(SplitExpenseModel updatedExpense) async {
    // Model instance update
    await updatedExpense.save();
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
      // Round per-person share to 2 decimal places immediately.
      // This prevents floating-point drift (e.g. 1000÷3 = 333.3333...)
      // from accumulating into phantom debts over many expenses.
      final perPerson = double.parse(
        (expense.amount / expense.splitAmong.length).toStringAsFixed(2),
      );

      // The payer paid the full amount
      balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) + expense.amount;

      // Each person in the split owes their rounded share
      for (final person in expense.splitAmong) {
        balances[person] = (balances[person] ?? 0) - perPerson;
      }
    }

    // Final pass: snap any balance within ±0.02 of zero to exactly 0.0
    // This catches any residual rounding from multi-expense accumulation.
    return balances.map((k, v) => MapEntry(k, v.abs() < 0.02 ? 0.0 : v));
  }

  // ─── Settlement Algorithm (Greedy) ──────────────────────────

  /// Returns the minimum list of transactions to settle all debts.
  /// The sum of all balances always equals 0 (conservation of money).
  List<Settlement> getSettlements(String tripId) {
    final balances = getBalances(tripId);
    final List<Settlement> settlements = [];

    // Separate into creditors (+ve balance) and debtors (-ve balance)
    // Use 0.5 paisa (0.005) as the ignore threshold — anything smaller
    // is floating-point noise, not a real debt.
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    for (final entry in balances.entries) {
      if (entry.value > 0.005) {
        creditors.add(entry);
      } else if (entry.value < -0.005) {
        debtors.add(MapEntry(entry.key, -entry.value)); // make positive
      }
    }

    // Sort descending so largest debts/credits are handled first
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    // Greedy two-pointer matching
    int i = 0, j = 0;
    final cAmounts = creditors.map((e) => e.value).toList();
    final dAmounts = debtors.map((e) => e.value).toList();

    while (i < creditors.length && j < debtors.length) {
      final transfer = cAmounts[i] < dAmounts[j] ? cAmounts[i] : dAmounts[j];

      // Round to nearest paisa before recording
      final rounded = double.parse(transfer.toStringAsFixed(2));

      if (rounded > 0) {
        settlements.add(Settlement(
          from: debtors[j].key,
          to: creditors[i].key,
          amount: rounded,
        ));
      }

      cAmounts[i] -= transfer;
      dAmounts[j] -= transfer;

      // Move pointer when a balance is effectively zero
      if (cAmounts[i] < 0.005) i++;
      if (dAmounts[j] < 0.005) j++;
    }

    return settlements;
  }
}
