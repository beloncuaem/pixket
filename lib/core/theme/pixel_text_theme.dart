import 'package:flutter/material.dart';

import 'app_palette.dart';

const String pixelFontFamily = 'VT323';
const String bodyFontFamily = 'BeVietnamPro';

FontWeight _fontWeightFor(double weight) {
  if (weight >= 700) return FontWeight.w700;
  if (weight >= 600) return FontWeight.w600;
  if (weight >= 500) return FontWeight.w500;
  return FontWeight.w400;
}

TextStyle _body(
  AppPalette palette, {
  required double size,
  required double weight,
  double height = 1.5,
  Color? color,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: size,
    // Be Vietnam Pro bundle gồm các weight tĩnh, nên fontWeight mới là khóa
    // chọn asset; fontVariations giữ lại để sau này đổi sang font variable.
    fontWeight: _fontWeightFor(weight),
    fontVariations: [FontVariation('wght', weight)],
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? palette.ink,
  );
}

TextStyle _pixel(
  AppPalette palette, {
  required double size,
  Color? color,
  double letterSpacing = 0.6,
}) {
  return TextStyle(
    fontFamily: pixelFontFamily,
    fontSize: size,
    height: 1.05,
    letterSpacing: letterSpacing,
    color: color ?? palette.ink,
  );
}

/// `TextTheme` của giao diện Pixel: chữ số/tiêu đề dùng VT323, nội dung dùng
/// Be Vietnam Pro. Mỗi style đã mang màu từ palette nên không gọi
/// `TextTheme.apply` (nó sẽ ghi đè màu muted riêng của từng style).
TextTheme pixelTextTheme(AppPalette palette) {
  final label = _pixel(palette, size: 17, letterSpacing: 0.9);
  return TextTheme(
    displayLarge: _pixel(palette, size: 48),
    displayMedium: _pixel(palette, size: 40),
    displaySmall: _pixel(palette, size: 34),
    headlineMedium: _pixel(palette, size: 30),
    headlineSmall: _pixel(palette, size: 26),
    titleLarge: _pixel(palette, size: 28),
    titleMedium: _pixel(palette, size: 22),
    titleSmall: label,
    labelLarge: _body(palette, size: 15, weight: 600, height: 1.2),
    labelMedium: _body(palette, size: 13, weight: 500, height: 1.2),
    labelSmall: _body(palette, size: 12, weight: 500, height: 1.2),
    bodyLarge: _body(palette, size: 16, weight: 400),
    bodyMedium: _body(palette, size: 14, weight: 400),
    bodySmall: _body(palette, size: 13, weight: 400, color: palette.inkMuted),
  );
}
