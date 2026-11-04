import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'gallery_saver_core.dart';

/// Nhánh web: trình duyệt không có "thư viện ảnh" để ghi vào, cách duy nhất là
/// đẩy một tệp xuống mục Tải xuống của browser — blob URL + `<a download>` rồi
/// click. Không plugin nào tham gia, nên R3 không còn nợ gì ở đây.
class WebGallerySaver extends GallerySaver {
  const WebGallerySaver();

  /// Tải tệp xuống luôn khả dụng trên browser, không cần quyền nào.
  @override
  bool get isSupported => true;

  @override
  Future<String?> saveImage(Uint8List bytes, {required String name}) async {
    // Browser không đoán định dạng từ bytes: blob phải tự khai. JPEG vì đó là
    // định dạng `squareBytes` sinh ra trên web và là định dạng của gần hết ảnh
    // đã upload; chữ ký seam không có tham số extension nên không chính xác hơn
    // được. Tên cũng phải có đuôi, vì browser dùng nguyên chuỗi `download` làm
    // tên tệp chứ không tự thêm đuôi như `gal` vẫn làm.
    final blob = web.Blob(
      <JSAny>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'image/jpeg'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = name.contains('.') ? name : '$name.jpg';
    final body = web.document.body;
    var attached = false;
    try {
      // Firefox bỏ qua click trên neo chưa gắn vào tài liệu, nên phải attach;
      // body vắng mặt chỉ xảy ra ngoài ngữ cảnh trang, khi đó click vẫn chạy
      // trên Chrome/Edge và chúng ta không còn chỗ nào để gắn.
      body?.appendChild(anchor);
      attached = true;
      anchor.click();
    } catch (_) {
      // Gắn neo hoặc click hỏng là browser từ chối ngay trước mắt: nói thẳng
      // lần ghi hỏng thay vì báo thành công như `return null` cũ.
      web.URL.revokeObjectURL(url);
      return gallerySaveFailedMessage;
    } finally {
      // Chỉ gỡ khi thực sự đã gắn: gỡ một neo chưa attach là DOMException, mà DOMException
      // ném ra trong finally sẽ thay thế thông báo ở nhánh catch và người dùng nhận câu
      // chung của caller thay vì câu có thủ phạm.
      if (attached) body?.removeChild(anchor);
    }
    // Revoke ở task sau: nhả blob URL ngay sau click là race đã biết — có
    // browser kịp khởi động tải trước khi URL chết, có browser thì không, và ta
    // không quan sát được phía nào thắng. Blob còn giữ tấm ảnh trong bộ nhớ một
    // giây, đổi lấy việc không cắt ngang lượt tải người dùng vừa bấm.
    Future.delayed(
      const Duration(seconds: 1),
      () => web.URL.revokeObjectURL(url),
    );
    return null;
  }
}

GallerySaver gallerySaver = const WebGallerySaver();
