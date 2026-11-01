import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/screens/categories/category_glyph_grid.dart';
import 'package:chi_tieu/screens/categories/manage_categories_screen.dart';
import 'package:chi_tieu/widgets/pixel/app_icon.dart';
import 'package:chi_tieu/widgets/pixel/pixel_badge.dart';
import 'package:chi_tieu/widgets/pixel/pixel_button.dart';
import 'package:chi_tieu/widgets/pixel/pixel_screen_header.dart';
import 'package:chi_tieu/widgets/pixel/pixel_text_field.dart';

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(List<Category> categories)
    : super(CategoryState(categories: categories));

  final List<String> added = [];

  @override
  Future<void> addCategory(String name, String icon) async {
    added.add('$name:$icon');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child, List<Category> categories, {double? textScale}) =>
    ProviderScope(
      overrides: [
        categoryProvider.overrideWith(
          (ref) => _FakeCategoryNotifier(categories),
        ),
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
        home: child,
      ),
    );

Category _c(int id, String name, {String icon = 'coffee', bool d = false}) =>
    Category(id: id, name: name, icon: icon, isDefault: d);

Future<void> openAddDialog(WidgetTester tester) async {
  await tester.tap(find.text('THÊM DANH MỤC'));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'validateCategoryName: rỗng / trùng / trùng bỏ qua hoa thường / hợp lệ',
    () {
      expect(
        validateCategoryName('  ', const ['Cà phê']),
        'Nhập tên danh mục.',
      );
      expect(
        validateCategoryName('Cà phê', const ['Cà phê']),
        contains('đã tồn tại'),
      );
      expect(
        validateCategoryName('cÀ PHÊ', const ['Cà phê']),
        contains('đã tồn tại'),
      );
      expect(validateCategoryName('Xe hơi', const ['Cà phê']), isNull);
    },
  );

  testWidgets('Danh mục: header pixel, nhãn MẶC ĐỊNH, không còn FAB', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const ManageCategoriesScreen(), [
        _c(1, 'Ăn uống', d: true),
        _c(2, 'Cà phê'),
      ]),
    );
    expect(find.byType(PixelScreenHeader), findsOneWidget);
    expect(find.text('QUẢN LÝ DANH MỤC'), findsOneWidget);
    expect(find.text('MẶC ĐỊNH'), findsOneWidget);
    expect(find.byType(PixelBadge), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byType(PixelButton), findsWidgets);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('Danh mục hệ thống không có nút sửa/xóa', (tester) async {
    await tester.pumpWidget(
      _wrap(const ManageCategoriesScreen(), [_c(1, 'Ăn uống', d: true)]),
    );
    expect(find.byTooltip('Sửa danh mục'), findsNothing);
    expect(find.byTooltip('Xóa danh mục'), findsNothing);
  });

  testWidgets('Danh mục tùy chỉnh có nút sửa/xóa', (tester) async {
    await tester.pumpWidget(
      _wrap(const ManageCategoriesScreen(), [_c(2, 'Cà phê')]),
    );
    expect(find.byTooltip('Sửa danh mục'), findsOneWidget);
    expect(find.byTooltip('Xóa danh mục'), findsOneWidget);
  });

  testWidgets('Thêm danh mục: lưới 19 ô 48dp, lưu gọi addCategory', (
    tester,
  ) async {
    final fake = _FakeCategoryNotifier([_c(2, 'Cà phê')]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoryProvider.overrideWith((ref) => fake)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ManageCategoriesScreen(),
        ),
      ),
    );
    await openAddDialog(tester);

    expect(find.text('DANH MỤC MỚI'), findsOneWidget);
    expect(find.byType(CategoryGlyphGrid), findsOneWidget);
    expect(find.byKey(const ValueKey('glyph-cell-forkKnife')), findsOneWidget);
    expect(find.byType(PixelTextField), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('glyph-cell-'),
      ),
      findsNWidgets(19),
    );

    final cell = tester.getSize(
      find.byKey(const ValueKey('glyph-cell-coffee')),
    );
    expect(cell.width, greaterThanOrEqualTo(48));
    expect(cell.height, greaterThanOrEqualTo(48));
    expect(find.byType(AppIcon), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('glyph-cell-forkKnife')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('categoryNameField')),
      'Ăn vặt',
    );
    await tester.tap(find.text('LƯU'));
    await tester.pumpAndSettle();

    expect(fake.added, ['Ăn vặt:forkKnife']);
    expect(find.text('DANH MỤC MỚI'), findsNothing);
  });

  testWidgets('Tên trùng hiện lỗi dưới field, không lưu', (tester) async {
    await tester.pumpWidget(
      _wrap(const ManageCategoriesScreen(), [_c(2, 'Cà phê')]),
    );
    await openAddDialog(tester);
    await tester.enterText(
      find.byKey(const ValueKey('categoryNameField')),
      'Cà phê',
    );
    await tester.tap(find.text('LƯU'));
    await tester.pump();
    expect(find.textContaining('đã tồn tại'), findsOneWidget);
    expect(find.byType(PixelTextField), findsOneWidget);
  });

  testWidgets('Danh mục 1.3x text scale không vỡ', (tester) async {
    await tester.pumpWidget(
      _wrap(const ManageCategoriesScreen(), [
        _c(1, 'Ăn uống', d: true),
      ], textScale: 1.3),
    );
    expect(tester.takeException(), isNull);
  });
}
