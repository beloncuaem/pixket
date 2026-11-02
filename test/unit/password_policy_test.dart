import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/utils/password_policy.dart';

void main() {
  group('PasswordPolicy.validate', () {
    test('chấp nhận mật khẩu đạt chuẩn', () {
      expect(PasswordPolicy.validate('secret11'), isNull);
      expect(PasswordPolicy.validate('Cafe@2026x'), isNull);
      expect(PasswordPolicy.validate('dài hơn nữa thì càng tốt 123'), isNull);
    });

    test('rỗng và quá ngắn bị chặn', () {
      expect(PasswordPolicy.validate(''), 'Vui lòng nhập mật khẩu');
      expect(
        PasswordPolicy.validate('1234567'),
        PasswordPolicy.tooShortMessage,
        reason: 'sàn là 8 ký tự, không phải 6 của GoTrue',
      );
    });

    test('sàn độ dài là 8', () {
      expect(PasswordPolicy.minimumLength, 8);
      expect(PasswordPolicy.validate('a' * 7), isNotNull);
      expect(PasswordPolicy.validate('ab7!def2'), isNull);
    });

    test('từ chối mật khẩu phổ biến, kể cả viết hoa', () {
      expect(PasswordPolicy.validate('password123'), contains('quá phổ biến'));
      expect(PasswordPolicy.validate('Password123'), contains('quá phổ biến'));
      expect(PasswordPolicy.validate('Pixket123'), contains('quá phổ biến'));
    });

    test('từ chối chuỗi một ký tự và số tăng/giảm dần', () {
      expect(PasswordPolicy.validate('a' * 10), contains('dễ đoán'));
      expect(PasswordPolicy.validate('12345678'), isNotNull);
      expect(PasswordPolicy.validate('87654321'), isNotNull);
    });

    test('không chặn số không tuần tự hay chữ lẫn số', () {
      expect(PasswordPolicy.validate('13579113'), isNull);
      expect(PasswordPolicy.validate('abcd1234'), isNull);
    });
  });
}
