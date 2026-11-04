import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'receipt_notifier_core.dart';

/// Nhánh trình duyệt: Web Notifications API. `flutter_local_notifications` trên
/// web không crash mà chỉ im lặng (spec Plan 2 mục 2), nên đây là **thêm tính
/// năng** chứ không phải sửa lỗi.
class WebReceiptNotifier extends ReceiptNotifier {
  const WebReceiptNotifier();

  /// Notification là API có sẵn của browser: không có kênh nào để khởi tạo.
  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermission() async {
    if (!_isSupported) return;
    // Không await lời hứa của browser: chip hỏi quyền của Chrome/Edge chỉ xong khi
    // người dùng bấm vào nó, và đo thật ở Chromium cho thấy nếu họ không bấm thì
    // `permission` vẫn `default` mãi — để `await` ở đây sẽ giữ onboarding làm con
    // tin, `completeOnboarding()` không chạy và app không bao giờ tới màn login.
    // `ignore()` vừa ném lỗi đi vừa cho Future hoàn thành ngay nên người dùng vẫn
    // thấy lời hỏi, chỉ là app không chờ câu trả lời.
    web.Notification.requestPermission().toDart.ignore();
  }

  @override
  Future<void> showBudgetAlert({
    required int threshold,
    required String monthLabel,
  }) async {
    // Quyền phải là `granted`: ở trạng thái `default` thì Notification bị browser
    // bỏ qua âm thầm, còn `denied` thì ném SecurityError.
    if (!_isSupported || web.Notification.permission != 'granted') return;
    web.Notification(
      budgetAlertTitle,
      web.NotificationOptions(body: budgetAlertBody(threshold, monthLabel)),
    );
  }

  /// Chế độ riêng tư của Safari và non-secure context không có `Notification`, mà
  /// dart2js không kiểm tra hộ: đụng vào property của undefined là TypeError. Hỏi
  /// một lần bằng try/catch để nền tảng thiếu API thành "không báo được", không
  /// thành lỗi lật màn hình ngân sách.
  bool get _isSupported {
    try {
      web.Notification.permission;
      return true;
    } catch (_) {
      return false;
    }
  }
}

ReceiptNotifier receiptNotifier = const WebReceiptNotifier();
