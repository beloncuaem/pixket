import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;

/// Lưu ảnh khoản chi vào thư viện của máy. Trả về thông báo tiếng Việt cho
/// người dùng, hoặc null khi thành công.
///
/// Ưu tiên signed URL vì đó là bản đang hiển thị; ảnh cục bộ chỉ còn với khoản
/// chi chưa upload. [client] tiêm vào để unit test không cần mạng.
Future<String?> saveReceiptToGallery({
  required String? signedUrl,
  required String? localPath,
  required String name,
  http.Client? client,
}) async {
  try {
    final bytes = await _readBytes(
      signedUrl: signedUrl,
      localPath: localPath,
      client: client,
    );
    if (bytes == null) return 'Khoản chi này chưa có ảnh để tải.';

    await Gal.putImageBytes(bytes, name: name);
    return null;
  } on GalException catch (error) {
    return error.type == GalExceptionType.accessDenied
        ? 'Pixket cần quyền lưu ảnh vào thư viện.'
        : 'Không lưu được ảnh vào thư viện.';
  } catch (_) {
    return 'Không lưu được ảnh về máy.';
  }
}

Future<Uint8List?> _readBytes({
  required String? signedUrl,
  required String? localPath,
  http.Client? client,
}) async {
  final url = signedUrl?.trim();
  if (url != null && url.isNotEmpty) {
    final response = await (client ?? http.Client()).get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw StateError('signed URL trả ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  final path = localPath?.trim();
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('không tìm thấy $path');
  }
  return file.readAsBytes();
}
