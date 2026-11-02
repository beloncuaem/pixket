import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/providers/expense_provider.dart';
import 'package:pixket/providers/priority_provider.dart';
import 'package:pixket/screens/camera/camera_screen.dart';
import 'package:pixket/widgets/hamburger_button.dart';
import 'package:pixket/widgets/pixel/app_icon.dart';
import 'package:pixket/widgets/pixel/pixel_badge.dart';
import 'package:pixket/widgets/pixel/pixel_button.dart';

class _FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _FakeExpenseNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePriorityNotifier extends StateNotifier<PriorityState>
    implements PriorityNotifier {
  _FakePriorityNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _noop() {}

Widget feed() => ProviderScope(
  overrides: [
    expenseProvider.overrideWith(
      (ref) => _FakeExpenseNotifier(const ExpenseState()),
    ),
    categoryProvider.overrideWith(
      (ref) => _FakeCategoryNotifier(const CategoryState()),
    ),
    priorityProvider.overrideWith(
      (ref) => _FakePriorityNotifier(const PriorityState()),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.dark,
    home: const CameraScreen(onMenuTap: _noop),
  ),
);

void main() {
  // Camera plugin không khởi tạo được trong test → notice card hiện sau khi
  // future báo lỗi; future này chỉ hoàn tất trong event loop thật.
  Future<void> pumpFeed(WidgetTester tester) async {
    await tester.pumpWidget(feed());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> pumpFeedUntilCameraError(WidgetTester tester) async {
    await pumpFeed(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  testWidgets('HUD dùng nhãn NHẬT KÝ + nút menu, không còn Icons.*', (
    tester,
  ) async {
    await pumpFeed(tester);
    expect(find.textContaining('NHẬT KÝ'), findsOneWidget);
    expect(find.byType(HamburgerButton), findsOneWidget);
    expect(find.byIcon(Icons.grid_view), findsNothing);
    expect(find.byIcon(Icons.camera_alt), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chưa có ảnh thì ẩn nút lưới', (tester) async {
    await pumpFeed(tester);
    expect(find.byType(PixelBadge), findsNothing);
    expect(find.text('0 ảnh'), findsNothing);
  });

  testWidgets('notice card camera lỗi là pixel, không còn Material button', (
    tester,
  ) async {
    await pumpFeedUntilCameraError(tester);
    expect(find.text('CHỌN ẢNH TỪ THƯ VIỆN'), findsOneWidget);
    expect(find.text('CAMERA CHƯA SẴN SÀNG'), findsOneWidget);
    expect(find.byType(PixelButton), findsWidgets);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nút chụp là pixel kèm nhãn ngữ nghĩa', (tester) async {
    await pumpFeed(tester);
    expect(find.bySemanticsLabel('Chụp khoản chi'), findsOneWidget);
    // Đang mở camera: PixelLoading thay cho CircularProgressIndicator.
    expect(find.text('Đang mở camera…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('HUD tối dùng token palette, không dùng màu trắng hardcode', (
    tester,
  ) async {
    await pumpFeed(tester);
    final palette = AppTheme.dark.extension<AppPalette>()!;
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, palette.feedBg);
    expect(find.byType(AppIcon), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
