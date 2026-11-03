import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/data/models/category.dart';
import 'package:pixket/data/models/expense.dart';
import 'package:pixket/providers/auth_provider.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/providers/expense_provider.dart';
import 'package:pixket/providers/theme_provider.dart';
import 'package:pixket/screens/settings/settings_screen.dart';
import 'package:pixket/screens/trash/trash_screen.dart';
import 'package:pixket/widgets/pixel/app_icon.dart';
import 'package:pixket/widgets/pixel/pixel_screen_header.dart';

Expense _deleted(int id) => Expense(
  id: id,
  caption: 'Cà phê $id',
  amount: 45000,
  categoryId: 1,
  createdAt: DateTime(2026, 10, 30, 9),
  deletedAt: DateTime(2026, 10, 5, 18),
);

class _FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _FakeExpenseNotifier(List<Expense> deletedRows)
    : _deletedRows = deletedRows,
      super(const ExpenseState());

  final List<Expense> _deletedRows;
  final List<int> restored = [];
  final List<int> purged = [];

  @override
  Future<List<Expense>> getDeletedExpenses() async => _deletedRows;

  @override
  Future<void> restoreExpense(int id) async => restored.add(id);

  @override
  Future<void> permanentlyDeleteExpense(Expense expense) async =>
      purged.add(expense.id!);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier()
    : super(
        CategoryState(
          categories: [Category(id: 1, name: 'Ăn uống', icon: 'coffee')],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
    : super(const AppAuthState(status: AuthStatus.authenticated));

  int signOutCalls = 0;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThemeNotifier extends StateNotifier<ThemeMode>
    implements ThemeNotifier {
  _FakeThemeNotifier() : super(ThemeMode.light);

  int toggles = 0;

  @override
  Future<void> toggleTheme() async {
    toggles++;
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _trash(
  List<Expense> rows, {
  _FakeExpenseNotifier? fake,
  double? textScale,
}) => ProviderScope(
  overrides: [
    expenseProvider.overrideWith((ref) => fake ?? _FakeExpenseNotifier(rows)),
    categoryProvider.overrideWith((ref) => _FakeCategoryNotifier()),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    builder: textScale == null
        ? null
        : (context, inner) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: inner!,
          ),
    home: const TrashScreen(),
  ),
);

Widget _settings({
  _FakeAuthNotifier? auth,
  _FakeThemeNotifier? theme,
  double? textScale,
}) => ProviderScope(
  overrides: [
    authProvider.overrideWith((ref) => auth ?? _FakeAuthNotifier()),
    themeProvider.overrideWith((ref) => theme ?? _FakeThemeNotifier()),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    builder: textScale == null
        ? null
        : (context, inner) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: inner!,
          ),
    home: const SettingsScreen(),
  ),
);

void main() {
  testWidgets('Thùng rác: hai nút hiện ra, không còn PopupMenuButton', (
    tester,
  ) async {
    await tester.pumpWidget(_trash([_deleted(7)]));
    await tester.pumpAndSettle();

    expect(find.byType(PixelScreenHeader), findsOneWidget);
    expect(find.text('THÙNG RÁC'), findsOneWidget);
    expect(find.byKey(const ValueKey('trash-restore-7')), findsOneWidget);
    expect(find.byKey(const ValueKey('trash-purge-7')), findsOneWidget);
    expect(find.text('XÓA VĨNH VIỄN'), findsWidgets);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    // Ngày xóa lấy từ deletedAt, không phải createdAt.
    expect(find.textContaining('Xóa ngày 05/10/2026'), findsOneWidget);
  });

  testWidgets('Thùng rác: KHÔI PHỤC gọi restoreExpense', (tester) async {
    final fake = _FakeExpenseNotifier([_deleted(7)]);
    await tester.pumpWidget(_trash(const [], fake: fake));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trash-restore-7')));
    await tester.pumpAndSettle();
    expect(fake.restored, [7]);
  });

  testWidgets('Thùng rác trống hiện empty state pixel', (tester) async {
    await tester.pumpWidget(_trash(const []));
    await tester.pumpAndSettle();
    expect(find.text('THÙNG RÁC ĐANG TRỐNG'), findsOneWidget);
    expect(find.byType(AppIcon), findsWidgets);
  });

  testWidgets('XÓA VĨNH VIỄN phải xác nhận; HỦY không xóa', (tester) async {
    final fake = _FakeExpenseNotifier([_deleted(7)]);
    await tester.pumpWidget(_trash(const [], fake: fake));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trash-purge-7')));
    await tester.pumpAndSettle();
    expect(find.text('XÓA VĨNH VIỄN?'), findsOneWidget);
    await tester.tap(find.text('HỦY'));
    await tester.pumpAndSettle();
    expect(fake.purged, isEmpty);

    // Nút trong dialog mang cùng nhãn với nút trên hàng nên lấy `.last`.
    await tester.tap(find.byKey(const ValueKey('trash-purge-7')).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('XÓA VĨNH VIỄN').last);
    await tester.pumpAndSettle();
    expect(fake.purged, [7]);
  });

  testWidgets('Cài đặt: 4 nhóm, bỏ mục xuất CSV, không SwitchListTile', (
    tester,
  ) async {
    await tester.pumpWidget(_settings());
    await tester.pumpAndSettle();

    for (final label in [
      'DỮ LIỆU',
      'GIAO DIỆN & BIỂU ĐỒ',
      'TÀI KHOẢN',
      'VỀ APP',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('CÀI ĐẶT'), findsOneWidget);
    expect(find.text('Xuất CSV (sao lưu)'), findsNothing);
    expect(find.text('Quản lý danh mục'), findsOneWidget);
    expect(find.text('Thùng rác'), findsOneWidget);
    expect(find.text('Chế độ tối'), findsOneWidget);
    expect(find.text('Phiên bản 2.5.0 • PIXEL JOURNAL'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsNothing);

    for (final box in tester.widgetList<DecoratedBox>(
      find.byType(DecoratedBox),
    )) {
      final decoration = box.decoration;
      if (decoration is BoxDecoration) expect(decoration.gradient, isNull);
    }
  });

  testWidgets('Cài đặt: công tắc đổi theme, đăng xuất cần xác nhận', (
    tester,
  ) async {
    final auth = _FakeAuthNotifier();
    final theme = _FakeThemeNotifier();
    await tester.pumpWidget(_settings(auth: auth, theme: theme));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('darkModeToggle')));
    await tester.pumpAndSettle();
    expect(theme.toggles, 1);

    // Nhóm hiệu ứng mới đẩy 'Đăng xuất' xuống dưới nếp gấp màn hình.
    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('ĐĂNG XUẤT?'), findsOneWidget);
    expect(auth.signOutCalls, 0);
    await tester.tap(find.text('ĐĂNG XUẤT'));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 1);
  });

  // Mỗi màn hình một test: pumpWidget trùng lên cùng ProviderScope với overrides
  // khác loại sẽ làm riverpod báo lỗi "Changing the kind of override".
  testWidgets('Thùng rác 1.3x text scale trên màn ngắn không vỡ', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_trash([_deleted(7)], textScale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('trash-restore-7')), findsOneWidget);
  });

  testWidgets('Cài đặt 1.3x text scale trên màn ngắn không vỡ', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_settings(textScale: 1.3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('VỀ APP'), findsOneWidget);
  });
}
