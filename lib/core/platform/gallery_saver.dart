import 'dart:typed_data';

// Façade conditional: impl thật chọn theo nền tảng, code chung chỉ biết lớp dưới
// đây. Hai seam trước tách lớp trừu tượng sang `_core.dart` để impl không phải
// import lại façade; ở đây brief khai đúng bốn file nên để chung một chỗ, và các
// impl import trở lại file này — vòng import hợp lệ trong Dart, dart2js compile
// bình thường (`flutter build web` exit 0).
export 'gallery_saver_stub.dart'
    if (dart.library.io) 'gallery_saver_io.dart'
    if (dart.library.js_interop) 'gallery_saver_web.dart';

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
/// Đặt cạnh nhau để `_io` và `_web` không hai bản sao tiếng Việt drift.
const String gallerySaveFailedMessage = 'Không lưu được ảnh vào thư viện.';
