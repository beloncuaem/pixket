@Tags(['web'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/platform/local_draft_store.dart';
import 'package:pixket/core/platform/local_draft_store_web.dart';
import 'package:pixket/core/utils/square_image.dart';

Uint8List bytes3(int seed) => Uint8List.fromList([seed, seed + 1, seed + 2]);

void main() {
  // Kiểu khai báo lấy từ façade để test chứng minh seam expose lớp web.
  late LocalDraftStore store;

  setUp(() => store = WebLocalDraftStore());

  test('handle là key pixket-draft://, không phải blob URL', () async {
    final handle = await store.save(
      bytes3(1),
      extension: 'jpg',
      squared: false,
    );
    expect(handle, 'pixket-draft://0.jpg');
    expect(await store.readBytes(handle), bytes3(1));
    expect(await store.exists(handle), isTrue);
  });

  test('squared: true ghép marker _sq vào handle', () async {
    final handle = await store.save(
      bytes3(4),
      extension: 'jpg',
      squared: true,
    );
    expect(handle, 'pixket-draft://0_sq.jpg');
    expect(isSquareImagePath(handle), isTrue);
  });

  test('hai draft liên tiếp không đè lên nhau', () async {
    final a = await store.save(bytes3(10), extension: 'jpg', squared: false);
    final b = await store.save(bytes3(20), extension: 'png', squared: false);
    expect(a, 'pixket-draft://0.jpg');
    expect(b, 'pixket-draft://1.png');
    expect(await store.readBytes(a), bytes3(10));
    expect(await store.readBytes(b), bytes3(20));
  });

  test('delete thì mất bản nhưng không ném', () async {
    final handle = await store.save(
      bytes3(1),
      extension: 'jpg',
      squared: false,
    );
    await store.delete(handle);
    expect(await store.exists(handle), isFalse);
    expect(await store.readBytes(handle), isNull);
    await store.delete(handle);
  });

  test('handle của phiên khác trả null thay vì ném', () async {
    expect(await store.readBytes('pixket-draft://9.jpg'), isNull);
    expect(await store.exists('pixket-draft://9.jpg'), isFalse);
  });
}
