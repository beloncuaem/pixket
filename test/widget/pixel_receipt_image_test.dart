import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/data/models/expense.dart';
import 'package:pixket/widgets/pixel/app_icon.dart';
import 'package:pixket/widgets/pixel/pixel_receipt_image.dart';

const String _objectPath = '0f1c2b3d-4e5f-4a6b-8c9d-0e1f2a3b4c5d/noon.png';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SizedBox(width: 200, height: 200, child: child)),
);

void main() {
  testWidgets('không có nguồn ảnh → placeholder cloudOff + chữ', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const PixelReceiptImage()));
    expect(find.text('Không tải được ảnh'), findsOneWidget);
    expect(find.byType(AppIcon), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('file không tồn tại không làm crash cây widget', (tester) async {
    // dart:io không chạy trong fake-async của flutter_test nên Image.file
    // dừng ở trạng thái đang tải; điều kiểm chứng được là không có exception.
    await tester.pumpWidget(
      _wrap(const PixelReceiptImage(localPath: '/tmp/khong_co_file.jpg')),
    );
    expect(find.byType(PixelReceiptImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('receiptPlaceholder hiển thị cloudOff kèm nhãn chữ', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(receiptPlaceholder()));
    expect(find.text('Không tải được ảnh'), findsOneWidget);
    expect(find.byType(AppIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fromExpense dùng displayImageUrl và cacheKey là path', (
    tester,
  ) async {
    final expense = Expense(
      id: 1,
      caption: 'Ăn trưa',
      amount: 35000,
      categoryId: 2,
      priority: 1,
      imagePath: _objectPath,
      createdAt: DateTime(2026, 11, 1, 12),
    );
    final withUrl = expense.copyWith(
      displayImageUrl: 'https://signed/noon.png',
    );
    await tester.pumpWidget(_wrap(PixelReceiptImage.fromExpense(withUrl)));
    final network = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(network.imageUrl, 'https://signed/noon.png');
    expect(network.cacheKey, _objectPath);
  });

  testWidgets('có semanticLabel và bắt chạm khi có onTap', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        PixelReceiptImage(
          localPath: '/tmp/khong_co_file.jpg',
          semanticLabel: 'Ảnh khoản cà phê',
          onTap: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Ảnh khoản cà phê'), findsOneWidget);
    handle.dispose();
  });
}
