import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../platform/gallery_saver.dart';

/// Lưu ảnh khoản chi vào thư viện của máy. Trả về thông báo tiếng Việt cho
/// người dùng, hoặc null khi thành công.
///
/// Ưu tiên signed URL vì đó là bản đang hiển thị; [bytes] là ảnh cục bộ mà
/// caller đã đọc từ draft — handle ra sao là việc của caller, file này chỉ nhận
/// bytes. [client] và [saver] tiêm vào để unit test không cần mạng lẫn plugin.
Future<String?> saveReceiptToGallery({
  required String? signedUrl,
  required Uint8List? bytes,
  required String name,
  http.Client? client,
  GallerySaver? saver,
}) async {
  final target = saver ?? gallerySaver;

  // Bản cũ bắt `catch (_)` toàn hàm, nên trên nền tảng thiếu plugin mỗi lần bấm
  // đều nhận "Không lưu được ảnh về máy." dù lý do không liên quan thư viện. Từ
  // giờ mỗi câu tin phải có một thủ phạm: nền tảng thì stub trả lời, tải hỏng thì
  // StateError trả lời, ghi hỏng thì seam trả lời. Hỏi nền tảng trước để khỏi tải
  // về một ảnh chắc chắn không lưu được.
  if (!target.isSupported) return gallerySaveUnsupportedMessage;

  final Uint8List? image;
  try {
    // signed URL thắng [bytes] đúng như bản cũ: khi cả hai có thì ảnh người dùng
    // đang nhìn thấy trên feed mới là bản đáng lưu về máy.
    image = await _bytesFromUrl(signedUrl, client) ?? bytes;
  } on StateError {
    return 'Không tải được ảnh từ Cloud.';
  }
  if (image == null) return 'Khoản chi này chưa có ảnh để tải.';

  return target.saveImage(image, name: name);
}

/// Bytes của ảnh tại signed URL; null khi không có URL nào, và ném [StateError]
/// khi URL trả về lỗi để caller phân biệt "chưa có ảnh" với "ảnh hỏng trên Cloud".
Future<Uint8List?> _bytesFromUrl(String? signedUrl, http.Client? client) async {
  final url = signedUrl?.trim();
  if (url == null || url.isEmpty) return null;

  final response = await (client ?? http.Client()).get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw StateError('signed URL trả ${response.statusCode}');
  }
  return response.bodyBytes;
}
