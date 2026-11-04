/// Nơi gửi cảnh báo ngân sách. Mỗi nền tảng báo hiệu một kiểu — Android/iOS dùng
/// plugin notification, trình duyệt dùng Web Notifications, nền tảng không có cả
/// hai thì nói thẳng — nên code chung không được import plugin nào (R3 trong
/// `test/unit/web_platform_boundary_test.dart`).
abstract class ReceiptNotifier {
  const ReceiptNotifier();

  /// Chuẩn bị kênh báo hiệu, chạy một lần lúc boot.
  Future<void> initialize();

  /// Hỏi người dùng quyền hiển thị cảnh báo.
  Future<void> requestPermission();

  /// Báo một mốc ngưỡng đã vượt.
  Future<void> showBudgetAlert({
    required int threshold,
    required String monthLabel,
  });
}

/// Hai chuỗi này giữ nguyên văn từ `notification_service.dart` cũ; đặt cạnh khai
/// báo để hai nhánh `_io` và `_web` không có hai bản sao tiếng Việt drift nhau.
const String budgetAlertTitle = 'Cảnh báo ngân sách';

String budgetAlertBody(int threshold, String monthLabel) =>
    'Bạn đã sử dụng $threshold% ngân sách tháng $monthLabel.';
