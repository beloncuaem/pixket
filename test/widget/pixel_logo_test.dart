import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/widgets/pixel/pixel_logo.dart';

void main() {
  group('logoGridSize', () {
    test('làm tròn xuống bội số 8', () {
      expect(logoGridSize(24), 24);
      expect(logoGridSize(16), 16);
      expect(logoGridSize(25), 24);
      expect(logoGridSize(31), 24);
      expect(logoGridSize(32), 32);
    });

    test('không bao giờ nhỏ hơn 8', () {
      expect(logoGridSize(0), 8);
      expect(logoGridSize(7), 8);
      expect(logoGridSize(-12), 8);
    });
  });

  group('buildLogoGrid', () {
    test('đúng kích thước lưới đã khai báo', () {
      for (final n in [8, 16, 24, 32]) {
        final rows = buildLogoGrid(n);
        expect(rows, hasLength(n), reason: 'n = $n sai số hàng');
        for (final row in rows) {
          expect(row.length, n, reason: 'n = $n có hàng sai độ dài');
        }
      }
    });

    test('ống kính không tràn ra ngoài thân máy', () {
      for (final n in [8, 16, 24, 32]) {
        for (final simple in [false, true]) {
          final rows = buildLogoGrid(n, simple: simple);
          final y0 = (0.33 * n).round(), y1 = (0.75 * n).round();
          for (var y = 0; y < n; y++) {
            if (y >= y0 && y < y1) continue;
            // 'f' là gờ nhả chụp, cố ý nằm trên thân máy.
            final stray = rows[y].replaceAll('.', '').replaceAll('f', '');
            expect(
              stray,
              isEmpty,
              reason: 'n = $n simple=$simple có mực "$stray" ở hàng $y',
            );
          }
        }
      }
    });

    test('chỉ dùng ký tự đã định nghĩa trong lưới', () {
      const allowed = {
        '.',
        'k',
        'b',
        'f',
        'h',
        'g',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
      };
      for (final n in [16, 24, 32]) {
        for (final simple in [false, true]) {
          for (final char in buildLogoGrid(
            n,
            simple: simple,
          ).join().split('')) {
            expect(
              allowed.contains(char),
              isTrue,
              reason: 'n = $n simple=$simple có ký tự lạ "$char"',
            );
          }
        }
      }
    });

    test('bản simple bỏ gờ nhả chụp và ô ngắm', () {
      final full = buildLogoGrid(24).join().split('');
      final simple = buildLogoGrid(24, simple: true).join().split('');
      expect(simple.contains('f'), isFalse);
      expect(full.contains('f'), isTrue);
      // 'h' vừa là ô ngắm vừa là đồng tử, nên so số lượng: simple ít hơn đúng
      // bằng số ô ô ngắm đã bỏ.
      int count(List<String> cells, String char) =>
          cells.where((c) => c == char).length;
      expect(count(simple, 'h'), lessThan(count(full, 'h')));
    });

    // n = 16 quá nhỏ để giữ đủ sáu cung; đó là giới hạn đã biết của glyph nhỏ.
    test('đủ sáu cung iris ở cỡ brand 24', () {
      final rows = buildLogoGrid(24).join();
      for (final char in ['1', '2', '3', '4', '5', '6']) {
        expect(rows.contains(char), isTrue, reason: 'thiếu cung "$char"');
      }
    });
  });

  group('PixelLogo', () {
    Future<void> pump(WidgetTester tester, Widget logo) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: logo)),
        ),
      );
    }

    testWidgets('làm tròn size lẻ xuống bội số 8', (tester) async {
      await pump(tester, const PixelLogo(size: 25));
      expect(tester.takeException(), isNull);
      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(PixelLogo),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.width, 24);
      expect(box.height, 24);
    });

    testWidgets('vẽ được ở cả hai theme', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const Scaffold(body: Center(child: PixelLogo())),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$brightness ném lỗi');
        expect(find.byType(CustomPaint), findsWidgets);
      }
    });
  });
}
