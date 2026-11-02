import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/screens/main_screen.dart';
import 'package:pixket/widgets/pixel/pixel_star_field.dart';

import '../support/fakes.dart';

Finder _starPaint() => find.descendant(
  of: find.byType(PixelStarField),
  matching: find.byType(CustomPaint),
);

/// MainScreen có nền sao (repeat 1,4 s + chu kỳ trôi 30 s) nên phải tắt
/// animation, nếu không `pumpAndSettle` không bao giờ dừng.
Widget _host({ThemeData? theme}) => ProviderScope(
  overrides: mainScreenOverrides(),
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

/// Drawer dùng ListView lazy: ở surface mặc định 800x600 mục 'Cài đặt' nằm
/// dưới nếp gấp nên không được build. Cùng khuôn app_drawer_test._openDrawer.
void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('không còn thanh tab đáy', (tester) async {
    await tester.pumpWidget(_host());
    await _settle(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.bottomNavigationBar, isNull);
  });

  testWidgets('đổi khu vực qua drawer', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_host());
    await _settle(tester);

    await tester.tap(find.byTooltip('Mở menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thống kê'));
    await tester.pumpAndSettle();

    expect(find.text('THEO DANH MỤC'), findsOneWidget);
  });

  testWidgets('vuốt ngang từ mép trái mở drawer', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_host());
    await _settle(tester);

    await tester.drag(
      find.byKey(const ValueKey('edge-swipe-area')),
      const Offset(220, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt'), findsOneWidget);
  });

  testWidgets('nền sao vẽ ở theme tối', (tester) async {
    await tester.pumpWidget(_host());
    await _settle(tester);
    expect(_starPaint(), findsWidgets);
  });

  testWidgets('nền sao không vẽ ở theme sáng', (tester) async {
    await tester.pumpWidget(_host(theme: AppTheme.light));
    await _settle(tester);
    expect(_starPaint(), findsNothing);
  });
}
