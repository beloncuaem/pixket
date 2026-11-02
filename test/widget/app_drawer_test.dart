import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/navigation/app_section.dart';
import 'package:pixket/widgets/app_drawer.dart';
import 'package:pixket/widgets/pixel/app_icon.dart';
import 'package:pixket/widgets/pixel/pixel_logo.dart';

AppDrawer _drawer({
  AppSection selected = AppSection.feed,
  ValueChanged<AppSection>? onSelectSection,
  VoidCallback? onOpenCategories,
  VoidCallback? onOpenTrash,
  VoidCallback? onOpenSettings,
  VoidCallback? onToggleTheme,
  Future<void> Function()? onLogout,
}) {
  return AppDrawer(
    selected: selected,
    onSelectSection: onSelectSection ?? (_) {},
    onOpenCategories: onOpenCategories ?? () {},
    onOpenTrash: onOpenTrash ?? () {},
    onOpenSettings: onOpenSettings ?? () {},
    onToggleTheme: onToggleTheme ?? () {},
    displayName: 'Quang',
    email: 'quang@example.com',
    isDarkMode: true,
    onLogout: onLogout ?? () async {},
  );
}

Future<void> _openDrawer(WidgetTester tester, AppDrawer drawer) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final key = GlobalKey<ScaffoldState>();
  await tester.pumpWidget(
    // Drawer có nền sao (Consumer) nên cần ProviderScope.
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(key: key, drawer: drawer, body: const SizedBox.expand()),
      ),
    ),
  );
  key.currentState!.openDrawer();
  await tester.pumpAndSettle();
}

void main() {
  group('AppDrawer', () {
    testWidgets('Hiển thị các mục điều hướng chính', (tester) async {
      await _openDrawer(tester, _drawer());

      for (final section in AppSection.values) {
        expect(find.text(section.label), findsOneWidget);
      }
      expect(find.text('Quản lý danh mục'), findsOneWidget);
      expect(find.text('Thùng rác'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets('Chọn mục gọi callback và đóng drawer', (tester) async {
      AppSection? selected;
      await _openDrawer(
        tester,
        _drawer(onSelectSection: (section) => selected = section),
      );

      await tester.tap(find.text(AppSection.statistics.label));
      await tester.pumpAndSettle();

      expect(selected, AppSection.statistics);
      expect(find.text('Quản lý danh mục'), findsNothing);
    });

    testWidgets('Mở quản lý danh mục', (tester) async {
      var opened = false;
      await _openDrawer(tester, _drawer(onOpenCategories: () => opened = true));

      await tester.tap(find.text('Quản lý danh mục'));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });

    testWidgets('Mở thùng rác', (tester) async {
      var opened = false;
      await _openDrawer(tester, _drawer(onOpenTrash: () => opened = true));

      await tester.tap(find.text('Thùng rác'));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });

    testWidgets('Mở cài đặt', (tester) async {
      var opened = false;
      await _openDrawer(tester, _drawer(onOpenSettings: () => opened = true));

      await tester.tap(find.text('Cài đặt'));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });

    testWidgets('Đổi giao diện sáng/tối', (tester) async {
      var toggled = false;
      await _openDrawer(tester, _drawer(onToggleTheme: () => toggled = true));

      expect(find.text('Giao diện tối'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    });

    testWidgets('Drawer không còn gradient tối cố định', (tester) async {
      await _openDrawer(tester, _drawer());

      for (final d in tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(DecoratedBox),
        ),
      )) {
        final dec = d.decoration;
        if (dec is BoxDecoration) expect(dec.gradient, isNull);
      }
      expect(find.byIcon(Icons.menu_rounded), findsNothing);
      expect(find.byType(AppIcon), findsWidgets);
    });

    testWidgets('Hiển thị hồ sơ cloud và nút đăng xuất', (tester) async {
      var loggedOut = false;
      await _openDrawer(
        tester,
        _drawer(onLogout: () async => loggedOut = true),
      );

      expect(find.text('Quang'), findsOneWidget);
      expect(find.text('quang@example.com'), findsOneWidget);
      expect(find.text('Cloud Sync'), findsOneWidget);
      expect(find.byType(PixelLogo), findsOneWidget);
      // Drawer dùng bản đầy đủ (có cầu vồng ở ống kính), không phải bản tối giản.
      expect(tester.widget<PixelLogo>(find.byType(PixelLogo)).simple, isFalse);

      await tester.tap(find.byTooltip('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(loggedOut, isTrue);
    });
  });
}
