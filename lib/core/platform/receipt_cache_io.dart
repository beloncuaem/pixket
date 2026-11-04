import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Xóa sạch hai tầng cache ảnh của nền tảng này: ảnh đã giải mã trong RAM và tệp
/// `flutter_cache_manager` ghi trên đĩa.
Future<void> clearReceiptCache() async {
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
  await DefaultCacheManager().emptyCache();
}

/// Buột một ảnh cụ thể phải tải lại. `cacheKey` là path object trong Storage chứ
/// không phải signed URL — signed URL đổi mỗi lần ký nên không dùng làm khóa.
Future<void> evictReceiptImage(String url, {String? cacheKey}) async {
  await CachedNetworkImage.evictFromCache(url, cacheKey: cacheKey);
}
