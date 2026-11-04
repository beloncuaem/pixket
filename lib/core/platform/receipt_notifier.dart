export 'receipt_notifier_core.dart';
export 'receipt_notifier_stub.dart'
    if (dart.library.io) 'receipt_notifier_io.dart'
    if (dart.library.js_interop) 'receipt_notifier_web.dart';
