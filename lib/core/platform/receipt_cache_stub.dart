/// Mặc định của conditional export — chỉ chạy trên nền tảng không có
/// `dart.library.io` lẫn `dart.library.js_interop`. Ném to là có chủ đích: đăng
/// xuất mà cache không xóa được thì ảnh của người dùng cũ còn nằm trong phiên.
Future<void> clearReceiptCache() =>
    throw UnsupportedError('Pixket chưa xóa được cache ảnh trên nền tảng này.');

Future<void> evictReceiptImage(String url, {String? cacheKey}) =>
    throw UnsupportedError('Pixket chưa xóa được cache ảnh trên nền tảng này.');
