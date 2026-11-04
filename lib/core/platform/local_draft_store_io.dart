import 'dart:io';
import 'dart:typed_data';

import '../utils/square_image.dart';
import 'local_draft_store_core.dart';

/// Draft giữ trên đĩa để người dùng chụp xong, tắt app trước khi upload vẫn còn
/// (spec cha mục 5.1.1). `path_provider` đã bị gỡ nên lấy `Directory.systemTemp`:
/// trên Android biến môi trường TMPDIR trỏ thẳng vào thư mục cache của app.
class IoLocalDraftStore extends LocalDraftStore {
  /// [dir] cho unit test trỏ draft vào thư mục tạm riêng; để trống thì dùng
  /// cache của app.
  IoLocalDraftStore({this.dir});

  final Directory? dir;

  Directory get _root {
    final dir = this.dir;
    if (dir != null) return dir;
    final root = Directory('${Directory.systemTemp.path}/pixket_drafts');
    if (!root.existsSync()) root.createSync(recursive: true);
    return root;
  }

  String _name(String extension, bool squared) =>
      'pixket_${DateTime.now().microsecondsSinceEpoch}'
      '${squared ? squareImageSuffix : '.$extension'}';

  @override
  Future<String> save(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  }) async {
    final file = File('${_root.path}/${_name(extension, squared)}');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<Uint8List?> readBytes(String handle) async {
    // readBytes/exists cố ý KHÔNG neo [_root]: ảnh legacy trước seam bytes vẫn
    // là đường dẫn tuyệt đối cạnh tệp tạm của camera plugin (`writeSquareCopy`
    // cũ ghi `pixket_<micros>_sq.jpg` vào chính thư mục đó), và đường dẫn ấy
    // đang chảy vào đây từ expense_repository._resolveImage (dòng 60) khi sửa
    // khoản chi cũ và từ feed_photo_page._localReceiptBytes (dòng 190) khi lưu
    // ảnh về thư viện. Chặn như `delete` bên dưới sẽ biến hai luồng Android đó
    // thành StateError thay vì đọc được ảnh.
    final file = File(handle);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> exists(String handle) => File(handle).exists();

  @override
  Future<void> delete(String handle) async {
    // `handle` đến từ `expense.imagePath` — dữ liệu đọc về từ DB, kẻ khác có
    // thể ghi được (lib/providers/expense_provider.dart:191), nên nó không được
    // biến thành lệnh xóa tệp tùy ý. Chỉ xóa khi đường dẫn resolve nằm trong
    // thư mục draft; mọi trường hợp còn lại coi như vô sự vì delete hứa không
    // ném.
    final file = await _insideDrafts(handle);
    if (file == null) return;
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // Không làm mất luồng chính vì một tệp tạm không xóa được.
      }
    }
  }

  /// File của [handle] khi nó nằm thật sự dưới [_root] sau khi đã đi hết
  /// symlink; null khi đường dẫn bịa, đã mất, hoặc trốn khỏi thư mục draft.
  Future<File?> _insideDrafts(String handle) async {
    final String resolved;
    try {
      resolved = await File(handle).resolveSymbolicLinks();
    } on FileSystemException {
      return null;
    }
    final root = await _root.resolveSymbolicLinks();
    return _isUnder(resolved, root) ? File(resolved) : null;
  }

  /// So sánh theo prefix có dấu ngăn cách, để `.../pixket_drafts_evil/x.jpg`
  /// không được tính là con của `.../pixket_drafts`.
  bool _isUnder(String path, String root) {
    final normalizedPath = path.replaceAll(r'\', '/');
    final normalizedRoot = root.replaceAll(r'\', '/');
    return normalizedPath.startsWith('$normalizedRoot/');
  }
}

LocalDraftStore localDraftStore = IoLocalDraftStore();
