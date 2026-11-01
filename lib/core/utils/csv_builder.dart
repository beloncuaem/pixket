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

  static String escapeField(String value) {
    final mustQuote =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!mustQuote) return value;
    return '"${value.replaceAll('"', '""')}"';
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
