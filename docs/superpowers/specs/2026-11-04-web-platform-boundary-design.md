# Pixket Plan 2 — Ranh giới nền tảng web (Web Platform Boundary)

Ngày: 2026-11-04
Trạng thái: đã duyệt trong brainstorming, chuyển writing-plans
Plan 1: `docs/superpowers/plans/2026-11-04-drop-sqlite.md` — **đã merge**, `main` = `01dd660`
Spec cha: `2026-11-04-pwa-design.md` — mục 3, 5, 5.1, 7, 12 là quyết định **đã chốt**; spec này
tham chiếu chứ không chép lại, và chỉ thêm những gì Plan 2 đo mới hoặc quy hoạch mới.

## 1. Vị trí trong chuỗi ba plan

| Plan | Giao phẩm | Trạng thái |
|---|---|---|
| 1 — Drop SQLite | Data layer chỉ còn Supabase + `shared_preferences` | đã merge `01dd660` |
| 2 — Boundary (spec này) | App **chạy đúng trong trình duyệt** tới mức nghiệp vụ đầy đủ, có đăng nhập | chưa bắt đầu |
| 3 — PWA shell & deploy | manifest/icon/service worker brand pixel, CSP, GitHub Pages, redirect URL Supabase Auth, Lighthouse installable, checklist mục 12.5 trên thiết bị thật | chưa viết |

Plan 2 **không** tạo file `web/manifest.json` mới, **không** service worker, **không** deploy. Plan 3
nhận từ Plan 2: một bản `build/web` chạy được thật, một báo cáo audit, và danh sách việc còn lại.

## 2. Sáu premise của spec cha đã bị bác, và cách nó đổi thiết kế

| Premise cũ | Đo lại (bằng chứng ở mục 10) | Hệ quả cho Plan 2 |
|---|---|---|
| "`flutter build web` hiện đang fail vì `dart:io`" (mục 2 + 4.1) | Build **exit 0**, `√ Built build\web`, 53,6s trên `01dd660` với đủ 8 file import `dart:io` và `flutter_cache_manager` còn nguyên. dart2js stub `dart:io`; plugin channel chỉ thiếu lúc chạy | Tiêu chí "build sạch" không còn là đích. Plan 2 **mở đầu bằng audit runtime** (mục 5) và chỉ nghiệm thu bằng trình duyệt |
| "`flutter_cache_manager` gãy compile, bắt buộc bọc" (mục 4.1/4.2) | Compile sạch thật; vẫn **phải** bọc, nhưng vì luật cấu trúc (seam render/eviction), **không** vì "sẽ ném khi chạy" — *Lượt 1 audit đo lại:* pubspec của `flutter_cache_manager` 3.4.5 có khai báo `web:` và package có conditional import `_config_web.dart` (cache không ghi đĩa trên web) | Boundary test (mục 4) vẫn là chốt chống hồi quy, và là **chốt tự động duy nhất** — vì compiler im lặng |
| "`flutter_local_notifications` 18: `initialize()` ném runtime" (mục 4.2) | Không ném: 8 nhánh `if (kIsWeb)`; `initialize()` trả `true` (:114), `show()` return sớm (:219) → web **âm thầm không hiện gì** | `ReceiptNotifier` bản Web là **thêm tính năng**, không phải sửa crash → xếp cuối thứ tự làm (mục 6), không chặn luồng nào |
| "Migration cho người dùng Android/**Windows**"; "Bản Android và **Windows** không đổi hành vi" (mục 6.3, 14.3) | `sqflite` 2.4.4 chỉ đăng ký plugin android/ios/macos theo pubspec của package → Windows chưa từng có `pixket.db` | Plan 2 **không cam kết và không nghiệm thu Windows**. iOS được giữ nguyên hành vi nhưng không build-test (không có Xcode) |
| "`camera` không có implementation web, bản web phải dùng `image_picker`" (mục 4.2 seam 3) | *Lượt 1 audit (debug build):* `camera_web` **có** đăng ký plugin và ống ngắm chạy thật ở 1280x720. `takePicture()` **chưa đo** | Seam `PhotoCapture` vẫn bắt buộc (screen không được import `camera` trực tiếp), nhưng bản web **không bắt buộc** tụt sang `image_picker`: giữ `image_picker` làm mặc định an toàn, `camera_web` là lựa chọn chọn-sau, chỉ khi Lượt 2 đo được `takePicture()` |
| "`CachedNetworkImage` sẽ ném `MissingPluginException` trên web ⇒ bấm ảnh là vỡ" (dòng dự đoán của seam 5) | Chưa đo được (feed cần đăng nhập). Bằng chứng trong pub cache nghiêng về **render được, không persist**: `config.dart:3-4` + `_config_web.dart:17-18` (`NonStoringObjectProvider`, `MemoryCacheSystem`) | Seam 5 vẫn làm, nhưng nghiệm thu là **hành vi render + eviction đúng**, không phải "hết lỗi trong console"; `pixel_receipt_image.dart:176` `errorWidget` đổi lỗi ảnh thành placeholder im lặng nên phải nhìn bằng mắt, không nhìn bằng console |

Bản vá đã ghi trực tiếp vào spec cha, có nhãn "(sửa 2026-11-04)" tại mục 2, 4.1, 4.2, 6.3, 8, 12.2,
14 và mục 15.

## 3. Phạm vi

**Trong phạm vi Plan 2**
- Audit runtime lần 0 (mục 5) — sản phẩm là bảng lỗi đo được, không phải code.
- 6 seam platform, tính cả `receipt_cache.dart` (mục 4.2).
- Đổi đơn vị tiền tệ của ảnh từ đường dẫn file sang `Uint8List` (mục 4.3).
- Boundary test mở rộng (mục 4.1) — rule mới cho `gal`, `camera`, `flutter_local_notifications`.
- Parity web cho `squareBytes` và `LocalDraftStore`, chạy bằng `flutter test --platform chrome`.
- Job CI `flutter build web --release`.

**Ngoài phạm vi, có chủ đích**
- Mọi thứ mục 1 gán cho Plan 3.
- Không gỡ `sqflite` (spec cha mục 6.3: gỡ ở release kế tiếp, sau khi ai cũng chạy migration).
- Không nâng `flutter_local_notifications` 18 → 22 (spec cha mục 5.1.2).
- Không đụng `flutter_secure_storage`, Supabase schema, RLS, `supabase_setup.sql`.
- Web Push chạy nền, viewfinder tự viết bằng `getUserMedia` (spec cha mục 2).

## 4. Ranh giới: quy ước file và những chữ ký đổi

Mỗi capability = **4 file** theo mẫu `x.dart` (conditional export) + `x_io.dart` + `x_web.dart` +
`x_stub.dart`. Stub là điều kiện mặc định của conditional export, đồng thời là seam để widget test
tiêm implementation không đụng plugin. Chi tiết mục 5 spec cha.

### 4.1 Ba quy tắc boundary (định nghĩa nghiệm thu được)

Test mới `test/unit/web_platform_boundary_test.dart` duyệt đệ quy `lib/` và asserts:

- **R1** — không file nào ngoài `*_io.dart` chứa `import 'dart:io'`.
- **R2** — không file nào ngoài `*_io.dart` import `package:flutter_cache_manager` hoặc
  `package:cached_network_image` (spec cha mục 12.1 đã nêu 2 package này).
- **R3** — không file nào ngoài `*_io.dart` import `package:gal`, `package:camera`,
  `package:flutter_local_notifications`. *Bổ sung so với spec cha:* cả ba compile được trên web;
  `gal` và `flutter_local_notifications` thì không có nhánh web (ném / im lặng), còn `camera` **có**
  `camera_web` (Lượt 1 audit) — nên R3 giữ nguyên vì lý do cấu trúc: screen không được biết plugin.

`*_web.dart` được phép dùng `dart:js_interop` / `package:web`. `kIsWeb` được phép xuất hiện ở code
chung (guard runtime), không bị R1–R3 chạm tới. Test chỉ quét `lib/`, không quét `test/` vì test chạy
trên VM nơi `dart:io` là hợp lệ.

Harness có sẵn để bắt chước: `_filesContaining()` trong `test/widget/legacy_cleanup_test.dart:14-17`
đã scan `lib/` theo chuỗi.

### 4.2 Sáu seam và đúng những chỗ gọi chúng

| # | Capability (file mới) | Chỗ gọi hiện tại sẽ đổi | Bản IO | Bản Web |
|---|---|---|---|---|
| 1 | `squareBytes` — `lib/core/utils/square_image.dart` (+`_io`/`_web`/`_stub`) | `camera_screen.dart:159,180`; `expense_repository.dart:64`; `expense_repository_write_test.dart:283,289` | `image` package + `compute`, giữ `squareImageSide`/`Quality`/`Suffix` | `createImageBitmap` + `OffscreenCanvas` + `convertToBlob` (spec cha mục 7.1) |
| 2 | `LocalDraftStore` — `lib/core/platform/local_draft_store.dart` | `expense_form_sheet.dart:130,175`; `expense_provider.dart:192`; `camera_screen.dart:162,182` (truyền `imagePath`) | ghi file tạm như hiện tại (spec cha mục 5.1.1) | bytes/Blob URL giữ trong phiên |
| 3 | `PhotoCapture` — `lib/core/platform/photo_capture.dart` | `camera_screen.dart:62-169` (ống ngắm `camera`), `:171-187` (`image_picker` gallery) | `camera` + viewfinder pixel hiện có | `image_picker` `ImageSource.camera`/`.gallery` (spec cha mục 3, 7.5) |
| 4 | `GallerySaver` — `lib/core/platform/gallery_saver.dart` | `save_to_gallery.dart:26` | `Gal.putImageBytes` | Blob + `<a download>` (gal không có plugin web) |
| 5 | `ReceiptCacheImage` + `receipt_cache.dart` | `pixel_receipt_image.dart:160`; `app.dart:70`; `expense_provider.dart:187` | `CachedNetworkImage`, `DefaultCacheManager().emptyCache()` | `Image.network` + `imageCache.clear()`/`evict(url)` |
| 6 | `ReceiptNotifier` — `lib/core/platform/receipt_notifier.dart` | `main.dart:21`; `budget_provider.dart:168`; `onboarding_screen.dart:53` | `flutter_local_notifications` 18.0.1, giữ nguyên chuỗi tiếng Việt (`notification_service.dart:50-51`) | Web Notifications API qua `dart:js_interop` (spec cha mục 8) |

`receipt_cache.dart` phải có **cả hai** hàm: `clearReceiptCache()` và
`evictReceiptImage(String url, {String? cacheKey})`. Thiếu hàm sau thì `expense_provider.dart:187`
vẫn import `cached_network_image` và phạm R2.

Ngoài 6 seam, một chỗ đổi hành vi nữa nằm trong code chung: `onboarding_screen.dart:52-53` xin quyền
camera + notification upfront. Trên web phải **bỏ qua cả hai lời gọi** để browser tự hỏi đúng lúc
(spec cha mục 8). Đây là guard `kIsWeb`, không phải seam thứ 7.

### 4.3 Bytes là đơn vị tiền tệ

| Chữ ký | Hiện tại | Sau Plan 2 |
|---|---|---|
| `writeSquareCopy` | `Future<File> writeSquareCopy(File source)` (`square_image.dart:50`) | `Future<Uint8List> squareBytes(Uint8List source)`; `cropToSquareBytes` pure Dart giữ nguyên (`square_image_test.dart:24-55` không đổi) |
| `uploadReceiptImage` | `Future<String> uploadReceiptImage(String localFilePath)` (`supabase_storage_service.dart:20`) | `Future<String> uploadReceiptImage(Uint8List bytes, {required String extension, required bool squared})` (spec cha mục 7.2) |
| `_resolveImage` | nhận `String? source` là đường dẫn, `File(value).exists()` (`expense_repository.dart:54-72`) | nhận bytes + tên; nhánh lazy-migrate ảnh legacy thành IO-only |
| `saveReceiptToGallery` | `{signedUrl, localPath, name, client}` (`save_to_gallery.dart:12-17`) | `{signedUrl, bytes, name, client}` + đi qua `GallerySaver` |
| `PixelReceiptImage` | `enum ReceiptImageSource { signedUrl, localFile, none }` + `String? localPath` (`pixel_receipt_image.dart:11,144`) | `localBytes` + `Uint8List? localBytes`; nhánh render `Image.file` (:179-180) → `Image.memory` |
| `openExpenseForm` | `imagePath:` xuyến suốt `camera_screen.dart:189` → `expense_form_sheet.dart` | `draft:` (token của `LocalDraftStore`) hoặc bytes |

### 4.4 Gate có sẵn sẽ đổi nghĩa — sửa, không xóa

`legacy_cleanup_test.dart:87-97` ("mọi ảnh khoản chi đi qua `PixelReceiptImage`") đang loại trừ đúng
một file `pixel_receipt_image.dart` khi scan `Image.file(` và `CachedNetworkImage(`. Sau Plan 2, hai
needle đó hợp lệ trong `*_io.dart`, nên điều kiện loại trừ phải thành "file `*_io.dart`". Cùng luật
cho 4 file spec cha mục 12.3 đã nêu và 2 file spec cha **chưa** nêu:

| File test | Vì sao đụng |
|---|---|
| `test/unit/square_image_test.dart` | `cropToSquareBytes` giữ nguyên; nếu có case `writeSquareCopy` thì chuyển sang `squareBytes` IO |
| `test/unit/save_to_gallery_test.dart` | `localPath:` → `bytes:`; case "thiếu tệp" (`:45-47`) phải viết lại thành case lỗi nền tảng, vì `catch (_)` ở `save_to_gallery.dart:32` bị bỏ |
| `test/widget/pixel_receipt_image_test.dart` | `localPath:` (`:31,:74`) → bytes; `CachedNetworkImage` (`:62`) → `ReceiptCacheImage` |
| `test/unit/pixel_receipt_image_test.dart` | `ReceiptImageSource.localFile` + `localPath` (`:20,:25-26,:41`) → `localBytes` |
| `test/unit/expense_repository_write_test.dart` | gọi thẳng `writeSquareCopy` (`:277-289`) — **spec cha mục 12.3 liệt kê thiếu file này** |
| `test/widget/legacy_cleanup_test.dart` | gate scan `lib/` (`:87-97`) |

## 5. Task 0 — audit runtime, làm trước khi viết bất kỳ dòng nào

Lý do: dart2js và plugin stub im lặng lúc compile, nên danh sách "chỗ phải sửa" phải lấy từ máy đo,
không từ suy luận. Bản spec cha được viết từ suy luận và đã sai 4 chỗ (mục 2); Lượt 1 của chính Task 0
lại bác thêm 2 chỗ nữa (2 dòng cuối mục 2) — nên các hàng đợi "chưa đo" trong audit là một phần của
phương pháp, không phải thiếu sót.

**Cách chạy**
1. `flutter build web --debug` *(buộc, sửa theo Lượt 1 audit)*. Bản release gán `debugPrint` thành
   hàm rỗng (`lib/main.dart:15-17`) nên mọi chuỗi `Unsupported operation: ...` — đúng thứ ta cần đo —
   biến mất khỏi console, người dùng chỉ còn thấy thông báo tiếng Việt.
2. Serve tĩnh: `python -m http.server --directory build/web 3000` *(sửa theo audit: Supabase cấu hình
   OAuth callback về `localhost:3000`, serve cổng khác thì Google login chết bằng `ERR_CONNECTION_REFUSED`
   và đó là lỗi cấu hình, không phải lỗi seam)*.
3. Điều khiển bằng Chromium của Playwright MCP (đã chứng minh render được app; **máy này không có
   Google Chrome**, chỉ có Edge).
4. Lượt 1 — chưa đăng nhập: onboarding → màn hình login → bấm Google OAuth → bấm nhập email sai →
   đọc console. Lượt 2 — người dùng đăng nhập thật một lần (~15 phút) và đi qua: feed, thêm khoản chi
   bằng ảnh, sửa, xóa, danh mục, mức độ, ngân sách, thống kê, cài đặt, thùng rác, tải ảnh.

**Sản phẩm:** `docs/superpowers/audits/2026-11-04-web-runtime-audit.md`, mỗi dòng một lỗi:

```
màn hình | hành động | chuỗi lỗi nguyên văn | file:nguyên nhân | mức độ | plan xử lý
```

**Ràng buộc**
- Task 0 chỉ đọc, không sửa code.
- Không dán signed URL có token, không dán nội dung `.env` vào báo cáo. `.env` local có anon key vốn
  public theo spec cha mục 10.3, vẫn không đưa vào docs.
- Nếu audit tìm ra chỗ gãy ngoài 6 seam mục 4.2: ghi vào báo cáo và **thêm task**, không âm thầm mở
  rộng phạm vi.
- Cuối Plan 2 chạy lại đúng script này; bảng lỗi rỗng (hoặc còn dòng đã san sang Plan 3 kèm lý do)
  là bằng chứng nghiệm thu.

## 6. Thứ tự làm — theo mức gãy, mỗi capability một commit

| Bước | Việc | Vì sao ở vị trí này |
|---|---|---|
| 0 | Audit runtime mục 5 | Không có gì sửa được nếu chưa biết lỗi thật là gì |
| 1 | `squareBytes` + boundary test R1–R3 | Mọi luồng ảnh đi qua đây; là seam duy nhất có **thuật toán** phải port (canvas) nên cần parity test sớm |
| 2 | `LocalDraftStore` | giải phóng `camera_screen`/`expense_form_sheet`/`expense_provider` khỏi `File`; điều kiện cần của bước 3 |
| 3 | `PhotoCapture` | đổi ảnh vào app; sau bước 1–2 nên chữ ký bytes đã ổn định |
| 4 | `GallerySaver` | một hàm, một chỗ gọi, rủi ro thấp; kèm việc bỏ `catch (_)` ở `save_to_gallery.dart:32` để người dùng web thấy lý do thật thay vì 'Không lưu được ảnh về máy.' |
| 5 | `ReceiptCacheImage` + `receipt_cache.dart` | ảnh signed URL trên web hiện **không hiển thị được** (cache manager ném khi chạy); D2 là widget thuần nên cần render web |
| 6 | `ReceiptNotifier` | không chặn luồng nào; 18.0.1 đã im lặng chứ không crash (mục 2) → đây là thêm tính năng, làm cuối |

Thứ tự này giả định audit mục 5 **không** đảo tình tiết nào. Nếu audit đo được thứ tự gãy khác,
audit thắng, và spec này được cập nhật kèm lý do — không đi theo bảng trên một cách máy móc.

## 7. Chiến lược kiểm thử

- **VM (`flutter test`)** — giữ baseline **405 pass / 7 skip / 0 fail** trên `01dd660`; 6 file mục 4.4
  được **sửa cho chạy lại, không xóa**; boundary test R1–R3 chạy ở đây.
- **Web parity (`flutter test --platform chrome`)** — hai mục tiêu: `squareBytes` (cùng một ảnh mẫu
  JPEG → decode được, đúng `squareImageSide` × `squareImageSide` (1200×1200), không đảo hướng EXIF) và
  `LocalDraftStore` bản web (save/read/exists/delete trong một phiên). Máy không có Chrome → thử
  `CHROME_EXECUTABLE` trỏ `msedge.exe`; nếu runner từ chối Edge thì fallback sang kiểm chứng qua
  Playwright Chromium trên `build/web`, và **phải ghi rõ trong báo cáo** rằng parity chưa chạy qua
  runner — không im lặng bỏ.
- **Build + CI** — thêm job `flutter build web --release` (cạnh `build-apk.yml`). Nói rõ giới hạn:
  job này chứng minh compile + chạy được test boundary, **không** chứng minh hành vi web.
- **Thủ công** — spec cha mục 12.5 items 1–5 tự kiểm chứng bằng script audit mục 5 (item 1 dùng
  build tĩnh thay cho `flutter run -d chrome` vì không có Chrome). Items 6–7 thuộc Plan 3.

## 8. Tiêu chí hoàn thành Plan 2

1. Boundary test R1–R3 xanh; `grep -rn "dart:io" lib --include=*.dart` chỉ ra file `*_io.dart`.
2. Bảng audit mục 5 không còn dòng mức "chặn luồng" nào ở trạng thái "chưa xử lý"; mỗi dòng còn lại
   ghi rõ "san Plan 3" kèm lý do.
3. Luồng web đã đo thật trong trình duyệt: đăng nhập, xem feed, thêm/sửa/xóa khoản chi kèm ảnh vuông,
   danh mục, mức độ, ngân sách, thống kê, tải ảnh về máy.
4. `flutter analyze` + `flutter test` pass; 6 file mục 4.4 vẫn còn và vẫn assert điều cũ.
5. Không còn tham số ảnh dạng đường dẫn file trong pipeline: `writeSquareCopy` biến mất,
   `ReceiptImageSource.localFile` → `localBytes`, `uploadReceiptImage` nhận bytes.
6. Hành vi mobile không đổi về mặt code: draft vẫn ghi đĩa, notification vẫn qua plugin 18, cache vẫn
   qua `CachedNetworkImage` — kiểm chứng bằng reading + test; **chưa chạy lại trên máy Android thật**,
   nên tiêu chí này ghi rõ mức chứng cứ là test chứ không phải thiết bị (Plan 3 hoặc chủ dự án chạy
   thiết bị).
7. Giao phẩm cho Plan 3: báo cáo audit + danh sách việc còn lại + `build/web` chạy được.

## 9. Rủi ro còn lại

| Rủi ro | Xử lý |
|---|---|
| Canvas crop cho kết quả khác `image` package (màu, EXIF, quality) | parity test mục 7; lệch chấp nhận được thì ghi vào audit, không sửa âm thầm (spec cha mục 13 đã nêu) |
| `compute()` trên web chạy cùng thread → cắt ảnh lớn có thể đơ UI | bản web dùng `createImageBitmap`/`OffscreenCanvas` native của browser (spec cha mục 4.3, 7.1); nếu buộc phải dùng `image` package thì đo và ghi |
| Blob URL của draft hết hạn khi reload giữa chừng | draft web chỉ sống trong phiên; báo cho người dùng thay vì crash (spec cha mục 13) |
| `flutter test --platform chrome` không dùng được với Edge | fallback Playwright + ghi rõ giới hạn (mục 7) |
| Refactor chạm 8 file `lib/` + 6 file test, dễ lẫn hồi quy | mỗi capability một commit; review diff từng capability; audit script chạy lại ở cuối |
| Audit lượt 2 cần người đăng nhập thật | chủ dự án đăng nhập một lần ~15 phút; lượt 1 không cần ai |

## 10. Nguồn kiểm chứng

- `flutter build web` trên `main` `01dd660`: exit 0, `√ Built build\web`, 53,6s.
- 8 file `lib/` import `dart:io` (grep); chỗ dùng cụ thể lấy từ bảng spec cha mục 4.1 và xác nhận lại
  tại `pixel_receipt_image.dart:179-180`, `save_to_gallery.dart:53`, `expense_repository.dart:61,64`,
  `supabase_storage_service.dart:27`, `expense_provider.dart:192`, `camera_screen.dart:159,180`,
  `expense_form_sheet.dart:130,175`.
- `flutter_local_notifications` 18.0.1 — `lib/src/flutter_local_notifications_plugin.dart` trong pub
  cache: 8 nhánh `if (kIsWeb)`, `initialize()` :114, `show()` :219.
- `gal` 2.3.3 (`flutter.plugin.platforms`: android/ios/macos/windows) và `sqflite` 2.4.4
  (android/ios/macos) — pubspec của package trong pub cache.
- `pubspec.lock`: `permission_handler` 11.4.0, `sqflite` 2.4.4, `shared_preferences` 2.5.6,
  `flutter_cache_manager` 3.4.5, `cached_network_image` 3.4.1, `gal` 2.3.3, `image` 4.12.0.
- Chuỗi lỗi trong output `test/unit/legacy_settings_migration_test.dart`
  (`Bad state: database is locked`, `Bad state: no such table: app_settings`) là `StateError` **do test
  giả lập** tại :72 và :82 — không phải lỗi nền tảng, đừng trích làm bằng chứng.
- Playwright MCP Chromium đã render thành công `build/web` trên máy này; Google Chrome không được cài,
  `CHROME_EXECUTABLE` chưa đặt.
- Baseline test `flutter test` trên `01dd660`: 405 pass / 7 skip / 0 fail; 59 file `*_test.dart`.
