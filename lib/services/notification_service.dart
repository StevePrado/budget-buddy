import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification settings and request permissions on Android 13+
  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
      },
    );

    // Request permissions for Android 13+ (POST_NOTIFICATIONS)
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }

    _isInitialized = true;
  }

  /// Sends a test notification to verify device alerts
  Future<void> showTestNotification() async {
    await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_buddy_channel',
      'Budget Alerts & Reminders',
      channelDescription: 'Notifications for budget alerts and spending updates',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '💰 Budget Buddy Alert',
      body: 'Test successful! Local notifications are working on your device.',
      notificationDetails: details,
    );
  }

  /// Send an over-budget alert
  Future<void> showOverBudgetAlert({
    required String period,
    required double overAmount,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_alert_channel',
      'Budget Warning Alerts',
      channelDescription: 'Alerts when your spending exceeds the budget',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 1001,
      title: '⚠️ Over Budget Warning!',
      body:
          'You have exceeded your $period budget limit by ₱${overAmount.toStringAsFixed(2)}.',
      notificationDetails: details,
    );
  }

  /// Send an 80% caution alert (near budget limit)
  Future<void> showBudgetNearLimitAlert({
    required String period,
    required double percentUsed,
    required double remainingAmount,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_alert_channel',
      'Budget Warning Alerts',
      channelDescription: 'Alerts when your spending exceeds or nears the budget',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 1002,
      title: '🔔 Budget Caution ($period)',
      body:
          'You have used ${percentUsed.toStringAsFixed(1)}% of your budget. Only ₱${remainingAmount.toStringAsFixed(2)} left!',
      notificationDetails: details,
    );
  }
}
