import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Phần thân của HUD trên: padding 10 + nút 48 + padding 22. FeedPhotoPage chừa
/// đúng chừng này để ảnh không bị thanh tiêu đề đè lên.
const double feedHudBarHeight = 80;

/// Viền chuyển sáng cho HUD trên/dưới của feed, chỉ dùng token nền tối.
LinearGradient hudTopGradient(AppPalette palette) => LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    palette.feedBg.withValues(alpha: 0.92),
    palette.feedBg.withValues(alpha: 0),
  ],
  stops: const [0.0, 1.0],
);

LinearGradient hudBottomGradient(AppPalette palette) => LinearGradient(
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
  colors: [
    palette.feedBg.withValues(alpha: 0.94),
    palette.feedBg.withValues(alpha: 0),
  ],
  stops: const [0.0, 1.0],
);
