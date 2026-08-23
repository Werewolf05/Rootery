import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'hydroponics_alerts_channel',
      'Hydroponics Alerts',
      channelDescription: 'Critical hydroponics telemetry and device alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> showDryingCompleteNotification(String cropType) async {
    await showNotification(
      id: 1,
      title: 'Batch Cycle Complete',
      body: 'Your $cropType batch reached harvest window.',
      payload: 'drying_complete',
    );
  }

  Future<void> showTemperatureAlert(double temp) async {
    await showNotification(
      id: 2,
      title: 'Temperature Alert',
      body:
          'Temperature is ${temp.toStringAsFixed(1)} C. Check climate control.',
      payload: 'temp_alert',
    );
  }

  Future<void> showLowStockAlert(String productName) async {
    await showNotification(
      id: 3,
      title: 'Low Stock Alert',
      body: '$productName is running low in stock',
      payload: 'low_stock',
    );
  }

  Future<void> showOrderUpdate(String orderId, String status) async {
    await showNotification(
      id: 4,
      title: 'Order Update',
      body: 'Order #$orderId is now $status',
      payload: 'order_$orderId',
    );
  }

  Future<void> showPhOutOfRangeAlert(double ph) async {
    await showNotification(
      id: 101,
      title: 'pH Out Of Range',
      body:
          'Measured pH is ${ph.toStringAsFixed(2)}. Target range is 5.5 to 6.8.',
      payload: 'alert_ph',
    );
  }

  Future<void> showTdsHighAlert(double tds) async {
    await showNotification(
      id: 102,
      title: 'TDS High',
      body:
          'TDS reached ${tds.toStringAsFixed(0)} ppm. Consider flushing the system.',
      payload: 'alert_tds',
    );
  }

  Future<void> showLowReservoirAlert(double levelPercent) async {
    await showNotification(
      id: 103,
      title: 'Reservoir Level Low',
      body:
          'Reservoir at ${levelPercent.toStringAsFixed(0)}%. Refill recommended.',
      payload: 'alert_reservoir',
    );
  }

  Future<void> showDeviceOfflineAlert(String deviceId) async {
    await showNotification(
      id: 104,
      title: 'Device Offline',
      body: '$deviceId has gone offline. Check power and Wi-Fi.',
      payload: 'alert_offline',
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
