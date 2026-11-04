import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/platform/receipt_notifier.dart';
import 'package:pixket/providers/budget_provider.dart';

/// Notifier giả: ghi lại đúng cặp tham số seam nhận được, vì thứ duy nhất đáng
/// khoá ở lớp này là *lựa chọn mốc + lời gọi*, không phải nội dung thông báo.
class _RecordingNotifier implements ReceiptNotifier {
  final calls = <(int, String)>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> showBudgetAlert({
    required int threshold,
    required String monthLabel,
  }) async {
    calls.add((threshold, monthLabel));
  }
}

/// Chạy vòng ngưỡng với repository giả. `markSent` kiểm tra thứ tự: báo xong mới
/// được đánh dấu, vì đảo lại thì một lần báo lỗi sẽ nuốt mốc đó tới tận tháng sau.
Future<List<(int, String)>> _run(
  double usageRatio, {
  Set<int> alreadySent = const {},
}) async {
  final notifier = _RecordingNotifier();
  final marked = <int>[];
  await notifyBudgetCrossing(
    notifier,
    usageRatio: usageRatio,
    monthLabel: '11/2026',
    hasSent: (threshold) async => alreadySent.contains(threshold),
    markSent: (threshold) async {
      if (notifier.calls.length != marked.length + 1) {
        throw StateError('markSent($threshold) chạy trước showBudgetAlert');
      }
      marked.add(threshold);
    },
  );
  return notifier.calls;
}

void main() {
  test('vượt 92% thì báo đúng hai mốc 80 và 90, bỏ mốc 100', () async {
    expect(await _run(0.92), [(80, '11/2026'), (90, '11/2026')]);
  });

  test('đúng 80% vẫn tính là vượt mốc', () async {
    expect(await _run(0.8), [(80, '11/2026')]);
  });

  test('79% thì không gửi gì', () async {
    expect(await _run(0.79), isEmpty);
  });

  test('mốc đã gửi trong tháng này thì bỏ, mốc khác vẫn gửi', () async {
    // 1.0 vượt cả ba mốc nên hàng đợi là [80, 90, 100]; 80 đã gửi thì còn hai cái
    // sau. Một usage thấp hơn (0.95) sẽ loại luôn mốc 100 và không kiểm chứng được
    // gì cho vế "mốc khác vẫn gửi".
    expect(await _run(1.0, alreadySent: {80}), [
      (90, '11/2026'),
      (100, '11/2026'),
    ]);
  });

  test('100% gửi cả ba mốc theo thứ tự tăng dần', () async {
    expect(await _run(1.0), [
      (80, '11/2026'),
      (90, '11/2026'),
      (100, '11/2026'),
    ]);
  });

  test('chuỗi tiếng Việt của cảnh báo giữ nguyên bản cũ', () {
    // `notification_service.dart` cũ-hardcode hai chuỗi này ở :50-51; seam phải
    // trả đúng từng ký tự vì người dùng đã quen nội dung đó.
    expect(budgetAlertTitle, 'Cảnh báo ngân sách');
    expect(
      budgetAlertBody(90, '11/2026'),
      'Bạn đã sử dụng 90% ngân sách tháng 11/2026.',
    );
  });
}
