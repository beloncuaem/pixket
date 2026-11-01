import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/utils/csv_builder.dart';
import 'package:chi_tieu/data/models/expense.dart';

void main() {
  Expense build({
    String caption = 'Cà phê',
    double amount = 35000,
    int categoryId = 1,
    int priority = 0,
    DateTime? createdAt,
    String? imagePath,
  }) {
    return Expense(
      caption: caption,
      amount: amount,
      categoryId: categoryId,
      priority: priority,
      createdAt: createdAt ?? DateTime(2026, 5, 20, 8, 5),
      imagePath: imagePath,
    );
  }

  group('CsvBuilder.escapeField', () {
    test('leaves plain text untouched', () {
      expect(CsvBuilder.escapeField('Cà phê'), 'Cà phê');
      expect(CsvBuilder.escapeField(''), '');
    });

    test('quotes separators, quotes, and newlines', () {
      expect(CsvBuilder.escapeField('a,b'), '"a,b"');
      expect(CsvBuilder.escapeField('x"y'), '"x""y"');
      expect(CsvBuilder.escapeField('dòng 1\ndòng 2'), '"dòng 1\ndòng 2"');
      expect(CsvBuilder.escapeField('cr\r\nlf'), '"cr\r\nlf"');
    });
  });

  group('CsvBuilder.buildCsv', () {
    const names = {1: 'Ăn uống', 2: 'Nhà ở'};

    test('starts with a UTF-8 BOM then the header row', () {
      final csv = CsvBuilder.buildCsv(
        expenses: [build()],
        categoryNames: names,
      );
      expect(csv.startsWith(CsvBuilder.bom), isTrue);
      expect(
        csv.substring(CsvBuilder.bom.length).split('\r\n').first,
        'ngày,ghi chú,số tiền,danh mục,mức độ,ảnh',
      );
    });

    test('formats one data row with rounded amount and priority label', () {
      final csv = CsvBuilder.buildCsv(
        expenses: [build()],
        categoryNames: names,
      );
      final rows = csv.substring(CsvBuilder.bom.length).split('\r\n');
      expect(rows[1], '20/05/2026 08:05,Cà phê,35000,Ăn uống,Thiết yếu,');
      expect(rows.last, isEmpty, reason: 'CSV kết thúc bằng một dòng mới');
    });

    test('uses the category name map and falls back to "Khác"', () {
      expect(
        CsvBuilder.buildCsv(expenses: [build()], categoryNames: names),
        contains(',Ăn uống,'),
      );
      expect(
        CsvBuilder.buildCsv(
          expenses: [build(categoryId: 99)],
          categoryNames: names,
        ),
        contains(',Khác,'),
      );
      expect(
        CsvBuilder.buildCsv(
          expenses: [build(categoryId: 99)],
          categoryNames: const {},
        ),
        contains(',Khác,'),
      );
    });

    test('quotes a caption containing a comma', () {
      final csv = CsvBuilder.buildCsv(
        expenses: [build(caption: 'bún, chả')],
        categoryNames: names,
      );
      expect(csv, contains('"bún, chả"'));
    });

    test('writes the storage path of the receipt image', () {
      final csv = CsvBuilder.buildCsv(
        expenses: [build(imagePath: 'uuid-abc/receipt.jpg')],
        categoryNames: names,
      );
      expect(csv, contains('uuid-abc/receipt.jpg'));
    });

    test('empty list yields only the header', () {
      final csv = CsvBuilder.buildCsv(expenses: [], categoryNames: names);
      expect(
        csv,
        '${CsvBuilder.bom}ngày,ghi chú,số tiền,danh mục,mức độ,ảnh\r\n',
      );
    });

    test('handles 1000 rows without a size limit problem', () {
      final csv = CsvBuilder.buildCsv(
        expenses: List.generate(1000, (_) => build()),
        categoryNames: names,
      );
      expect(csv.split('\r\n').length, 1002);
    });
  });
}
