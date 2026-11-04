# Pixket PWA — Design Spec

Ngày: 2026-11-04
Trạng thái: đã được duyệt trong brainstorming, chuyển sang writing-plans
Phiên bản app hiện tại: 2.6.0+8 (Flutter 3.47.6, Dart SDK ^3.13.5)

## 1. Mục tiêu

Thêm bản PWA cho Pixket: người dùng mở trang web, "Add to Home Screen" và dùng như app native,
đầy đủ tính năng so với bản Android. Bản web **cần mạng** để đọc/ghi dữ liệu — không có offline
data, không có hàng đợi sync.

Host trên **GitHub Pages** qua GitHub Actions, cạnh workflow `build-apk.yml` sẵn có.

## 2. Phạm vi

**Trong phạm vi:**
- Làm cho bản web **chạy đúng khi chạy thật** (Plan 2). *Sửa 2026-11-04:* bản đầu viết "`flutter
  build web` hiện đang fail vì `dart:io`" — sai; build web đã compile sạch (mục 4.1).
- Đủ tính năng trên web: chụp/chọn ảnh hóa đơn, xem feed, thêm/sửa/xóa khoản chi, thống kê,
  ngân sách, danh mục, mức độ cần thiết, đăng nhập email + Google OAuth, lưu ảnh về máy,
  cảnh báo ngưỡng ngân sách.
- Manifest + icon + service worker đúng brand pixel.
- Deploy GitHub Pages + CI build web mỗi push.
- Chốt chống hồi quy: không file nào ngoài `*_io.dart` được import `dart:io`.

**Ngoài phạm vi:**
- Offline data / cache dữ liệu Supabase / hàng đợi sync khi mất mạng.
- Web Push chạy nền (app đóng vẫn nhận thông báo) — cần VAPID + server gửi push.
- Viewfinder camera live tự viết bằng `getUserMedia`.
- Custom domain, iOS App Store / Google Play từ bản web.

## 3. Quyết định đã chốt

| Vấn đề | Quyết định |
|---|---|
| Mức offline | Cài đặt được, cần mạng. Service worker chỉ cache app shell. |
| Nơi host | GitHub Pages |
| Tính năng web | Đầy đủ parity với mobile; tạo implementation web mới, không cắt tính năng |
| Camera web | `image_picker` với `ImageSource.camera` → `<input capture>`, không tự viết viewfinder |
| SQLite | Bỏ hẳn `sqflite`. `priority_levels` thành **bảng hệ thống read-only** trên Supabase (không per-user, không RPC, xóa 6 method chết); 3 key pre-auth giữ ở máy bằng `shared_preferences` |
| Cấu trúc code | Một codebase duy nhất + `XFile`/bytes làm đơn vị tiền tệ chung; `dart:io` nhốt sau conditional import |

## 4. Hiện trạng đã kiểm chứng

### 4.1 Không có "nút thắt compile" — nút thắt là runtime

> **Sửa 2026-11-04.** Bản đầu mục này tên "Nút thắt compile" và mục 2 khẳng định `flutter build
> web` đang fail vì `dart:io`. Đã đo lại trên `main` sau Plan 1 (`01dd660`, vẫn đủ 8 file import
> `dart:io`, vẫn `flutter_cache_manager` + `cached_network_image`): **`flutter build web` exit 0,
> `√ Built build\web`**. dart2js cung cấp stub cho `dart:io` và đường truyền MethodChannel của
> plugin, nên code biên dịch được rồi mới ném lúc chạy (`Unsupported operation:` với `File`,
> `MissingPluginException:` với plugin). Hệ quả: build **không phải** bằng chứng nghiệm thu; chỉ
> chạy trong trình duyệt mới là bằng chứng. Plan 2 vì thế mở đầu bằng một lượt audit runtime.

`dart:io` không tồn tại trên web. **8 file trong `lib/` import `dart:io`** (chỉ dùng `File`,
không có `Platform`/`Directory`):

| File | Chỗ dùng |
|---|---|
| `lib/core/utils/save_to_gallery.dart` | dòng 53 — đọc bytes từ local path |
| `lib/core/utils/square_image.dart` | dòng 50-63 — `writeSquareCopy(File)` |
| `lib/data/repositories/expense_repository.dart` | dòng 61, 64 — `File(value).exists()`, `writeSquareCopy` |
| `lib/data/repositories/supabase_storage_service.dart` | dòng 27 — `File(localFilePath)` + `lengthSync()` |
| `lib/providers/expense_provider.dart` | dòng 192 — `File(local)` |
| `lib/screens/camera/camera_screen.dart` | dòng 159, 180 — `File(picture.path)` |
| `lib/screens/camera/expense_form_sheet.dart` | dòng 130, 131, 133, 175 — draft file exists/delete |
| `lib/widgets/pixel/pixel_receipt_image.dart` | dòng 180 — `File(localPath!)` để hiển thị |

**Dependency phải bọc — vì runtime, không vì compile:** `flutter_cache_manager` 3.4.5 (kéo theo
`cached_network_image` 3.4.1) import `dart:io` **vô điều kiện** trong chuỗi export chính
(`cache_store.dart:2`, `cache_object_provider.dart:1`, `json_cache_info_repository.dart:2`,
`compat/file_service_compat.dart:1`). Vì dart2js stub `dart:io`, thứ này **vẫn compile** trên web
(đã đo, xem khung ở mục 4.1) rồi mới ném lúc chạy — nên lập luận "bắt buộc phải bọc" vẫn đúng, chỉ
là vì hành vi chứ không vì build. Badge pub.dev của cả bản mới nhất đều **không có Web**.

### 4.2 Bảng web-support (đo lại 2026-11-04; cột phiên bản là bản **lock**, pubspec chỉ pin `^`)

**Import `dart:io` vô điều kiện — phải bọc (compile vẫn chạy, runtime ném):**

| Package | Lock | Lý do |
|---|---|---|
| `flutter_cache_manager` | 3.4.5 | `dart:io` vô điều kiện trong export chain |
| `cached_network_image` | 3.4.1 | phụ thuộc `flutter_cache_manager` |

**Không có implementation cho web — phải có nhánh web:**

| Package | Lock | Hành vi trên web (đo lại) |
|---|---|---|
| `gal` | 2.3.3 | pubspec package khai báo android/ios/macos/windows, **không có web** → `MissingPluginException` trong `Gal.putImageBytes`. Hiện `save_to_gallery.dart:32` `catch (_) {}` nuốt lỗi, nên trên web bấm "lưu ảnh" chỉ ra dòng 'Không lưu được ảnh về máy.' chứ không crash (đọc mã, chưa chạy) |
| `flutter_local_notifications` | 18.0.1 | **không ném**: plugin có 8 nhánh `if (kIsWeb)` — `initialize()` trả `true` (`flutter_local_notifications_plugin.dart:114`), `show()` return sớm (:219). Trên web mọi lệnh notification **âm thầm không làm gì**. Web Notifications chính thức chỉ có từ 22.0.0, và ta **không nâng** (mục 5.1) |
| `sqflite` | 2.4.4 | pubspec package chỉ đăng ký plugin cho android/ios/macos → không có factory trên web **và trên Windows/Linux**. Plan 1 đã xóa mọi usage khỏi code chung; file migration guard bằng `kIsWeb` + `_supportedPlatforms` |

`path_provider` không còn trong project (gỡ ở Plan 1, mục 6.3).

**Đã hỗ trợ web ở đúng bản pin — không cần làm gì:**

`camera` 0.11.1 · `image_picker` 1.1.2 · `shared_preferences` 2.5.6 · `permission_handler`
11.4.0 (có `permission_handler_html` từ 11.1.0) · `flutter_secure_storage` 11.2.0 (có
`flutter_secure_storage_web`) · `supabase_flutter` · `flutter_dotenv` 5.2.1 · `image` 4.12.0
(pure Dart) · `http`.

**Lưu ý đã xác minh:** trên web, `XFile.path` trả về từ `camera`/`image_picker` là **blob URL**,
không phải đường dẫn filesystem. Mọi chỗ đang làm `File(path)` phải đổi sang `readAsBytes()`.

### 4.3 `compute()` trên web chạy cùng thread

Đọc trực tiếp SDK tại `packages/flutter/lib/src/foundation/_isolates_web.dart`:

```dart
Future<R> compute<M, R>(ComputeCallback<M, R> callback, M message, {String? debugLabel}) async {
  await null;               // chỉ pump một frame
  return callback(message); // chạy trên main thread, không isolate
}
```

Hệ quả: `cropToSquareBytes` đang decode ảnh 12MP bằng package `image` sẽ **đơ UI web khoảng 1s+**.
Không thể dùng `compute` như cơ chế chống giật trên web.

### 4.4 Kiến trúc dữ liệu hiện tại

Đã là **Cloud-only**: `expenses`, `categories`, `budgets`, `budget_alerts` đều qua Supabase.
SQLite chỉ còn đúng 2 bảng:

- `app_settings` — 3 key: `onboarding_complete` (`app_settings_provider.dart:33,38`),
  `theme_mode` (`theme_provider.dart:14,24`), `chart_spend_ramp` (`app_settings_provider.dart:71`).
- `priority_levels` — 4 mức seed + CRUD của người dùng.

RLS đã bật đủ 5 bảng: `supabase_setup.sql:203-207`.

**Code thừa kế sai phát hiện được:** `PriorityRepository.deleteAndMoveExpenses` đang chạy
transaction trên bảng `expenses` **local** trong khi nguồn thật của expenses là Supabase. Nhánh
update đó là no-op chết, phải dọn khi chuyển bảng.

## 5. Kiến trúc: ranh giới platform

Hướng đã chọn: **một codebase**, `dart:io` chỉ xuất hiện trong các file `*_io.dart` được nạp
qua conditional import. Mỗi capability là một cặp file cùng chữ ký:

```
lib/core/platform/
  gallery_saver.dart        // export conditional
  gallery_saver_io.dart     // gal
  gallery_saver_web.dart    // Blob + <a download>
  gallery_saver_stub.dart   // fallback + seam cho test
  photo_capture.dart        // + _io / _web / _stub
  local_draft_store.dart    // + _io / _web / _stub
  receipt_notifier.dart     // + _io / _web / _stub
  receipt_cache_image.dart  // + _io / _web / _stub (widget)
  receipt_cache.dart        // clearReceiptCache / evictReceiptImage, + _io / _web / _stub
```

Mỗi capability gồm **4 file**: `x.dart` (export conditional), `x_io.dart`, `x_web.dart` và
`x_stub.dart`. Stub là điều kiện mặc định của conditional export (nền tảng không có `dart.library.io`
lẫn `dart.library.js_interop`) đồng thời là seam để test/widget tiêm implementation không đụng plugin.

Riêng `square_image.dart` không chuyển hẳn vào `lib/core/platform/`: file này đang ở
`lib/core/utils/` và chứa cả phần pure Dart (`cropToSquareBytes`, các hằng `squareImageSide`/
`squareImageQuality`/`squareImageSuffix`, `isSquareImagePath`) lẫn phần IO. Giữ nguyên vị trí,
tách phần platform-specific ra cặp `_io`/`_web`/`_stub` cùng thư mục `lib/core/utils/` để không phải
đổi import ở `supabase_storage_service.dart` và các test hiện có.

Mẫu conditional import:

```dart
export 'gallery_saver_stub.dart'
    if (dart.library.io) 'gallery_saver_io.dart'
    if (dart.library.js_interop) 'gallery_saver_web.dart';
```

**5 interface cần viết:**

| Interface | Chữ ký | Bản IO (giữ nguyên hành vi) | Bản Web |
|---|---|---|---|
| `LocalDraftStore` | `save(Uint8List) → draft`, `readBytes(draft)`, `exists(draft)`, `delete(draft)` | Ghi file tạm như hiện tại | Blob/object URL giữ trong phiên |
| `GallerySaver` | `save(Uint8List bytes, {String name}) → String? errorMessage` | `Gal.putImageBytes` | Blob + `<a download>` + click |
| `PhotoCapture` | `capture() → Uint8List?`, `pick() → Uint8List?` | `camera` plugin + viewfinder pixel hiện có | `image_picker` `ImageSource.camera` / `.gallery` |
| `ReceiptNotifier` | `initialize()`, `requestPermission()`, `showBudgetAlert({threshold, monthLabel})` | `flutter_local_notifications` 18 | Web Notifications API qua `dart:js_interop` |
| `ReceiptCacheImage` | widget nhận `url` + placeholder/error | `CachedNetworkImage` | `Image.network` + `loadingBuilder`/`errorBuilder` |

Kèm hai hàm trong `receipt_cache.dart`: `clearReceiptCache()` (IO gọi
`DefaultCacheManager().emptyCache()`, Web chỉ clear `PaintingBinding.instance.imageCache`) thay cho
`app.dart:69`, và `evictReceiptImage(String url, {String? cacheKey})` thay cho
`CachedNetworkImage.evictFromCache` ở `expense_provider.dart:187` — Web evict khỏi
`imageCache` theo url. Thiếu hàm sau thì code chung vẫn import `cached_network_image` và phạm
quy tắc ở mục 12.1.

### 5.1 Hai hành vi mobile phải giữ nguyên

1. **Draft ảnh vẫn ghi ra đĩa trên mobile.** Nếu chuyển sang giữ bytes trong bộ nhớ cho gọn thì
   người dùng Android chụp xong, tắt app trước khi upload sẽ **mất draft** — đó là hồi quy.
   `LocalDraftStore` bản IO vẫn ghi file tạm; chỉ bản Web giữ trong phiên (mất khi reload —
   chấp nhận được vì draft vốn bị xóa sau upload/hủy).
2. **Không nâng `flutter_local_notifications`.** Bản 18.0.1 giữ nguyên cho IO; web tự viết bằng
   Web Notifications API. Nhảy 18 → 22 (4 major version) ngay trước khi ship là rủi ro hồi quy
   trên Android/iOS không đáng, trong khi notification hiện tại chỉ là một cảnh báo ngưỡng đơn giản.

## 6. Data layer: bỏ SQLite

### 6.1 `priority_levels` → Supabase (bảng hệ thống, read-only)

**Bằng chứng dẫn tới thiết kế này:** đã grep toàn bộ `lib/` và `test/` — `addLevel`
(`priority_provider.dart:32`), `updateLevel` (:40), `deleteLevel` (:45), và `insert`
(`priority_repository.dart:11`), `update` (:16), `deleteAndMoveExpenses` (:26), `nextId` (:42)
**không có bất kỳ caller nào** ngoài chính định nghĩa của chúng. Ba màn hình dùng
`priorityProvider` đều chỉ `watch` để đọc (`camera_screen.dart:303`,
`expense_form_sheet.dart:188`, `home_screen.dart:105`). Nghĩa là 4 mức độ là **dữ liệu hệ thống
cố định**, không phải dữ liệu người dùng.

Vì vậy dựng bảng theo đúng mẫu các danh mục hệ thống đang seed (`user_id IS NULL`,
`supabase_setup.sql:245+`), **không** per-user:

```sql
CREATE TABLE IF NOT EXISTS public.priority_levels (
    id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    level_key   INT NOT NULL UNIQUE,   -- giá trị mà cột expenses.priority trỏ tới (0..3)
    name        TEXT NOT NULL,
    color_value BIGINT NOT NULL,
    sort_order  INT NOT NULL
);
ALTER TABLE public.priority_levels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone authenticated can view priority levels" ON public.priority_levels;
CREATE POLICY "Anyone authenticated can view priority levels" ON public.priority_levels
    FOR SELECT TO authenticated USING (true);

INSERT INTO public.priority_levels (level_key, name, color_value, sort_order) VALUES
    (0, 'Thiết yếu', ('xFF43A047')::bit(32)::bigint, 0),
    (1, 'Rất cần',   ('xFF1E88E5')::bit(32)::bigint, 1),
    (2, 'Cần vừa',   ('xFFFB8C00')::bit(32)::bigint, 2),
    (3, 'Chưa cần',  ('xFFE53935')::bit(32)::bigint, 3)
ON CONFLICT (level_key) DO NOTHING;
```

Viết màu bằng cast `('xFF43A047')::bit(32)::bigint` thay vì số thập phân để hex gốc trong
`database_helper.dart:183-186` còn nhìn thấy được và không thể chép sai. Giá trị thập phân đúng
(đã tính lại, dùng khi đối chiếu): `4282622023` / `4280191205` / `4294675456` / `4293212469`.
Bắt buộc giữ đúng số để màu không đổi so với bản hiện tại.

Lợi so với phương án per-user: không cần seed trong `handle_new_user()`, không cần backfill cho
user hiện hữu, RLS chỉ một policy SELECT (client không bao giờ ghi), và không cần RPC.

**Ràng buộc phải tôn trọng:** `expenses` đang có `CHECK (priority BETWEEN 0 AND 3)`
(`supabase_setup.sql:129-130`, tên `expenses_priority_range`). Bảng hệ thống 4 dòng khớp đúng
constraint đó. Nếu sau này mở UI cho tạo mức tùy chỉnh thì phải nới constraint và chuyển sang
per-user — ngoài phạm vi spec này.

**Xóa code chết:** bỏ `addLevel`/`updateLevel`/`deleteLevel` khỏi `PriorityNotifier` và
`insert`/`update`/`deleteAndMoveExpenses`/`nextId` khỏi `PriorityRepository`. Việc này cũng xóa
luôn nhánh transaction đang update bảng `expenses` **local** vốn không còn là nguồn thật
(mục 4.4). Các fake trong `test/support/fakes.dart` dùng `noSuchMethod` nên không bị vỡ khi
bớt method.

`PriorityRepository.getAll()` viết lại thành Supabase repository, theo đúng mẫu `_requireClient()`
của `category_repository.dart:7-16`. Model `PriorityLevel` thêm factory `fromSupabaseRow` đọc
`level_key` thành `id`, giữ nguyên `fromMap`/`toMap` cho test.

### 6.2 3 key pre-auth → `shared_preferences`

`onboarding_complete`, `theme_mode`, `chart_spend_ramp` **không thể** lên Supabase: routing là
onboarding → login (`app.dart:24-34`) và `theme_mode` được watch ngay trong `PixketApp.build`,
nghĩa là cả ba được đọc **trước khi có auth**. Row per-user có RLS sẽ khiến app không khởi động
được cho người chưa đăng nhập.

`AppSettingsRepository` giữ **nguyên chữ ký** `getString`/`setString`/`getBool`/`setBool`/`remove`,
chỉ đổi ruột từ `sqflite` sang `shared_preferences`. Hệ quả: `app_settings_provider.dart`,
`theme_provider.dart` và cả 3 chỗ test hiện tại (`test/support/memory_settings.dart` →
`MemorySettingsRepository`, `test/unit/effects_settings_test.dart` → `_BrokenSettings`,
`test/widget/settings_effects_test.dart`) **không phải sửa**.

### 6.3 Xóa

- `lib/data/database/database_helper.dart` (toàn bộ file).
- Lời gọi `DatabaseHelper.instance.database` ở `main.dart:19`.
- Dependency `path_provider` khỏi `pubspec.yaml`. **Đã kiểm tra:** trong `lib/` và `test/` chỉ có
  một chỗ duy nhất liên quan là `getDatabasesPath()` ở `database_helper.dart:18`, mà hàm đó thuộc
  `sqflite` chứ không phải `path_provider`. Trước khi gỡ vẫn phải chạy `flutter pub deps` để xác
  nhận không package nào cần nó làm peer, và `flutter analyze` + `flutter test` sau khi gỡ.
- 7 method chết của priority (danh sách ở mục 6.1).

**Giữ lại `sqflite` trong đợt này — sửa so với bản spec đầu.** Migration phải *đọc* DB SQLite cũ
thì mới chuyển được dữ liệu, nên không thể gỡ `sqflite` cùng lúc với việc viết migration. Trình tự
đúng:

1. Đợt này: xóa `database_helper.dart` + `path_provider`, chuyển `app_settings` sang
   `shared_preferences`, thêm migration đọc DB cũ bằng `sqflite` trực tiếp (`databaseExists` +
   `openDatabase(readOnly: true)`), **giữ `sqflite` trong `pubspec.yaml`** chỉ để phục vụ migration.
2. Release kế tiếp, khi mọi user đã chạy migration: gỡ `sqflite` và xóa file migration.

Việc giữ `sqflite` **không chặn build web**: đã kiểm chứng (mục 4.2) nó compile được trên web và
chỉ ném `MissingPluginException` lúc chạy, mà migration đã guard bằng `if (kIsWeb) return;`.

**Migration cho người dùng Android/iOS hiện hữu:** *(sửa 2026-11-04: bản đầu ghi "Android/Windows".
`sqflite` 2.4.4 chỉ đăng ký plugin cho android/ios/macos theo pubspec của package, nên trên Windows
chưa bao giờ có `pixket.db` để mà migrate — Windows không thuộc phạm vi nghiệm thu của chuỗi PWA.)*
chạy một bước one-shot lúc khởi động: nếu
`pixket.db` không tồn tại (cài mới) thì bỏ qua; nếu tồn tại thì đọc 3 key `app_settings` → ghi
sang `shared_preferences` **chỉ khi key đó chưa có giá trị** → đánh dấu đã migrate bằng key
`legacy_sqlite_migrated`. Chỉ chạy trên IO. Nếu đọc DB cũ ném lỗi thì **không** set cờ, để lần
khởi động sau thử lại.

`priority_levels` không cần migration: bảng hệ thống 4 dòng seed trong SQL tái tạo đúng những gì
mọi người dùng đang có, vì không UI nào cho phép họ sửa.

## 7. Đường ống ảnh

Đơn vị tiền tệ chung đổi từ `String localFilePath` sang **bytes (`Uint8List`)**, vì web không có
đường dẫn filesystem.

### 7.1 Cắt vuông: tách lõi pure Dart, hai implementation

`cropToSquareBytes(Uint8List) → Uint8List?` (`square_image.dart:23-45`) **đã là pure Dart**
(package `image` + `bakeOrientation` + `copyCrop` + `copyResize` + `encodeJpg`) → chạy trên web
nguyên trạng về mặt logic. Vấn đề duy nhất là hiệu năng (mục 4.3).

Tách thành `squareBytes(Uint8List) → Future<Uint8List?>` với hai implementation:

- **IO:** giữ nguyên `image` + `compute` + các hằng `squareImageSide = 1200`,
  `squareImageQuality = 85`, `squareImageSuffix = '_sq.jpg'`.
- **Web:** `createImageBitmap` (đặt `imageOrientation: 'from-image'` để bake EXIF, tương đương
  `img.bakeOrientation`) → vẽ lên `OffscreenCanvas` 1200×1200 cắt giữa → `convertToBlob`
  type `image/jpeg`, quality 0.85. Chạy native của trình duyệt nên không đơ UI.

`writeSquareCopy(File)` bị xóa; việc ghi file chuyển vào `LocalDraftStore` bản IO.
`isSquareImagePath` / marker `_sq` giữ nguyên vì đó là quy ước đặt tên object trong Supabase
Storage, không liên quan filesystem.

### 7.2 Upload

`SupabaseStorageService.uploadReceiptImage(String localFilePath)` đổi thành
`uploadReceiptImage(Uint8List bytes, {required String extension, required bool squared})`:

- `file.lengthSync()` trong tên file (`supabase_storage_service.dart:43`) → `bytes.length`.
- Suy `contentType` từ tham số `extension` thay vì parse đường dẫn.
- Marker `_sq` lấy từ tham số `squared` thay vì `isSquareImagePath(localFilePath)`.
- Dùng `uploadBinary` (đã có sẵn ở `uploadSquareBytes`) thay vì `upload(file)`.

### 7.3 Migration ảnh legacy

`expense_repository.dart:61-64` kiểm tra `File(value).exists()` để lazy-migrate ảnh legacy chưa
vuông. Đây là logic **chỉ có ý nghĩa trên mobile** (web không có path legacy). Chuyển vào
`LocalDraftStore`/một hàm IO-only; bản Web trả về "không có gì để migrate".

### 7.4 Hiển thị

`pixel_receipt_image.dart`: enum `ReceiptImageSource.localFile` đổi thành `localBytes`, nhánh
`File(localPath!)` ở dòng 180 thành `Image.memory`. Nhánh `signedUrl` đi qua `ReceiptCacheImage`
(mục 5).

### 7.5 Camera

`camera_screen.dart` dòng 159, 180 (`File(picture.path)`) đổi sang `picture.readAsBytes()`.
Bản Web dùng `image_picker` với `ImageSource.camera`: trên trình duyệt mobile sinh
`<input type="file" accept="image/*" capture="environment">` mở thẳng app camera gốc; trên
desktop mở file picker. Không có ống ngắm live trong app — chấp nhận theo quyết định mục 3.

## 8. Notification trên web

*(Sửa 2026-11-04: bản 18.0.1 **không ném** trên web — `initialize()` trả `true`, `show()` return
sớm nên mọi lệnh notification im lặng vô hiệu. Vì ta không nâng lên 22 (mục 5.1), bản Web vẫn phải
tự viết, nhưng đây là **thêm tính năng**, không phải sửa crash.)* Viết `ReceiptNotifier`
bản Web bằng **Web Notifications API** qua `dart:js_interop`:

- `requestPermission()` → `Notification.requestPermission()`.
- `showBudgetAlert(threshold, monthLabel)` → `new Notification('Cảnh báo ngân sách', body: ...)`
  với đúng chuỗi tiếng Việt đang dùng ở `notification_service.dart:50-51`.
- `initialize()` → no-op, chỉ ghi nhận `'Notification' in globalThis`.

Không có push chạy nền: thông báo chỉ hiện khi app đang mở, **đúng bằng** hành vi hiện tại
(`_plugin.show()` được gọi lúc phát hiện vượt ngưỡng, không có scheduled notification).

`permission_handler` ở `onboarding_screen.dart:52-53`: trên web **bỏ qua** cả hai lời gọi
(`Permission.camera.request()` và `NotificationService.requestPermission()`), để trình duyệt tự
hỏi quyền đúng lúc người dùng bấm chụp / bật cảnh báo. `permission_handler` 11.3.1 có
`permission_handler_html` nhưng mô hình quyền của browser khác, không nên xin quyền upfront.

## 9. PWA plumbing

### 9.1 Manifest — hiện là template Flutter mặc định, sai brand

`web/manifest.json` đang có `background_color` và `theme_color` = `#0175C2` (xanh Flutter), trong
khi palette thật là light `canvas: #FFF6E3` / `ink: #2B2118` và dark `canvas: #0E2A4F`
(`app_palette.dart:53-77`).

Sửa thành:

```json
{
  "id": "/pixket/",
  "name": "Pixket",
  "short_name": "Pixket",
  "description": "Pixket — Nhật ký chi tiêu pixel",
  "start_url": "/pixket/",
  "scope": "/pixket/",
  "display": "standalone",
  "background_color": "#FFF6E3",
  "theme_color": "#FFF6E3",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [ /* Icon-192, Icon-512, Icon-maskable-192, Icon-maskable-512 */ ]
}
```

`start_url`/`scope`/`id` phải khớp `--base-href /pixket/` (mục 10).

### 9.2 Icon — sinh từ chính `PixelLogo`, mở rộng tool sẵn có

`web/icons/*.png` hiện đề ngày 4/10 và 1/11, **chưa phải logo Lens Orbit** mà commit `629882a`
vừa dựng (logo đang vẽ procedural trong `lib/widgets/pixel/pixel_logo.dart`).

**Không viết tool mới.** Mở rộng `test/tool/launcher_icons_test.dart` — tool headless này đã render
`PixelLogo` trên nền `AppPalette.dark` ra PNG ở kích thước tùy ý và ghi theo đường dẫn. Thêm vào
map `_targets`:

| Key | px | path | Ghi chú |
|---|---|---|---|
| `web192` | 192 | `web/icons/Icon-192.png` | logo chiếm trọn |
| `web512` | 512 | `web/icons/Icon-512.png` | logo chiếm trọn |
| `webMask192` | 192 | `web/icons/Icon-maskable-192.png` | logo trong safe zone 80% |
| `webMask512` | 512 | `web/icons/Icon-maskable-512.png` | logo trong safe zone 80% |
| `webFavicon` | 64 | `web/favicon.png` | logo trong safe zone 80% |

Maskable cần tham số padding mới (hiện tool chưa có): nền `AppPalette.dark.canvas` phủ kín, logo
co còn 80% cạnh và canh giữa, để icon không bị hệ điều hành cắt mất viền.

Chạy: `PIXKET_GEN_ICONS=1 flutter test test/tool/launcher_icons_test.dart` (mặc định skip nên CI
không ghi đè file).

### 9.3 Service worker — không tự viết

Với phạm vi "cài đặt được, cần mạng", `flutter build web --release` **tự sinh**
`flutter_service_worker.js` cache app shell (engine, font, `main.dart.js`, assets). Không cần
service worker tùy chỉnh. Chỉ cần đảm bảo `start_url`/`scope` khớp base href để SW đăng ký đúng
scope `/pixket/`.

Không cache dữ liệu Supabase và không cache ảnh signed URL (TTL 3600s theo
`supabase_storage_service.dart:17` — cache lại sẽ phục vụ URL hết hạn).

### 9.4 `index.html`

- `<meta name="theme-color" content="#FFF6E3">` + bản dark qua `prefers-color-scheme`.
- `apple-touch-icon` trỏ icon maskable đã sinh lại.
- Splash pixel thay khoảng trắng mặc định trong lúc tải `main.dart.js` (nền `#FFF6E3`, logo
  `PixelLogo` tĩnh hoặc placeholder PNG).
- CSP meta (mục 11).
- Giữ `flutter_bootstrap.js` loader mặc định của Flutter.

## 10. Deploy: GitHub Pages + CI

### 10.1 Workflow mới `.github/workflows/deploy-web.yml`

- Trigger: `push` lên `main`, đường dẫn `lib/**`, `web/**`, `pubspec.*`, `assets/**`.
- Bước: `flutter build web --release --base-href /pixket/` → deploy thư mục `build/web` lên nhánh
  `gh-pages` (action gh-pages, giữ history bằng force-push nhánh `gh-pages` — nhánh này không
  chứa code nên không đụng quy tắc "không force-push main").
- Bật GitHub Pages source = branch `gh-pages` / folder `/ (root)`.
- Remote hiện tại là `https://github.com/beloncuaem/pixket.git` nên trang sẽ chạy ở
  **`https://beloncuaem.github.io/pixket/`** — đây là giá trị thật của `start_url`/`scope`/`id`
  trong manifest (mục 9.1) và là redirect URL phải khai báo trong Supabase Auth (mục 11).

### 10.2 Job kiểm tra build web

Thêm vào `build-apk.yml` (hoặc workflow riêng chạy mỗi push): `flutter analyze` + `flutter test`
+ `flutter build web --release`. Đây là chốt để PR không làm gãy web mà không ai biết.

### 10.3 `.env` trên web

`.env` đang được bundle làm asset (`pubspec.yaml: assets: - .env`) → trên web tải được ở
`assets/.env`. Đã kiểm tra nội dung chỉ có `SUPABASE_URL` và `SUPABASE_ANON_KEY`.

**Chấp nhận được**, vì anon/publishable key của Supabase được thiết kế để public, bảo mật nằm ở
RLS — và RLS đã bật đủ 5 bảng (`supabase_setup.sql:203-207`). Điều kiện bắt buộc:

- Bảng `priority_levels` mới **phải** có RLS (mục 6.1).
- Không commit giá trị thật ngoài những key vốn đã public; `.env` thật vẫn nằm trong `.gitignore`
  và CI phải nhận qua GitHub Secrets rồi ghi ra file lúc build.

## 11. Bảo mật

| Vấn đề | Đánh giá | Xử lý |
|---|---|---|
| `.env` public trên web | Chỉ chứa anon key — public theo thiết kế Supabase | RLS bắt buộc cho mọi bảng; secrets CI qua GitHub Secrets |
| `flutter_secure_storage` trên web | Bản web dùng WebCrypto + **localStorage**, đánh dấu experimental, kém an toàn hơn Android Keystore | Chấp nhận có ý thức; bù bằng CSP chặt, không nhúng script bên thứ ba, không dùng CDN ngoài |
| Ảnh signed URL | TTL 3600s, bypass RLS với ai cầm được | Không cache trong service worker |
| Google OAuth trên web | `auth_repository.dart:80` đã có nhánh `kIsWeb ? null : deepLink`; `supabase_config.dart:80` đã trả `FlutterAuthClientOptions()` cho web | Thêm `https://beloncuaem.github.io/pixket/` vào danh sách redirect URL trong Supabase Dashboard |

CSP tối thiểu trong `index.html`: `default-src 'self'; script-src 'self' 'unsafe-eval';
img-src 'self' data: blob: https://<SUPABASE_HOST>; connect-src 'self' https://<SUPABASE_HOST>;
style-src 'self' 'unsafe-inline'`, trong đó `<SUPABASE_HOST>` là host lấy từ `SUPABASE_URL`
trong `.env` (không hardcode vào repo để tránh lệch khi đổi project Supabase).
(`'unsafe-eval'` cần cho dart2js/CanvasKit; phải thử và siết dần, không nới rộng thêm.)

## 12. Kiểm thử

### 12.1 Chốt chống hồi quy quan trọng nhất

Thêm test duyệt `lib/` và khẳng định **không file nào ngoài `*_io.dart` được import `dart:io`**.
Đây là cách rẻ nhất đảm bảo build web không gãy lại khi sau này có người thêm `File` vào code
chung. Cùng nguyên tắc cho `package:flutter_cache_manager` và `package:cached_network_image`:
chỉ được import từ file `*_io.dart`.

Đặt tại `test/unit/web_platform_boundary_test.dart`.

### 12.2 Test hiện có

59 file `*_test.dart` trong `test/unit`, `test/widget`, `test/tool` (đếm lại sau Plan 1). Baseline
`flutter test` trên `main` `01dd660`: **405 pass / 7 skip / 0 fail**. Giữ nguyên `flutter test`.
Nhờ `AppSettingsRepository` giữ nguyên chữ ký (mục 6.2) nên `MemorySettingsRepository`,
`_BrokenSettings` và các test effects không phải sửa.

### 12.3 Test hiện có chắc chắn bị ảnh hưởng

Đã kiểm tra trong `test/unit` và `test/widget` — 4 file này đụng trực tiếp phần code phải refactor,
nên **phải sửa cho chạy lại được, không được xóa**:

| File | Vì sao bị ảnh hưởng |
|---|---|
| `test/unit/square_image_test.dart` | `writeSquareCopy(File)` bị xóa, tách thành `squareBytes(Uint8List)` |
| `test/unit/save_to_gallery_test.dart` | hàm đổi sang nhận bytes + đi qua `GallerySaver` |
| `test/widget/pixel_receipt_image_test.dart` | `ReceiptImageSource.localFile` → `localBytes`, `CachedNetworkImage` → `ReceiptCacheImage` |
| `test/widget/legacy_cleanup_test.dart` | nhánh migration ảnh legacy (`expense_repository.dart:61`) chuyển thành IO-only |

### 12.4 Test mới cần viết

- Unit: `squareBytes` bản IO — kế thừa toàn bộ assertion cắt vuông/EXIF/quality từ
  `square_image_test.dart` sau khi tách hàm.
- Unit: `PriorityRepository.getAll()` bản Supabase — đọc `level_key` thành `id`, đúng thứ tự
  `sort_order`, giữ đúng `color_value`; dùng fake client theo mẫu `test/support/fakes.dart`.
- Unit: `AppSettingsRepository` trên `SharedPreferences.setMockInitialValues({})` cho cả 3 key
  `onboarding_complete`, `theme_mode`, `chart_spend_ramp`.
- Unit: migration one-shot SQLite → shared_preferences (mục 6.3), có cờ đã-migrate để không chạy
  lại lần hai, và không ghi đè key người dùng đã có giá trị mới.
- Widget: `ReceiptCacheImage` cả hai nhánh IO/Web render được với url + placeholder.
- Boundary test mục 12.1.

### 12.5 Kiểm thử thủ công bắt buộc

Không thể khẳng định PWA hoạt động chỉ bằng `flutter test`. Phải kiểm tra trên trình duyệt thật:

1. `flutter run -d chrome` — app mở được, đăng nhập email + Google OAuth chạy được.
2. Chụp/chọn ảnh trên Chrome desktop (file picker) và Chrome Android (camera gốc), ảnh lên feed
   đúng dạng vuông.
3. Thêm/sửa/xóa khoản chi, đổi danh mục, đổi mức độ cần thiết, đặt ngân sách, xem thống kê.
4. Lưu ảnh về máy → browser download chạy.
5. Cảnh báo ngưỡng ngân sách → notification của trình duyệt hiện.
6. Lighthouse PWA audit: installable, manifest hợp lệ, SW đăng ký đúng scope.
7. Deploy lên GitHub Pages rồi "Add to Home Screen" trên Android, mở lại xác nhận chạy standalone.

## 13. Rủi ro và dự phòng

| Rủi ro | Khả năng | Dự phòng |
|---|---|---|
| Cắt ảnh vuông bằng canvas cho kết quả khác bản IO (màu, EXIF, quality) | Trung bình | So sánh byte/kích thước trên cùng một ảnh mẫu; nếu lệch chấp nhận được thì ghi rõ trong spec, nếu không thì dùng `squareImageSide` nhỏ hơn cho web |
| Blob URL của draft hết hạn khi reload giữa chừng trên web | Trung bình | Draft web chỉ sống trong phiên; hiện thông báo rõ khi mất draft thay vì crash |
| Migration `app_settings` SQLite → `shared_preferences` hỏng trên máy người dùng Android hiện hữu (mất cờ onboarding → bị đưa lại vào màn giới thiệu, mất theme đã chọn) | Trung bình | Migration one-shot có cờ đánh dấu, **không ghi đè** key đã có giá trị; chạy trước khi xóa dependency; giữ backup branch trước khi merge. `priority_levels` không cần migration vì là bảng hệ thống cố định |
| GitHub Pages cache `flutter_service_worker.js` quá lâu khiến user kẹt bản cũ | Thấp | Action deploy set `Cache-Control: no-cache` cho `flutter_service_worker.js` và `index.html` |
| CSP chặn CanvasKit hoặc Supabase | Trung bình | Nới từng directive một, kiểm tra console; không dùng `unsafe-inline` cho `script-src` |
| Google OAuth không nhận redirect origin mới | Cao nếu quên | Thêm `https://beloncuaem.github.io/pixket/` vào Supabase Auth redirect URLs trước khi test |

## 14. Tiêu chí hoàn thành

1. Bản web **chạy đúng trong trình duyệt** cho toàn bộ luồng nghiệp vụ (mục 12.5), không còn lỗi
   `Unsupported operation` / `MissingPluginException` chưa giải thích được. *(Tiêu chí "build web
   compile sạch" đã đạt sẵn từ trước Plan 2 — see mục 4.1 — nên nó chỉ là điều kiện cần, không phải
   bằng chứng; `flutter build web --release --base-href /pixket/` vẫn phải chạy sạch trong CI.)*
2. `flutter analyze` và `flutter test` pass, bao gồm boundary test mục 12.1.
3. Bản Android (và iOS nếu build) **không đổi hành vi**: draft vẫn ghi đĩa, notification vẫn qua
   `flutter_local_notifications`, ảnh vẫn cache qua `cached_network_image`. *Sửa 2026-11-04: Windows
   rút khỏi tiêu chí — project không có bằng chứng bản Windows từng chạy được các plugin này (mục
   6.3), và Plan 2 không nghiệm thu Windows.*
4. Không còn `path_provider` và `database_helper.dart` trong project; `sqflite` chỉ còn được
   import từ đúng một file migration (mục 6.3) và sẽ gỡ ở release kế tiếp.
5. Deploy lên GitHub Pages thành công; Lighthouse báo installable.
6. Checklist thủ công mục 12.5 chạy hết trên Chrome desktop, Chrome Android và bản đã cài
   lên home screen.
7. Manifest + icon đúng brand pixel (`#FFF6E3`, logo Lens Orbit), không còn màu `#0175C2`
   hay icon Flutter mặc định.

## 15. Nguồn kiểm chứng

- `sqflite` · `path_provider` · `camera` 0.11.1 · `image_picker` · `gal` · `image` · `http` ·
  `supabase_flutter` · `flutter_dotenv` 5.2.1 · `shared_preferences` · `flutter_secure_storage` ·
  `permission_handler` — badge nền tảng trên pub.dev
- `flutter_local_notifications` changelog — web support thêm ở 22.0.0; issue #481
- `cached_network_image` / `flutter_cache_manager` — pub.dev (không có Web ở cả bản mới nhất),
  và giải nén bản 3.4.5 + 3.4.8 để xác nhận `dart:io` vô điều kiện
- `sqflite_common_ffi_web` — pub.dev (experimental; không chọn vì 2 bảng quá nhỏ)
- `dart:io` không khả dụng trên web — api.flutter.dev/flutter/dart-io/
- `compute()` bản web — đọc trực tiếp `packages/flutter/lib/src/foundation/_isolates_web.dart`
  của Flutter 3.47.6 cài tại `C:\flutter`

**Bổ sung 2026-11-04 (đo trên `main` `01dd660`, Flutter 3.47.6 tại `/c/flutter/bin/flutter`):**

- `flutter build web` exit 0, `√ Built build\web` (53,6s) dù còn 8 file import `dart:io` và còn
  `flutter_cache_manager` → mục 4.1/4.2 viết lại: không có nút thắt compile.
- `flutter_local_notifications` 18.0.1 — đọc `lib/src/flutter_local_notifications_plugin.dart`
  trong pub cache: 8 nhánh `if (kIsWeb)`, `initialize()` trả `true` ở :114, `show()` return sớm ở :219.
- `gal` 2.3.3 và `sqflite` 2.4.4 — khối `flutter.plugin.platforms` trong pubspec của từng package
  trong pub cache (gal: android/ios/macos/windows; sqflite: android/ios/macos).
- Cảnh báo cho người đọc spec: 2 chuỗi `Bad state: database is locked` và
  `Bad state: no such table: app_settings` trong output của
  `test/unit/legacy_settings_migration_test.dart` là `StateError` **do test giả lập** (dòng 72, 82),
  không phải lỗi thật của sqflite trên nền tảng — đừng trích chúng làm bằng chứng.
- Máy dev không có Google Chrome, chỉ có Microsoft Edge; `build/web` đã render được bằng Chromium
  của Playwright.
