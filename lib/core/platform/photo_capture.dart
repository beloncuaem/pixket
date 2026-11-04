export 'photo_capture_core.dart';
export 'photo_capture_stub.dart'
    if (dart.library.io) 'photo_capture_io.dart'
    if (dart.library.js_interop) 'photo_capture_web.dart';
