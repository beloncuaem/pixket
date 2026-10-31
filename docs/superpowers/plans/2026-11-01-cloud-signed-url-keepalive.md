# Cloud Security, Signed URLs & Keep-alive — Implementation Plan (Plan 1/4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển ảnh hóa đơn sang Supabase Storage private + signed URL, hardening SQL idempotent với policy owner-only, thêm rollback khi ghi lỗi, và dựng workflow keep-alive chống pause 7 ngày.

**Architecture:** Tách logic suy ra storage path khỏi `SupabaseStorageService` sang helper thuần (`lib/core/utils/storage_paths.dart`) để unit test được không cần mạng. `Expense` nhận thêm field transient `displayImageUrl`; repository ký URL theo lô khi đọc và ủy quyền ghi cho `ExpenseRowWriter` để test rollback. SQL là file duy nhất người dùng chạy thủ công trong Supabase SQL Editor.

**Tech Stack:** Flutter 3.x / Dart 3.13, `supabase_flutter` 2.8.3 (`storage_client` 2.8.1, `gotrue` 2.27.3), `cached_network_image` 3.4.1, PostgreSQL RLS, GitHub Actions.

**Spec:** [docs/superpowers/specs/2026-11-01-chi-tieu-pixel-redesign-design.md](../specs/2026-11-01-chi-tieu-pixel-redesign-design.md) — §3.7, §4.2, §4.3, §4.7, §6, §7, §9.

## Global Constraints

- Trả lời và comment bằng tiếng Việt; giữ thuật ngữ kỹ thuật tiếng Anh.
- Không đưa `SUPABASE_*` key, token, mật khẩu vào source, log, workflow hay tài liệu; chỉ dùng `.env` (đã gitignore) và GitHub Secrets.
- Không commit/push/merge nếu người dùng chưa yêu cầu rõ. Bước "Commit" dưới đây chỉ chạy khi đã được ủy quyền.
- Không bỏ qua lỗi analyze/test/build để "cho xong".
- Bắt buộc chạy trước khi kết thúc mỗi task: `flutter analyze`, `flutter test`.
- `flutter` **không** có trong PATH của Git Bash trên máy phát triển này; SDK ở `/c/flutter/bin`. Mỗi lệnh chạy với `export PATH="$PATH:/c/flutter/bin"` (đã xác minh `flutter --version` → Flutter 3.47.6 / Dart 3.13.5).
- Không thêm dependency mới trong plan này.
- UI copy tiếng Việt, không dùng emoji làm icon.
- Ảnh người dùng luôn hiển thị chất lượng gốc; không filter, không pixelate.
- Cùng một khoản chi chỉ lưu MỘT giá trị trong `expenses.image_url`: storage path dạng `<user_uuid>/<file>`; giá trị URL public legacy vẫn được đọc đúng nhưng không được ghi mới.

**Depends on:** không (plan đầu tiên).
**Blocks:** Plan 3 (CSV cần `limit/offset`), Plan 4 (redesign các widget ảnh).

---

## File Structure

| File | Responsibility |
| --- | --- |
| Create `lib/core/utils/storage_paths.dart` | Pure: nhận diện storage path từ path/URL, chia lô, ký URL theo lô với signer injectable |
| Create `test/unit/storage_paths_test.dart` | Test pure helper, bao gồm case URL legacy đã có trong `auth_and_supabase_test.dart` |
| Modify `lib/data/repositories/supabase_storage_service.dart` | Upload trả path, `signPaths`, `deleteByPath`, bỏ `getPublicUrl` và static `storagePathFromUrl` |
| Modify `test/unit/auth_and_supabase_test.dart` | Xóa group `Storage Path Tests` (đã chuyển sang `storage_paths_test.dart`) |
| Create `lib/data/repositories/expense_row_writer.dart` | Seam ghi DB (insert/update) để test rollback không cần Supabase |
| Create `test/unit/expense_repository_write_test.dart` | Test rollback + normalize path khi ghi |
| Modify `lib/data/models/expense.dart` | Field transient `displayImageUrl` |
| Modify `test/unit/models_test.dart` | Test field mới và `copyWith` |
| Create `lib/data/repositories/expense_image_mapping.dart` | `storagePathsOf`, `attachSignedUrls` |
| Create `test/unit/expense_image_mapping_test.dart` | Test gán URL đã ký |
| Modify `lib/data/repositories/expense_repository.dart` | Ký URL khi đọc, dùng writer + rollback, phân trang `limit/offset` |
| Modify `lib/providers/expense_provider.dart:156-170` | Xóa object theo path, evict cache theo cacheKey |
| Modify `lib/widgets/expense_card.dart`, `lib/screens/home/home_screen.dart`, `lib/screens/camera/feed_grid_screen.dart`, `lib/screens/camera/feed_photo_page.dart`, `lib/screens/camera/expense_form_sheet.dart`, `lib/screens/trash/trash_screen.dart` | Đọc ảnh từ `displayImageUrl` + `cacheKey` |
| Create `test/widget/signed_image_source_test.dart` | Widget test: không còn nhánh `startsWith('http')` trên `imagePath` |
| Modify `supabase_setup.sql` | Bản viết lại idempotent, private bucket, owner-only policy, ràng buộc, dedupe, `updated_at` |
| Create `.github/workflows/supabase-keepalive.yml` | Ping REST mỗi 2 ngày + manual dispatch |
| Create `docs/supabase-keepalive.md` | Hướng dẫn secrets, chạy tay, phương án cron-job.org |
| Modify `README.md`, `docs/requirements.md` | Ghi nhận thay đổi cloud + keep-alive |

---

### Task 1: Pure helper cho storage path và ký URL theo lô

**Files:**
- Create: `lib/core/utils/storage_paths.dart`
- Create: `test/unit/storage_paths_test.dart`

**Interfaces:**
- Consumes: không.
- Produces:
  - `const String receiptBucket = 'expense-receipts';`
  - `String? storagePathOf(String? storedValue)` — trả path object, hoặc `null`
  - `List<List<T>> chunkList<T>(List<T> items, {int size = 50})`
  - `typedef SignedUrlSigner = Future<Map<String, String>> Function(List<String> batch);`
  - `Future<Map<String, String>> signPathsInChunks(Iterable<String> paths, {required SignedUrlSigner signer, int chunkSize = 50})`

- [ ] **Step 1: Viết test failing**

Tạo `test/unit/storage_paths_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/utils/storage_paths.dart';

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

    test('trả null với URL lạ, bucket không có object, tệp cục bộ, giá trị rỗng', () {
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
    });
  });

  group('chunkList', () {
    test('chia đúng thứ tự và bỏ rỗng', () {
      expect(chunkList(<int>[], size: 3), isEmpty);
      expect(
        chunkList(List.generate(7, (i) => i), size: 3),
        [[0, 1, 2], [3, 4, 5], [6]],
      );
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
      final result = await signPathsInChunks(
        ['', '  ', 'a/1.jpg'],
        signer: (batch) async => {for (final p in batch) p: 'u:$p'},
      );
      expect(result.keys, ['a/1.jpg']);
    });
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận fail vì thiếu file**

Run: `flutter test test/unit/storage_paths_test.dart`
Expected: FAIL — lỗi biên dịch `Target of URI doesn't exist: 'package:chi_tieu/core/utils/storage_paths.dart'`.

- [ ] **Step 3: Viết implementation tối thiểu**

Tạo `lib/core/utils/storage_paths.dart`:

```dart
/// Tiện ích thuần về đường dẫn ảnh hóa đơn trong Supabase Storage.
/// Không chạm mạng, không phụ thuộc model khác nên unit test được.
library;

const String receiptBucket = 'expense-receipts';

/// Path dạng `<uuid>/ tên_tệp`; uuid là id người dùng nên không nhầm với tệp cục bộ.
final RegExp _storedPathPattern = RegExp(
  r'^[0-9a-fA-F][0-9a-fA-F-]{34,35}/.+',
);

/// Suy ra path object từ giá trị đang lưu: path chuẩn, public URL legacy,
/// signed URL. Trả null nếu là ảnh cục bộ hoặc giá trị không hợp lệ.
String? storagePathOf(String? storedValue) {
  final value = storedValue?.trim();
  if (value == null || value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(receiptBucket);
    if (bucketIndex < 0 || bucketIndex == segments.length - 1) return null;
    return segments.sublist(bucketIndex + 1).join('/');
  }

  return _storedPathPattern.hasMatch(value) ? value : null;
}

/// Chia danh sách thành các lô tối đa `size` phần tử, giữ nguyên thứ tự.
List<List<T>> chunkList<T>(List<T> items, {int size = 50}) {
  if (items.isEmpty) return const [];
  final chunkSize = size < 1 ? 1 : size;
  final result = <List<T>>[];
  for (var start = 0; start < items.length; start += chunkSize) {
    final end = start + chunkSize > items.length ? items.length : start + chunkSize;
    result.add(items.sublist(start, end));
  }
  return result;
}

typedef SignedUrlSigner = Future<Map<String, String>> Function(List<String> batch);

/// Ký URL cho từng lô, khử trùng trước khi gọi signer.
Future<Map<String, String>> signPathsInChunks(
  Iterable<String> paths, {
  required SignedUrlSigner signer,
  int chunkSize = 50,
}) async {
  final unique = paths
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toSet()
      .toList();

  final result = <String, String>{};
  for (final batch in chunkList(unique, size: chunkSize)) {
    result.addAll(await signer(batch));
  }
  return result;
}
```

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `flutter test test/unit/storage_paths_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Kiểm tra toàn dự án**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 6: Commit (khi được ủy quyền)**

```bash
git add lib/core/utils/storage_paths.dart test/unit/storage_paths_test.dart
git commit -m "feat(storage): add pure helpers for receipt paths and signed url batching"
```

---

### Task 2: SupabaseStorageService dùng path riêng và ký URL

**Files:**
- Modify: `lib/data/repositories/supabase_storage_service.dart:1-59`
- Modify: `test/unit/auth_and_supabase_test.dart:1-8` (import), `:56-88` (xóa group)

**Interfaces:**
- Consumes: `receiptBucket`, `storagePathOf`, `signPathsInChunks` từ Task 1.
- Produces:
  - `Future<String> SupabaseStorageService.uploadReceiptImage(String localFilePath)` → **storage path** (không còn public URL)
  - `Future<Map<String, String>> SupabaseStorageService.signPaths(List<String> paths, {int expiresIn = signedUrlTtlSeconds})`
  - `Future<void> SupabaseStorageService.deleteByPath(String storagePath)`
  - `Future<void> SupabaseStorageService.deleteReceiptImage(String storedValue)`
  - `static const int SupabaseStorageService.signedUrlTtlSeconds = 86400;`
  - `static const String SupabaseStorageService.bucketName = 'expense-receipts';`

- [ ] **Step 1: Viết test failing cho hành vi mới**

`SupabaseStorageService` gọi `SupabaseConfig.client` (static), nên phần ký URL được test qua `signPathsInChunks` ở Task 1; ở đây test hợp đồng tĩnh: rằng service không còn tham chiếu `getPublicUrl`. Thêm vào `test/unit/storage_paths_test.dart` (cuối file, trước `}` cuối):

```dart
  group('Hợp đồng service', () {
    test('bucket name và TTL dùng chung một nguồn cấu hình', () {
      expect(SupabaseStorageService.bucketName, receiptBucket);
      expect(SupabaseStorageService.signedUrlTtlSeconds, 86400);
    });
  });
```

Thêm import:

```dart
import 'package:chi_tieu/data/repositories/supabase_storage_service.dart';
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/unit/storage_paths_test.dart`
Expected: FAIL — `signedUrlTtlSeconds` chưa tồn tại (undefined getter).

- [ ] **Step 3: Viết lại service**

Thay toàn bộ `lib/data/repositories/supabase_storage_service.dart`:

```dart
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
```

- [ ] **Step 4: Xóa test trùng đã chuyển chỗ**

Trong `test/unit/auth_and_supabase_test.dart`: xóa `import 'package:chi_tieu/data/repositories/supabase_storage_service.dart';` (dòng 6) và toàn bộ `group('Storage Path Tests', ...)` (dòng 56-88) vì đã chuyển sang `test/unit/storage_paths_test.dart`.

- [ ] **Step 5: Chạy test và sửa tham chiếu cũ**

Run: `flutter test`
Expected: FAIL ở các file còn gọi `SupabaseStorageService.storagePathFromUrl` hoặc dùng giá trị trả về của `uploadReceiptImage` như URL — đó là `lib/data/repositories/expense_repository.dart:36-42` và `lib/providers/expense_provider.dart:156-170`. Ghi lại danh sách này; Task 4 và Task 5 sửa chính thức. Để `flutter test` xanh ngay bây giờ, tạm thời chỉ sửa `expense_provider.dart:161` thành `await SupabaseStorageService().deleteReceiptImage(imagePath);` và bỏ điều kiện `startsWith('http')` (dòng 159-160) — thay bằng:

```dart
      await SupabaseStorageService().deleteReceiptImage(imagePath);
      await CachedNetworkImage.evictFromCache(imagePath);
```

- [ ] **Step 6: Kiểm tra**

Run: `flutter analyze` rồi `flutter test`
Expected: analyze sạch, test pass (task sau sẽ hoàn thiện lại phần provider).

- [ ] **Step 7: Commit (khi được ủy quyền)**

```bash
git add lib/data/repositories/supabase_storage_service.dart test/unit/storage_paths_test.dart test/unit/auth_and_supabase_test.dart lib/providers/expense_provider.dart
git commit -m "feat(storage): store receipt paths privately and sign urls in batches"
```

---

### Task 3: `Expense.displayImageUrl` transient

**Files:**
- Modify: `lib/data/models/expense.dart:3-55`
- Modify: `test/unit/models_test.dart`

**Interfaces:**
- Consumes: không.
- Produces:
  - `final String? Expense.displayImageUrl` (không nằm trong `toMap`, không ghi DB)
  - `Expense.copyWith({..., String? displayImageUrl})`

- [ ] **Step 1: Viết test failing**

Thêm vào `test/unit/models_test.dart` (trong group `Expense` hiện có, hoặc tạo group mới):

```dart
  group('Expense.displayImageUrl', () {
    Expense sample() => Expense(
      id: 1,
      caption: 'Cà phê',
      amount: 45000,
      categoryId: 3,
      createdAt: DateTime(2026, 11, 1, 9, 30),
      imagePath: 'user-1/1710_204.jpg',
    );

    test('mặc định null và không ghi vào toMap', () {
      final expense = sample();
      expect(expense.displayImageUrl, isNull);
      expect(expense.toMap().containsKey('display_image_url'), isFalse);
    });

    test('copyWith gán URL hiển thị mà không đổi imagePath', () {
      final updated = sample().copyWith(
        displayImageUrl: 'https://signed/abc',
      );
      expect(updated.displayImageUrl, 'https://signed/abc');
      expect(updated.imagePath, 'user-1/1710_204.jpg');
      expect(updated.id, 1);
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/unit/models_test.dart`
Expected: FAIL — `No named parameter with the name 'displayImageUrl'`.

- [ ] **Step 3: Implement**

Sửa `lib/data/models/expense.dart`:

```dart
  final int? id;
  final String? imagePath;
  /// Signed URL chỉ dùng để hiển thị trong phiên hiện tại; không lưu vào DB.
  final String? displayImageUrl;
  final String caption;
```

Trong constructor, thêm `this.displayImageUrl,` ngay sau `this.imagePath,`. Trong `copyWith`, thêm tham số và truyền xuống:

```dart
  Expense copyWith({
    int? id,
    String? imagePath,
    String? displayImageUrl,
    String? caption,
    double? amount,
    int? categoryId,
    int? priority,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      displayImageUrl: displayImageUrl ?? this.displayImageUrl,
      caption: caption ?? this.caption,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
```

`toMap` và `fromMap` giữ nguyên (`displayImageUrl` không thuộc dữ liệu).

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `flutter test test/unit/models_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/data/models/expense.dart test/unit/models_test.dart
git commit -m "feat(model): add transient displayImageUrl to Expense"
```

---

### Task 4: Mapping signed URL vào danh sách khoản chi

**Files:**
- Create: `lib/data/repositories/expense_image_mapping.dart`
- Create: `test/unit/expense_image_mapping_test.dart`

**Interfaces:**
- Consumes: `storagePathOf` (Task 1), `Expense.displayImageUrl` (Task 3).
- Produces:
  - `List<String> storagePathsOf(List<Expense> expenses)`
  - `List<Expense> attachSignedUrls(List<Expense> expenses, Map<String, String> signedByPath)`

- [ ] **Step 1: Viết test failing**

Tạo `test/unit/expense_image_mapping_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/repositories/expense_image_mapping.dart';

Expense _e(String? image, {String caption = 'A'}) => Expense(
  caption: caption,
  amount: 10000,
  categoryId: 1,
  createdAt: DateTime(2026, 11, 1),
  imagePath: image,
);

void main() {
  group('storagePathsOf', () {
    test('bỏ khoản chi không có ảnh và chuẩn hóa URL legacy', () {
      final paths = storagePathsOf([
        _e('user-1/a.jpg'),
        _e(null),
        _e(
          'https://x.supabase.co/storage/v1/object/public/expense-receipts/user-1/b.jpg',
        ),
      ]);
      expect(paths, ['user-1/a.jpg', 'user-1/b.jpg']);
    });
  });

  group('attachSignedUrls', () {
    test('gán đúng URL theo path và giữ nguyên các field khác', () {
      final rows = [_e('user-1/a.jpg', caption: 'Cà phê'), _e('user-1/missing.jpg')];
      final out = attachSignedUrls(rows, {'user-1/a.jpg': 'https://signed/a'});

      expect(out[0].displayImageUrl, 'https://signed/a');
      expect(out[0].caption, 'Cà phê');
      expect(out[0].imagePath, 'user-1/a.jpg');
      expect(out[1].displayImageUrl, isNull);
    });

    test('không_mutate danh sách gốc', () {
      final rows = [_e('user-1/a.jpg')];
      attachSignedUrls(rows, {'user-1/a.jpg': 'https://signed/a'});
      expect(rows.single.displayImageUrl, isNull);
    });
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/unit/expense_image_mapping_test.dart`
Expected: FAIL — URI không tồn tại.

- [ ] **Step 3: Implement**

Tạo `lib/data/repositories/expense_image_mapping.dart`:

```dart
import '../../core/utils/storage_paths.dart';
import '../models/expense.dart';

/// Danh sách path cần ký URL cho một trang khoản chi.
List<String> storagePathsOf(List<Expense> expenses) => [
  for (final expense in expenses)
    if (storagePathOf(expense.imagePath) case final path?) path,
];

/// bản sao Expense kèm signed URL; phần tử không có URL giữ nguyên hiển thị trống.
List<Expense> attachSignedUrls(
  List<Expense> expenses,
  Map<String, String> signedByPath,
) => [
  for (final expense in expenses)
    expense.copyWith(
      displayImageUrl: signedByPath[storagePathOf(expense.imagePath)],
    ),
];
```

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `flutter test test/unit/expense_image_mapping_test.dart`
Expected: PASS. Nếu cú pháp `if (... case final path?)` bị analyzer phàn nàn, dùng bản tường minh:

```dart
List<String> storagePathsOf(List<Expense> expenses) {
  final paths = <String>[];
  for (final expense in expenses) {
    final path = storagePathOf(expense.imagePath);
    if (path != null) paths.add(path);
  }
  return paths;
}
```

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/data/repositories/expense_image_mapping.dart test/unit/expense_image_mapping_test.dart
git commit -m "feat(data): map signed receipt urls onto expense view models"
```

---

### Task 5: Repository ký URL khi đọc, rollback khi ghi, phân trang

**Files:**
- Create: `lib/data/repositories/expense_row_writer.dart`
- Modify: `lib/data/repositories/expense_repository.dart:1-129` (và `getDeletedExpenses`, `getExpenseById`)
- Create: `test/unit/expense_repository_write_test.dart`

**Interfaces:**
- Consumes: `SupabaseStorageService.signPathsInBatches/deleteByPath/uploadReceiptImage` (Task 2), `storagePathOf` (Task 1), `storagePathsOf`/`attachSignedUrls` (Task 4).
- Produces:
  - `abstract class ExpenseRowWriter { String currentUserId(); Future<int> insert(Map<String, dynamic> values); Future<void> update(int id, Map<String, dynamic> values); }`
  - `class SupabaseExpenseRowWriter implements ExpenseRowWriter`
  - `ExpenseRepository({SupabaseStorageService? storageService, ExpenseRowWriter? writer})`
  - `@visibleForTesting Future<int> ExpenseRepository.saveExpense({int? expenseId, String? imageSource, Map<String, dynamic> values})`
  - `Future<List<Expense>> ExpenseRepository.decorateWithSignedUrls(List<Expense> rows)`
  - `getExpenses({..., int? limit, int? offset})`

- [ ] **Step 1: Viết test failing**

Tạo `test/unit/expense_repository_write_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/repositories/expense_repository.dart';
import 'package:chi_tieu/data/repositories/expense_row_writer.dart';
import 'package:chi_tieu/data/repositories/supabase_storage_service.dart';

class _FakeStorage extends SupabaseStorageService {
  final List<String> uploads = [];
  final List<String> deleted = [];
  final Map<String, String> signed;

  _FakeStorage({this.signed = const {}});

  @override
  Future<String> uploadReceiptImage(String localFilePath) async {
    uploads.add(localFilePath);
    return 'user-1/${localFilePath.split('/').last}';
  }

  @override
  Future<void> deleteByPath(String storagePath) async {
    deleted.add(storagePath);
  }

  @override
  Future<Map<String, String>> signPaths(
    List<String> paths, {
    int expiresIn = signedUrlTtlSeconds,
  }) async => {for (final p in paths) p: signed[p] ?? 'https://signed/$p'};
}

class _ThrowingWriter implements ExpenseRowWriter {
  @override
  String currentUserId() => 'user-1';

  @override
  Future<int> insert(Map<String, dynamic> values) async =>
      throw StateError('db down');

  @override
  Future<void> update(int id, Map<String, dynamic> values) async =>
      throw StateError('db down');
}

class _RecordingWriter implements ExpenseRowWriter {
  Map<String, dynamic>? inserted;
  Map<String, dynamic>? updated;
  int? updatedId;

  @override
  String currentUserId() => 'user-1';

  @override
  Future<int> insert(Map<String, dynamic> values) async {
    inserted = values;
    return 77;
  }

  @override
  Future<void> update(int id, Map<String, dynamic> values) async {
    updatedId = id;
    updated = values;
  }
}

void main() {
  late _FakeStorage storage;
  late Directory tempDir;

  setUp(() async {
    storage = _FakeStorage();
    tempDir = await Directory.systemTemp.createTemp('ct_img');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<String> fakeImage() async {
    final file = File('${tempDir.path}/IMG_1.jpg');
    await file.writeAsBytes([1, 2, 3]);
    return file.path;
  }

  test('upload lỗi DB thì dọn ảnh vừa tải lên', () async {
    final image = await fakeImage();
    final repository = ExpenseRepository(
      storageService: storage,
      writer: _ThrowingWriter(),
    );

    expect(
      () => repository.saveExpense(
        expenseId: null,
        imageSource: image,
        values: {'caption': 'A', 'amount': 1000},
      ),
      throwsStateError,
    );
    await Future<void>.delayed(Duration.zero);
    expect(storage.uploads, [image]);
    expect(storage.deleted, ['user-1/IMG_1.jpg']);
  });

  test('insert lưu path thay vì URL và không xóa ảnh cũ', () async {
    final image = await fakeImage();
    final writer = _RecordingWriter();
    final repository = ExpenseRepository(
      storageService: storage,
      writer: writer,
    );

    final id = await repository.saveExpense(
      expenseId: null,
      imageSource: image,
      values: {'caption': 'A'},
    );

    expect(id, 77);
    expect(writer.inserted?['image_url'], 'user-1/IMG_1.jpg');
    expect(storage.deleted, isEmpty);
  });

  test('giá trị legacy URL được chuẩn hóa về path khi update', () async {
    final writer = _RecordingWriter();
    final repository = ExpenseRepository(
      storageService: storage,
      writer: writer,
    );

    await repository.saveExpense(
      expenseId: 5,
      imageSource:
          'https://x.supabase.co/storage/v1/object/public/expense-receipts/user-1/old.jpg',
      values: {'caption': 'B'},
    );

    expect(writer.updatedId, 5);
    expect(writer.updated?['image_url'], 'user-1/old.jpg');
    expect(storage.uploads, isEmpty);
  });

  test('thiếu ảnh khi đang có ảnh thì giữ nguyên dòng cũ', () async {
    final writer = _RecordingWriter();
    final repository = ExpenseRepository(
      storageService: storage,
      writer: writer,
    );

    await repository.saveExpense(
      expenseId: 9,
      imageSource: null,
      values: {'caption': 'C', 'image_url': 'user-1/keep.jpg'},
    );

    expect(writer.updated?['image_url'], 'user-1/keep.jpg');
  });

  test('decorateWithSignedUrls gán URL cho cả dòng legacy', () async {
    final repository = ExpenseRepository(
      storageService: _FakeStorage(signed: {'user-1/a.jpg': 'https://s/a'}),
      writer: _RecordingWriter(),
    );
    final rows = [
      Expense(
        caption: 'A',
        amount: 1,
        categoryId: 1,
        createdAt: DateTime(2026, 11, 1),
        imagePath: 'user-1/a.jpg',
      ),
    ];

    final decorated = await repository.decorateWithSignedUrls(rows);
    expect(decorated.single.displayImageUrl, 'https://s/a');
  });

  test('decorate không ném lỗi khi ký URL thất bại', () async {
    final repository = ExpenseRepository(
      storageService: _BrokenStorage(),
      writer: _RecordingWriter(),
    );
    final rows = [
      Expense(
        caption: 'A',
        amount: 1,
        categoryId: 1,
        createdAt: DateTime(2026, 11, 1),
        imagePath: 'user-1/a.jpg',
      ),
    ];

    final decorated = await repository.decorateWithSignedUrls(rows);
    expect(decorated.single.displayImageUrl, isNull);
  });
}

class _BrokenStorage extends SupabaseStorageService {
  @override
  Future<Map<String, String>> signPaths(
    List<String> paths, {
    int expiresIn = signedUrlTtlSeconds,
  }) async => throw StateError('offline');
}
```

Thêm import đầu file:

```dart
import 'dart:io';
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/unit/expense_repository_write_test.dart`
Expected: FAIL — `saveExpense`/`decorateWithSignedUrls` chưa tồn tại, constructor chưa nhận tham số.

- [ ] **Step 3: Tạo seam ghi DB**

Tạo `lib/data/repositories/expense_row_writer.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Gom mọi thao tác ghi bảng expenses để repository test được rollback.
abstract class ExpenseRowWriter {
  String currentUserId();
  Future<int> insert(Map<String, dynamic> values);
  Future<void> update(int id, Map<String, dynamic> values);
}

class SupabaseExpenseRowWriter implements ExpenseRowWriter {
  SupabaseClient _client() {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Chưa kết nối được Supabase. Vui lòng kiểm tra mạng.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('Vui lòng đăng nhập để tiếp tục.');
    }
    return client;
  }

  @override
  String currentUserId() => _client().auth.currentUser!.id;

  @override
  Future<int> insert(Map<String, dynamic> values) async {
    final row = await _client().from('expenses').insert(values).select().single();
    return row['id'] as int;
  }

  @override
  Future<void> update(int id, Map<String, dynamic> values) =>
      _client().from('expenses').update(values).eq('id', id);
}
```

- [ ] **Step 4: Sửa repository**

`lib/data/repositories/expense_repository.dart` — thêm import và constructor:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/utils/storage_paths.dart';
import 'expense_image_mapping.dart';
import 'expense_row_writer.dart';

class ExpenseRepository {
  ExpenseRepository({
    SupabaseStorageService? storageService,
    ExpenseRowWriter? writer,
  }) : _storage = storageService ?? SupabaseStorageService(),
       _writer = writer ?? SupabaseExpenseRowWriter();

  final SupabaseStorageService _storage;
  final ExpenseRowWriter _writer;
```

Thay `_resolveImageUrl` (dòng 36-42) bằng resolve có thông tin "vừa tải lên":

```dart
  Future<({String? path, bool uploaded})> _resolveImage(String? source) async {
    final value = source?.trim();
    if (value == null || value.isEmpty) return (path: null, uploaded: false);

    final stored = storagePathOf(value);
    if (stored != null) return (path: stored, uploaded: false);

    if (await File(value).exists()) {
      return (path: await _storage.uploadReceiptImage(value), uploaded: true);
    }

    throw StateError('Không tìm thấy ảnh để tải lên Cloud.');
  }
```

Thay `insertExpense` (44-65) và `updateExpense` (67-89):

```dart
  /// Ghi khoản chi. Nếu DB lỗi thì dọn ảnh vừa upload (best-effort).
  @visibleForTesting
  Future<int> saveExpense({
    required int? expenseId,
    required String? imageSource,
    required Map<String, dynamic> values,
  }) async {
    final image = await _resolveImage(imageSource);
    final payload = <String, dynamic>{
      ...values,
      if (image.path != null) 'image_url': image.path,
    };

    try {
      if (expenseId == null) return await _writer.insert(payload);
      await _writer.update(expenseId, payload);
      return expenseId;
    } catch (_) {
      if (image.uploaded && image.path != null) {
        try {
          await _storage.deleteByPath(image.path!);
        } catch (_) {
          // Ảnh mồ côi sẽ bị policy owner-only chặn; không làm mất lỗi chính.
        }
      }
      rethrow;
    }
  }

  Future<int> insertExpense(Expense expense) => saveExpense(
    expenseId: null,
    imageSource: expense.imagePath,
    values: {
      'user_id': _writer.currentUserId(),
      'caption': expense.caption,
      'amount': expense.amount,
      'category_id': expense.categoryId,
      'priority': expense.priority,
      'image_url': expense.imagePath,
      'created_at': expense.createdAt.toIso8601String(),
      'deleted_at': expense.deletedAt?.toIso8601String(),
    },
  );

  Future<int> updateExpense(Expense expense) {
    final id = expense.id;
    if (id == null) {
      throw StateError('Không tìm thấy khoản chi cần cập nhật.');
    }
    return saveExpense(
      expenseId: id,
      imageSource: expense.imagePath,
      values: {
        'caption': expense.caption,
        'amount': expense.amount,
        'category_id': expense.categoryId,
        'priority': expense.priority,
        'image_url': expense.imagePath,
        'created_at': expense.createdAt.toIso8601String(),
        'deleted_at': expense.deletedAt?.toIso8601String(),
      },
    );
  }
```

Thêm hàm ký URL (đặt cạnh `_fromRow`):

```dart
  /// Gán signed URL cho danh sách; lỗi ký chỉ làm ảnh trống, không mất dữ liệu.
  Future<List<Expense>> decorateWithSignedUrls(List<Expense> rows) async {
    final paths = storagePathsOf(rows);
    if (paths.isEmpty) return rows;
    try {
      final signed = await _storage.signPathsInBatches(paths);
      return attachSignedUrls(rows, signed);
    } catch (error) {
      debugPrint('Ký URL ảnh thất bại: $error');
      return rows;
    }
  }
```

`getExpenses` (91-129): thêm phân trang và trả danh sách đã ký:

```dart
  Future<List<Expense>> getExpenses({
    DateTime? from,
    DateTime? to,
    String? search,
    int? categoryId,
    int? priority,
    double? minAmount,
    double? maxAmount,
    int? limit,
    int? offset,
  }) async {
    // ... giữ nguyên các điều kiện filter hiện có (dòng 100-123)
    var query = client.from('expenses').select().isFilter('deleted_at', null);
    // ... from/to/search/categoryId/priority/min/max
    query = query.order('created_at', ascending: false);
    if (limit != null) query = query.limit(limit);
    if (offset != null) query = query.range(offset, offset + limit! - 1);

    final data = await query;
    final rows = (data as List)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
    return decorateWithSignedUrls(rows);
  }
```

`getDeletedExpenses` (202-213) và `getExpenseById` (215-223): đổi `return (data as List)...toList();` thành gán biến `rows` rồi `return decorateWithSignedUrls(rows);` (với `getExpenseById`: `return decorated.isEmpty ? null : decorated.single;` qua `decorateWithSignedUrls([_fromRow(data)])`).

`_requireClient` (10-19) chỉ còn dùng cho các câu đọc; giữ nguyên.

- [ ] **Step 5: Chạy test, xác nhận pass**

Run: `flutter test test/unit/expense_repository_write_test.dart`
Expected: PASS (6 tests). Nếu test `saveExpense` báo lỗi `File` chưa import trong test, đã có `import 'dart:io';` ở Step 1.

- [ ] **Step 6: Chạy toàn bộ**

Run: `flutter analyze` && `flutter test`
Expected: cả hai sạch/pass.

- [ ] **Step 7: Commit (khi được ủy quyền)**

```bash
git add lib/data/repositories/expense_row_writer.dart lib/data/repositories/expense_repository.dart test/unit/expense_repository_write_test.dart
git commit -m "feat(data): sign receipt urls on read and roll back uploads when writes fail"
```

---

### Task 6: Provider và UI đọc ảnh từ `displayImageUrl`

**Files:**
- Modify: `lib/providers/expense_provider.dart:156-170`
- Modify: `lib/widgets/expense_card.dart:146-190`
- Modify: `lib/screens/home/home_screen.dart:465-476`, `:865-880`
- Modify: `lib/screens/camera/feed_grid_screen.dart:91`, `:134-155`
- Modify: `lib/screens/camera/feed_photo_page.dart:176-195`
- Modify: `lib/screens/camera/expense_form_sheet.dart:34`, `:310-330`
- Modify: `lib/screens/trash/trash_screen.dart:77-95`
- Create: `test/widget/signed_image_source_test.dart`

**Interfaces:**
- Consumes: `Expense.displayImageUrl`, `storagePathOf`, `SupabaseStorageService.deleteByPath`.
- Produces: quy ước — mọi `CachedNetworkImage` trong app nhận `imageUrl: expense.displayImageUrl!` và `cacheKey: storagePathOf(expense.imagePath)!`.

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/signed_image_source_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/widgets/expense_card.dart';

void main() {
  testWidgets('ExpenseCard dùng displayImageUrl, không đọc imagePath làm URL', (tester) async {
    final category = Category(id: 1, name: 'Ăn uống', icon: 'forkKnife');
    final expense = Expense(
      id: 1,
      caption: 'Cà phê sữa',
      amount: 39000,
      categoryId: 1,
      createdAt: DateTime(2026, 11, 1, 8, 30),
      imagePath: 'user-1/1710_204.jpg',
      displayImageUrl: 'https://signed.example/a.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseCard(expense: expense, category: category, onTap: () {}),
        ),
      ),
    );

    expect(find.byType(ExpenseCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ExpenseCard không crash khi chưa ký được URL', (tester) async {
    final expense = Expense(
      id: 2,
      caption: 'Gửi xe',
      amount: 5000,
      categoryId: 2,
      createdAt: DateTime(2026, 11, 1, 9, 0),
      imagePath: 'user-1/1710_205.jpg',
    );

    final category = Category(id: 2, name: 'Di chuyển', icon: 'car');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseCard(expense: expense, category: category, onTap: () {}),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
```

Chữ ký thật đã xác minh ở `lib/widgets/expense_card.dart:14-24`: `ExpenseCard({super.key, required this.expense, required this.category, this.onTap})` — **không có `onDelete`** và `category` là `Category` bắt buộc (không phải `Category?`), nên test phải truyền `category:`. `Category` có constructor không `const` (`lib/data/models/category.dart:8-14`) nên không bọc `const` quanh `Category(...)`.

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/widget/signed_image_source_test.dart`
Expected: FAIL — exception khi `Image.file(File('user-1/1710_204.jpg'))` được gọi vì `imagePath` không còn là URL.

- [ ] **Step 3: Sửa provider**

`lib/providers/expense_provider.dart:156-170` thay bằng:

```dart
  Future<void> permanentlyDeleteExpense(Expense expense) async {
    if (expense.id == null) return;

    final storedPath = storagePathOf(expense.imagePath);
    if (storedPath != null) {
      await SupabaseStorageService().deleteByPath(storedPath);
      final url = expense.displayImageUrl;
      if (url != null) {
        await CachedNetworkImage.evictFromCache(url, cacheKey: storedPath);
      }
    } else {
      final local = expense.imagePath;
      if (local != null) {
        final file = File(local);
        if (await file.exists()) await file.delete();
      }
    }

    // Ảnh phải xóa xong trước để không còn object mồ côi.
    await _repository.permanentlyDeleteExpense(expense.id!);
  }
```

Thêm import `package:chi_tieu/core/utils/storage_paths.dart` (hoặc đường dẫn tương đối `../core/utils/storage_paths.dart` tùy file đang dùng kiểu import).

- [ ] **Step 4: Sửa các điểm đọc ảnh**

Mẫu chung — áp dụng cho từng file, thay điều kiện `path.startsWith('http')`:

```dart
final url = expense.displayImageUrl;
final cacheKey = storagePathOf(expense.imagePath);

Widget image = url == null
    ? const Icon(Icons.broken_image_rounded)   // giữ nguyên placeholder cũ của file đó
    : CachedNetworkImage(
        imageUrl: url,
        cacheKey: cacheKey,
        fit: BoxFit.cover,
        placeholder: (_, __) => /* placeholder hiện có */,
        errorWidget: (_, __, ___) => /* errorWidget hiện có */,
      );
```

Cụ thể:

1. `lib/widgets/expense_card.dart:146-158` — đổi `_buildThumbnailImage(String path)` thành `_buildThumbnailImage(Expense expense)`; bên trong dùng `expense.displayImageUrl` + `cacheKey`; nhánh `Image.file(File(path))` chỉ chạy khi `storagePathOf(expense.imagePath) == null` (ảnh chưa lưu). Sửa cả call site dòng 183-185 theo cùng quy tắc.
2. `lib/screens/home/home_screen.dart:465-476` — `_buildImage()` trong widget chi tiết: dùng `expense.displayImageUrl`; `:865-880` `_buildLeadingWidget`: thay `if (img.startsWith('http'))` bằng `if (expense.displayImageUrl != null)`.
3. `lib/screens/camera/feed_grid_screen.dart:91` — `_buildImage(expense.imagePath!)` → `_buildImage(expense)`; `:134` đổi signature `_buildImage(Expense expense)` và dùng `displayImageUrl` + `cacheKey`.
4. `lib/screens/camera/feed_photo_page.dart:176` — `_buildImage()` dùng `widget.expense.displayImageUrl` + `cacheKey`; placeholder giữ nền `AppColors.feedBackground`.
5. `lib/screens/camera/expense_form_sheet.dart:34` — `_sourceImagePath` giữ nguyên cho ảnh tạm, nhưng nhánh hiển thị `:310-330` phải là: ảnh tạm tồn tại → `Image.file`; ngược lại → `widget.expense?.displayImageUrl` với `CachedNetworkImage(cacheKey: storagePathOf(widget.expense?.imagePath))`; không còn `path.startsWith('http')`.
6. `lib/screens/trash/trash_screen.dart:77-95` — dùng `expense.displayImageUrl` + `cacheKey`; nếu null thì hiện placeholder.

- [ ] **Step 5: Quét sót**

Run: `grep -rn "startsWith('http')\|getPublicUrl" lib/`
Expected: không còn kết quả nào (ngoại trừ nơi so sánh URL do chính app sinh cho shared link, hiện chưa tồn tại).

Run: `flutter test test/widget/signed_image_source_test.dart`
Expected: PASS.

- [ ] **Step 6: Kiểm tra toàn dự án**

Run: `flutter analyze` && `flutter test`
Expected: sạch/pass.

- [ ] **Step 7: Commit (khi được ủy quyền)**

```bash
git add lib/providers/expense_provider.dart lib/widgets/expense_card.dart lib/screens/home/home_screen.dart lib/screens/camera/ lib/screens/trash/trash_screen.dart test/widget/signed_image_source_test.dart
git commit -m "feat(ui): render receipts from signed urls with stable cache keys"
```

---

### Task 7: Viết lại `supabase_setup.sql` (private bucket, owner-only, idempotent)

**Files:**
- Modify: `supabase_setup.sql` (thay toàn bộ 182 dòng)

**Interfaces:**
- Consumes: không.
- Produces: schema mà app ở Task 2-6 kỳ vọng: bucket private, object chỉ chủ sở hữu đọc/ghi được, ràng buộc `amount > 0`/`priority 0..3`, không còn danh mục trùng.

- [ ] **Step 1: Kiểm tra điều kiện tiền quyết**

Run: `grep -n "expense-receipts\|public = true" supabase_setup.sql`
Expected: còn dòng `VALUES ('expense-receipts', 'expense-receipts', true)` — xác nhận bản cũ đang mở public trước khi thay.

- [ ] **Step 2: Thay toàn bộ nội dung `supabase_setup.sql`**

```sql
-- ==============================================================================
-- CHI TIÊU — SUPABASE SETUP v2.2 (idempotent, chạy lại nhiều lần an toàn)
-- Hướng dẫn: Supabase Dashboard -> SQL Editor -> dán toàn bộ -> RUN.
-- Không chứa khóa bí mật. Chỉ DDL, policy và seed danh mục mặc định.
-- ==============================================================================

-- 0. HÀM TIỆN ÍCH
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 1. BẢNG PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    currency_code TEXT DEFAULT 'VND',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        new.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. BẢNG CATEGORIES
CREATE TABLE IF NOT EXISTS public.categories (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    color_hex TEXT NOT NULL DEFAULT '#7BD8A8',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 2.1 DỌN DANH MỤC TRÙNG (kể cả danh mục hệ thống có user_id IS NULL)
DROP TABLE IF EXISTS public._ct_category_dupes;
CREATE TABLE public._ct_category_dupes AS
SELECT c.id AS dup_id, k.id AS keep_id
FROM public.categories c
JOIN (
    SELECT DISTINCT ON (user_id, lower(name)) id, user_id, lower(name) AS lname
    FROM public.categories
    ORDER BY user_id, lower(name), id
) k ON k.user_id IS NOT DISTINCT FROM c.user_id
   AND k.lname = lower(c.name)
   AND k.id <> c.id;

UPDATE public.expenses e SET category_id = d.keep_id
FROM public._ct_category_dupes d WHERE e.category_id = d.dup_id;

UPDATE public.budgets b SET category_id = d.keep_id
FROM public._ct_category_dupes d WHERE b.category_id = d.dup_id;

DELETE FROM public.categories c
USING public._ct_category_dupes d WHERE c.id = d.dup_id;

DROP TABLE IF EXISTS public._ct_category_dupes;

-- 2.2 INDEX DANH MỤC: mỗi user một tên, danh mục hệ thống cũng vậy
CREATE UNIQUE INDEX IF NOT EXISTS uniq_categories_user_name
    ON public.categories(user_id, lower(name)) WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uniq_categories_system_name
    ON public.categories(lower(name)) WHERE user_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories(user_id);

DROP TRIGGER IF EXISTS set_categories_updated_at ON public.categories;
CREATE TRIGGER set_categories_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3. BẢNG EXPENSES
CREATE TABLE IF NOT EXISTS public.expenses (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id BIGINT REFERENCES public.categories(id) ON DELETE SET NULL,
    caption TEXT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    priority INT NOT NULL DEFAULT 0,
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- image_url lưu path '<uuid>/<file>'; giá trị legacy (public URL) vẫn đọc được ở client.
DO $$ BEGIN
    ALTER TABLE public.expenses ADD CONSTRAINT expenses_amount_positive
        CHECK (amount > 0) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.expenses ADD CONSTRAINT expenses_priority_range
        CHECK (priority BETWEEN 0 AND 3) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.expenses ADD CONSTRAINT expenses_caption_not_blank
        CHECK (length(trim(caption)) > 0) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_expenses_user_created
    ON public.expenses(user_id, deleted_at, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user_category
    ON public.expenses(user_id, category_id);

DROP TRIGGER IF EXISTS set_expenses_updated_at ON public.expenses;
CREATE TRIGGER set_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 4. BẢNG BUDGETS
CREATE TABLE IF NOT EXISTS public.budgets (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id BIGINT REFERENCES public.categories(id) ON DELETE CASCADE,
    month TEXT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, month, category_id)
);
ALTER TABLE public.budgets ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$ BEGIN
    ALTER TABLE public.budgets ADD CONSTRAINT budgets_month_format
        CHECK (month ~ '^[0-9]{4}-[0-9]{2}$') NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.budgets ADD CONSTRAINT budgets_amount_non_negative
        CHECK (amount >= 0) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Mỗi tháng chỉ một ngân sách tổng (category_id IS NULL).
DELETE FROM public.budgets a
USING public.budgets b
WHERE a.category_id IS NULL AND b.category_id IS NULL
  AND a.user_id = b.user_id AND a.month = b.month AND a.id < b.id;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_budgets_total_per_month
    ON public.budgets(user_id, month) WHERE category_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_budgets_user_month ON public.budgets(user_id, month);

DROP TRIGGER IF EXISTS set_budgets_updated_at ON public.budgets;
CREATE TRIGGER set_budgets_updated_at
    BEFORE UPDATE ON public.budgets
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 5. BẢNG BUDGET_ALERTS
CREATE TABLE IF NOT EXISTS public.budget_alerts (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    month TEXT NOT NULL,
    threshold INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, month, threshold)
);
CREATE INDEX IF NOT EXISTS idx_budget_alerts_user_month
    ON public.budget_alerts(user_id, month);

-- 6. ROW LEVEL SECURITY
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can view public or own categories" ON public.categories;
CREATE POLICY "Users can view public or own categories" ON public.categories
    FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own categories" ON public.categories;
CREATE POLICY "Users can insert own categories" ON public.categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own categories" ON public.categories;
CREATE POLICY "Users can update own categories" ON public.categories
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own categories" ON public.categories;
CREATE POLICY "Users can delete own categories" ON public.categories
    FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own expenses" ON public.expenses;
CREATE POLICY "Users can manage own expenses" ON public.expenses
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own budgets" ON public.budgets;
CREATE POLICY "Users can manage own budgets" ON public.budgets
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own alerts" ON public.budget_alerts;
CREATE POLICY "Users can manage own alerts" ON public.budget_alerts
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 7. SEED DANH MỤC MẶC ĐỊNH (idempotent nhờ uniq_categories_system_name)
INSERT INTO public.categories (user_id, name, icon, color_hex, is_default)
VALUES
    (NULL, 'Ăn uống', 'forkKnife', '#7BD8A8', TRUE),
    (NULL, 'Di chuyển', 'car', '#8ECAE6', TRUE),
    (NULL, 'Mua sắm', 'shoppingBag', '#FFD86B', TRUE),
    (NULL, 'Hóa đơn', 'receipt', '#FFB38A', TRUE),
    (NULL, 'Giải trí', 'gameController', '#F28C9A', TRUE),
    (NULL, 'Sức khỏe', 'heartbeat', '#7BD8A8', TRUE),
    (NULL, 'Giáo dục', 'graduationCap', '#8ECAE6', TRUE),
    (NULL, 'Khác', 'dotsThreeOutline', '#FFD86B', TRUE)
ON CONFLICT DO NOTHING;

-- 8. STORAGE: BUCKET PRIVATE + CHỈ CHỦ SỞ HỮU TOUCH
INSERT INTO storage.buckets (id, name, public)
VALUES ('expense-receipts', 'expense-receipts', FALSE)
ON CONFLICT (id) DO UPDATE SET public = FALSE;

DROP POLICY IF EXISTS "User receipt upload policy" ON storage.objects;
DROP POLICY IF EXISTS "User receipt read policy" ON storage.objects;
DROP POLICY IF EXISTS "User receipt delete policy" ON storage.objects;
DROP POLICY IF EXISTS "receipt_owner_insert" ON storage.objects;
DROP POLICY IF EXISTS "receipt_owner_read" ON storage.objects;
DROP POLICY IF EXISTS "receipt_owner_update" ON storage.objects;
DROP POLICY IF EXISTS "receipt_owner_delete" ON storage.objects;

CREATE POLICY "receipt_owner_insert" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'expense-receipts'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "receipt_owner_read" ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'expense-receipts'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "receipt_owner_update" ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'expense-receipts'
        AND (storage.foldername(name))[1] = auth.uid()::text
    )
    WITH CHECK (
        bucket_id = 'expense-receipts'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "receipt_owner_delete" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'expense-receipts'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- 9. KIỂM TRA SAU KHI CHẠY (kỳ vọng: bucket_public = false, receipt_policies = 4)
SELECT 'bucket_public' AS check_name, public::text AS expected_false
FROM storage.buckets WHERE id = 'expense-receipts';

SELECT 'receipt_policies' AS check_name, count(*)::text AS expected_four
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname LIKE 'receipt_owner_%';
```

- [ ] **Step 3: Self-review SQL**

Kiểm tra lần lượt, đánh dấu từng dòng đã thấy trong file:
- [ ] Mọi `CREATE POLICY` đều có `DROP POLICY IF EXISTS` phía trước.
- [ ] Bucket được ghi `public = FALSE` và `ON CONFLICT ... DO UPDATE SET public = FALSE`.
- [ ] Cả 4 policy storage đều có `(storage.foldername(name))[1] = auth.uid()::text`.
- [ ] Constraint dùng `NOT VALID` trong khối `DO $$ ... EXCEPTION ... $$` để không abort khi dữ liệu cũ vi phạm.
- [ ] Seed dùng `ON CONFLICT DO NOTHING` và khớp 8 tên danh mục cũ.

- [ ] **Step 4: Ghi cảnh báo thứ tự triển khai vào README**

Chưa đổi README toàn bộ (Task 9); chỉ thêm vào `docs/requirements.md` mục "Điều kiện cấu hình bên ngoài" một gạch đầu dòng:

```markdown
- Từ v2.2 bucket `expense-receipts` là **private**: phải chạy lại `supabase_setup.sql`
  rồi cài bản app mới. Bản app cũ (dùng public URL) sẽ không còn xem được ảnh.
```

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add supabase_setup.sql docs/requirements.md
git commit -m "fix(supabase): make setup idempotent with private bucket and owner-only policies"
```

---

### Task 8: GitHub Actions keep-alive

**Files:**
- Create: `.github/workflows/supabase-keepalive.yml`

**Interfaces:**
- Consumes: GitHub Secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY` (người dùng tạo).
- Produces: job `ping` chạy mỗi 2 ngày và khi trigger tay.

- [ ] **Step 1: Tạo workflow**

Tạo `.github/workflows/supabase-keepalive.yml`:

```yaml
name: Supabase keep-alive

on:
  schedule:
    - cron: '0 3 */2 * *'
  workflow_dispatch:

permissions:
  contents: read

jobs:
  ping:
    name: Giữ dự án Supabase hoạt động
    runs-on: ubuntu-latest
    steps:
      - name: Kiểm tra secrets
        run: |
          if [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ]; then
            echo "Thiếu secret SUPABASE_URL hoặc SUPABASE_ANON_KEY." >&2
            exit 1
          fi
          echo "Secrets đã đủ (không in giá trị)."
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}

      - name: REST ping tới bảng categories
        run: |
          set -euo pipefail
          status=$(curl -sS -o /dev/null -w '%{http_code}' \
            -H "apikey: ${SUPABASE_ANON_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
            "${SUPABASE_URL}/rest/v1/categories?select=id&limit=1")
          echo "HTTP ${status}"
          if [ "${status}" -ge 400 ]; then
            echo "Supabase trả lỗi ${status}. Kiểm tra URL, anon key và RLS." >&2
            exit 1
          fi
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```

- [ ] **Step 2: Xác minh cú pháp YAML**

Run: `python -c "import yaml,sys; yaml.safe_load(open('.github/workflows/supabase-keepalive.yml', encoding='utf-8')); print('yaml ok')"`
Expected: `yaml ok`. Nếu Python không có PyYAML, thay bằng `node -e "const fs=require('fs');const s=fs.readFileSync('.github/workflows/supabase-keepalive.yml','utf8');if(/\t/.test(s)) throw new Error('có tab');console.log('yaml basic ok')"` và giữ lỗi tab làm chuẩn kiểm tra.

- [ ] **Step 3: Kiểm tra không lộ secret**

Run: `grep -n "SUPABASE_ANON_KEY\|SUPABASE_URL" .github/workflows/supabase-keepalive.yml`
Expected: chỉ xuất hiện dưới dạng `${{ secrets.* }}` và tên biến, **không có giá trị thật**.

- [ ] **Step 4: Commit (khi được ủy quyền)**

```bash
git add .github/workflows/supabase-keepalive.yml
git commit -m "ci: add supabase keep-alive workflow"
```

---

### Task 9: Tài liệu keep-alive

**Files:**
- Create: `docs/supabase-keepalive.md`

**Interfaces:**
- Consumes: workflow Task 8.
- Produces: hướng dẫn người dùng bật keep-alive.

- [ ] **Step 1: Viết tài liệu**

Tạo `docs/supabase-keepalive.md`:

```markdown
# Giữ Supabase hoạt động (free tier)

Supabase free tier **tạm dừng project sau 7 ngày không có hoạt động**. Project bị pause thì
app không đăng nhập, không đọc/ghi dữ liệu được nữa. Repo này có workflow GitHub Actions
`.github/workflows/supabase-keepalive.yml` gọi REST API mỗi 2 ngày một lần.

## 1. Bật workflow

1. Mở repo trên GitHub -> **Settings -> Secrets and variables -> Actions -> New repository secret**.
2. Tạo hai secret (tên đúng như dưới đây, phân biệt hoa thường):
   - `SUPABASE_URL`: ví dụ `https://<project-ref>.supabase.co`
   - `SUPABASE_ANON_KEY`: **anon / publishable key** (key an toàn để nhúng client).
3. Không dùng `service_role` key ở bất kỳ đâu trong workflow hay app.

## 2. Chạy thử bằng tay

1. **Actions -> Supabase keep-alive -> Run workflow**.
2. Mở log job `Giữ dự án Supabase hoạt động`, dòng cuối phải là `HTTP 200`.
   - `HTTP 400/401/404`: sai URL hoặc sai key.
   - `HTTP 403`: RLS/policy từ chối — kiểm tra đã chạy `supabase_setup.sql` chưa.
3. Lần đầu chạy, GitHub sẽ hỏi xác nhận chạy workflow; bấm **Approve and run**.

## 3. Lịch chạy

- `cron: '0 3 */2 * *'` — 03:00 UTC cách ngày, tức mỗi 2 ngày.
- GitHub **tự tắt schedule của repo không có commit nào trong 60 ngày**. Vì vậy:
  - Commit hoặc "This repo is active" không phải giải pháp lâu dài.
  - Hãy bật thêm phương án dự phòng bên dưới.

## 4. Dự phòng: cron-job.org

1. Tạo account tại <https://cron-job.org>.
2. **Create cronjob** -> Schedule: `Every 2 days`, 03:00.
3. **HTTP request**: `GET https://<project-ref>.supabase.co/rest/v1/categories?select=id&limit=1`
4. **Header**:
   - `apikey: <SUPABASE_ANON_KEY>`
   - `Authorization: Bearer <SUPABASE_ANON_KEY>`
5. **Expected Response Code**: `200`.
6. Bật **Execution history** để kiểm tra khi app báo lỗi mạng.

Khóa anon/publishable được đặt trong service ngoài là chấp nhận được vì nó vốn đã nằm
trong `.env` của app; tuyệt đối không đặt `service_role` key ở đây.

## 5. Khi project đã bị pause

1. Supabase Dashboard -> **Project settings -> General -> Restore project** (hoặc Unpause).
2. Chạy workflow tay một lần để xác nhận còn sống.
3. Nếu restore không khả dụng (project bị xóa), tạo project mới, chạy lại
   `supabase_setup.sql` và cập nhật `.env` — ảnh trong Storage của project cũ không tự về.
```

- [ ] **Step 2: Commit (khi được ủy quyền)**

```bash
git add docs/supabase-keepalive.md
git commit -m "docs: add supabase keep-alive guide"
```

---

### Task 10: Build xanh và bàn giao

**Files:**
- Modify: `README.md` (mục cloud và kiểm thử)
- Modify: `docs/requirements.md` (FR mới, acceptance)

**Interfaces:**
- Consumes: toàn bộ Task 1-9.
- Produces: tài liệu khớp thực tế.

- [ ] **Step 1: Chạy bộ kiểm chứng**

```bash
flutter analyze
flutter test
flutter build apk --debug
```
Expected: analyze `No issues found`, test toàn bộ pass, build in `√ Built build\app\outputs\flutter-apk\app-debug.apk`.

- [ ] **Step 2: Ghi kết quả thật**

Tổ hợp số test sau plan này phải tăng so với 69; lấy số liệu thật từ output `flutter test` (không ước đoán).

Sửa `README.md`:
- Bảng công nghệ: dòng `Cloud Database` ghi thêm "Storage private + signed URL".
- Mục "Cấu hình Supabase": nhắc bucket `expense-receipts` là **private**, ảnh hiển thị qua signed URL hạn 24 giờ.
- Thêm mục "Giữ Supabase hoạt động" liên kết `docs/supabase-keepalive.md`.
- Số test: cập nhật theo output thật.

Sửa `docs/requirements.md`:
- FR-21 `Ảnh hóa đơn lưu bucket private, hiển thị qua signed URL hạn 24h` — Đã có.
- FR-22 `Keep-alive Supabase bằng GitHub Actions (kèm cron-job.org dự phòng)` — Đã có, cần người dùng cấu hình secrets.
- FR-23 `Rollback ảnh đã upload khi ghi DB thất bại` — Đã có.
- Mục 8 "Tiêu chí nghiệm thu": thay số test bằng số thật, ghi rõ "chưa xác minh trên thiết bị" cho luồng camera/deep link nếu chưa chạy.

- [ ] **Step 3: Chốt trạng thái xác minh**

Thêm vào `docs/requirements.md` §8 các dòng:

```markdown
- Chưa xác minh bằng tay (không có thiết bị/emulator trong phiên): tải ảnh thật lên
  bucket private, xem ảnh qua signed URL trên thiết bị, ảnh legacy còn hiển thị.
- Người dùng cần: chạy lại `supabase_setup.sql`, thêm GitHub Secrets, chạy workflow tay
  một lần và xác nhận `HTTP 200`.
```

- [ ] **Step 4: Commit (khi được ủy quyền)**

```bash
git add README.md docs/requirements.md
git commit -m "docs: record private bucket, signed urls and keep-alive status"
```

---

## Chốt chặn cuối plan

- [ ] `grep -rn "getPublicUrl" lib/` → không kết quả.
- [ ] `grep -rn "startsWith('http')" lib/` → không kết quả.
- [ ] `supabase_setup.sql` có `public = FALSE` và 4 policy `receipt_owner_%`.
- [ ] Workflow không chứa key thật.
- [ ] `flutter analyze` + `flutter test` + `flutter build apk --debug` xanh.
- [ ] Người dùng đã được liệt kê rõ 3 việc thủ công: chạy SQL, thêm secrets, test ảnh trên máy.
