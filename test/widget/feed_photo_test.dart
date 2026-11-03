import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/data/models/category.dart';
import 'package:pixket/data/models/expense.dart';
import 'package:pixket/data/models/priority_level.dart';
import 'package:pixket/screens/camera/feed_grid_screen.dart';
import 'package:pixket/screens/camera/feed_photo_page.dart';
import 'package:pixket/widgets/pixel/pixel_badge.dart';
import 'package:pixket/widgets/pixel/pixel_receipt_image.dart';

const String _objectPath = '0f1c2b3d-4e5f-4a6b-8c9d-0e1f2a3b4c5d/a.png';

final photos = [
  Expense(
    id: 1,
    caption: 'Bún chả',
    amount: 60000,
    categoryId: 10,
    priority: 0,
    imagePath: _objectPath,
    createdAt: DateTime(2026, 11, 1, 12, 30),
  ),
  Expense(
    id: 2,
    caption: 'Xe bus',
    amount: 7000,
    categoryId: 11,
    priority: 3,
    createdAt: DateTime(2026, 11, 1, 9),
  ),
];

final categories = <int, Category>{
  10: Category(id: 10, name: 'Ăn uống', icon: 'forkKnife'),
  11: Category(id: 11, name: 'Đi lại', icon: 'car'),
};

const _canThiet = PriorityLevel(
  id: 0,
  name: 'Cần thiết',
  colorValue: 0xFF7BD8A8,
  sortOrder: 0,
);

/// Nền sao (Consumer + repeat vô hạn ở theme tối) nên cần ProviderScope; tắt
/// animation ở `builder` để cờ áp dụng cho cả route được push, nếu không
/// `pumpAndSettle` không bao giờ dừng.
Widget _app({required Widget home}) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: home,
  ),
);

Widget wrap(Widget child) => _app(
  home: Scaffold(body: SizedBox(width: 400, height: 560, child: child)),
);

Widget photoPage() => FeedPhotoPage(
  expense: photos.first,
  category: categories[10],
  priority: _canThiet,
  onEdit: () {},
  onDelete: () {},
);

void main() {
  testWidgets('lưới 3 cột, đủ số ảnh, tiêu đề đếm ảnh', (tester) async {
    await tester.pumpWidget(
      wrap(FeedGridScreen(expenses: photos, categoriesById: categories)),
    );
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(find.byType(PixelReceiptImage), findsNWidgets(2));
    expect(find.text('2 ảnh'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chạm ô lưới thì trả index qua Navigator.pop', (tester) async {
    int? popped;
    await tester.pumpWidget(
      _app(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<int>(
                  MaterialPageRoute(
                    builder: (_) => FeedGridScreen(
                      expenses: photos,
                      categoriesById: categories,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PixelReceiptImage).last);
    await tester.pumpAndSettle();
    expect(popped, 1);
  });

  testWidgets('lưới rỗng hiện empty state pixel', (tester) async {
    await tester.pumpWidget(
      wrap(const FeedGridScreen(expenses: [], categoriesById: {})),
    );
    expect(find.byType(GridView), findsNothing);
    expect(find.text('CHƯA CÓ KHOẢN CHI NÀO'), findsOneWidget);
    expect(find.text('Mở camera và chụp khoản chi đầu tiên.'), findsOneWidget);
  });

  testWidgets('trang ảnh hiện panel: badge, số tiền, ghi chú, ngày giờ', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(photoPage()));
    expect(find.byType(PixelReceiptImage), findsOneWidget);
    expect(find.byType(PixelBadge), findsNWidgets(2));
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Cần thiết'), findsOneWidget);
    expect(find.textContaining('60.000'), findsOneWidget);
    expect(find.text('Bún chả'), findsOneWidget);
    expect(find.textContaining('12:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nút sửa, tải ảnh và xóa có nhãn tiếng Việt và 48dp', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(photoPage()));
    for (final key in ['feed-edit', 'feed-download', 'feed-delete']) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(find.byTooltip('Chỉnh sửa khoản chi'), findsOneWidget);
    expect(find.byTooltip('Tải ảnh về máy'), findsOneWidget);
    expect(find.byTooltip('Chuyển vào thùng rác'), findsOneWidget);
  });

  testWidgets('ảnh là ô vuông nằm trọn phía trên panel, không bị che', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(photoPage()));
    final image = tester.getRect(find.byType(PixelReceiptImage));
    final panel = tester.getRect(find.byType(FeedCaptionPanel));
    expect(image.width, image.height);
    expect(image.bottom, lessThanOrEqualTo(panel.top));
  });

  testWidgets('ẩn bộ đếm khi không truyền vị trí ảnh', (tester) async {
    await tester.pumpWidget(wrap(photoPage()));
    expect(find.textContaining(RegExp(r'^\d+/\d+$')), findsNothing);

    await tester.pumpWidget(
      wrap(
        FeedPhotoPage(
          expense: photos.first,
          onEdit: () {},
          onDelete: () {},
          photoIndex: 3,
          photoCount: 12,
        ),
      ),
    );
    expect(find.text('3/12'), findsOneWidget);
  });

  testWidgets('trang ảnh không còn glass pill và placeholder cũ', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(photoPage()));
    expect(find.byType(PixelReceiptImage), findsOneWidget);
    expect(find.text('Ảnh không khả dụng'), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('không có danh mục thì panel vẫn vẽ badge Khác', (tester) async {
    await tester.pumpWidget(
      wrap(FeedPhotoPage(expense: photos[1], onEdit: () {}, onDelete: () {})),
    );
    expect(find.text('Khác'), findsOneWidget);
    expect(find.textContaining('7.000'), findsOneWidget);
  });
}
