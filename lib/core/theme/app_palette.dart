import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// Token màu của giao diện Pixel. Light là mặc định, dark đảo nền mực.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkMuted,
    required this.inkInverse,
    required this.line,
    required this.lineStrong,
    required this.shadow,
    required this.mint,
    required this.mintStrong,
    required this.mintInk,
    required this.butter,
    required this.butterInk,
    required this.peach,
    required this.peachInk,
    required this.sky,
    required this.skyInk,
    required this.rose,
    required this.roseInk,
    required this.onAccent,
    required this.danger,
    required this.dangerInk,
    required this.success,
    required this.warning,
    required this.feedBg,
    required this.feedPanel,
    required this.feedInk,
    required this.feedMuted,
  });

  static const _accents = <String, Color>{
    'mint': Color(0xFF7BD8A8),
    'butter': Color(0xFFFFD86B),
    'peach': Color(0xFFFFB38A),
    'sky': Color(0xFF8ECAE6),
    'rose': Color(0xFFF28C9A),
  };

  final Color canvas, surface, surfaceAlt, ink, inkMuted, inkInverse;
  final Color line, lineStrong, shadow;
  final Color mint, mintStrong, mintInk;
  final Color butter, butterInk, peach, peachInk, sky, skyInk, rose, roseInk;
  final Color onAccent, danger, dangerInk, success, warning;
  final Color feedBg, feedPanel, feedInk, feedMuted;

  static const AppPalette light = AppPalette(
    canvas: Color(0xFFFFF6E3),
    surface: Color(0xFFFFFDF6),
    surfaceAlt: Color(0xFFFFF1D6),
    ink: Color(0xFF2B2118),
    inkMuted: Color(0xFF6E5F4E),
    inkInverse: Color(0xFFFFF6E3),
    line: Color(0xFF1B140E),
    lineStrong: Color(0xFF1B140E),
    shadow: Color(0xFF1B140E),
    mint: Color(0xFF7BD8A8),
    mintStrong: Color(0xFF2F9E6E),
    mintInk: Color(0xFF1F7A52),
    butter: Color(0xFFFFD86B),
    butterInk: Color(0xFF6E4A00),
    peach: Color(0xFFFFB38A),
    peachInk: Color(0xFF7A3108),
    sky: Color(0xFF8ECAE6),
    skyInk: Color(0xFF0F4A63),
    rose: Color(0xFFF28C9A),
    roseInk: Color(0xFF7A1B2A),
    onAccent: Color(0xFF1B140E),
    danger: Color(0xFFB3261E),
    dangerInk: Color(0xFFB3261E),
    success: Color(0xFF1F7A52),
    warning: Color(0xFF6E4A00),
    feedBg: Color(0xFF14100B),
    feedPanel: Color(0xFF1E1710),
    feedInk: Color(0xFFFFF6E3),
    feedMuted: Color(0xFFC9B79E),
  );

  static const AppPalette dark = AppPalette(
    canvas: Color(0xFF1A130D),
    surface: Color(0xFF241A12),
    surfaceAlt: Color(0xFF302318),
    ink: Color(0xFFFFF6E3),
    inkMuted: Color(0xFFC9B79E),
    inkInverse: Color(0xFF2B2118),
    line: Color(0xFF6B553F),
    lineStrong: Color(0xFFFFF6E3),
    shadow: Color(0xFF000000),
    mint: Color(0xFF7BD8A8),
    mintStrong: Color(0xFF3FBF86),
    mintInk: Color(0xFF9BE9C2),
    butter: Color(0xFFFFD86B),
    butterInk: Color(0xFFFFE7A6),
    peach: Color(0xFFFFB38A),
    peachInk: Color(0xFFFFCDB0),
    sky: Color(0xFF8ECAE6),
    skyInk: Color(0xFFBEE4F5),
    rose: Color(0xFFF28C9A),
    roseInk: Color(0xFFF7B7C0),
    onAccent: Color(0xFF1B140E),
    danger: Color(0xFFFF8A7A),
    dangerInk: Color(0xFFFF8A7A),
    success: Color(0xFF9BE9C2),
    warning: Color(0xFFFFE7A6),
    feedBg: Color(0xFF0D0A07),
    feedPanel: Color(0xFF17110B),
    feedInk: Color(0xFFFFF6E3),
    feedMuted: Color(0xFFC9B79E),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? inkMuted,
    Color? inkInverse,
    Color? line,
    Color? lineStrong,
    Color? shadow,
    Color? mint,
    Color? mintStrong,
    Color? mintInk,
    Color? butter,
    Color? butterInk,
    Color? peach,
    Color? peachInk,
    Color? sky,
    Color? skyInk,
    Color? rose,
    Color? roseInk,
    Color? onAccent,
    Color? danger,
    Color? dangerInk,
    Color? success,
    Color? warning,
    Color? feedBg,
    Color? feedPanel,
    Color? feedInk,
    Color? feedMuted,
  }) => AppPalette(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    inkInverse: inkInverse ?? this.inkInverse,
    line: line ?? this.line,
    lineStrong: lineStrong ?? this.lineStrong,
    shadow: shadow ?? this.shadow,
    mint: mint ?? this.mint,
    mintStrong: mintStrong ?? this.mintStrong,
    mintInk: mintInk ?? this.mintInk,
    butter: butter ?? this.butter,
    butterInk: butterInk ?? this.butterInk,
    peach: peach ?? this.peach,
    peachInk: peachInk ?? this.peachInk,
    sky: sky ?? this.sky,
    skyInk: skyInk ?? this.skyInk,
    rose: rose ?? this.rose,
    roseInk: roseInk ?? this.roseInk,
    onAccent: onAccent ?? this.onAccent,
    danger: danger ?? this.danger,
    dangerInk: dangerInk ?? this.dangerInk,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    feedBg: feedBg ?? this.feedBg,
    feedPanel: feedPanel ?? this.feedPanel,
    feedInk: feedInk ?? this.feedInk,
    feedMuted: feedMuted ?? this.feedMuted,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      inkInverse: mix(inkInverse, other.inkInverse),
      line: mix(line, other.line),
      lineStrong: mix(lineStrong, other.lineStrong),
      shadow: mix(shadow, other.shadow),
      mint: mix(mint, other.mint),
      mintStrong: mix(mintStrong, other.mintStrong),
      mintInk: mix(mintInk, other.mintInk),
      butter: mix(butter, other.butter),
      butterInk: mix(butterInk, other.butterInk),
      peach: mix(peach, other.peach),
      peachInk: mix(peachInk, other.peachInk),
      sky: mix(sky, other.sky),
      skyInk: mix(skyInk, other.skyInk),
      rose: mix(rose, other.rose),
      roseInk: mix(roseInk, other.roseInk),
      onAccent: mix(onAccent, other.onAccent),
      danger: mix(danger, other.danger),
      dangerInk: mix(dangerInk, other.dangerInk),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      feedBg: mix(feedBg, other.feedBg),
      feedPanel: mix(feedPanel, other.feedPanel),
      feedInk: mix(feedInk, other.feedInk),
      feedMuted: mix(feedMuted, other.feedMuted),
    );
  }

  /// Màu nhãn danh mục ổn định: cùng key luôn ra cùng accent.
  /// Dấu `& 0x7FFFFFFF` giữ chỉ mục luôn dương dù hashCode ra số âm.
  Color accentForCategory(Object key) {
    const order = ['mint', 'sky', 'butter', 'peach', 'rose'];
    final index = (key.hashCode & 0x7FFFFFFF) % order.length;
    return _accents[order[index]]!;
  }

  Color priorityColor(int priority) => switch (priority) {
    0 => mint,
    1 => sky,
    2 => butter,
    3 => rose,
    _ => mint,
  };

  Color priorityInk(int priority) => switch (priority) {
    0 => mintInk,
    1 => skyInk,
    2 => butterInk,
    3 => roseInk,
    _ => mintInk,
  };

  String priorityLabel(int priority) {
    // `elementAtOrNull` nằm trong dart:collection, không import ở đây
    // nên guard bằng index thường.
    if (priority < 0 || priority >= AppStrings.priorityLabels.length) {
      return AppStrings.priorityLabels.first;
    }
    return AppStrings.priorityLabels[priority];
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
