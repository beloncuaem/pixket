import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/constants/app_info.dart';

List<File> _dartFiles(String root) =>
    Directory(root)
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

List<String> _filesContaining(String needle, {String root = 'lib'}) => [
  for (final file in _dartFiles(root))
    if (file.readAsStringSync().contains(needle)) file.path,
];

const _legacyWidgets = [
  'lib/widgets/glass_card.dart',
  'lib/widgets/screen_background.dart',
  'lib/widgets/category_icon_badge.dart',
  'lib/widgets/expense_card.dart',
  'lib/widgets/priority_badge.dart',
  'lib/widgets/category_chip.dart',
  'lib/widgets/amount_display.dart',
  'lib/core/constants/app_colors.dart',
];

const _legacyEffects = [
  'lib/widgets/pixel/pixel_tab_bar.dart',
  'lib/widgets/pixel/mosaic_wipe.dart',
  'lib/widgets/pixel/rainbow_sweep.dart',
  'lib/widgets/pixel/rainbow_rule.dart',
  'lib/widgets/pixel/pixel_confetti.dart',
];

void main() {
  group('Pixel cleanup gates', () {
    test('8 file cũ không còn trên đĩa', () {
      expect([
        for (final path in _legacyWidgets)
          if (File(path).existsSync()) path,
      ], isEmpty);
    });

    test('tab bar đáy và dải 7 màu không quay lại', () {
      expect([
        for (final path in _legacyEffects)
          if (File(path).existsSync()) path,
      ], isEmpty);
      for (final needle in [
        'PixelTabBar',
        'MosaicWipe',
        'RainbowSweep',
        'RainbowRule',
        'PixelConfetti',
        'bottomNavigationBar',
      ]) {
        expect(_filesContaining(needle), isEmpty, reason: needle);
      }
    });

    test('lib/ không còn tham chiếu AppColors hay Icons.*', () {
      expect(_filesContaining('AppColors'), isEmpty);
      expect(_filesContaining('Icons.'), isEmpty);
    });

    test('lib/ không còn widget cũ, fl_chart và google_fonts', () {
      for (final needle in [
        'GlassCard',
        'ScreenBackground',
        'CategoryIconBadge',
        'ExpenseCard',
        'PriorityBadge',
        'CategoryChip',
        'AmountDisplay',
        'fl_chart',
        'google_fonts',
      ]) {
        expect(_filesContaining(needle), isEmpty, reason: needle);
      }
    });

    test('mọi ảnh khoản chi đi qua PixelReceiptImage', () {
      // Placeholder/evict cache là API ảnh, còn widget render ảnh thì phải gom
      // về một chỗ; provider được phép gọi evictFromCache.
      final renderers = [
        for (final path in _filesContaining('Image.file('))
          if (!path.endsWith('pixel_receipt_image.dart')) path,
        for (final path in _filesContaining('CachedNetworkImage('))
          if (!path.endsWith('pixel_receipt_image.dart')) path,
      ];
      expect(renderers, isEmpty);
    });

    test('pubspec và AppInfo cùng một phiên bản', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('version: ${AppInfo.version}+${AppInfo.build}'));
      expect(AppInfo.version, '2.5.0');
      expect(AppInfo.build, '6');
      expect(AppInfo.tagline, 'PIXEL JOURNAL');
    });

    test('màn hình chính và widget pixel tồn tại đúng đường dẫn', () {
      for (final path in [
        'lib/screens/home/home_screen.dart',
        'lib/screens/statistics/statistics_screen.dart',
        'lib/screens/budget/budget_screen.dart',
        'lib/screens/categories/manage_categories_screen.dart',
        'lib/screens/trash/trash_screen.dart',
        'lib/screens/settings/settings_screen.dart',
        'lib/widgets/pixel/pixel_receipt_image.dart',
        'lib/widgets/pixel/pixel_screen_header.dart',
        'lib/widgets/pixel/pixel_expense_tile.dart',
        'lib/widgets/pixel/pixel_share_bar.dart',
        'lib/widgets/pixel/pixel_stacked_share.dart',
        'lib/widgets/pixel/pixel_bar_chart.dart',
        'lib/widgets/pixel/feed_hud.dart',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });
}
