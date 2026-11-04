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
    final file = File(handle);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> exists(String handle) => File(handle).exists();

  @override
  Future<void> delete(String handle) async {
    final file = File(handle);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // Không làm mất luồng chính vì một tệp tạm không xóa được.
      }
    }
  }
}

LocalDraftStore localDraftStore = IoLocalDraftStore();
