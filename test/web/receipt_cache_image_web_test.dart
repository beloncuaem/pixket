@Tags(['web'])
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/platform/local_draft_store.dart';
import 'package:pixket/core/platform/receipt_cache_image_web.dart'
    as web_render;

/// JPEG tối thiểu (4 byte), cách sinh quen thuộc của các test ảnh trong repo.
Uint8List tinyJpeg() => Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xD9]);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 120, height: 120, child: child)),
);

/// Hai test này chỉ có ý nghĩa khi chạy bằng Chrome trong CI (bước `--platform
/// chrome test/web` của Task 7): trên VM thì `localDraftStore` là nhánh tệp thật
/// nên đọc bytes cần I/O ngoài fake-async, còn nhánh web trả bytes bằng microtask.
void main() {
  testWidgets('handle được đọc qua store rồi mới vẽ ảnh', (tester) async {
    final handle = await localDraftStore.save(
      tinyJpeg(),
      extension: 'jpg',
      squared: false,
    );

    await tester.pumpWidget(
      _wrap(web_render.ReceiptLocalImage(draftHandle: handle)),
    );
    // Khung hình đầu chưa có bytes. Nếu widget bỏ qua handle thì ảnh không bao
    // giờ xuất hiện, kể cả sau khi chờ.
    expect(find.byType(Image), findsNothing);

    await tester.pump();
    expect(
      tester.widget<Image>(find.byType(Image)).image.runtimeType,
      MemoryImage,
    );

    await localDraftStore.delete(handle);
  }, skip: !kIsWeb);

  testWidgets('handle không còn trong store thì về placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        web_render.ReceiptLocalImage(
          draftHandle: 'pixket-draft://khong-ton-tai.jpg',
          placeholder: (_) => const Text(
            'Không tải được ảnh',
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.text('Không tải được ảnh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: !kIsWeb);
}
