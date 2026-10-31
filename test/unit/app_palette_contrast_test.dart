import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_palette.dart';

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

void main() {
  group('AppPalette contrast', () {
    for (final palette in [AppPalette.light, AppPalette.dark]) {
      final name = palette == AppPalette.light ? 'light' : 'dark';

      test('$name: ink trên canvas >= 4.5', () {
        expect(
          contrast(palette.ink, palette.canvas),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('$name: inkMuted trên canvas >= 4.5', () {
        expect(
          contrast(palette.inkMuted, palette.canvas),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('$name: inkMuted trên surface >= 4.5', () {
        expect(
          contrast(palette.inkMuted, palette.surface),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('$name: onAccent trên mỗi accent >= 4.5', () {
        for (final accent in [
          palette.mint,
          palette.butter,
          palette.peach,
          palette.sky,
          palette.rose,
        ]) {
          expect(contrast(palette.onAccent, accent), greaterThanOrEqualTo(4.5));
        }
      });
      test('$name: danger trên canvas >= 4.5', () {
        expect(
          contrast(palette.danger, palette.canvas),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('$name: feedInk trên feedPanel >= 4.5', () {
        expect(
          contrast(palette.feedInk, palette.feedPanel),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('$name: feedMuted trên feedPanel >= 4.5', () {
        expect(
          contrast(palette.feedMuted, palette.feedPanel),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    test('accentForCategory ổn định và nằm trong 5 accent', () {
      final a = AppPalette.light.accentForCategory('Ăn uống');
      final b = AppPalette.light.accentForCategory('Ăn uống');
      expect(a, b);
      final allowed = <Color>{
        AppPalette.light.mint,
        AppPalette.light.butter,
        AppPalette.light.peach,
        AppPalette.light.sky,
        AppPalette.light.rose,
      }.map((c) => c.toARGB32()).toSet();
      expect(allowed.contains(a.toARGB32()), isTrue);
    });

    test('priorityColor ánh xạ 0..3 đúng spec', () {
      expect(AppPalette.light.priorityColor(0), AppPalette.light.mint);
      expect(AppPalette.light.priorityColor(1), AppPalette.light.sky);
      expect(AppPalette.light.priorityColor(2), AppPalette.light.butter);
      expect(AppPalette.light.priorityColor(3), AppPalette.light.rose);
      expect(AppPalette.light.priorityColor(9), AppPalette.light.mint);
    });
  });
}
