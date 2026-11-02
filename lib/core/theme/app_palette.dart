import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// Token màu của giao diện Pixel. Light là giấy kem, dark là nền vũ trụ.
///
/// Sáu accent xếp theo dải Nyan Cat: đỏ → cam → vàng → lục → dương → tím.
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
    required this.violet,
    required this.violetInk,
    required this.star,
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

  final Color canvas, surface, surfaceAlt, ink, inkMuted, inkInverse;
  final Color line, lineStrong, shadow;
  final Color mint, mintStrong, mintInk;
  final Color butter, butterInk, peach, peachInk, sky, skyInk, rose, roseInk;
  final Color violet, violetInk, star;
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
    mint: Color(0xFF57D98A),
    mintStrong: Color(0xFF2F9E6E),
    mintInk: Color(0xFF146B3C),
    butter: Color(0xFFFFE45C),
    butterInk: Color(0xFF8A6A00),
    peach: Color(0xFFFFA53D),
    peachInk: Color(0xFF9C4A06),
    sky: Color(0xFF57AEFF),
    skyInk: Color(0xFF0F4C8F),
    rose: Color(0xFFFF5C5C),
    roseInk: Color(0xFFC0273B),
    violet: Color(0xFFB983FF),
    violetInk: Color(0xFF57309E),
    star: Color(0xFFFFE45C),
    onAccent: Color(0xFF1B140E),
    danger: Color(0xFFB3261E),
    dangerInk: Color(0xFFB3261E),
    success: Color(0xFF146B3C),
    warning: Color(0xFF8A6A00),
    feedBg: Color(0xFF06121F),
    feedPanel: Color(0xFF0E2A4F),
    feedInk: Color(0xFFFFF6E3),
    feedMuted: Color(0xFFC9B79E),
  );

  static const AppPalette dark = AppPalette(
    canvas: Color(0xFF0E2A4F),
    surface: Color(0xFF16396A),
    surfaceAlt: Color(0xFF1D4A82),
    ink: Color(0xFFF2F8FF),
    inkMuted: Color(0xFFA8C3E8),
    inkInverse: Color(0xFF2B2118),
    line: Color(0xFF4E76A8),
    lineStrong: Color(0xFFDCEBFF),
    shadow: Color(0xFF06121F),
    mint: Color(0xFF6BE58A),
    mintStrong: Color(0xFF3FBF86),
    mintInk: Color(0xFF9BE9C2),
    butter: Color(0xFFFFE873),
    butterInk: Color(0xFFFFE7A6),
    peach: Color(0xFFFFB347),
    peachInk: Color(0xFFFFCDB0),
    sky: Color(0xFF6FB7FF),
    skyInk: Color(0xFFBEE4F5),
    rose: Color(0xFFFF6B6B),
    roseInk: Color(0xFFF7B7C0),
    violet: Color(0xFFC99BFF),
    violetInk: Color(0xFFE0C4FF),
    star: Color(0xFFFFFFFF),
    onAccent: Color(0xFF1B140E),
    // Spec §12 chốt #FF8A7A nhưng chỉ đo trên canvas/surface; trên surfaceAlt
    // nó còn 3.89 nên chữ báo lỗi trong ô nhập trượt 4.5. #FFA79A đạt 4.78.
    danger: Color(0xFFFFA79A),
    dangerInk: Color(0xFFFFA79A),
    success: Color(0xFF9BE9C2),
    warning: Color(0xFFFFE7A6),
    feedBg: Color(0xFF06121F),
    feedPanel: Color(0xFF0E2A4F),
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
    Color? violet,
    Color? violetInk,
    Color? star,
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
    violet: violet ?? this.violet,
    violetInk: violetInk ?? this.violetInk,
    star: star ?? this.star,
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
      violet: mix(violet, other.violet),
      violetInk: mix(violetInk, other.violetInk),
      star: mix(star, other.star),
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

  /// Sáu accent theo dải Nyan Cat: đỏ · cam · vàng · lục · dương · tím.
  /// Là getter của instance nên light và dark không còn dùng chung một bảng.
  List<Color> get accents => [rose, peach, butter, mint, sky, violet];

  /// Bản ink của sáu accent: deep trên nền kem, tint trên nền đêm.
  List<Color> get accentInks => [
    roseInk,
    peachInk,
    butterInk,
    mintInk,
    skyInk,
    violetInk,
  ];

  Color accentAt(int index) => accents[index % accents.length];

  Color accentInkAt(int index) => accentInks[index % accentInks.length];

  /// Màu nhãn danh mục ổn định: cùng key luôn ra cùng accent.
  /// Dấu `& 0x7FFFFFFF` giữ chỉ mục luôn dương dù hashCode ra số âm.
  Color accentForCategory(Object key) =>
      accents[(key.hashCode & 0x7FFFFFFF) % accents.length];

  /// Chỉ mục accent của bốn mức ưu tiên: Thiết yếu=lục, Rất cần=dương,
  /// Cần vừa=vàng, Chưa cần=đỏ. Giữ ánh xạ cũ để dải lục→đỏ không bị đảo.
  static const _priorityAccentIndex = [3, 4, 2, 0];

  /// Ngoài 0..3 thì coi như Thiết yếu (lục), không kẹp về 3 vì ô 3 là đỏ.
  static int _prioritySlot(int priority) =>
      priority < 0 || priority > 3 ? 0 : priority;

  Color priorityColor(int priority) =>
      accentAt(_priorityAccentIndex[_prioritySlot(priority)]);

  Color priorityInk(int priority) =>
      accentInkAt(_priorityAccentIndex[_prioritySlot(priority)]);

  String priorityLabel(int priority) {
    // `elementAtOrNull` nằm trong dart:collection, không import ở đây
    // nên guard bằng index thường.
    if (priority < 0 || priority >= AppStrings.priorityLabels.length) {
      return AppStrings.priorityLabels.first;
    }
    return AppStrings.priorityLabels[priority];
  }

  /// Bậc mức chi theo `t = giá trị / mốc tham chiếu`.
  /// `t` âm rơi vào bậc 0 vì nhánh nào cũng so `< 0.25` trước.
  /// NaN (kỳ rỗng: 0/0) cũng về bậc 0, nếu không sẽ tô đỏ "Vượt mức" oan.
  int spendBand(double t) {
    if (t.isNaN) return 0;
    return t < 0.25
        ? 0
        : t < 0.5
        ? 1
        : t < 0.75
        ? 2
        : 3;
  }

  /// Tô khối theo mức chi: dương → lục → vàng → đỏ.
  Color rampFill(double t) => [sky, mint, butter, rose][spendBand(t)];

  /// Bản ink của [rampFill], cho thanh mảnh, legend và chữ màu.
  Color rampInk(double t) =>
      [skyInk, mintInk, butterInk, roseInk][spendBand(t)];

  /// Nhãn chữ của bậc mức chi: màu không bao giờ mang nghĩa một mình.
  String rampLabel(double t) =>
      const ['Thấp', 'Vừa', 'Cao', 'Vượt mức'][spendBand(t)];
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
