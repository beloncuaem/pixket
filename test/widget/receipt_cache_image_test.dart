import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/platform/receipt_cache_image.dart';

/// JPEG tối thiểu (4 byte). File test không share fixture, nên mỗi file tự sinh
/// như `test/unit/local_draft_store_test.dart` vẫn làm.
Uint8List tinyJpeg() => Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xD9]);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 120, height: 120, child: child)),
);

/// Hai nhánh của `ReceiptLocalImage` cùng cho ra một `Image`, nên muốn biết ảnh
/// đến từ đâu thì phải nhìn loại provider: `MemoryImage` là bytes, `FileImage`
/// là handle trên nền tảng có hệ tệp.
Type _provider(WidgetTester tester) =>
    tester.widget<Image>(find.byType(Image)).image.runtimeType;

void main() {
  testWidgets('bytes thì render trực tiếp, không đụng tới tệp', (tester) async {
    await tester.pumpWidget(_wrap(ReceiptLocalImage(bytes: tinyJpeg())));

    expect(_provider(tester), MemoryImage);
    expect(find.text('Không tải được ảnh'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chỉ có handle thì ảnh đọc bằng FileImage', (tester) async {
    await tester.pumpWidget(
      _wrap(const ReceiptLocalImage(draftHandle: '/tmp/khong_co_file.jpg')),
    );

    expect(_provider(tester), FileImage);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bytes thắng handle khi cả hai đều có', (tester) async {
    // Đổi thứ tự thành handle-trước thì ảnh vừa chụp trên Android phải đọc lại từ
    // đĩa mỗi lần mở form, nên ưu tiên bytes là hành vi có chủ đích.
    await tester.pumpWidget(
      _wrap(
        ReceiptLocalImage(
          draftHandle: '/tmp/khong_co_file.jpg',
          bytes: tinyJpeg(),
        ),
      ),
    );

    expect(_provider(tester), MemoryImage);
  });

  testWidgets('không handle lẫn bytes thì chỉ có placeholder', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ReceiptLocalImage(
          placeholder: (_) => const Text(
            'Không tải được ảnh',
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.text('Không tải được ảnh'), findsOneWidget);
  });

  testWidgets('ảnh mạng đi qua ReceiptCacheImage', (tester) async {
    await tester.pumpWidget(
      _wrap(const ReceiptCacheImage(url: 'https://signed/noon.png')),
    );

    expect(find.byType(ReceiptCacheImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
