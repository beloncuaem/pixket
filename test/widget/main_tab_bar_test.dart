import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/screens/main_screen.dart';
import 'package:pixket/widgets/pixel/pixel_star_field.dart';
import 'package:pixket/widgets/pixel/pixel_tab_bar.dart';

import '../support/fakes.dart';
import '../support/memory_settings.dart';

Finder _starPaint() => find.descendant(
  of: find.byType(PixelStarField),
  matching: find.byType(CustomPaint),
);

/// MainScreen có RainbowRule và nền sao (repeat 1,4 s) nên phải tắt animation,
/// nếu không `pumpAndSettle` không bao giờ dừng.
Widget _host({ThemeData? theme, MemorySettingsRepository? repo}) =>
    ProviderScope(
      overrides: [
        ...mainScreenOverrides(),
        effectsProvider.overrideWith(
          (ref) => EffectSettingsNotifier(
            repository: repo ?? MemorySettingsRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.dark,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const MainScreen(),
          ),
        ),
      ),
    );

/// Section chụp giữ `PixelLoading` (repeat vô hạn) tới khi plugin camera báo
/// lỗi, mà future đó chỉ hoàn tất trong event loop thật → phải `runAsync`,
/// cùng khuôn `pumpFeedUntilCameraError` của test/widget/feed_hud_test.dart.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tab bar đổi section một lần và drawer vẫn mở', (tester) async {
    // Drawer dùng ListView lazy: ở surface mặc định 800x600 mục 'Cài đặt' nằm
    // dưới nếp gấp nên không được build. Cùng khuôn app_drawer_test._openDrawer.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host());
    await _settle(tester);

    expect(find.byType(PixelTabBar), findsOneWidget);

    await tester.tap(find.text('BIỂU'));
    await tester.pumpAndSettle();
    expect(find.text('THEO DANH MỤC'), findsOneWidget);

    // Drawer vẫn mở được bằng nút menu trên header của section sổ.
    await tester.tap(find.text('SỔ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mở menu'));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsOneWidget);
  });

  testWidgets('nền sao vẽ khi dark và bật fx_stars', (tester) async {
    await tester.pumpWidget(_host());
    await _settle(tester);
    expect(_starPaint(), findsOneWidget);
  });

  testWidgets('nền sao tắt khi fx_stars = false', (tester) async {
    final repo = MemorySettingsRepository()..store['fx_stars'] = 'false';
    await tester.pumpWidget(_host(repo: repo));
    await _settle(tester);
    expect(_starPaint(), findsNothing);
  });

  testWidgets('nền sao không vẽ ở theme sáng', (tester) async {
    await tester.pumpWidget(_host(theme: AppTheme.light));
    await _settle(tester);
    expect(_starPaint(), findsNothing);
  });
}
