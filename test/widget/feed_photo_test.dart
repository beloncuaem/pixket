import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/platform/gallery_saver.dart';
import 'package:pixket/core/platform/local_draft_store.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/data/models/category.dart';
import 'package:pixket/data/models/expense.dart';
import 'package:pixket/data/models/priority_level.dart';
import 'package:pixket/screens/camera/feed_grid_screen.dart';
import 'package:pixket/screens/camera/feed_photo_page.dart';
import 'package:pixket/widgets/pixel/pixel_badge.dart';
import 'package:pixket/widgets/pixel/pixel_receipt_image.dart';
import 'package:pixket/widgets/pixel/pixel_star_field.dart';

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

/// Máy mà plugin chết giữa chừng: nền tảng nói lưu được, rồi lần ghi ném một lỗi
/// không gọi được tên. Chỉ màn hình mới chứng minh được là app không im lặng.
class _ThrowingSaver implements GallerySaver {
  @override
  bool get isSupported => true;

  @override
  Future<String?> saveImage(Uint8List bytes, {required String name}) =>
      throw StateError('boom');
}

/// Draft trả bytes ngay lập tức: chỉ cần một giá trị không-null để luồng lưu ảnh
/// đi tới tận seam, còn tệp thật thì testWidgets không đọc được (fake-async).
class _BytesDraftStore extends LocalDraftStore {
  const _BytesDraftStore();

  @override
  Future<Uint8List?> readBytes(String handle) async =>
      Uint8List.fromList([1, 2, 3]);

  @override
  Future<String> save(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  }) async => 'unused';

  @override
  Future<bool> exists(String handle) async => true;

  @override
  Future<void> delete(String handle) async {}
}

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

  testWidgets('nền sao phủ toàn trang, không để viền đen quanh ảnh', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(photoPage()));
    final page = tester.getRect(find.byType(FeedPhotoPage));
    // Một trường sao duy nhất phủ full-bleed: panel dưới trong suốt nên nền
    // sao chạy liền từ mép trên xuống mép dưới.
    expect(find.byType(PixelStarField), findsOneWidget);
    expect(tester.getSize(find.byType(PixelStarField)), page.size);
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

  testWidgets('lỗi không tên vẫn ra SnackBar, không im lặng', (tester) async {
    // imagePath là đường dẫn tệp, không phải storage path → storagePathOf trả
    // null → _localReceiptBytes đọc bytes từ draft, nên luồng đi tới tận
    // saveImage; saver giả ném ở đó mô đúng "plugin chết giữa chừng". Draft giả
    // vì `IoLocalDraftStore.readBytes` là I/O thật, nằm ngoài fake-async của
    // testWidgets nên chuỗi await của màn hình không bao giờ hoàn tất.
    // displayImageUrl vẫn null nên không gọi mạng.
    final previousStore = localDraftStore;
    final previousSaver = gallerySaver;
    localDraftStore = const _BytesDraftStore();
    gallerySaver = _ThrowingSaver();
    addTearDown(() {
      localDraftStore = previousStore;
      gallerySaver = previousSaver;
    });

    await tester.pumpWidget(
      wrap(
        FeedPhotoPage(
          expense: photos.first.copyWith(imagePath: '/tmp/pixket_legacy/a.jpg'),
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('feed-download')));
    await tester.pumpAndSettle();

    expect(find.text('Không lưu được ảnh về máy.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
