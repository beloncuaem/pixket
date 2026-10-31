import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/storage_paths.dart';

/// Ảnh hóa đơn lưu trong bucket private; mọi hiển thị đi qua signed URL.
class SupabaseStorageService {
  static const String bucketName = receiptBucket;
  static const int signedUrlTtlSeconds = 86400;

  /// Tải ảnh lên storage, trả về path dạng `<user_id>/<file>` (không trả URL).
  Future<String> uploadReceiptImage(String localFilePath) async {
    final client = SupabaseConfig.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('Vui lòng đăng nhập để lưu ảnh lên Cloud.');
    }

    final file = File(localFilePath);
    if (!await file.exists()) {
      throw StateError('Không tìm thấy ảnh để tải lên Cloud.');
    }

    final extension = localFilePath.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.lengthSync()}.$extension';
    final storagePath = '${user.id}/$fileName';

    await client.storage.from(bucketName).upload(
      storagePath,
      file,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );

    return storagePath;
  }

  /// Ký URL cho một lô path; path thất bại bị bỏ qua (UI sẽ hiện placeholder).
  Future<Map<String, String>> signPaths(
    List<String> paths, {
    int expiresIn = signedUrlTtlSeconds,
  }) async {
    if (paths.isEmpty) return const {};
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Chưa cấu hình Supabase.');
    }

    final results = await client.storage
        .from(bucketName)
        .createSignedUrlsResult(paths, expiresIn);

    final signed = <String, String>{};
    for (final result in results) {
      switch (result) {
        case SignedUrlSuccess(:final path, :final signedUrl):
          signed[path] = signedUrl;
        case SignedUrlFailure(:final path, :final error):
          debugPrint('Không ký được ảnh $path: $error');
      }
    }
    return signed;
  }

  Future<Map<String, String>> signPathsInBatches(
    Iterable<String> paths, {
    int chunkSize = 50,
  }) => signPathsInChunks(
    paths,
    chunkSize: chunkSize,
    signer: (batch) => signPaths(batch),
  );

  Future<void> deleteByPath(String storagePath) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Chưa cấu hình Supabase.');
    }
    await client.storage.from(bucketName).remove([storagePath]);
  }

  /// Xóa object từ bất kỳ giá trị nào từng lưu trong `image_url`.
  Future<void> deleteReceiptImage(String storedValue) async {
    final path = storagePathOf(storedValue);
    if (path == null) return;
    await deleteByPath(path);
  }
}
