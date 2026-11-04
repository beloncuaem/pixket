export 'local_draft_store_core.dart';
export 'local_draft_store_stub.dart'
    if (dart.library.io) 'local_draft_store_io.dart'
    if (dart.library.js_interop) 'local_draft_store_web.dart';
