import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/utils/storage_paths.dart';
import 'package:pixket/data/repositories/supabase_storage_service.dart';

void main() {
  group('storagePathOf', () {
    test('giữ nguyên path đã chuẩn (uuid/tên tệp)', () {
      expect(
        storagePathOf('9c0f6a1e-2b3c-4d5e-6f70-8192a3b4c5d6/1710_204533.jpg'),
        '9c0f6a1e-2b3c-4d5e-6f70-8192a3b4c5d6/1710_204533.jpg',
      );
    });

    test('rút path từ public URL legacy', () {
      expect(
        storagePathOf(
          'https://abc.supabase.co/storage/v1/object/public/'
          'expense-receipts/user-1/123_45.jpg',
        ),
        'user-1/123_45.jpg',
      );
    });

    test('rút path từ signed URL', () {
      expect(
        storagePathOf(
          'https://abc.supabase.co/storage/v1/object/sign/'
          'expense-receipts/user-1/123_45.jpg?token=xyz',
        ),
        'user-1/123_45.jpg',
      );
    });

    test(
      'trả null với URL lạ, bucket không có object, tệp cục bộ, giá trị rỗng',
      () {
        expect(storagePathOf('https://example.com/image.jpg'), isNull);
        expect(
          storagePathOf(
            'https://abc.supabase.co/storage/v1/object/public/expense-receipts',
          ),
          isNull,
        );
        expect(storagePathOf('/data/user/0/com.x/app/CACHE/IMG_1.jpg'), isNull);
        expect(storagePathOf(null), isNull);
        expect(storagePathOf('   '), isNull);
      },
    );
  });

  group('chunkList', () {
    test('chia đúng thứ tự và bỏ rỗng', () {
      expect(chunkList(<int>[], size: 3), isEmpty);
      expect(chunkList(List.generate(7, (i) => i), size: 3), [
        [0, 1, 2],
        [3, 4, 5],
        [6],
      ]);
    });
  });

  group('signPathsInChunks', () {
    test('khử trùng path và gộp kết quả từng lô', () async {
      final batches = <List<String>>[];
      final result = await signPathsInChunks(
        ['a/1.jpg', 'a/1.jpg', 'b/2.jpg'],
        chunkSize: 1,
        signer: (batch) async {
          batches.add(batch);
          return {batch.first: 'https://signed/${batch.first}'};
        },
      );

      expect(batches, [
        ['a/1.jpg'],
        ['b/2.jpg'],
      ]);
      expect(result, {
        'a/1.jpg': 'https://signed/a/1.jpg',
        'b/2.jpg': 'https://signed/b/2.jpg',
      });
    });

    test('bỏ qua path rỗng', () async {
      final result = await signPathsInChunks([
        '',
        '  ',
        'a/1.jpg',
      ], signer: (batch) async => {for (final p in batch) p: 'u:$p'});
      expect(result.keys, ['a/1.jpg']);
    });
  });

  group('Hợp đồng service', () {
    test('bucket name và TTL dùng chung một nguồn cấu hình', () {
      expect(SupabaseStorageService.bucketName, receiptBucket);
      // Signed URL là bypass RLS: không được dài quá 1 giờ.
      expect(
        SupabaseStorageService.signedUrlTtlSeconds,
        lessThanOrEqualTo(3600),
      );
      expect(SupabaseStorageService.signedUrlTtlSeconds, greaterThan(0));
    });
  });
}
