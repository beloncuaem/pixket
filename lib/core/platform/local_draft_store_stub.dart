import 'dart:typed_data';

import 'local_draft_store_core.dart';

LocalDraftStore localDraftStore = const _UnsupportedLocalDraftStore();

class _UnsupportedLocalDraftStore extends LocalDraftStore {
  const _UnsupportedLocalDraftStore();

  Never _fail() => throw UnsupportedError(
    'Pixket chưa lưu được ảnh tạm trên nền tảng này.',
  );

  @override
  Future<String> save(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  }) => _fail();

  @override
  Future<Uint8List?> readBytes(String handle) => _fail();

  @override
  Future<bool> exists(String handle) => _fail();

  @override
  Future<void> delete(String handle) => _fail();
}
