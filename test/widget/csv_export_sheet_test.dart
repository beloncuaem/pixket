import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/screens/settings/csv_export_sheet.dart';

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier()
    : super(
        CategoryState(
          categories: [
            Category(
              id: 1,
              name: 'Ăn uống',
              icon: 'forkKnife',
              isDefault: true,
            ),
          ],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  _FakeAuthNotifier() : super(const AppAuthState(isConfigured: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryProvider.overrideWith((ref) => _FakeCategoryNotifier()),
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showCsvExportSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers three range choices and an export button', (
    tester,
  ) async {
    await openSheet(tester);
    expect(find.text('Xuất CSV (sao lưu)'), findsOneWidget);
    expect(find.text('THÁNG NÀY'), findsOneWidget);
    expect(find.text('TOÀN BỘ'), findsOneWidget);
    expect(find.text('TỰ CHỌN'), findsOneWidget);
    expect(find.text('Xuất và chia sẻ'), findsOneWidget);
  });

  testWidgets('opens with a default range label even when signed out', (
    tester,
  ) async {
    await openSheet(tester);
    // Sheet không được crash khi authState.user == null và phải hiện khoảng
    // ngày mặc định (Tháng này) dưới dạng "A – B".
    expect(find.textContaining('–'), findsOneWidget);
    expect(find.text('Xuất và chia sẻ'), findsOneWidget);
  });
}
