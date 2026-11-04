export 'square_image_core.dart';
export 'square_image_stub.dart'
    if (dart.library.io) 'square_image_io.dart'
    if (dart.library.js_interop) 'square_image_web.dart';
