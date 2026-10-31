import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

class SupabaseStorageService {
  static const String bucketName = 'expense-receipts';

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

    return client.storage.from(bucketName).getPublicUrl(storagePath);
  }

  Future<void> deleteReceiptImage(String imageUrl) async {
    final path = storagePathFromUrl(imageUrl);
    if (path == null) return;
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Chưa cấu hình Supabase.');
    }
    await client.storage.from(bucketName).remove([path]);
  }

  static String? storagePathFromUrl(String imageUrl) {
    final segments = Uri.tryParse(imageUrl)?.pathSegments;
    if (segments == null) return null;
    final bucketIndex = segments.indexOf(bucketName);
    if (bucketIndex < 0 || bucketIndex == segments.length - 1) return null;
    return segments.sublist(bucketIndex + 1).join('/');
  }
}
