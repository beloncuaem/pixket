import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pixket/core/platform/gallery_saver.dart';
import 'package:pixket/core/utils/save_to_gallery.dart';

/// Nhánh signed URL cần một client không ra mạng; ba byte dưới đây là "ảnh"
/// giả để test khẳng định đúng bytes tải về được trao cho seam.
class _FakeClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(Uint8List.fromList([1, 2, 3])),
        200,
        contentLength: 3,
      );
}

/// Saver giả của nền tảng lưu được ảnh: ghi lại những gì seam nhận để test thấy
/// bytes và tên đi qua nguyên bản, thay chỉ tin vào "không có thông báo".
class _RecordingSaver implements GallerySaver {
  Uint8List? savedBytes;
  String? savedName;

  @override
  bool get isSupported => true;

  @override
  Future<String?> saveImage(Uint8List bytes, {required String name}) async {
    savedBytes = bytes;
    savedName = name;
    return null;
  }
}

/// Đại diện cho máy không có thư viện ảnh để lưu — đúng trường hợp mà bản cũ
/// nuốt `MissingPluginException` rồi báo chung "Không lưu được ảnh về máy."
class _UnsupportedSaver implements GallerySaver {
  const _UnsupportedSaver();
  @override
  bool get isSupported => false;
  @override
  Future<String?> saveImage(Uint8List bytes, {required String name}) async =>
      'Pixket không lưu được ảnh vào thư viện trên máy này.';
}

void main() {
  test('khoản chi không có ảnh thì báo rõ ràng', () async {
    expect(
      await saveReceiptToGallery(
        signedUrl: null,
        bytes: null,
        name: 'pixket_1',
        saver: _RecordingSaver(),
      ),
      'Khoản chi này chưa có ảnh để tải.',
    );
  });

  test('signed URL trả lỗi vẫn nói đúng chỗ hỏng thay vì lỗi chung', () async {
    final message = await saveReceiptToGallery(
      signedUrl: 'https://signed/a.jpg',
      bytes: null,
      name: 'pixket_1',
      client: MockClient((_) async => http.Response('gone', 404)),
      saver: _RecordingSaver(),
    );

    expect(message, 'Không tải được ảnh từ Cloud.');
  });

  test('signed URL chỉ toàn khoảng trắng tính như chưa có ảnh, không ném', () async {
    // Case "tệp cục bộ không tồn tại" của bản cũ chuyển thành đây: đọc draft đã
    // sang caller, nên điều còn lại phải khoá ở file này là giá trị rỗng/vắng
    // mặt không được biến thành Uri.parse('') rồi ném toạc ra UI.
    final saver = _RecordingSaver();
    final message = await saveReceiptToGallery(
      signedUrl: '   ',
      bytes: null,
      name: 'pixket_1',
      saver: saver,
    );

    expect(message, 'Khoản chi này chưa có ảnh để tải.');
    expect(saver.savedBytes, isNull);
  });

  test('bytes có sẵn đi qua seam nguyên bản và không gọi mạng', () async {
    final saver = _RecordingSaver();
    final message = await saveReceiptToGallery(
      signedUrl: null,
      bytes: Uint8List.fromList([7, 8, 9]),
      name: 'pixket_1',
      // 500 cố ý: nếu code còn đi tải ảnh khi đã có bytes thì thông báo đổi
      // thành lỗi Cloud và test đỏ, chứ không im lặng tốn một request.
      client: MockClient((_) async => http.Response('x', 500)),
      saver: saver,
    );

    expect(message, isNull);
    expect(saver.savedBytes, Uint8List.fromList([7, 8, 9]));
    expect(saver.savedName, 'pixket_1');
  });

  test('signed URL là bản được lưu khi cả hai nguồn đều có', () async {
    final saver = _RecordingSaver();
    final message = await saveReceiptToGallery(
      signedUrl: 'https://example.test/a.jpg',
      bytes: Uint8List.fromList([7, 8, 9]),
      name: 'pixket_1',
      client: _FakeClient(),
      saver: saver,
    );

    // Ưu tiên signed URL giữ nguyên như bản cũ: đó là ảnh người dùng đang thấy.
    expect(message, isNull);
    expect(saver.savedBytes, Uint8List.fromList([1, 2, 3]));
  });

  test(
    'nền tảng không lưu được ảnh thì nói đúng lý do, không nói chung chung',
    () async {
      final message = await saveReceiptToGallery(
        signedUrl: 'https://example.test/a.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
        name: 'a.jpg',
        client: _FakeClient(),
        saver: const _UnsupportedSaver(),
      );
      expect(message, 'Pixket không lưu được ảnh vào thư viện trên máy này.');
    },
  );
}
