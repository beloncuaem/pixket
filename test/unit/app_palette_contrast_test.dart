import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_palette.dart';

// Color.r/.g/.b trả double 0.0-1.0 trên Flutter 3.47 (đã đo), nên nhân 255 trước.
double luminance(Color c) {
  double f(int channel) {
    final s = channel / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * f((c.r * 255).round()) +
      0.7152 * f((c.g * 255).round()) +
      0.0722 * f((c.b * 255).round());
}

/// WCAG 2.1: (L_sang + 0.05) / (L_toi + 0.05).
double contrast(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

const _textMin = 4.5;
const _nonTextMin = 3.0;

String _bgName(AppPalette p, Color bg) => switch (bg) {
  _ when bg == p.canvas => 'canvas',
  _ when bg == p.surface => 'surface',
  _ => 'surfaceAlt',
};

void main() {
  group('Chữ và nền — WCAG 1.4.3 (>= 4.5)', () {
    for (final palette in [AppPalette.light, AppPalette.dark]) {
      final name = palette == AppPalette.light ? 'light' : 'dark';

      for (final bg in [palette.canvas, palette.surface, palette.surfaceAlt]) {
        final bgName = _bgName(palette, bg);

        test('$name: ink và inkMuted trên $bgName', () {
          expect(contrast(palette.ink, bg), greaterThanOrEqualTo(_textMin));
          expect(contrast(palette.inkMuted, bg), greaterThanOrEqualTo(_textMin));
        });

        test('$name: cả 6 accentInk trên $bgName', () {
          for (final ink in palette.accentInks) {
            expect(contrast(ink, bg), greaterThanOrEqualTo(_textMin));
          }
        });

        test('$name: danger và success trên $bgName', () {
          expect(contrast(palette.danger, bg), greaterThanOrEqualTo(_textMin));
          expect(contrast(palette.success, bg), greaterThanOrEqualTo(_textMin));
        });
      }

      test('$name: onAccent trên cả 6 accent', () {
        expect(palette.accents.length, 6);
        for (final accent in palette.accents) {
          expect(contrast(palette.onAccent, accent), greaterThanOrEqualTo(_textMin));
        }
      });

      test('$name: feedInk và feedMuted trên feedPanel', () {
        expect(
          contrast(palette.feedInk, palette.feedPanel),
          greaterThanOrEqualTo(_textMin),
        );
        expect(
          contrast(palette.feedMuted, palette.feedPanel),
          greaterThanOrEqualTo(_textMin),
        );
      });
    }
  });

  group('Khối và viền — WCAG 1.4.11 (>= 3.0)', () {
    for (final palette in [AppPalette.light, AppPalette.dark]) {
      final name = palette == AppPalette.light ? 'light' : 'dark';

      test('$name: mintStrong là khối/viền nên chỉ cần 3.0', () {
        for (final bg in [palette.canvas, palette.surface, palette.surfaceAlt]) {
          expect(
            contrast(palette.mintStrong, bg),
            greaterThanOrEqualTo(_nonTextMin),
            reason: _bgName(palette, bg),
          );
        }
        // Chữ đặt trên khối mintStrong vẫn phải đạt 4.5.
        expect(
          contrast(palette.onAccent, palette.mintStrong),
          greaterThanOrEqualTo(_textMin),
        );
      });

      test('$name: lineStrong tách khối khỏi canvas', () {
        expect(
          contrast(palette.lineStrong, palette.canvas),
          greaterThanOrEqualTo(_nonTextMin),
        );
      });
    }

    test('dark: cả 6 bright accent đạt 3.0 trên canvas nên dùng làm khối được', () {
      for (final accent in AppPalette.dark.accents) {
        expect(contrast(accent, AppPalette.dark.canvas), greaterThanOrEqualTo(_nonTextMin));
      }
    });
  });

  group('Hai ngoại lệ đã biết của spec §12 — khoá lại để không trôi', () {
    test('light: bright accent dưới 3.0 trên canvas nên khối bắt buộc viền ink', () {
      for (final accent in AppPalette.light.accents) {
        expect(contrast(accent, AppPalette.light.canvas), lessThan(_nonTextMin));
      }
      // Viền ink là thứ gánh tương phản phi-text cho khối ở theme kem.
      expect(
        contrast(AppPalette.light.line, AppPalette.light.canvas),
        greaterThanOrEqualTo(_nonTextMin),
      );
    });

    test('dark: rose bright trượt 4.5 trên surface nên chữ đỏ phải dùng roseInk', () {
      expect(
        contrast(AppPalette.dark.rose, AppPalette.dark.surface),
        lessThan(_textMin),
      );
      expect(
        contrast(AppPalette.dark.roseInk, AppPalette.dark.surface),
        greaterThanOrEqualTo(_textMin),
      );
    });
  });

  group('Cấu trúc dải Nyan Cat', () {
    test('6 accent, light và dark không còn dùng chung một bảng', () {
      expect(AppPalette.light.accents.length, 6);
      expect(AppPalette.dark.accents.length, 6);
      expect(AppPalette.light.accentInks.length, 6);
      expect(AppPalette.dark.accentInks.length, 6);
      expect(
        AppPalette.light.accents.map((c) => c.toARGB32()),
        isNot(equals(AppPalette.dark.accents.map((c) => c.toARGB32()))),
      );
    });

    test('accentForCategory ổn định và nằm trong 6 accent', () {
      final a = AppPalette.light.accentForCategory('Ăn uống');
      final b = AppPalette.light.accentForCategory('Ăn uống');
      expect(a, b);
      final allowed = AppPalette.light.accents.map((c) => c.toARGB32()).toSet();
      expect(allowed.contains(a.toARGB32()), isTrue);
    });

    test('priorityColor ánh xạ 0..3 theo dải lục -> đỏ', () {
      final light = AppPalette.light;
      expect(light.priorityColor(0), light.mint);
      expect(light.priorityColor(1), light.sky);
      expect(light.priorityColor(2), light.butter);
      expect(light.priorityColor(3), light.rose);
      expect(light.priorityColor(9), light.mint);
      expect(light.priorityColor(-1), light.mint);
    });

    test('priorityInk khớp priorityColor', () {
      final light = AppPalette.light;
      expect(light.priorityInk(0), light.mintInk);
      expect(light.priorityInk(1), light.skyInk);
      expect(light.priorityInk(2), light.butterInk);
      expect(light.priorityInk(3), light.roseInk);
      expect(light.priorityInk(9), light.mintInk);
    });

    test('sao chỉ vẽ ở theme tối', () {
      expect(AppPalette.dark.star, const Color(0xFFFFFFFF));
      expect(
        contrast(AppPalette.dark.star, AppPalette.dark.canvas),
        greaterThanOrEqualTo(_nonTextMin),
      );
    });

    test('lerp và copyWith mang đủ violet, violetInk, star', () {
      final mixed = AppPalette.light.lerp(AppPalette.dark, 0.5);
      expect(mixed.violet, isNotNull);
      expect(mixed.violetInk, isNotNull);
      expect(mixed.star, isNotNull);
      expect(
        AppPalette.light.copyWith(violet: AppPalette.dark.violet).violet,
        AppPalette.dark.violet,
      );
    });
  });
}
