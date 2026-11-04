import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';

import 'gallery_saver.dart';

/// Nhánh mobile/desktop: `gal` tự xin quyền và tự thêm đuôi tệp, nên tên được
/// trao nguyên bản như người dùng thấy trong thư viện.
class IoGallerySaver extends GallerySaver {
  const IoGallerySaver();

  /// `gal` chỉ đăng ký plugin cho Android/iOS/macOS/Windows; ngoài danh sách đó
  /// (Linux, hay `flutter test` trên một runner Linux) mọi lệnh ghi là
  /// `MissingPluginException`. Trả lời theo đúng danh sách ấy để người dùng nhận
  /// lý do thật thay vì một crash, và để test chạy như nhau trên mọi OS. Không
  /// hỏi `Gal.hasAccess()`: quyền thật do chính lần ghi trả lời bằng [GalException].
  @override
  bool get isSupported =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows;

  @override
  Future<String?> saveImage(Uint8List bytes, {required String name}) async {
    try {
      await Gal.putImageBytes(bytes, name: name);
      return null;
    } on GalException catch (error) {
      // Hai chuỗi này giữ nguyên từ bản cũ: plugin báo loại lỗi thì app mới dịch
      // được thành thứ người dùng hiểu, và màn hình đã quen hai câu đó.
      return error.type == GalExceptionType.accessDenied
          ? 'Pixket cần quyền lưu ảnh vào thư viện.'
          : gallerySaveFailedMessage;
    }
  }
}

GallerySaver gallerySaver = const IoGallerySaver();
