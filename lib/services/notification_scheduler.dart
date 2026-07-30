import 'package:hive_flutter/hive_flutter.dart';

import '../models/emi_model.dart';
import '../models/subscription_model.dart';
import '../providers/expense_provider.dart';
import 'notification_service.dart';
import 'spending_insight_service.dart';

/// Hands the app's time-based notifications to the Android AlarmManager ahead of
/// time, so they are delivered even when the app process is gone.
///
/// ## Why this exists
///
/// Every reminder used to be posted with `FlutterLocalNotificationsPlugin.show()`
/// from inside `LogProcessor.processAll`, which only runs while Dart is alive:
/// either the once-a-minute `Timer` in `ExpenseProvider`, or the 15-minute
/// Workmanager task. Neither survives the app being closed:
///
///  * Workmanager work is *deferrable*. Doze and App Standby batch it, and most
///    OEM skins (Xiaomi, Realme, Oppo, Vivo, Samsung) force-stop the process on
///    swipe-away, which cancels its pending jobs until the next manual launch.
///  * The in-app `Timer` obviously dies with the process.
///
/// So with the app closed there was nothing registered with the OS that could
/// wake the device and post anything. Scheduling through AlarmManager moves that
/// responsibility to the system, where it belongs.
///
/// ## Consequence
///
/// An alarm carries fixed text — it cannot run Dart to compose a message at fire
/// time. Bodies are therefore composed here, when arming. [rearmAll] is called
/// on launch, on resume, on pause (the last chance before the process may be
/// killed) and from the Workmanager task, which keeps the copy current.
class NotificationScheduler {
  /// Local hour for the "did you forget to log?" nudge.
  static const int _reminderHour = 20;

  /// Local hour for the end-of-day spending recap.
  static const int _insightHour = 18;

  /// How far ahead the daily nudge is armed. Long enough that a user who does
  /// not open the app for a week still gets reminded; refreshed on every
  /// [rearmAll].
  static const int _windowDays = NotificationService.dailyReminderWindowDays;

  /// Upper bound on how many subscriptions/EMIs get their own alarm. Android
  /// caps an app at 500 pending alarms, so this stays well clear.
  static const int _maxPerCollection = 50;

  static bool _running = false;

  /// Cancels and re-arms every scheduled notification this class owns.
  ///
  /// Safe to call as often as you like: IDs are deterministic so re-arming
  /// overwrites rather than accumulates, and re-entry is guarded.
  static Future<void> rearmAll() async {
    if (_running) return;
    _running = true;
    try {
      await _cancelManaged();
      await _armDailyReminders();
      await _armInsight();
      await _armSubscriptionReminders();
      await _armEmiReminders();
    } catch (_) {
      // Never let scheduling break a UI action or the background task.
    } finally {
      _running = false;
    }
  }

  /// Clears the ID ranges this class owns.
  ///
  /// Driven off the pending list rather than blindly walking each range, so a
  /// re-arm costs one query plus a cancel per alarm that actually exists —
  /// not thousands of no-op platform calls.
  static Future<void> _cancelManaged() async {
    final service = NotificationService();
    final pending = await service.pendingNotifications();

    for (final request in pending) {
      if (_isManaged(request.id)) {
        await service.cancel(request.id);
      }
    }
  }

  static bool _isManaged(int id) {
    bool inRange(int base, int size) => id >= base && id < base + size;
    return inRange(
            NotificationService.dailyReminderIdBase, _windowDays) ||
        inRange(NotificationService.insightIdBase, _windowDays) ||
        inRange(NotificationService.subscriptionIdBase, _maxPerCollection) ||
        inRange(NotificationService.emiIdBase, _maxPerCollection);
  }

  /// Next occurrence of [hour] local time, strictly in the future.
  static DateTime _nextAt(int hour, {int addDays = 0}) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour);
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
    return target.add(Duration(days: addDays));
  }

  // ---------------------------------------------------------------------------
  // Daily "forgot to record money?" nudge
  // ---------------------------------------------------------------------------

  /// The original check was "no transaction in the last 24h", which an alarm
  /// cannot evaluate at fire time. Re-arming when the app is backgrounded gives
  /// the same outcome from the user's side: logging an expense before leaving
  /// pushes the series forward, so the nudge only lands after a quiet day.
  static Future<void> _armDailyReminders() async {
    const bodies = [
      "👀 Your wallets are looking quiet today. Did you forget to record any spending?",
      "💸 Spent anything today? Tap to log it before you forget where it went!",
      "🧾 A quick minute now saves a mystery later — log today's expenses!",
      "📊 Staying on top of your budget? Tap to add any transactions from today.",
    ];

    for (int day = 0; day < _windowDays; day++) {
      await NotificationService().scheduleLogReminder(
        id: NotificationService.dailyReminderIdBase + day,
        title: '💸 Forgot to record money?',
        body: bodies[day % bodies.length],
        when: _nextAt(_reminderHour, addDays: day),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Daily spending insight
  // ---------------------------------------------------------------------------

  /// Only the next occurrence is armed — there is no point projecting stale
  /// spending copy days into the future.
  static Future<void> _armInsight() async {
    final insight = await SpendingInsightService.computeInsight();
    if (insight == null) return;

    await NotificationService().scheduleInsight(
      id: NotificationService.insightIdBase,
      title: insight.title,
      body: insight.body,
      when: _nextAt(_insightHour),
    );
  }

  // ---------------------------------------------------------------------------
  // Subscription / EMI due reminders
  //
  // These are a natural fit: date, name and amount are all known in advance, so
  // the pre-composed body is never stale.
  // ---------------------------------------------------------------------------

  static Future<void> _armSubscriptionReminders() async {
    final box = await Hive.openBox<SubscriptionModel>(
        ExpenseProvider.subscriptionBoxName);

    var slot = 0;
    for (final sub in box.values) {
      if (slot >= _maxPerCollection) break;

      final due = _nextMonthlyOccurrence(
        sub.paymentDay,
        hour: sub.paymentHour,
        minute: sub.paymentMinute,
      );
      final label = sub.note.isNotEmpty ? sub.note : sub.category;

      await NotificationService().scheduleLogReminder(
        id: NotificationService.subscriptionIdBase + slot,
        title: '📅 Upcoming Subscription',
        body:
            'Your subscription for "$label" is due tomorrow on the ${sub.paymentDay}th.',
        // Nudge a day before the charge lands.
        when: due.subtract(const Duration(days: 1)),
      );
      slot++;
    }
  }

  static Future<void> _armEmiReminders() async {
    final box = await Hive.openBox<EmiModel>(ExpenseProvider.emiBoxName);

    var slot = 0;
    for (final emi in box.values) {
      if (slot >= _maxPerCollection) break;
      if (emi.monthsPaid >= emi.totalMonths) continue; // fully paid off

      final due = _nextMonthlyOccurrence(emi.paymentDay);
      await NotificationService().scheduleLogReminder(
        id: NotificationService.emiIdBase + slot,
        title: '📅 Upcoming EMI',
        body:
            'Your EMI for "${emi.itemName}" is due tomorrow on the ${emi.paymentDay}th.',
        when: due.subtract(const Duration(days: 1)),
      );
      slot++;
    }
  }

  /// Next time day-of-month [day] comes around at [hour]:[minute] local time.
  ///
  /// [day] is clamped to the length of the target month, so a subscription set
  /// to the 31st still fires in February.
  static DateTime _nextMonthlyOccurrence(int day,
      {int hour = 0, int minute = 0}) {
    final now = DateTime.now();

    final lastDayThisMonth = DateTime(now.year, now.month + 1, 0).day;
    final thisMonth = DateTime(now.year, now.month,
        day > lastDayThisMonth ? lastDayThisMonth : day, hour, minute);
    if (thisMonth.isAfter(now)) return thisMonth;

    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final lastDayNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    return DateTime(nextYear, nextMonth,
        day > lastDayNextMonth ? lastDayNextMonth : day, hour, minute);
  }
}
