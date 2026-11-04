// Façade của seam render ảnh hóa đơn: hai widget dưới đây có chữ ký giống hệt
// nhau ở ba nhánh, nên code chung (PixelReceiptImage) không cần biết nền tảng nào
// đang vẽ. Không có class nào ở file này vì mỗi nhánh tự định nghĩa widget —
// trừu tượng chung sẽ buộc nhánh web phải import plugin ảnh.
export 'receipt_cache_image_stub.dart'
    if (dart.library.io) 'receipt_cache_image_io.dart'
    if (dart.library.js_interop) 'receipt_cache_image_web.dart';
