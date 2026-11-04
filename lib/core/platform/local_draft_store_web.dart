import 'dart:typed_data';

import 'local_draft_store_core.dart';

/// Draft web chỉ sống trong phiên: reload là mất, chấp nhận theo spec cha mục 13.
/// Không dùng blob URL vì preview render từ bytes, khỏi phải revoke.
class WebLocalDraftStore extends LocalDraftStore {
  final Map<String, Uint8List> _drafts = {};
  int _counter = 0;

  @override
  Future<String> save(
    Uint8List bytes, {
    required String extension,
    required bool squared,
  }) async {
    final suffix = squared ? '_sq' : '';
    final handle = 'pixket-draft://${_counter++}$suffix.$extension';
    _drafts[handle] = bytes;
    return handle;
  }

  @override
  Future<Uint8List?> readBytes(String handle) async => _drafts[handle];

  @override
  Future<bool> exists(String handle) async => _drafts.containsKey(handle);

  @override
  Future<void> delete(String handle) async => _drafts.remove(handle);
}

LocalDraftStore localDraftStore = WebLocalDraftStore();
