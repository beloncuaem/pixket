import 'dart:typed_data';

/// Ảnh tạm giữa lúc chụp và lúc upload. `handle` là chuỗi mờ: trên mobile là
/// đường dẫn tệp, trên web là key trong bộ nhớ phiên. Code chung **không** được
/// giả định hình thức nào của nó ngoài `storagePathOf(handle) == null`.
abstract class LocalDraftStore {
  const LocalDraftStore();

  /// Ghi [bytes] và trả handle. `squared: true` để tên mang marker
  /// [squareImageSuffix] nhờ đó `isSquareImagePath` chặn việc cắt lần hai.
  Future<String> save(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  });

  /// null khi handle không còn trỏ tới tệp/blob nào (đã upload, đã xóa, hoặc
  /// handle legacy của máy khác).
  Future<Uint8List?> readBytes(String handle);

  Future<bool> exists(String handle);

  /// Không ném khi handle vắng mặt: gọi từ `dispose()` và từ luồng xóa ảnh.
  Future<void> delete(String handle);
}
