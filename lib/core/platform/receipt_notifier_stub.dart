import 'receipt_notifier_core.dart';

ReceiptNotifier receiptNotifier = const _UnsupportedReceiptNotifier();

/// Nền tảng không có plugin notification lẫn Web Notifications: nói thẳng bằng
/// `UnsupportedError` thay vì im lặng, vì im lặng ở đây nghĩa là người dùng không
/// bao giờ nhận được cảnh báo vượt ngân sách.
class _UnsupportedReceiptNotifier extends ReceiptNotifier {
  const _UnsupportedReceiptNotifier();

  Never _fail() => throw UnsupportedError(
    'Pixket chưa gửi được cảnh báo trên nền tảng này.',
  );

  @override
  Future<void> initialize() => _fail();

  @override
  Future<void> requestPermission() => _fail();

  @override
  Future<void> showBudgetAlert({
    required int threshold,
    required String monthLabel,
  }) => _fail();
}
