import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'photo_capture_core.dart';

PhotoCapture photoCapture = const _UnsupportedPhotoCapture();

class _UnsupportedPhotoCapture extends PhotoCapture {
  const _UnsupportedPhotoCapture();

  Never _fail() =>
      throw UnsupportedError('Pixket chưa chụp được ảnh trên nền tảng này.');

  @override
  Future<void> initialize() => _fail();

  @override
  bool get isReady => _fail();

  @override
  String? get errorMessage => _fail();

  @override
  bool get supportsLiveViewfinder => _fail();

  @override
  bool get canSwitchCamera => _fail();

  @override
  bool get isTakingPicture => _fail();

  @override
  Future<void> useNextCamera() => _fail();

  @override
  Future<Uint8List?> capture() => _fail();

  @override
  Future<({Uint8List bytes, String extension})?> pickFromGallery() => _fail();

  @override
  Widget buildViewfinder(BuildContext context) => _fail();

  @override
  void dispose() => _fail();
}
