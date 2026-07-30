import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static int _insightNotificationId = 1000;

  static const String logsChannelId = 'expense_tracker_logs';
  static const String insightsChannelId = 'spending_insights';

  /// Deterministic ID ranges for scheduled (AlarmManager-backed) notifications.
  ///
  /// Scheduling always overwrites the same ID rather than allocating a new one,
  /// so re-arming can never pile up duplicate alarms.
  static const int dailyReminderIdBase = 2000; // 2000..2006 (rolling 7 days)
  static const int dailyReminderWindowDays = 7;
  static const int insightIdBase = 2100; // 2100..2106
  static const int subscriptionIdBase = 3000; // 3000..3999
  static const int emiIdBase = 4000; // 4000..4999

  Future<void> init() async {
    // NOTE: the `timezone` database is deliberately NOT initialised. Alarms are
    // scheduled as absolute instants against tz.UTC (see [_toInstant]), which
    // needs no database, so the 445 KB tzf asset stays out of the bundle.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Channel for automated subscription/EMI logs
    const AndroidNotificationChannel logsChannel = AndroidNotificationChannel(
      logsChannelId,
      'Automated Logs',
      description: 'Notifications for automated subscription and EMI logs.',
      importance: Importance.high,
    );

    // Channel for spending insight notifications
    const AndroidNotificationChannel insightsChannel =
        AndroidNotificationChannel(
      insightsChannelId,
      'Spending Insights',
      description: 'Smart spending alerts and budget warnings.',
      importance: Importance.high,
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(logsChannel);
    await androidPlugin?.createNotificationChannel(insightsChannel);

    // Request notification permission for Android 13+
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> showNotification(
      {required String title, required String body}) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        logsChannelId,
        'Automated Logs',
        channelDescription:
            'Notifications for automated subscription and EMI logs.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      ),
    );

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> showInsightNotification(
      {required String title, required String body}) async {
    await _notificationsPlugin.show(
      id: _insightNotificationId,
      title: title,
      body: body,
      notificationDetails: _insightDetails,
    );
    // Wrap within 1000..1999 so this counter can never walk into the
    // deterministic IDs reserved for scheduled notifications below.
    _insightNotificationId = 1000 + ((_insightNotificationId + 1 - 1000) % 1000);
  }

  // ---------------------------------------------------------------------------
  // Scheduled notifications
  //
  // These hand the notification to the OS AlarmManager up front, so it is
  // delivered even when the app process has been swiped away or killed by OEM
  // battery management. Anything that relies on the Dart isolate being alive at
  // fire time (Workmanager, in-app timers) cannot make that guarantee.
  // ---------------------------------------------------------------------------

  static const NotificationDetails _logDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      logsChannelId,
      'Automated Logs',
      channelDescription:
          'Notifications for automated subscription and EMI logs.',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  static const NotificationDetails _insightDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      insightsChannelId,
      'Spending Insights',
      channelDescription: 'Smart spending alerts and budget warnings.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'spending insight',
    ),
  );

  /// Converts a local wall-clock [DateTime] into the equivalent absolute
  /// instant expressed in UTC.
  ///
  /// The plugin turns this into `epochMillis` for AlarmManager, so pinning the
  /// location to UTC schedules the correct moment without needing the device's
  /// IANA zone name (which the `timezone` package cannot determine on its own).
  /// This is also why [DateTimeComponents]-based repeats are deliberately not
  /// used — those re-derive wall-clock time in the supplied zone and would
  /// drift by the UTC offset.
  tz.TZDateTime _toInstant(DateTime localTime) =>
      tz.TZDateTime.from(localTime.toUtc(), tz.UTC);

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required NotificationDetails details,
  }) async {
    if (!when.isAfter(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _toInstant(when),
      notificationDetails: details,
      // Inexact deliberately: it needs no SCHEDULE_EXACT_ALARM/USE_EXACT_ALARM
      // permission (USE_EXACT_ALARM is audited by Play and is intended for
      // alarm-clock/calendar apps). allowWhileIdle still punches through Doze,
      // and these reminders do not need to-the-minute precision.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedules a reminder from the "Automated Logs" channel.
  Future<void> scheduleLogReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) =>
      _schedule(
        id: id,
        title: title,
        body: body,
        when: when,
        details: _logDetails,
      );

  /// Schedules a reminder from the "Spending Insights" channel.
  Future<void> scheduleInsight({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) =>
      _schedule(
        id: id,
        title: title,
        body: body,
        when: when,
        details: _insightDetails,
      );

  Future<void> cancel(int id) => _notificationsPlugin.cancel(id: id);

  Future<List<PendingNotificationRequest>> pendingNotifications() =>
      _notificationsPlugin.pendingNotificationRequests();
}
