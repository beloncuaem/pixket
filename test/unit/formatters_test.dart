import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/utils/amount_input_formatter.dart';
import 'package:chi_tieu/core/utils/currency_formatter.dart';
import 'package:chi_tieu/core/utils/date_formatter.dart';
import 'package:chi_tieu/core/utils/expense_date_limits.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('Formats VND currency properly for various values', () {
      expect(CurrencyFormatter.format(35000), '35.000\u00a0đ');
      expect(CurrencyFormatter.format(1500000), '1.500.000\u00a0đ');
      expect(CurrencyFormatter.format(0), '0\u00a0đ');
      expect(CurrencyFormatter.format(100), '100\u00a0đ');
      expect(CurrencyFormatter.format(999999999), '999.999.999\u00a0đ');
    });
  });

  group('DateFormatter Tests', () {
    test('Formats today as "Hôm nay"', () {
      final now = DateTime.now();
      expect(DateFormatter.formatDate(now), 'Hôm nay');
    });

    test('Formats yesterday as "Hôm qua"', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1, 10, 0);
      expect(DateFormatter.formatDate(yesterday), 'Hôm qua');
    });

    test('Formats older date as dd/MM/yyyy', () {
      final pastDate = DateTime(2025, 5, 20);
      expect(DateFormatter.formatDate(pastDate), '20/05/2025');
    });

    test('Formats time as HH:mm', () {
      final time = DateTime(2026, 10, 14, 8, 5);
      expect(DateFormatter.formatTime(time), '08:05');

      final evening = DateTime(2026, 10, 14, 21, 45);
      expect(DateFormatter.formatTime(evening), '21:45');
    });
  });

  group('CurrencyFormatter.parseInput', () {
    test('reads grouped and punctuated VND text', () {
      expect(CurrencyFormatter.parseInput('1.500.000'), 1500000);
      expect(CurrencyFormatter.parseInput('1,500,000'), 1500000);
      expect(CurrencyFormatter.parseInput('  35 000 ₫'), 35000);
      expect(CurrencyFormatter.parseInput('0'), 0);
    });

    test('returns null when no digit exists', () {
      expect(CurrencyFormatter.parseInput(''), isNull);
      expect(CurrencyFormatter.parseInput('abc'), isNull);
      expect(CurrencyFormatter.parseInput('   '), isNull);
    });

    test('toEditableText seeds controllers with grouped digits', () {
      expect(CurrencyFormatter.toEditableText(1500000), '1.500.000');
      expect(CurrencyFormatter.toEditableText(35000.6), '35.001');
      expect(CurrencyFormatter.toEditableText(0), '');
    });
  });

  group('ThousandsSeparatorInputFormatter', () {
    const formatter = ThousandsSeparatorInputFormatter();

    TextEditingValue edit(String from, String to, {int? cursor}) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: from,
          selection: TextSelection.collapsed(offset: from.length),
        ),
        TextEditingValue(
          text: to,
          selection: TextSelection.collapsed(offset: cursor ?? to.length),
        ),
      );
    }

    test('groups every three digits', () {
      expect(edit('', '3').text, '3');
      expect(edit('35', '35000').text, '35.000');
      expect(edit('150000', '1500000').text, '1.500.000');
    });

    test('drops non digits pasted from elsewhere', () {
      expect(edit('', '1,234,567 đ').text, '1.234.567');
    });

    test('strips leading zeros', () {
      expect(edit('', '007').text, '7');
      expect(edit('0', '').text, '');
    });

    test('refuses more than maxDigits', () {
      final result = edit('123.456.789.012', '123.456.789.0123');
      expect(result.text, '123.456.789.012');
    });

    test('reformats when appending a digit at the end', () {
      final result = edit('35.000', '35.0001');
      expect(result.text, '350.001');
      expect(result.selection.extentOffset, result.text.length);
    });

    test('keeps the caret in place when typing in the middle', () {
      // '35.000' + chen '0' ngay sau ky tu dau -> '305.000', con tro sau so 3.
      final result = edit('35.000', '305.000', cursor: 3);
      expect(result.text, '305.000');
      expect(result.selection.extentOffset, 3);
    });

    test('static helpers round-trip digit counting', () {
      expect(
        ThousandsSeparatorInputFormatter.groupDigits('1234567'),
        '1.234.567',
      );
      expect(
        ThousandsSeparatorInputFormatter.countDigitsBefore('1.234.5', 6),
        4,
      );
      expect(
        // '1.234.567': sau chu so thu 4 ('4') la offset 5, ke do dau cham.
        ThousandsSeparatorInputFormatter.offsetAfterDigitCount('1.234.567', 4),
        5,
      );
    });
  });

  group('ExpenseDateLimits', () {
    final now = DateTime(2026, 10, 26, 14, 30);

    test('firstDate is ten years back', () {
      expect(ExpenseDateLimits.firstDate(now), DateTime(2016, 10, 26));
    });

    test('lastDate is now', () {
      expect(ExpenseDateLimits.lastDate(now), now);
    });

    test('future beyond one minute tolerance is rejected', () {
      expect(
        ExpenseDateLimits.validate(now.add(const Duration(seconds: 30)), now),
        isNull,
      );
      expect(
        ExpenseDateLimits.validate(now.add(const Duration(minutes: 5)), now),
        'Không thể ghi nhận khoản chi trong tương lai.',
      );
    });

    test('dates before firstDate are rejected', () {
      expect(
        ExpenseDateLimits.validate(DateTime(2000, 1, 1), now),
        'Khoản chi không thể cũ hơn 10 năm.',
      );
    });

    test('combine keeps the calendar day but swaps the clock', () {
      expect(
        ExpenseDateLimits.combine(DateTime(2026, 5, 20, 9, 5), 21, 45),
        DateTime(2026, 5, 20, 21, 45),
      );
    });

    test('clamp pulls an out-of-range value back inside', () {
      expect(
        ExpenseDateLimits.clampToAllowedRange(
          now.add(const Duration(hours: 2)),
          now,
        ),
        now,
      );
      expect(
        ExpenseDateLimits.clampToAllowedRange(DateTime(1999, 1, 1), now),
        ExpenseDateLimits.firstDate(now),
      );
    });
  });
}
