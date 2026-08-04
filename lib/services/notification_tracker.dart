import 'dart:async';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import 'ai_category_service.dart';
import 'notification_service.dart';

// Set to true on develop branch (Premium features), and false on main branch (Free release)
const bool kEnableAutoLogging = false;

class NotificationTracker {
  static final NotificationTracker _instance = NotificationTracker._internal();
  factory NotificationTracker() => _instance;
  NotificationTracker._internal();

  static const _channel = MethodChannel('com.ameybhogle.expensetracker/payment_detection');

  StreamSubscription? _subscription;
  bool _isListening = false;

  /// Deduplication cache: stores "amount|merchant" -> timestamp of last processed notification.
  /// Prevents the same transaction from being processed multiple times within the cooldown window.
  final Map<String, DateTime> _recentTransactions = {};
  static const _deduplicationCooldown = Duration(seconds: 60);

  /// The app's own package name — notifications from this package must be ignored
  /// to prevent an infinite self-triggering loop.
  static const _ownPackageName = 'com.ameybhogle.expensetracker';

  bool get isListening => _isListening;

  /// Starts listening to notifications.
  Future<void> startListening() async {
    if (_isListening) {
      // Sync enable auto logging state anyway
      try {
        await _channel.invokeMethod('setEnableAutoLogging', {'enabled': kEnableAutoLogging});
      } catch (_) {}
      return;
    }

    final isGranted = await NotificationListenerService.isPermissionGranted();
    if (!isGranted) {
      return;
    }

    // Sync enable auto logging state with native SharedPreferences
    try {
      await _channel.invokeMethod('setEnableAutoLogging', {'enabled': kEnableAutoLogging});
    } catch (_) {}

    _isListening = true;
    _subscription = NotificationListenerService.notificationsStream.listen((event) {
      _handleNotificationEvent(event);
    });
  }

  /// Stops listening to notifications.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  /// Processes intercepted notifications.
  Future<void> _handleNotificationEvent(ServiceNotificationEvent event) async {
    final package = event.packageName;

    // CRITICAL: Ignore the app's own notifications to prevent infinite loop.
    // Our "Payment Detected" notification contains ₹ and "Spent", which would
    // re-match the transaction regex and cause endless self-triggering.
    if (package == _ownPackageName) return;

    // Only process notifications that look like transactions
    final title = event.title;
    final content = event.content;

    final textToParse = "$title $content";
    final txType = isTransactionMessage(textToParse, package);
    if (txType == null) {
      return; // Not a transaction
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

      final currencySymbol = settingsBox.get('currency_symbol', defaultValue: '₹') as String;
      final merchant = parsed.merchant ?? 'Merchant';

      // Deduplication: skip if we already processed this exact amount+merchant recently
      final dedupeKey = '${parsed.amount!.toStringAsFixed(2)}|$merchant';
      final now = DateTime.now();
      final lastSeen = _recentTransactions[dedupeKey];
      if (lastSeen != null && now.difference(lastSeen) < _deduplicationCooldown) {
        return;
      }
      _recentTransactions[dedupeKey] = now;

      // Housekeeping: purge stale entries older than 5 minutes
      _recentTransactions.removeWhere((_, ts) => now.difference(ts).inMinutes > 5);

      // Free Tier / main branch behavior: Only notify the user to add the expense manually
      if (!kEnableAutoLogging) {
        // We return immediately because the native CustomNotificationListener already handles notification posting
        // when the app is in the background/foreground, to ensure it works when closed.
        return;
      }

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
      await NotificationService().showNotification(
        title: '✨ Auto-Logged Transaction',
        body: 'Saved $currencySymbol${parsed.amount!.toStringAsFixed(0)} at $merchant under $category.',
      );

    } catch (_) {
      // Silently handle errors in background notification processing
    }
  }

  /// Returns null if not a transaction, or bool: true=income, false=expense.
  /// Kept in sync with `isTransactionMessage` in
  /// android/app/src/main/kotlin/.../CustomNotificationListener.kt.
  /// Change both together.
  static bool? isTransactionMessage(String text, String package) {
    final lowerText = text.toLowerCase();

    // 1. A reminder, request, offer or failure is not a completed transaction.
    //    Checked first, for every package.
    const notATransaction = [
      'due date', 'is due', 'due on', 'due by', 'upcoming', 'reminder',
      'will be debited', 'will be deducted', 'scheduled', 'autopay',
      'requesting', 'has requested', 'payment request', 'collect request',
      'failed', 'declined', 'unsuccessful', 'cancelled', 'reversed',
      'offer', 'cashback', 'reward', 'scratch card', 'you won', 'voucher',
      'otp', 'code', 'verification', 'verify',
    ];
    if (notATransaction.any(lowerText.contains)) return null;

    // 2. Incoming money (word-bounded).
    const creditTriggers = [
      'credited', 'received', 'refund', 'deposited', 'added',
    ];
    if (creditTriggers.any((t) => RegExp('\\b$t').hasMatch(lowerText))) {
      return true; // isIncome = true
    }

    // 3. Outgoing money.
    final debitVerb =
        RegExp(r'\b(?:debited|withdrawn|paid|sent|spent|transferred|trf)\b');
    if (debitVerb.hasMatch(lowerText)) return false; // isIncome = false

    // Some issuers only ever say "txn" / "transaction" / "payment of".
    if (const ['txn', 'transaction', 'payment of'].any(lowerText.contains)) {
      return false; // Default to outgoing
    }

    return null;
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
    return ParsedTx(amount: amount, merchant: extractPayee(text));
  }

  /// Pulls a human-readable payee name out of a transaction message.
  ///
  /// Kept in sync with `extractPayee` in
  /// android/app/src/main/kotlin/.../CustomNotificationListener.kt — the native
  /// listener is what posts the notification on the free build, this Dart copy
  /// is used when auto-logging is on. Change both together.
  ///
  /// Returning null is deliberate: the old catch-all "(to|at) <anything>" regex
  /// matched the first "to" anywhere in the string, which on a real SVC Bank
  /// message yielded the STOPUPI helpline number instead of the payee. No name
  /// beats a wrong name.
  static String? extractPayee(String text) {
    final patterns = [
      // NPCI remittance format, passed through by most Indian banks:
      //   "... CR UPI/DR/127097027155/AKANKSHA A."
      RegExp(r'UPI[/-](?:DR|CR)[/-]\d+[/-]([A-Za-z][A-Za-z\s]{1,39}?)(?=[.,/]|\s+(?:Ref|Not|SMS|Call)|$)',
          caseSensitive: false),
      // SBI style: "... trf to AKANKSHA A Refno 127097027155"
      RegExp(r'(?:trf|transfer(?:red)?)\s+to\s+([A-Za-z][A-Za-z\s]{1,39}?)(?=\s+(?:refno|ref|on\s+\d|on\s+date|via|using|upi)|[.,]|$)',
          caseSensitive: false),
      // "Paid Rs.10 to Akanksha Aher on 30-07" — the amount sits between the
      // verb and "to", which a literal "paid to" match cannot catch.
      RegExp(r'(?:paid|sent|debited)\b.{0,40}?\bto\s+([A-Za-z][A-Za-z\s]{1,39}?)(?=\s+(?:refno|ref|on\s+\d|on\s+date|via|using|upi)|[.,?]|$)',
          caseSensitive: false),
      // "... to VPA akanksha@okaxis" — fall back to the handle's local part
      RegExp(r'VPA\s+([\w.\-]+)@[\w]+', caseSensitive: false),
      // Card / POS: "spent Rs.500 at AMAZON on 30-07"
      RegExp(r'\bat\s+([A-Za-z][A-Za-z0-9\s&.\-]{2,39}?)(?=\s+(?:on\s+\d|on\s+date|ref|using|via)|[.,]|$)',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final candidate = match
          .group(1)
          ?.trim()
          .replaceAll(RegExp(r'^[.,\-\s]+|[.,\-\s]+$'), '');
      if (candidate != null && candidate.isNotEmpty && _isPlausibleName(candidate)) {
        return _toTitleCase(candidate);
      }
    }
    return null;
  }

  /// Rejects reference numbers, helpline numbers and bank boilerplate.
  static bool _isPlausibleName(String candidate) {
    if (candidate.length < 3 || candidate.length > 40) return false;

    final letters = RegExp(r'[A-Za-z]').allMatches(candidate).length;
    final digits = RegExp(r'\d').allMatches(candidate).length;
    if (letters < 2 || digits > letters) return false;

    final lower = candidate.toLowerCase();
    const noise = [
      'your account', 'a/c', 'account', 'bank', 'upi', 'vpa', 'call',
      'sms', 'stopupi', 'not you', 'avl bal', 'clr bal', 'bal',
    ];
    return !noise.any((n) => lower == n || lower.startsWith('$n '));
  }

  /// "AKANKSHA A" -> "Akanksha A", so the notification doesn't shout.
  static String _toTitleCase(String raw) => raw
      .split(RegExp(r'\s+'))
      .map((w) => w.length <= 1
          ? w.toUpperCase()
          : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

class ParsedTx {
  final double? amount;
  final String? merchant;

  ParsedTx({this.amount, this.merchant});
}
