import 'dart:async';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import 'ai_category_service.dart';
import 'notification_service.dart';

class NotificationTracker {
  static final NotificationTracker _instance = NotificationTracker._internal();
  factory NotificationTracker() => _instance;
  NotificationTracker._internal();

  StreamSubscription? _subscription;
  bool _isListening = false;

  bool get isListening => _isListening;

  /// Starts listening to notifications.
  Future<void> startListening() async {
    if (_isListening) return;

    final isGranted = await NotificationListenerService.isPermissionGranted();
    if (!isGranted) {
      print("Notification listener permission not granted.");
      return;
    }

    _isListening = true;
    _subscription = NotificationListenerService.notificationsStream.listen((event) {
      _handleNotificationEvent(event);
    });
    print("Notification listener started.");
  }

  /// Stops listening to notifications.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    print("Notification listener stopped.");
  }

  /// Processes intercepted notifications.
  Future<void> _handleNotificationEvent(ServiceNotificationEvent event) async {
    // Only process notifications that look like transactions
    final title = event.title ?? '';
    final content = event.content ?? '';
    final package = event.packageName ?? '';

    final textToParse = "$title $content";
    if (!_isTransactionMessage(textToParse, package)) {
      return;
    }

    try {
      final parsed = _parseTransaction(textToParse);
      if (parsed == null || parsed.amount == null || parsed.amount! <= 0) {
        return;
      }

      // Initialize Hive if background service runs in a separate isolate
      await Hive.initFlutter();
      
      // Register adapters if not already registered (avoid crash in background isolate)
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseModelAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(CategoryModelAdapter());

      // Open boxes
      final expenseBox = await Hive.openBox<ExpenseModel>(ExpenseProvider.expenseBoxName);
      final categoryBox = await Hive.openBox<CategoryModel>(ExpenseProvider.categoryBoxName);
      final settingsBox = await Hive.openBox('settings_v1');

      // Check if auto-logging is globally enabled in settings
      final isAutoLoggingEnabled = settingsBox.get('auto_logging_enabled', defaultValue: true) as bool;
      if (!isAutoLoggingEnabled) return;

      // Extract categories list
      final availableCategories = categoryBox.values.map((c) => c.name).toList();
      if (availableCategories.isEmpty) {
        availableCategories.add('Food');
        availableCategories.add('Shopping');
        availableCategories.add('Transport');
        availableCategories.add('Utilities');
        availableCategories.add('Entertainment');
        availableCategories.add('Other');
      }

      final merchant = parsed.merchant ?? 'Unknown Merchant';
      
      // Use AI to get category
      final aiService = AICategoryService();
      await aiService.init();
      final category = await aiService.categorizeMerchant(merchant, availableCategories);

      // Create new expense
      final newExpense = ExpenseModel(
        id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
        amount: parsed.amount!,
        category: category,
        date: DateTime.now(),
        note: 'Auto-logged from notification: $merchant',
        paymentMethod: 'UPI', // Default for auto-logged notifications
        isIncome: false,
      );

      await expenseBox.add(newExpense);

      // Notify the user of successful log
      final currencySymbol = settingsBox.get('currency_symbol', defaultValue: '₹') as String;
      await NotificationService().showNotification(
        title: '✨ Auto-Logged Transaction',
        body: 'Saved $currencySymbol${parsed.amount!.toStringAsFixed(0)} at $merchant under $category.',
      );

    } catch (e) {
      print("NotificationTracker Error: $e");
    }
  }

  /// Determines if a notification matches typical transaction trigger words.
  bool _isTransactionMessage(String text, String package) {
    final lowerText = text.toLowerCase();
    
    // Check for common financial package names
    final knownFinPackages = [
      'com.google.android.apps.nbu.paisa.user', // GPay
      'net.one97.paytm', // Paytm
      'com.phonepe.app', // PhonePe
      'in.org.npci.upiapp', // BHIM
    ];

    if (knownFinPackages.contains(package)) {
      return true;
    }

    // Keyword checks (e.g. UPI, debited, paid, spent)
    final triggers = [
      'debited',
      'sent to',
      'paid to',
      'spent',
      'txn',
      'transaction',
      'payment of',
      'withdrawn',
    ];

    for (var trigger in triggers) {
      if (lowerText.contains(trigger)) {
        // Exclude OTPs or security codes
        if (!lowerText.contains('otp') && !lowerText.contains('code') && !lowerText.contains('verification')) {
          return true;
        }
      }
    }

    return false;
  }

  /// Parses transaction amount and merchant from notification text.
  ParsedTx? _parseTransaction(String text) {
    // 1. Regex to find amount
    // Matches: ₹500, Rs. 500, Rs 500, INR 500, Rs.500.00, etc.
    final amountRegex = RegExp(r'(?:₹|Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)', caseSensitive: false);
    final match = amountRegex.firstMatch(text);
    if (match == null) return null;

    final amountStr = match.group(1)?.replaceAll(',', '');
    final amount = double.tryParse(amountStr ?? '');

    // 2. Regex to find merchant
    // Matches common templates:
    // "paid to [Merchant] on..."
    // "sent to [Merchant] using..."
    // "txn of Rs.500.00 at [Merchant]..."
    // "debited to [Merchant]..."
    String? merchant;
    final merchantRegexes = [
      RegExp(r'(?:paid|sent|transferr?ed)\s+to\s+([^.]+?)(?:\s+on|\s+using|\s+at|\s+from|\s+ref|\.)', caseSensitive: false),
      RegExp(r'at\s+([^.]+?)(?:\s+on|\s+using|\s+from|\s+ref|\.)', caseSensitive: false),
      RegExp(r'debited\s+to\s+([^.]+?)(?:\s+on|\s+using|\s+from|\s+ref|\.)', caseSensitive: false),
    ];

    for (var regex in merchantRegexes) {
      final merchantMatch = regex.firstMatch(text);
      if (merchantMatch != null) {
        final rawMerchant = merchantMatch.group(1)?.trim();
        if (rawMerchant != null && rawMerchant.isNotEmpty && rawMerchant.length < 50) {
          // Avoid matching clean words like "your account" or "HDFC"
          if (!rawMerchant.toLowerCase().contains('your account') &&
              !rawMerchant.toLowerCase().contains('a/c')) {
            merchant = rawMerchant;
            break;
          }
        }
      }
    }

    // Fallback: If no merchant found, try matching everything after "to" up to 20 chars
    if (merchant == null) {
      final fallbackRegex = RegExp(r'(?:to|at)\s+([A-Za-z0-9\s&]{3,20})', caseSensitive: false);
      final fallbackMatch = fallbackRegex.firstMatch(text);
      if (fallbackMatch != null) {
        merchant = fallbackMatch.group(1)?.trim();
      }
    }

    return ParsedTx(amount: amount, merchant: merchant);
  }
}

class ParsedTx {
  final double? amount;
  final String? merchant;

  ParsedTx({this.amount, this.merchant});
}
