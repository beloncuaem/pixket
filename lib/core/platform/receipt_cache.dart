// Façade cache ảnh hóa đơn: hai hàm dưới đây có mặt ở mọi nền tảng, nhưng phần
// "xóa bộ nhớ đệm trên đĩa" chỉ tồn tại ở nhánh `_io`. Tách ra khỏi seam widget vì
// caller là provider/notifier, không phải widget tree.
export 'receipt_cache_stub.dart'
    if (dart.library.io) 'receipt_cache_io.dart'
    if (dart.library.js_interop) 'receipt_cache_web.dart';
