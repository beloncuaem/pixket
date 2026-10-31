import 'package:flutter/material.dart';

/// LEGACY: chỉ dành cho các màn hình chưa chuyển sang `context.palette`.
/// Plan 4 Task 14 xóa toàn bộ file. Không thêm tham chiếu mới.
@Deprecated('Dùng context.palette (AppPalette) thay vì AppColors')
class AppColors {
  // Brand & Accent Colors (Pixel)
  static const Color primary = Color(0xFF2F9E6E); // mintStrong
  static const Color primaryLight = Color(0xFF7BD8A8); // mint

  // Backgrounds & Surfaces (Dark Mode)
  static const Color backgroundDark = Color(0xFF1A130D);
  static const Color surfaceDark = Color(0xFF241A12);
  static const Color surfaceDarkLight = Color(0xFF302318);
  static const Color borderDark = Color(0xFF6B553F);

  // Feed (nền tối kiểu Locket)
  static const Color feedBackground = Color(0xFF14100B);
  static const Color glassSurfaceDark = Color(0xCC241A12);
  static const Color glassBorderDark = Color(0x33FFF6E3);

  // Backgrounds & Surfaces (Light Mode)
  static const Color backgroundLight = Color(0xFFFFF6E3);
  static const Color surfaceLight = Color(0xFFFFFDF6);
  static const Color surfaceLightDark = Color(0xFFFFF1D6);
  static const Color borderLight = Color(0xFF1B140E);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFFFF6E3);
  static const Color textSecondaryDark = Color(0xFFC9B79E);
  static const Color textPrimaryLight = Color(0xFF2B2118);
  static const Color textSecondaryLight = Color(0xFF6E5F4E);

  // Priority Colors: màu chữ/nét/chart trên nền kem nên dùng biến thể ink đậm
  static const Color priority0 = Color(0xFF1F7A52); // P0: Thiết yếu
  static const Color priority1 = Color(0xFF0F4A63); // P1: Cao
  static const Color priority2 = Color(0xFF6E4A00); // P2: Trung bình
  static const Color priority3 = Color(0xFFB3261E); // P3: Thấp/Lãng phí

  // Gradients for Cards
  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF241A12), Color(0xFF1A130D)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7BD8A8), Color(0xFF2F9E6E)],
  );

  static const LinearGradient balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF241A12), Color(0xFF1A130D), Color(0xFF1F7A52)],
  );

  static const LinearGradient pageGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A130D), Color(0xFF241A12), Color(0xFF14100B)],
  );

  static const LinearGradient pageGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDF6), Color(0xFFFFF6E3), Color(0xFFFFF1D6)],
  );

  static const LinearGradient feedTopGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xB3000000), Color(0x00000000)],
  );

  static const LinearGradient feedBottomGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x99000000), Color(0xF2000000)],
  );

  static const LinearGradient captureButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7BD8A8), Color(0xFF2F9E6E)],
  );

  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return priority0;
      case 1:
        return priority1;
      case 2:
        return priority2;
      case 3:
      default:
        return priority3;
    }
  }
}
