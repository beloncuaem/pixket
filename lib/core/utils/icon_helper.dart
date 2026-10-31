import 'package:flutter/material.dart';

import '../icons/pixel_glyph_data.dart';
import '../../widgets/pixel/app_icon.dart';

class IconHelper {
  static const Set<String> categoryIconKeys = {
    'forkKnife',
    'coffee',
    'car',
    'shoppingBag',
    'receipt',
    'gameController',
    'heartbeat',
    'graduationCap',
    'house',
    'airplaneTilt',
    'gift',
    'pawPrint',
    'barbell',
    'filmStrip',
    'tShirt',
    'deviceMobile',
    'bank',
    'wallet',
    'dotsThreeOutline',
  };

  // Ánh xạ từ các emoji cũ sang icon tương ứng
  static const Map<String, String> _emojiToIconName = {
    '🍜': 'forkKnife',
    '🍲': 'forkKnife',
    '🍔': 'forkKnife',
    '🍕': 'forkKnife',
    '☕': 'coffee',
    '🚗': 'car',
    '🛵': 'car',
    '🚌': 'car',
    '🛍️': 'shoppingBag',
    '🛒': 'shoppingBag',
    '⚡': 'receipt',
    '💡': 'receipt',
    '🧾': 'receipt',
    '🎮': 'gameController',
    '💊': 'heartbeat',
    '🏥': 'heartbeat',
    '📚': 'graduationCap',
    '🏠': 'house',
    '✈️': 'airplaneTilt',
    '🎁': 'gift',
  };

  static List<String> get availableIcons =>
      categoryIconKeys.toList(growable: false);

  static String normalizeIconKey(String iconKey) {
    final mappedKey = _emojiToIconName[iconKey] ?? iconKey;
    return categoryIconKeys.contains(mappedKey)
        ? mappedKey
        : 'dotsThreeOutline';
  }

  static Widget getIconWidget(
    String iconKey, {
    double size = 16,
    Color? color,
    Color? secondary,
  }) {
    final mappedKey = _emojiToIconName[iconKey] ?? iconKey;
    return AppIcon(
      name: PixelGlyphData.rowsOf(mappedKey) != null
          ? mappedKey
          : PixelGlyphData.fallbackKey,
      size: size,
      color: color,
      secondary: secondary,
    );
  }

  static Color parseColor(
    String? colorHex, {
    Color defaultColor = const Color(0xFF10B981),
  }) {
    if (colorHex == null || colorHex.isEmpty) return defaultColor;
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return defaultColor;
  }
}
