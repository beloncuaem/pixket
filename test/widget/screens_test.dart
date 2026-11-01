import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/screens/settings/settings_screen.dart';
import 'package:chi_tieu/screens/trash/trash_screen.dart';
import 'package:chi_tieu/screens/categories/manage_categories_screen.dart';
import 'package:chi_tieu/screens/onboarding/onboarding_screen.dart';
import 'package:chi_tieu/providers/theme_provider.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/providers/expense_provider.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/expense.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets('Renders settings options correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeProvider.overrideWith((ref) => _MockThemeNotifier()),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      expect(find.text('CÀI ĐẶT'), findsOneWidget);
      expect(find.text('Chế độ tối'), findsOneWidget);
      expect(find.text('Quản lý danh mục'), findsOneWidget);
      expect(find.text('Thùng rác'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('darkModeToggle')),
        findsOneWidget,
      ); // PixelChip thay SwitchListTile
    });
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('Renders onboarding elements', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      expect(find.text('BỎ QUA'), findsOneWidget);
      expect(find.text('Chào mừng đến với Piket'), findsOneWidget);
      expect(find.text('TIẾP TỤC'), findsOneWidget);
    });
  });

  group('ManageCategoriesScreen Widget Tests', () {
    testWidgets('Renders categories screen with add button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryProvider.overrideWith((ref) => _MockCategoryNotifier()),
          ],
          child: const MaterialApp(home: ManageCategoriesScreen()),
        ),
      );

      expect(find.text('QUẢN LÝ DANH MỤC'), findsOneWidget);
      expect(find.text('THÊM DANH MỤC'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Nhà ở'), findsOneWidget);
    });
  });

  group('TrashScreen Widget Tests', () {
    testWidgets('Renders empty trash screen when no deleted expenses', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryProvider.overrideWith((ref) => _MockCategoryNotifier()),
            expenseProvider.overrideWith((ref) => _MockExpenseNotifier()),
          ],
          child: const MaterialApp(home: TrashScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('THÙNG RÁC'), findsOneWidget);
      expect(find.text('THÙNG RÁC ĐANG TRỐNG'), findsOneWidget);
    });
  });
}

class _MockThemeNotifier extends StateNotifier<ThemeMode>
    implements ThemeNotifier {
  _MockThemeNotifier() : super(ThemeMode.light);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _MockCategoryNotifier()
    : super(
        CategoryState(
          categories: [
            Category(id: 1, name: 'Ăn uống', icon: '🍜', isDefault: true),
            Category(id: 2, name: 'Nhà ở', icon: '🏠', isDefault: true),
          ],
          isLoading: false,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _MockExpenseNotifier() : super(const ExpenseState());

  @override
  Future<List<Expense>> getDeletedExpenses() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
