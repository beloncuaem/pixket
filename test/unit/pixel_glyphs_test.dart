import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/icons/pixel_glyph_data.dart';
import 'package:pixket/core/navigation/app_section.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/utils/icon_helper.dart';
import 'package:pixket/widgets/pixel/pixel_glyph.dart';

void main() {
  test('pixelGlyphValidationError bắt đúng lỗi', () {
    expect(
      pixelGlyphValidationError('a', PixelGlyphData.all['label']!),
      isEmpty,
    );
    expect(
      pixelGlyphValidationError('bad', List.filled(15, '.' * 16)),
      contains('16 hàng'),
    );
    expect(
      pixelGlyphValidationError('bad', List.filled(16, '.' * 15)),
      contains('16 ký tự'),
    );
    expect(
      pixelGlyphValidationError('bad', [
        for (var i = 0; i < 15; i++) '.' * 16,
        'x' * 16,
      ]),
      contains('ký tự không hợp lệ'),
    );
  });

  test('mọi glyph hợp lệ 16x16', () {
    for (final entry in PixelGlyphData.all.entries) {
      expect(
        pixelGlyphValidationError(entry.key, entry.value),
        isEmpty,
        reason: 'glyph ${entry.key} không hợp lệ',
      );
    }
  });

  const navGlyphs = [
    'menu',
    'close',
    'back',
    'chevronRight',
    'chevronDown',
    'plus',
    'minus',
    'check',
    'edit',
    'trash',
    'search',
    'filter',
    'calendar',
    'clock',
    'refresh',
    'undo',
    'eye',
    'eyeOff',
    'mail',
    'lock',
    'logout',
    'user',
    'sun',
    'moon',
    'alert',
    'info',
    'settings',
    'cloud',
    'cloudOff',
    'grid',
    'share',
    'download',
    'sparkle',
    'camera',
    'chart',
    'tag',
  ];

  test('có glyph cho nhóm điều hướng và UI', () {
    for (final key in navGlyphs) {
      expect(PixelGlyphData.rowsOf(key), isNotNull, reason: 'thiếu glyph $key');
      expect(
        pixelGlyphValidationError(key, PixelGlyphData.rowsOf(key)!),
        isEmpty,
      );
    }
  });

  test('có glyph cho toàn bộ khóa danh mục', () {
    for (final key in IconHelper.availableIcons) {
      expect(PixelGlyphData.rowsOf(key), isNotNull, reason: 'thiếu glyph $key');
    }
  });

  test('có glyph fallback', () {
    expect(PixelGlyphData.rowsOf(PixelGlyphData.fallbackKey), isNotNull);
    expect(PixelGlyphData.rowsOf('khong_ton_tai'), isNull);
  });

  const spaceshipGlyphs = [
    'holocam',
    'bridge',
    'radar',
    'cargo',
    'console',
    'airlock',
    'engine',
  ];

  test('bộ glyph tàu vũ trụ tồn tại và đủ cho mọi khu vực', () {
    for (final key in spaceshipGlyphs) {
      expect(PixelGlyphData.rowsOf(key), isNotNull, reason: 'thiếu glyph $key');
    }
    for (final section in AppSection.values) {
      expect(
        PixelGlyphData.rowsOf(section.glyph),
        isNotNull,
        reason:
            'khu vực ${section.name} trỏ tới glyph ${section.glyph} không có',
      );
    }
  });

  test('bộ glyph tàu vũ trụ đa màu (từ 3 màu trở lên)', () {
    const inkChars = ['#', '+', 'k', 'w', '1', '2', '3', '4', '5', '6'];
    for (final key in spaceshipGlyphs) {
      final rows = PixelGlyphData.rowsOf(key)!.join();
      final used = inkChars.where(rows.contains).length;
      expect(
        used,
        greaterThanOrEqualTo(3),
        reason: 'glyph $key chỉ có $used màu',
      );
    }
  });

  testWidgets('PixelGlyph render không ném lỗi với glyph lạ', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: const Scaffold(body: PixelGlyph(name: 'khong_ton_tai', size: 32)),
      ),
    );
    expect(find.byType(PixelGlyph), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
