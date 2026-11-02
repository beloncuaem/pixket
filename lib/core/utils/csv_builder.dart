import 'package:intl/intl.dart';

import '../../data/models/expense.dart';

/// Dựng nội dung CSV theo RFC 4180, không chạm mạng hay Flutter.
class CsvBuilder {
  const CsvBuilder._();

  /// Excel trên Windows cần BOM để đọc đúng tiếng Việt.
  static const String bom = '\uFEFF';

  static const List<String> headers = [
    'ngày',
    'ghi chú',
    'số tiền',
    'danh mục',
    'mức độ',
    'ảnh',
  ];

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Ký tự mở đầu mà Excel/Google Sheets hiểu là công thức hoặc DDE.
  /// `caption` là chuỗi người dùng nhập tự do nên ô bắt đầu bằng một trong
  /// các ký tự này phải bị ép về kiểu text khi mở file.
  static const String _formulaTriggerChars = '=+-@\t\r';

  static String escapeField(String value) {
    final isFormula =
        value.isNotEmpty && _formulaTriggerChars.contains(value[0]);
    // Prefix ' khiến bảng tính coi ô là chuỗi literal, không tính công thức.
    final safe = isFormula ? "'$value" : value;

    // ';' cũng phải quote: ở locale dùng ';' làm phân tách, ô không quote
    // sẽ bị tách thành nhiều cột.
    final mustQuote =
        isFormula ||
        safe.contains(',') ||
        safe.contains(';') ||
        safe.contains('"') ||
        safe.contains('\n') ||
        safe.contains('\r');
    if (!mustQuote) return safe;
    return '"${safe.replaceAll('"', '""')}"';
  }

  static String buildCsv({
    required List<Expense> expenses,
    required Map<int, String> categoryNames,
  }) {
    final rows = <List<String>>[
      headers,
      for (final expense in expenses)
        [
          _dateFormat.format(expense.createdAt),
          expense.caption,
          expense.amount.round().toString(),
          categoryNames[expense.categoryId] ?? 'Khác',
          expense.priorityLabel,
          expense.imagePath ?? '',
        ],
    ];

    final buffer = StringBuffer(bom);
    buffer.writeAll(rows.map((row) => row.map(escapeField).join(',')), '\r\n');
    buffer.write('\r\n');
    return buffer.toString();
  }
}
