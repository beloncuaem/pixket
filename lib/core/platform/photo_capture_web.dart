import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_capture_core.dart';

/// Nhánh web: **không** bật `camera_web` dù plugin đó có đăng ký thật.
///
/// Lý do đo được ở Lượt 1 của audit: screen này không tự xin quyền (không có
/// `permission_handler`), nên khi browser còn `permission = 'prompt'` thì
/// `getUserMedia` không bao giờ hoàn tất và người dùng treo vĩnh viễn ở
/// "Đang mở camera…". `image_picker` thay vào đó mở `<input capture>` — chính
/// trình duyệt hỏi quyền tại thời điểm người dùng bấm, và luôn có đường thoát.
class WebPhotoCapture extends PhotoCapture {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<void> initialize() async {}

  @override
  bool get isReady => false;

  @override
  String? get errorMessage => null;

  @override
  bool get supportsLiveViewfinder => false;

  @override
  bool get canSwitchCamera => false;

  @override
  Future<void> useNextCamera() async {}

  @override
  Future<Uint8List?> capture() async =>
      (await _pick(ImageSource.camera))?.bytes;

  @override
  Future<({Uint8List bytes, String extension})?> pickFromGallery() =>
      _pick(ImageSource.gallery);

  Future<({Uint8List bytes, String extension})?> _pick(
    ImageSource source,
  ) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (image == null) return null;
    return (
      bytes: await image.readAsBytes(),
      extension: image.path.split('.').last.toLowerCase(),
    );
  }

  /// Screen không gọi cái này khi `supportsLiveViewfinder == false`; giữ
  /// `SizedBox.shrink()` để nhỡ có gọi cũng không vẽ gì đè lên hướng dẫn.
  @override
  Widget buildViewfinder(BuildContext context, {double aspectRatio = 1}) =>
      const SizedBox.shrink();

  @override
  void dispose() {}
}

PhotoCapture photoCapture = WebPhotoCapture();
