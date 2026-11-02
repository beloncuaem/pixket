import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/utils/pixel_allocate.dart';

void main() {
  group('pixelFilledCells', () {
    test('clamp 0..cells', () {
      expect(pixelFilledCells(0, 10), 0);
      expect(pixelFilledCells(0.049, 10), 0);
      expect(pixelFilledCells(0.05, 10), 1);
      expect(pixelFilledCells(0.5, 10), 5);
      expect(pixelFilledCells(1, 10), 10);
      expect(pixelFilledCells(3, 10), 10);
      expect(pixelFilledCells(-2, 10), 0);
    });
    test('NaN và vô cùng không làm crash', () {
      expect(pixelFilledCells(double.nan, 10), 0);
      expect(pixelFilledCells(double.infinity, 10), 10);
    });
  });

  group('allocateCells', () {
    test('tổng phần bằng tổng ô khi sum > 0', () {
      expect(allocateCells([1, 1, 1], 10).reduce((a, b) => a + b), 10);
      expect(allocateCells([0.33, 0.33, 0.34], 24).reduce((a, b) => a + b), 24);
    });
    test('largest remainder ưu tiên phần dư lớn nhất, tie theo index nhỏ', () {
      expect(allocateCells([2, 1], 3), [2, 1]);
      expect(allocateCells([1, 1, 1], 5), [2, 2, 1]);
      expect(allocateCells([1, 1], 1), [1, 0]);
    });
    test('sum <= 0 trả toàn 0, không NaN', () {
      expect(allocateCells([0, 0, 0], 12), [0, 0, 0]);
      expect(allocateCells([], 12), isEmpty);
      expect(allocateCells([-1, -2], 5), [0, 0]);
    });
    test('một phần chiếm hết', () {
      expect(allocateCells([0, 7], 6), [0, 6]);
    });
  });

  group('sharePercent', () {
    test('total <= 0 trả 0%', () {
      expect(sharePercent(0, 0), '0%');
      expect(sharePercent(5, 0), '0%');
      expect(sharePercent(5, -1), '0%');
    });
    test('làm tròn không dấu phẩy', () {
      expect(sharePercent(50, 200), '25%');
      expect(sharePercent(1, 3), '33%');
      expect(sharePercent(2, 3), '67%');
      expect(sharePercent(3, 3), '100%');
    });
  });

  group('pickAxisIndices', () {
    test('count <= maxLabels lấy hết', () {
      expect(pickAxisIndices(3, 8), [0, 1, 2]);
      expect(pickAxisIndices(0, 8), isEmpty);
    });
    test('thưa dần và luôn gồm index cuối', () {
      final idx = pickAxisIndices(31, 6);
      expect(idx.length, lessThanOrEqualTo(6));
      expect(idx.last, 30);
      expect(idx.first, 0);
      for (var i = 1; i < idx.length; i++) {
        expect(idx[i] > idx[i - 1], isTrue);
      }
    });
  });

  group('pixelBarChartSemantics', () {
    test('tóm tắt đủ từng dòng cho screen reader', () {
      final s = pixelBarChartSemantics(
        [DateTime(2026, 11, 1), DateTime(2026, 11, 2)],
        [10000, 20000],
        ['10.000 đ', '20.000 đ'],
      );
      expect(s, contains('10.000 đ'));
      expect(s, contains('20.000 đ'));
      expect(s.split('\n').length, 2);
    });
    test('rỗng trả chuỗi trống', () {
      expect(pixelBarChartSemantics([], [], []), isEmpty);
    });
  });
}
