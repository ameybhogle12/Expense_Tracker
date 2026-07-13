import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static int _insightNotificationId = 1000;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Channel for automated subscription/EMI logs
    const AndroidNotificationChannel logsChannel = AndroidNotificationChannel(
      'expense_tracker_logs',
      'Automated Logs',
      description: 'Notifications for automated subscription and EMI logs.',
      importance: Importance.high,
    );

    // Channel for spending insight notifications
    const AndroidNotificationChannel insightsChannel = AndroidNotificationChannel(
      'spending_insights',
      'Spending Insights',
      description: 'Smart spending alerts and budget warnings.',
      importance: Importance.high,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(logsChannel);
    await androidPlugin?.createNotificationChannel(insightsChannel);

    // Request notification permission for Android 13+
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> showNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'expense_tracker_logs',
      'Automated Logs',
      channelDescription: 'Notifications for automated subscription and EMI logs.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> showInsightNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'spending_insights',
      'Spending Insights',
      channelDescription: 'Smart spending alerts and budget warnings.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'spending insight',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: _insightNotificationId++,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}

