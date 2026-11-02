/// Chính sách mật khẩu tập trung, thuần Dart, không import Flutter.
///
/// Một nguồn duy nhất cho màn đăng ký, màn đặt lại mật khẩu và
/// `AuthRepository.updatePassword`, để UI và client không lệch nhau.
class PasswordPolicy {
  const PasswordPolicy._();

  /// Supabase/GoTrue chỉ đòi 6, nhưng 6 ký tự không còn đủ cho dữ liệu tài
  /// chính cá nhân; 8 là sàn hợp lý mà không đẩy người dùng sang ghi giấy.
  static const int minimumLength = 8;

  static const String tooShortMessage =
      'Mật khẩu từ 8 ký tự trở lên. Hãy thêm chữ số hoặc ký tự đặc biệt.';

  /// Danh sách mật khẩu yếu hay gặp. So sánh không phân biệt hoa/thường sau
  /// khi lowercase, chặn được các biến thể phổ biến của 'password123'.
  static const List<String> _weakPasswords = [
    'password',
    'password1',
    'password123',
    '12345678',
    '123456789',
    'qwerty123',
    'abc123456',
    'letmein1',
    'welcome123',
    'chitieu123',
    'pixket123',
  ];

  /// Trả về message lỗi, hoặc null nếu mật khẩu đạt.
  static String? validate(String password) {
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (password.length < minimumLength) return tooShortMessage;
    if (_weakPasswords.contains(password.toLowerCase())) {
      return 'Mật khẩu quá phổ biến. Chọn mật khẩu khác.';
    }
    // '12345678' / 'aaaaaaaa' — toàn một ký tự hoặc toàn số tăng dần.
    if (_isSingleCharClass(password) || _isSequential(password)) {
      return 'Mật khẩu quá dễ đoán. Chọn mật khẩu khác.';
    }
    return null;
  }

  static bool _isSingleCharClass(String value) {
    final first = value[0];
    return value.split('').every((ch) => ch == first);
  }

  static bool _isSequential(String value) {
    final digitsOnly = RegExp(r'^\d+$').hasMatch(value);
    if (!digitsOnly) return false;
    var ascending = true;
    var descending = true;
    for (var i = 1; i < value.length; i++) {
      final delta = value.codeUnitAt(i) - value.codeUnitAt(i - 1);
      if (delta != 1) ascending = false;
      if (delta != -1) descending = false;
    }
    return ascending || descending;
  }
}
