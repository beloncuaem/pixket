import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/widgets/pixel/pixel_logo.dart';

/// Lưới A2 "Lens Orbit" đã duyệt ở cỡ brand 24×24. Sửa hình là test này đỏ.
const a2At24 = <String>[
  '........................',
  '.......*..........*.....',
  '....*...................',
  '..........kk.k......*...',
  '.......kkkkk.kkkk..***..',
  '......kkkk....kkkk..*...',
  '.....kkk........kkk.....',
  '..*...k....ff....kkk....',
  '....kk.....ff...........',
  '....kk...ffffffs.s.k....',
  '...kk....ffffff....kk...',
  '...kk....s.ff....s.kk...',
  '...kk...s..ff...s..kk..*',
  '.*.kkkk........s...kk...',
  '....kmmk.....s....kk....',
  '...kmmmk..ss......kk....',
  '...kkmmks........k......',
  '....kkkk........kkk.....',
  '......kkkk....kkkk......',
  '.......kkkk.kkkkk....*..',
  '..*.......k.kk..........',
  '........................',
  '............*.........*.',
  '........................',
];

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
      for (final n in [8, 16, 24, 32, 48, 96]) {
        final rows = buildLogoGrid(n);
        expect(rows, hasLength(n), reason: 'n = $n sai số hàng');
        for (final row in rows) {
          expect(row.length, n, reason: 'n = $n có hàng sai độ dài');
        }
      }
    });

    test('chỉ dùng ký tự đã định nghĩa trong lưới', () {
      const allowed = {'.', 'k', 's', 'f', 'm', '*'};
      for (final n in [16, 24, 32, 48]) {
        for (final char in buildLogoGrid(n).join().split('')) {
          expect(
            allowed.contains(char),
            isTrue,
            reason: 'n = $n có ký tự lạ "$char"',
          );
        }
      }
    });

    test('cỡ brand dựng lại đúng bản A2 đã duyệt', () {
      expect(buildLogoGrid(24), a2At24);
    });

    // Lưới 8 và 16 quá nhỏ để giữ đủ nét: đó là giới hạn đã biết của glyph bé,
    // app không vẽ logo ở hai cỡ này.
    test('giữ đủ vành, quỹ đạo, vì sao, hành tinh, sao ở cỡ dùng thật', () {
      for (final n in [24, 40, 48, 192]) {
        final rows = buildLogoGrid(n).join();
        for (final char in ['k', 's', 'f', 'm', '*']) {
          expect(rows.contains(char), isTrue, reason: 'n = $n mất nét "$char"');
        }
      }
    });

    test('mọi ô sao nằm ngoài vành, không đè vào ống kính', () {
      final rows = buildLogoGrid(24);
      for (var y = 0; y < 24; y++) {
        for (var x = 0; x < 24; x++) {
          if (rows[y][x] != '*') continue;
          final rho = math.sqrt(math.pow(x - 11.5, 2) + math.pow(y - 11.5, 2));
          expect(rho, greaterThan(8.8), reason: 'sao ô ($x,$y) đè vào vành');
        }
      }
    });
  });

  group('logoCellColor', () {
    test('ánh xạ đúng token của bảng màu', () {
      final palette = AppPalette.dark;
      expect(logoCellColor('k', palette, isDark: true), palette.ink);
      expect(logoCellColor('s', palette, isDark: true), palette.sky);
      expect(logoCellColor('f', palette, isDark: true), palette.butter);
      expect(logoCellColor('m', palette, isDark: true), palette.mint);
    });

    test('sao chỉ vẽ trên nền tối, nền sáng để trống', () {
      expect(
        logoCellColor('*', AppPalette.dark, isDark: true),
        AppPalette.dark.star,
      );
      expect(logoCellColor('*', AppPalette.light, isDark: false), isNull);
    });

    test('ký tự ngoài bảng không vẽ gì', () {
      expect(logoCellColor('z', AppPalette.light, isDark: false), isNull);
      expect(logoCellColor('.', AppPalette.light, isDark: false), isNull);
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
