import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/csv_builder.dart';
import '../models/expense.dart';
import 'expense_repository.dart';

/// Sao lưu khoản chi ra file CSV và mở share sheet.
class CsvExportService {
  CsvExportService([ExpenseRepository? repository])
    : _repository = repository ?? ExpenseRepository();

  static const int pageSize = 1000;

  final ExpenseRepository _repository;

  Future<List<Expense>> collectRows({DateTime? from, DateTime? to}) async {
    final all = <Expense>[];
    var offset = 0;
    while (true) {
      final page = await _repository.getExpenses(
        from: from,
        to: to,
        limit: pageSize,
        offset: offset,
      );
      all.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return all;
  }

  static String buildFileName(DateTime now) =>
      'piket_${DateFormat('yyyyMMdd_HHmm').format(now)}.csv';

  /// Ghi file vào thư mục tạm và trả đường dẫn.
  Future<String> exportFile({
    required List<Expense> rows,
    required Map<int, String> categoryNames,
    String? fileName,
  }) async {
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/${fileName ?? buildFileName(DateTime.now())}';
    final file = File(path);
    await file.writeAsString(
      CsvBuilder.buildCsv(expenses: rows, categoryNames: categoryNames),
      flush: true,
    );
    return file.path;
  }

  /// Trả về số dòng đã ghi; hữu ích cho thông báo sau khi xuất.
  Future<({String path, int rowCount})> exportAndShare({
    DateTime? from,
    DateTime? to,
    required Map<int, String> categoryNames,
  }) async {
    final rows = await collectRows(from: from, to: to);
    final path = await exportFile(rows: rows, categoryNames: categoryNames);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        subject: 'Bản sao kê Piket',
        text:
            '${rows.length} khoản chi (${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}).',
      ),
    );

    return (path: path, rowCount: rows.length);
  }
}
