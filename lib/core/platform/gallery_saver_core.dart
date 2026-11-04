import 'dart:typed_data';

/// Nơi lưu ảnh hóa đơn về máy. Mỗi nền tảng hiểu "thư viện ảnh" một kiểu —
/// Android/iOS ghi qua `gal`, trình duyệt tải một tệp xuống, còn máy không có
/// chỗ nào để ghi thì nói thẳng — nên phần còn lại của app không được import
/// plugin nào cả (R3 trong `test/unit/web_platform_boundary_test.dart`).
abstract class GallerySaver {
  const GallerySaver();

  /// null khi thành công; ngược lại là thông báo tiếng Việt cho người dùng.
  Future<String?> saveImage(Uint8List bytes, {required String name});

  /// Máy này có chỗ để lưu ảnh không. Code chung hỏi trước khi tải ảnh về, vì
  /// một ảnh chắc chắn không lưu được thì không đáng tốn một lượt mạng.
  bool get isSupported;
}

/// Lý do chung cho mọi nền tảng không lưu được ảnh. Đặt ở file khai báo để
/// `gallery_saver_stub.dart` và `save_to_gallery.dart` cùng trích một bản, tránh
/// hai tin nhắn tiếng Việt drift nhau.
const String gallerySaveUnsupportedMessage =
    'Pixket không lưu được ảnh vào thư viện trên máy này.';

/// Câu trả lời khi nền tảng có chỗ lưu nhưng lần ghi hỏng vì lý do khác quyền.
const String gallerySaveFailedMessage =
    'Không lưu được ảnh vào thư viện.';
