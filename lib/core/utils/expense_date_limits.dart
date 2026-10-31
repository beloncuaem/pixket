/// Giới hạn ngày giờ cho khoản chi: không tương lai, không quá 10 năm.
class ExpenseDateLimits {
  const ExpenseDateLimits._();

  static DateTime firstDate(DateTime now) =>
      DateTime(now.year - 10, now.month, now.day);

  static DateTime lastDate(DateTime now) => now;

  /// null khi hợp lệ; ngược lại là thông báo lỗi tiếng Việt.
  static String? validate(
    DateTime value,
    DateTime now, {
    Duration tolerance = const Duration(minutes: 1),
  }) {
    if (value.isAfter(now.add(tolerance))) {
      return 'Không thể ghi nhận khoản chi trong tương lai.';
    }
    if (value.isBefore(firstDate(now))) {
      return 'Khoản chi không thể cũ hơn 10 năm.';
    }
    return null;
  }

  static DateTime combine(DateTime date, int hour, int minute) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  static DateTime clampToAllowedRange(
    DateTime value,
    DateTime now, {
    Duration tolerance = const Duration(minutes: 1),
  }) {
    if (value.isAfter(now)) return now;
    if (value.isBefore(firstDate(now))) return firstDate(now);
    return value;
  }
}
