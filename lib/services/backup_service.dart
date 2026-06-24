import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../models/subscription_model.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../models/emi_model.dart';
import '../models/wallet_model.dart';
import '../models/split_trip_model.dart';
import '../models/split_expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/split_provider.dart';

/// Thrown when a selected file isn't a valid Trip & Track backup.
class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
  @override
  String toString() => message;
}

/// Handles exporting all app data to a single JSON file and restoring from one.
/// Everything is local (Hive), so this is the only way users can move data
/// between devices or recover after a reinstall.
class BackupService {
  static const String _appTag = 'Trip & Track';
  static const int _backupVersion = 1;
  static const String _settingsBoxName = 'settings_v1';

  // ─── Export ─────────────────────────────────────────────────

  /// Opens the system save dialog. Returns the saved path, or null if the
  /// user cancelled.
  static Future<String?> exportBackup() async {
    final jsonStr = _buildJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    return FilePicker.platform.saveFile(
      dialogTitle: 'Save your Trip & Track backup',
      fileName: 'TripTrack_Backup_$stamp.json',
      bytes: bytes,
    );
  }

  static String _buildJson() {
    final data = <String, dynamic>{
      'transactions': Hive.box<ExpenseModel>(ExpenseProvider.expenseBoxName)
          .values
          .map(_expenseToMap)
          .toList(),
      'budgets': Hive.box<BudgetModel>(ExpenseProvider.budgetBoxName)
          .values
          .map(_budgetToMap)
          .toList(),
      'subscriptions':
          Hive.box<SubscriptionModel>(ExpenseProvider.subscriptionBoxName)
              .values
              .map(_subscriptionToMap)
              .toList(),
      'categories': Hive.box<CategoryModel>(ExpenseProvider.categoryBoxName)
          .values
          .map(_categoryToMap)
          .toList(),
      'goals': Hive.box<GoalModel>(ExpenseProvider.goalBoxName)
          .values
          .map(_goalToMap)
          .toList(),
      'emis': Hive.box<EmiModel>(ExpenseProvider.emiBoxName)
          .values
          .map(_emiToMap)
          .toList(),
      'wallets': Hive.box<WalletModel>(ExpenseProvider.walletBoxName)
          .values
          .map(_walletToMap)
          .toList(),
      'splitTrips': Hive.box<SplitTripModel>(SplitProvider.tripBoxName)
          .values
          .map(_tripToMap)
          .toList(),
      'splitExpenses':
          Hive.box<SplitExpenseModel>(SplitProvider.expenseBoxName)
              .values
              .map(_splitExpenseToMap)
              .toList(),
      'settings': _settingsToMap(),
    };

    return const JsonEncoder.withIndent('  ').convert({
      'app': _appTag,
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  // ─── Import ─────────────────────────────────────────────────

  /// Lets the user pick a backup file and restores it, replacing current data.
  /// Returns true if data was restored, false if the user cancelled.
  /// Throws [BackupException] if the file isn't a valid backup.
  static Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select a Trip & Track backup',
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      throw const BackupException('Could not read the selected file.');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('This file is not a valid backup.');
    }

    final data = decoded['data'];
    if (decoded['app'] != _appTag || data is! Map<String, dynamic>) {
      throw const BackupException(
          "This doesn't look like a Trip & Track backup.");
    }

    await _restore(data);
    return true;
  }

  static Future<void> _restore(Map<String, dynamic> data) async {
    await _replaceBox<ExpenseModel>(
        ExpenseProvider.expenseBoxName, data['transactions'], _expenseFromMap);
    await _replaceBox<BudgetModel>(
        ExpenseProvider.budgetBoxName, data['budgets'], _budgetFromMap);
    await _replaceBox<SubscriptionModel>(ExpenseProvider.subscriptionBoxName,
        data['subscriptions'], _subscriptionFromMap);
    await _replaceBox<CategoryModel>(
        ExpenseProvider.categoryBoxName, data['categories'], _categoryFromMap);
    await _replaceBox<GoalModel>(
        ExpenseProvider.goalBoxName, data['goals'], _goalFromMap);
    await _replaceBox<EmiModel>(
        ExpenseProvider.emiBoxName, data['emis'], _emiFromMap);
    await _replaceBox<WalletModel>(
        ExpenseProvider.walletBoxName, data['wallets'], _walletFromMap);
    await _replaceBox<SplitTripModel>(
        SplitProvider.tripBoxName, data['splitTrips'], _tripFromMap);
    await _replaceBox<SplitExpenseModel>(SplitProvider.expenseBoxName,
        data['splitExpenses'], _splitExpenseFromMap);
    _restoreSettings(data['settings']);
  }

  static Future<void> _replaceBox<T>(
    String boxName,
    dynamic list,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final box = Hive.box<T>(boxName);
    await box.clear();
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          await box.add(fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
  }

  // ─── Settings ───────────────────────────────────────────────

  static Map<String, dynamic> _settingsToMap() {
    final box = Hive.box(_settingsBoxName);
    final out = <String, dynamic>{};
    for (final key in box.keys) {
      final v = box.get(key);
      if (v is String || v is num || v is bool) {
        out[key.toString()] = v;
      }
    }
    return out;
  }

  static void _restoreSettings(dynamic settings) {
    if (settings is! Map) return;
    final box = Hive.box(_settingsBoxName);
    settings.forEach((k, v) {
      if (v is String || v is num || v is bool) {
        box.put(k.toString(), v);
      }
    });
  }

  // ─── Field mappers ──────────────────────────────────────────

  static String? _dt(DateTime? d) => d?.toIso8601String();
  static DateTime _reqDt(dynamic s) => DateTime.parse(s as String);
  static DateTime? _optDt(dynamic s) =>
      (s == null) ? null : DateTime.parse(s as String);
  static double _d(dynamic n) => (n as num).toDouble();
  static List<String> _strList(dynamic l) =>
      (l as List?)?.map((e) => e.toString()).toList() ?? [];

  static Map<String, dynamic> _expenseToMap(ExpenseModel e) => {
        'id': e.id,
        'amount': e.amount,
        'category': e.category,
        'date': _dt(e.date),
        'note': e.note,
        'paymentMethod': e.paymentMethod,
        'isIncome': e.isIncome,
      };
  static ExpenseModel _expenseFromMap(Map<String, dynamic> m) => ExpenseModel(
        id: m['id'].toString(),
        amount: _d(m['amount']),
        category: m['category'].toString(),
        date: _reqDt(m['date']),
        note: (m['note'] ?? '').toString(),
        paymentMethod: (m['paymentMethod'] ?? '').toString(),
        isIncome: m['isIncome'] == true,
      );

  static Map<String, dynamic> _budgetToMap(BudgetModel b) => {
        'category': b.category,
        'monthlyLimit': b.monthlyLimit,
      };
  static BudgetModel _budgetFromMap(Map<String, dynamic> m) => BudgetModel(
        category: m['category'].toString(),
        monthlyLimit: _d(m['monthlyLimit']),
      );

  static Map<String, dynamic> _subscriptionToMap(SubscriptionModel s) => {
        'id': s.id,
        'amount': s.amount,
        'category': s.category,
        'paymentMethod': s.paymentMethod,
        'note': s.note,
        'paymentDay': s.paymentDay,
        'lastProcessed': _dt(s.lastProcessed),
        'paymentHour': s.paymentHour,
        'paymentMinute': s.paymentMinute,
      };
  static SubscriptionModel _subscriptionFromMap(Map<String, dynamic> m) =>
      SubscriptionModel(
        id: m['id'].toString(),
        amount: _d(m['amount']),
        category: m['category'].toString(),
        paymentMethod: (m['paymentMethod'] ?? '').toString(),
        note: (m['note'] ?? '').toString(),
        paymentDay: (m['paymentDay'] as num).toInt(),
        lastProcessed: _optDt(m['lastProcessed']),
        paymentHour: (m['paymentHour'] as num?)?.toInt() ?? 0,
        paymentMinute: (m['paymentMinute'] as num?)?.toInt() ?? 0,
      );

  static Map<String, dynamic> _categoryToMap(CategoryModel c) => {
        'id': c.id,
        'name': c.name,
        'colorValue': c.colorValue,
        'iconCodePoint': c.iconCodePoint,
        'isCustom': c.isCustom,
      };
  static CategoryModel _categoryFromMap(Map<String, dynamic> m) => CategoryModel(
        id: m['id'].toString(),
        name: m['name'].toString(),
        colorValue: (m['colorValue'] as num).toInt(),
        iconCodePoint: (m['iconCodePoint'] as num).toInt(),
        isCustom: m['isCustom'] == true,
      );

  static Map<String, dynamic> _goalToMap(GoalModel g) => {
        'id': g.id,
        'name': g.name,
        'targetAmount': g.targetAmount,
        'savedAmount': g.savedAmount,
        'deadline': _dt(g.deadline),
        'colorValue': g.colorValue,
        'iconCodePoint': g.iconCodePoint,
      };
  static GoalModel _goalFromMap(Map<String, dynamic> m) => GoalModel(
        id: m['id'].toString(),
        name: m['name'].toString(),
        targetAmount: _d(m['targetAmount']),
        savedAmount: _d(m['savedAmount']),
        deadline: _optDt(m['deadline']),
        colorValue: (m['colorValue'] as num).toInt(),
        iconCodePoint: (m['iconCodePoint'] as num).toInt(),
      );

  static Map<String, dynamic> _emiToMap(EmiModel e) => {
        'id': e.id,
        'itemName': e.itemName,
        'totalAmount': e.totalAmount,
        'monthlyInstallment': e.monthlyInstallment,
        'totalMonths': e.totalMonths,
        'monthsPaid': e.monthsPaid,
        'paymentDay': e.paymentDay,
        'lastProcessed': _dt(e.lastProcessed),
        'paymentMethod': e.paymentMethod,
      };
  static EmiModel _emiFromMap(Map<String, dynamic> m) => EmiModel(
        id: m['id'].toString(),
        itemName: m['itemName'].toString(),
        totalAmount: _d(m['totalAmount']),
        monthlyInstallment: _d(m['monthlyInstallment']),
        totalMonths: (m['totalMonths'] as num).toInt(),
        monthsPaid: (m['monthsPaid'] as num).toInt(),
        paymentDay: (m['paymentDay'] as num).toInt(),
        lastProcessed: _optDt(m['lastProcessed']),
        paymentMethod: (m['paymentMethod'] ?? '').toString(),
      );

  static Map<String, dynamic> _walletToMap(WalletModel w) => {
        'id': w.id,
        'name': w.name,
      };
  static WalletModel _walletFromMap(Map<String, dynamic> m) => WalletModel(
        id: m['id'].toString(),
        name: m['name'].toString(),
      );

  static Map<String, dynamic> _tripToMap(SplitTripModel t) => {
        'id': t.id,
        'name': t.name,
        'members': t.members,
        'createdAt': _dt(t.createdAt),
        'settledPayments': t.settledPayments,
      };
  static SplitTripModel _tripFromMap(Map<String, dynamic> m) => SplitTripModel(
        id: m['id'].toString(),
        name: m['name'].toString(),
        members: _strList(m['members']),
        createdAt: _reqDt(m['createdAt']),
        settledPayments: _strList(m['settledPayments']),
      );

  static Map<String, dynamic> _splitExpenseToMap(SplitExpenseModel e) => {
        'id': e.id,
        'tripId': e.tripId,
        'amount': e.amount,
        'description': e.description,
        'paidBy': e.paidBy,
        'splitAmong': e.splitAmong,
        'date': _dt(e.date),
      };
  static SplitExpenseModel _splitExpenseFromMap(Map<String, dynamic> m) =>
      SplitExpenseModel(
        id: m['id'].toString(),
        tripId: m['tripId'].toString(),
        amount: _d(m['amount']),
        description: (m['description'] ?? '').toString(),
        paidBy: (m['paidBy'] ?? '').toString(),
        splitAmong: _strList(m['splitAmong']),
        date: _reqDt(m['date']),
      );
}
