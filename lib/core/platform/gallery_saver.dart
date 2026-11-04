// Façade conditional của seam lưu ảnh: lớp trừu tượng và hai chuỗi tiếng Việt ở
// `gallery_saver_core.dart`, impl thật chọn theo nền tảng — cùng một hình dạng với
// ba seam còn lại (`square_image`, `local_draft_store`, `receipt_notifier`) để impl
// không phải import ngược façade và tạo vòng import.
export 'gallery_saver_core.dart';
export 'gallery_saver_stub.dart'
    if (dart.library.io) 'gallery_saver_io.dart'
    if (dart.library.js_interop) 'gallery_saver_web.dart';
