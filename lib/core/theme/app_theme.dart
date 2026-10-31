import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';
import 'pixel_text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette palette) {
    final isDark = palette == AppPalette.dark;
    final textTheme = pixelTextTheme(palette);
    final scheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: palette.mintStrong,
      onPrimary: palette.onAccent,
      secondary: palette.butter,
      onSecondary: palette.onAccent,
      error: palette.danger,
      onError: palette.surface,
      surface: palette.surface,
      onSurface: palette.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      extensions: <ThemeExtension<dynamic>>[palette],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(letterSpacing: 0.9),
        iconTheme: IconThemeData(color: palette.ink, size: 24),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: palette.lineStrong, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.line,
        thickness: 2,
        space: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: palette.lineStrong, width: 3),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: palette.lineStrong, width: 2),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.canvas),
        actionTextColor: palette.butter,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(color: palette.mintStrong, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceAlt,
        labelStyle: textTheme.labelLarge,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
        errorStyle: textTheme.bodySmall?.copyWith(color: palette.danger),
        enabledBorder: _pixelBorder(palette.line),
        focusedBorder: _pixelBorder(palette.mintStrong, width: 3),
        errorBorder: _pixelBorder(palette.danger),
        focusedErrorBorder: _pixelBorder(palette.danger, width: 3),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.mintInk,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: Colors.transparent, width: 2),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.mint,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.surfaceAlt,
          disabledForegroundColor: palette.inkMuted,
          elevation: 0,
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: palette.lineStrong, width: 2),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.mint,
          foregroundColor: palette.onAccent,
          elevation: 0,
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: palette.lineStrong, width: 2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: palette.lineStrong, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.mintStrong
              : palette.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.mint
              : palette.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.all(palette.lineStrong),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.ink,
        textColor: palette.ink,
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.mintStrong,
        linearTrackColor: palette.surfaceAlt,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.ink,
          borderRadius: BorderRadius.circular(2),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: palette.canvas),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: palette.mint,
        headerForegroundColor: palette.onAccent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: palette.surface,
        dialBackgroundColor: palette.surfaceAlt,
        helpTextStyle: textTheme.labelMedium,
      ),
    );
  }

  static OutlineInputBorder _pixelBorder(Color color, {double width = 2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
