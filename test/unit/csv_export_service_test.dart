import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/utils/csv_builder.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/repositories/csv_export_service.dart';
import 'package:chi_tieu/data/repositories/expense_repository.dart';

class _PagedRepo extends ExpenseRepository {
  _PagedRepo(this.pages);

  /// Mỗi phần tử là một trang trả về theo thứ tự offset.
  final List<List<Expense>> pages;
  final List<int?> seenOffsets = [];
  final List<int?> seenLimits = [];

  @override
  Future<List<Expense>> getExpenses({
    DateTime? from,
    DateTime? to,
    String? search,
    int? categoryId,
    int? priority,
    double? minAmount,
    double? maxAmount,
    int? limit,
    int? offset,
  }) async {
    seenOffsets.add(offset);
    seenLimits.add(limit);
    final index = seenOffsets.length - 1;
    return index < pages.length ? pages[index] : <Expense>[];
  }
}

Expense _row() => Expense(
  caption: 'Cà phê',
  amount: 25000,
  categoryId: 1,
  createdAt: DateTime(2026, 5, 20, 8),
);

void main() {
  group('CsvExportService.collectRows', () {
    test('stops as soon as a page is short', () async {
      final repo = _PagedRepo([
        List.generate(1000, (_) => _row()),
        List.generate(250, (_) => _row()),
      ]);
      final service = CsvExportService(repo);

      final rows = await service.collectRows();

      expect(rows.length, 1250);
      expect(repo.seenLimits, [1000, 1000]);
      expect(repo.seenOffsets, [0, 1000]);
    });

    test('single short page means a single query', () async {
      final repo = _PagedRepo([List.generate(12, (_) => _row())]);
      final service = CsvExportService(repo);

      final rows = await service.collectRows(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31),
      );

      expect(rows.length, 12);
      expect(repo.seenOffsets, [0]);
    });

    test('exact multiple of pageSize still terminates', () async {
      final repo = _PagedRepo([
        List.generate(1000, (_) => _row()),
        <Expense>[],
      ]);
      final service = CsvExportService(repo);

      final rows = await service.collectRows();

      expect(rows.length, 1000);
      expect(repo.seenOffsets, [0, 1000]);
    });
  });

  group('CsvExportService.buildFileName', () {
    test('embeds the export timestamp', () {
      expect(
        CsvExportService.buildFileName(DateTime(2026, 11, 1, 9, 4)),
        'piket_20261101_0904.csv',
      );
    });

    test('csv text written for rows carries BOM and header', () {
      final csv = CsvBuilder.buildCsv(
        expenses: [_row()],
        categoryNames: const {1: 'Ăn uống'},
      );
      expect(csv, startsWith(CsvBuilder.bom));
      expect(csv, contains('Ăn uống'));
    });
  });
}
