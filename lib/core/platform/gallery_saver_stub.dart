import 'dart:typed_data';

import 'gallery_saver_core.dart';

GallerySaver gallerySaver = const _UnsupportedGallerySaver();

/// Nền tảng không có plugin nào nhận ảnh: thay vì để `MissingPluginException`
/// bị nuốt thành "Không lưu được ảnh về máy." như bản cũ, nói thẳng lý do.
class _UnsupportedGallerySaver extends GallerySaver {
  const _UnsupportedGallerySaver();

  @override
  bool get isSupported => false;

  @override
  Future<String?> saveImage(Uint8List bytes, {required String name}) async =>
      gallerySaveUnsupportedMessage;
}
