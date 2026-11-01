import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

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
