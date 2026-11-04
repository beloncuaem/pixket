import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'receipt_notifier_core.dart';

/// Nhánh mobile: dời nguyên văn từ `NotificationService`, giữ cả channel
/// `budget_alerts` lẫn hai chuỗi tiếng Việt để người dùng không thấy tin nhắn đổi
/// giọng chỉ vì app đổi cấu trúc.
class IoReceiptNotifier extends ReceiptNotifier {
  IoReceiptNotifier();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _isInitialized = true;
  }

  @override
  Future<void> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> showBudgetAlert({
    required int threshold,
    required String monthLabel,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        budgetAlertTitle,
        channelDescription: 'Thông báo khi mức chi vượt ngưỡng ngân sách',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    // `id` là threshold: ba mốc 80/90/100 thay thế nhau trong khay thông báo chứ
    // không chồng thành ba tin giống nhau.
    await _plugin.show(
      threshold,
      budgetAlertTitle,
      budgetAlertBody(threshold, monthLabel),
      details,
    );
  }
}

ReceiptNotifier receiptNotifier = IoReceiptNotifier();
