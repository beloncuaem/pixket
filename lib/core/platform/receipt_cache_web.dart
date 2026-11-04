import 'package:flutter/painting.dart';

/// Trên browser chỉ có một tầng cache mà app với tới được: ảnh đã giải mã trong
/// RAM. Tầng thứ hai là HTTP cache của chính browser, nằm ngoài tầm với của trang
/// (phải có service worker + Cache API), nên để Plan 3 đóng.
Future<void> clearReceiptCache() async {
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
}

/// Key của ảnh mạng trên web đúng là URL (`Image.network` tạo `NetworkImage(url)`),
/// nên `cacheKey` không có gì để làm ở nhánh này — chữ ký giữ cho hai nhánh giống
/// nhau. Signed URL được ký lại mỗi phiên nên ảnh cũ không thể bị phát cho chữ ký
/// mới.
Future<void> evictReceiptImage(String url, {String? cacheKey}) async {
  PaintingBinding.instance.imageCache.evict(NetworkImage(url));
}
