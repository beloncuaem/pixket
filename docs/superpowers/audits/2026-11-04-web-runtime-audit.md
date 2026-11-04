# Audit runtime bản web — Task 0, Plan 2 (ranh giới nền tảng)

Bằng chứng thu được bằng **chạy thật** trong trình duyệt, không phải bằng
`flutter build web` exit 0. dart2js im lặng: `dart:io` và MethodChannel compile
fine rồi mới ném lúc chạy, nên bảng dưới đây là thứ duy nhất nói cho Task 2..6
biết chỗ nào gãy thật.

**Bắt buộc cho mọi lượt audit lại (Lượt 2 và audit cuối Task 7):** đo bằng bản
**debug** (`flutter build web --debug`) và phục vụ ở cổng **3000**. Hai lý do:
`lib/main.dart:15-17` gán `debugPrint` thành hàm rỗng khi `kReleaseMode`, nên bản
release **không bao giờ** in `Unsupported operation:` — mọi nguyên nhân `dart:io`
dưới đây chỉ lấy được từ bản debug; và Supabase trả OAuth callback về
`http://localhost:3000/?code=<đã che>`, serve cổng khác là `ERR_CONNECTION_REFUSED`
trước khi kịp đo. Lượt 1 đã đo trên bản debug (kèm một bản release để ghi chuỗi
user-visible).

## Cách đo

- Build: `/c/flutter/bin/flutter build web` → exit 0, `√ Built build\web`.
- Serve: `python -m http.server --directory build/web 8080` (Python 3.14.6).
- Trình duyệt: Chromium đi kèm Playwright MCP (máy này không có Google Chrome;
  Edge không dùng tới vì runner test web không được chạy ở Task 0).
- Bật semantics của Flutter web bằng cách click `flt-semantics-placeholder`
  qua JS, vì CanvasKit không phơi tree khả năng tiếp cận nếu không bật. Toàn bộ
  chuỗi tiếng Việt dưới đây lấy nguyên văn từ `flt-semantics.innerText`.
- Snackbar tự ẩn sau 4 s (`pixel_snack_bar.dart:14`), nên kết quả được bắt bằng
  vòng poll semantics ngay sau cú click, không dựa vào screenshot đơn lẻ.
- Có chạy thêm một bản **debug** (`flutter build web --debug --output=build/web-debug`,
  serve ở 8081) vì `main.dart:15-17` tắt `debugPrint` trong bản release: bản
  release **không bao giờ** in nguyên nhân lỗi ra console. Mọi chuỗi "nguyên nhân"
  ở dưới chỉ lấy được từ bản debug.

## Bảng lỗi

Dòng **ĐO** = đo thật trong trình duyệt. Dòng **Dự đoán** = chưa đo được vì cần
dữ liệu/tài khoản thật; cột "Chuỗi lỗi nguyên văn" ghi `chưa đo (cần đăng nhập)`.
Bảng này có **14 dòng**: **5 dòng ĐO** (dòng 1, 2, 3, 13, 14) và **9 dòng Dự đoán**
(dòng 4-12); chưa kể 2 dòng ở mục "Ngoài phạm vi 6 seam". Số dòng 14 và 5/9 này là
số đếm lại từ bảng sau vòng review 1 (bản đầu ghi nhầm 13 dòng = 5 đo / 8 dự đoán,
vì thiếu dòng onboarding).

| Màn / hành động | Chuỗi lỗi nguyên văn | Nguyên nhân dự đoán | Mức | Plan |
|---|---|---|---|---|
| Chọn ảnh từ thư viện (màn camera), sau khi chọn tệp ảnh | `Error picking image: Unsupported operation: _Namespace` (bản debug) → user thấy `Không thể mở thư viện ảnh.` (bản release) | `camera_screen.dart:180` gọi `File(image.path)`; `dart:io` trên web ném `UnsupportedError` ở `_Namespace`. `image_picker` **không** hỏng — file chooser mở được và trả về tệp | Chặn luồng | Task 2 (`writeSquareCopy`) + Task 3 (`PhotoCapture`) |
| Bấm "Chụp khoản chi" khi ống ngắm đã sẵn sàng | `Không thể chụp ảnh. Vui lòng thử lại.` (không kèm nguyên nhân trong bản release — `debugPrint` bị tắt) | `camera_screen.dart:159` `writeSquareCopy(File(picture.path))`; cùng kiểu `Unsupported operation: _Namespace` như dòng trên. Chưa xác nhận được `takePicture()` có trả về trước đó hay không | Chặn luồng | Task 2 + Task 3 |
| Bấm "Tiếp tục với Google" | `net::ERR_CONNECTION_REFUSED`; trang lỗi trình duyệt ghi `This site can't be reached` / `localhost refused to connect.` | Không phải seam nền tảng. Chuỗi redirect: app → `/auth/v1/authorize?provider=google&flow_type=pkce` → Google → `/auth/v1/callback` → **`http://localhost:3000/?code=<đã che>`** (mã OAuth đã bị che). Supabase trả về `SITE_URL` = cổng 3000, trong khi bản audit serve ở cổng 8080, nên phiên không bao giờ quay về app | Chặn luồng | NGOÀI PHẠM VI — cấu hình `SITE_URL` phía Supabase; audit/lượt 2 phải serve đúng cổng 3000 |
| Feed, ảnh đã upload (chưa đo được) | `chưa đo (cần đăng nhập)` | **Không phải `MissingPluginException`** — bằng chứng trong pub cache nghiêng về "ảnh render được, nhưng không có gì được lưu xuống disk": `flutter_cache_manager-3.4.5/pubspec.yaml:36` khai báo `web:`, `lib/src/config/config.dart:3-4` là conditional import, `_config_web.dart:17-18` mặc định `NonStoringObjectProvider()` + `MemoryCacheSystem()`, và `cached_network_image_provider.dart:7-10` nối `cached_network_image_web` cho web. Vì vậy **vẫn chưa đo trong trình duyệt** (feed cần đăng nhập), chứ không suy đoán từ `dart:io` nữa. Console là dụng cụ sai ở đây: `pixel_receipt_image.dart:176` `errorWidget` biến mọi lỗi ảnh thành placeholder im lặng | Hành vi (chưa xác định) | Task 5 (nghiệm thu bằng hành vi render + eviction, không bằng console) |
| Feed, khoản chi chỉ còn ảnh local (chưa đo được) | `chưa đo (cần đăng nhập)` | `pixel_receipt_image.dart:179-180` `Image.file(File(localPath!))` → `Unsupported operation: _Namespace` | Sẹt góc | Task 5 (`ReceiptLocalImage`) |
| Lưu khoản chi mới (form khoản chi) (chưa đo được) | `chưa đo (cần đăng nhập)` | `expense_repository.dart:61` `await File(value).exists()` ném trước khi tới `StateError('Không tìm thấy ảnh để tải lên Cloud.')` ở `:71`; kể cả qua được thì `:64` `writeSquareCopy` (`square_image.dart:59,62`) và `supabase_storage_service.dart:27` `File(localFilePath)` đều ném | Chặn luồng | Task 2 |
| Sửa khoản chi có ảnh (chưa đo được) | `chưa đo (cần đăng nhập)` | Cùng đường ghi ảnh: `expense_repository.dart:61,64` | Chặn luồng | Task 2 |
| Xóa mềm rồi vĩnh viễn xóa khoản chi (chưa đo được) | `chưa đo (cần đăng nhập)` | Hai seam khác nhau trong cùng một hàm `permanentlyDeleteExpense`: `expense_provider.dart:187` `CachedNetworkImage.evictFromCache(...)` là `flutter_cache_manager`/`cached_network_image` (rule **R2**) → Task 5; nhánh local `:192-193` `File(local)` / `file.exists()` / `delete()` là `dart:io` (rule **R1**) → **Task 2** (`localDraftStore.delete(local)`, plan Task 2 đã ghi rõ `expense_provider.dart:192`), **không** phải Task 5 | Sẹt góc | `:187` → Task 5 (`receipt_cache.dart`); `:192-193` → Task 2 (`LocalDraftStore`) |
| Nút tải ảnh về máy (chưa đo được) | `chưa đo (cần đăng nhập)` | `save_to_gallery.dart:53` `File(path)` khi không có signed URL; `:26` `Gal.putImageBytes` — `gal` không có implementation web. `catch (_)` ở `:32-34` nuốt hết, user chỉ thấy `Không lưu được ảnh về máy.` | Sẹt góc | Task 4 |
| Dọn ảnh draft sau khi lưu / khi hủy form (chưa đo được) | `chưa đo (cần đăng nhập)` | `expense_form_sheet.dart:130-133` `File(sourceImagePath)`+`exists()`+`delete()`; `:175-176` `File(draftPath)`+`existsSync()`+`delete()` | Sẹt góc | Task 2 (`LocalDraftStore`) |
| Mở form khoản chi để chọn "mức độ" (chưa đo được) | `chưa đo (cần đăng nhập)` | Không vào được form: hai đường mở form (chụp / chọn ảnh) đều chết ở `dart:io` như 2 dòng đầu bảng. Bản thân danh sách mức độ đọc từ Supabase, không có seam riêng | Chặn luồng | (hệ quả của Task 2/3, không phải lỗi của Task 6) |
| Cảnh báo ngân sách 80/90/100% (chưa đo được) | `chưa đo (cần đăng nhập)` | `notification_service.dart:48` `_plugin.show(...)` — `flutter_local_notifications` không có implementation web. Trên web người dùng **im lặng không nhận được gì**, không có lỗi hiện ra | Sẹt góc | Task 6 |
| Đăng xuất → dọn cache ảnh (đã bấm; đã kết luận được một nửa) | (không có lỗi trong console sau khi đăng xuất) | `app.dart:98` gọi `unawaited(_clearUserCaches())`; `app.dart:70` `DefaultCacheManager().emptyCache()`. `indexedDB.databases()` = `[]` và `caches.keys()` = `[]` **không còn là dấu hiệu hỏng**: đúng cấu hình web của `flutter_cache_manager` — `_config_web.dart:17-18` đặt `NonStoringObjectProvider()` + `MemoryCacheSystem()`, nên web vốn không ghi gì xuống IndexedDB/Cache Storage và không có gì để dọn. Phần còn mở: cache của Task 5 **có** persist trên web hay không, phải kiểm bằng hành vi (ảnh còn hiện sau khi logout + login lại), nên vẫn cần đăng nhập | Hành vi (chưa xác định) | Task 5 (nghiệm thu bằng hành vi, không bằng console) |
| Onboarding: bấm `BẮT ĐẦU` (đường `_finish`), traverse tới `Permission.camera.request()` | (không có lỗi — đo được ở cả bản release lẫn debug) | `onboarding_screen.dart:52` `Permission.camera.request()` và `:53` `NotificationService.instance.requestPermission()` chạy hết trên web mà không ném gì (kết luận của controller: `permission_handler` trả `null` khi `kIsWeb`, `flutter_local_notifications` resolve ra `null` implementation nên `?.` là no-op). **Đo-an toàn trên web, nhưng là im lặng chứ không phải hoạt động.** `permission_handler` được xếp **ngoài** boundary test, vì R1–R3 là rule **import**: file này phải giữ import cho Android/iOS, và Task 3 bọc lời gọi bằng `if (!kIsWeb)` thay vì xóa import | Sẹt góc | Task 3 (`if (!kIsWeb)` ở `:52`) + Task 6 (`:53` → `receiptNotifier.requestPermission()`) |

## Đã đo — chạy ĐÚNG trên web (bằng chứng ngược, quan trọng để xếp thứ tự task)

Những thứ này **không** hỏng, và một vài nghi ngờ trong spec là thừa:

| Hạng mục | Bằng chứng đo được |
|---|---|
| Boot / onboarding | Render đủ 3 trang onboarding, không có console message nào ở bản release (0 error, 0 warning) |
| Font pixel | `GET /assets/assets/fonts/VT323-Regular.ttf => [200] OK`; `BeVietnamPro` 4 weight đều 200. Font pixel load bình thường trên web |
| `LegacySettingsMigration` | `legacy_settings_migration.dart:44` guard `if (kIsWeb) return;` hoạt động — `sqflite` không bị chạm lúc boot |
| `NotificationService.initialize()` | `notification_service.dart:15` chạy lúc boot (`main.dart:21`) mà **không ném**: bản debug chỉ log `Supabase initialized successfully.` rồi app vào tới `runApp`. Chỉ có `_plugin.show()` lúc báo hiệu là đáng ngờ |
| Onboarding → login | Nút `BẮT ĐẦU` ở trang onboarding cuối dẫn thẳng vào màn đăng nhập (không có nút "đã có tài khoản" trên onboarding như brief mô tả; nút đó nằm ở màn login) |
| Login → đăng ký | `Chưa có tài khoản? Đăng ký` mở màn `Tạo tài khoản mới` với đủ trường `Họ và tên`, `Email`, `Mật khẩu`, `Xác nhận mật khẩu`, `ĐĂNG KÝ`, không lỗi |
| Boot khi `localStorage` có `flutter.onboarding_complete` nhưng không có phiên | Vào thẳng màn đăng nhập, không lặp lại onboarding |
| Đăng nhập email/mật khẩu | Luồng REST chạy thật trên web. Với sai mật khẩu: `Failed to load resource: the server responded with a status of 400 () @ https://<project-ref>.supabase.co/auth/v1/token?grant_type=password` và app hiện đúng `Email hoặc mật khẩu không chính xác.` |
| `shared_preferences` trên web | `localStorage` có `flutter.onboarding_complete` = `"true"`, `flutter.theme_mode` = `"dark"`. Ghi/đọc bình thường |
| `flutter_secure_storage` | **Không bị chạm trên web**: `supabase_config.dart:80` trả `FlutterAuthClientOptions()` mặc định khi `kIsWeb`, nên `secure_session_storage.dart` (chỉ dùng ở nhánh không-web) không tạo `MissingPluginException` |
| `image_picker` | File chooser mở được (`[File chooser]: can be handled by browser_file_upload`) và nhận tệp trả về. Hỏng là do `dart:io` phía sau, không do plugin |
| `camera` (ống ngắm) | `camera_web` **có** đăng ký cho web. Khi quyền camera = `granted` và thiết bị rảnh: có 1 phần tử `<video>` với `srcObject` là `MediaStream` thật, `videoWidth=1280`, `videoHeight=720`, `readyState=4` — ống ngắm chạy được. Khi thiết bị bận: `Error listing cameras: CameraException(cameraNotReadable, The camera is not readable due to a hardware error that prevented access to the device.)` và app hiện trạng thái `CAMERA CHƯA SẴN SÀNG / Không tìm thấy máy ảnh trên thiết bị.` (xử lý graceful, không crash). Khi quyền = `prompt` (browser chưa quyết): màn hình **treo vĩnh viễn ở `Đang mở camera…`** — `getUserMedia` không settle trong môi trường automation; đây là bằng chứng ngược với ý "Task 3 nhẹ hơn", xem hệ quả số 2 |
| Boot với phiên đã có trong `localStorage` | App vào thẳng `MainScreen` (tab camera), gọi đúng 6 query PostgREST (`expenses` x4, `priority_levels`, `categories`) — tất cả `401` vì token giả. Không `MissingPluginException` nào |
| Điều hướng drawer | `Tổng quan`, `Thống kê`, `Ngân sách`, `Quản lý danh mục`, `Thùng rác`, `Cài đặt` đều render, không lỗi nền tảng. Thùng rác báo `Không tải được thùng rác. Kiểm tra kết nối.` (do 401, không do seam) |
| Chuyển dark/light | Toggle trong Cài đặt đổi nhãn `SÁNG` → `TỐI`, đổi theme thật, và lưu `flutter.theme_mode` = `"dark"` |
| Đăng xuất | Dialog `HỦY` / `ĐĂNG XUẤT` chạy, phiên bị xóa khỏi `localStorage`, app về trạng thái chưa đăng nhập. Chỉ có `403` từ `/auth/v1/logout?scope=local` vì token giả |

## Chưa đo (cần chủ dự án đăng nhập thật)

Toàn bộ phần có **dữ liệu ảnh thật**, vì không có tài khoản thì không có khoản
chi nào, nên không có ảnh nào được render và không có upload nào được gọi:

- Feed hiện ảnh đã upload (signed URL) — dòng 4 bảng trên.
- Ảnh local của khoản chi chưa upload — dòng 5.
- Lưu / sửa khoản chi kèm ảnh — dòng 6, 7.
- Xóa mềm, hoàn tác, vĩnh viễn xóa — dòng 8.
- Nút tải ảnh về máy — dòng 9.
- Dọn ảnh draft sau khi lưu / hủy form — dòng 10.
- Form khoản chi và danh sách "mức độ" — dòng 11.
- Cảnh báo ngân sách 80/90/100% — dòng 12.
- Thống kê có dữ liệu (biểu đồ pixel từ số liệu thật).

**Cách đo tiếp (đã mở sẵn đường, không cần viết code):**

1. Serve đúng cổng mà Supabase trả về: `python -m http.server --directory build/web 3000`.
   Khi đó callback OAuth sẽ quay về app thay vì `ERR_CONNECTION_REFUSED`.
   (Hoặc chủ dự án đổi `SITE_URL` trong Supabase Auth về cổng dùng để audit.)
2. Đăng nhập bằng email/mật khẩu hoặc Google một lần, rồi đi qua danh sách trên.
3. Chạy bằng **bản debug** (`--output=build/web-debug`) cho phần nguyên nhân, vì
   bản release che hết `debugPrint`; dùng bản release cho chuỗi user-visible.

Ghi chú quyền riêng tư: Chromium dùng cho audit là profile **đã có sẵn phiên Google
và đã được grant camera** cho `localhost:8080`. Chuỗi OAuth đã thực sự xin được
authorization code từ Google mà không cần nhập gì. Tôi **không** hoàn tất lượt
đăng nhập đó, vì brief ghi rõ Lượt 2 thuộc về chủ dự án. Ảnh webcam hiện trong
ống ngắm (chụp màn hình `audit-07-*.png`) là camera thật của máy đang chạy audit;
file ảnh chụp màn hình nằm ngoài repo (thư mục làm việc của Playwright MCP) và
**không** được commit.

## Ngoài phạm vi 6 seam

| Màn / hành động | Chuỗi lỗi nguyên văn | Nguyên nhân dự đoán | Mức | Plan |
|---|---|---|---|---|
| Serve bản web ra ngoài | (không có lỗi — đây là phát hiện, không phải crash) | `.env` được khai báo là asset trong `pubspec.yaml:39`, nên `flutter build web` **đóng gói luôn** thành `build/web/assets/.env` (382 byte) và `python -m http.server` phục vụ nó công khai: `GET http://localhost:8080/assets/.env => [200] OK`. Tôi không đọc và không dán nội dung file; chỉ đọc **tên biến** bằng `grep -o "^[A-Z_]*"`, và chúng là `SUPABASE_URL` + `SUPABASE_ANON_KEY`. Đây là **vệ sinh cấu hình (hygiene)**, không phải rò rỉ secret đang hoạt động: đúng hai giá trị đó đã là public theo thiết kế trong mọi SPA (anon key nằm trong bundle client, RLS mới là lớp bảo vệ). Nó **trở thành** rò rỉ thật ngay khi có một key không-anon (service_role, PAT, service key…) được đưa vào file này | Vệ sinh cấu hình (không phải leak đang hoạt động) | NGOÀI PHẠM VI cho Plan 2 — chuyển xuống mục "Việc còn lại cho Plan 3" với tư cách **tiền đề bắt buộc trước khi deploy** |
| OAuth web callback | `net::ERR_CONNECTION_REFUSED` | `SITE_URL` của Supabase trỏ cổng 3000; audit serve 8080. Không thuộc seam nào trong 6 seam | Chặn luồng | NGOÀI PHẠM VI — cấu hình, không phải code |

## Lượt 3 (Task 7) — trạng thái từng dòng sau Task 2..6

Đo trên bản **debug** (`flutter build web --debug --output=build/web-debug`, exit 0), phục vụ
`python -m http.server 3000 -b 127.0.0.1`, Chromium của Playwright MCP, semantics bật qua
`flt-semantics-placeholder`. Code được đo = worktree tại `b621e3e` cộng bản sửa
`receipt_notifier_core`/`receipt_notifier_web.dart` chưa commit ở thời điểm đo (xem dòng 14).
Không có lượt nào ở đây cần đăng nhập; vì vậy mọi dòng lệ thuộc dữ liệu ảnh vẫn **chưa đo**.

| # | Dòng trong bảng lỗi | Trạng thái sau Task 2..6 |
|---|---|---|
| 1 | Chọn ảnh từ thư viện, `_Namespace` | **Đã sửa về cấu trúc (Task 2 + Task 3)** — `lib/` không còn `import 'dart:io'` ngoài `*_io.dart` (R1 rỗng), `camera_screen` đi qua `PhotoCapture`, ảnh về dạng bytes. **Chưa đo lại trong browser** vì màn camera nằm sau đăng nhập |
| 2 | "Chụp khoản chi", `_Namespace` | **Đã sửa về cấu trúc (Task 2 + Task 3)** — `takePicture` nằm sau seam, `squareBytes` bản web dùng canvas. `takePicture()` trên web **vẫn chưa từng đo** (Lượt 1 đã ghi như vậy) |
| 3 | "Tiếp tục với Google", `ERR_CONNECTION_REFUSED` | **Còn (Plan 3, cấu hình)** — lượt này serve đúng cổng 3000 nên callback sẽ về được app, nhưng không bấm OAuth: máy audit không có phiên Google nào để chọn, và hoàn tất đăng nhập là việc của chủ dự án |
| 4 | Feed hiện ảnh signed URL | **Đã sửa về cấu trúc (Task 5)** — `CachedNetworkImage` chỉ còn trong `receipt_cache_image_io.dart`, web dùng `Image.network`. **Chưa đo**: cần ảnh thật. Nghiệm thu dòng này bắt buộc bằng hành vi render, không bằng console (hệ quả số 3) |
| 5 | Feed, khoản chi chỉ còn ảnh local | **Đã sửa về cấu trúc (Task 5)** — `Image.file` sau `_io.dart`; web đọc `LocalDraftStore` qua `FutureBuilder`. Chưa đo trong browser |
| 6 | Lưu khoản chi mới kèm ảnh | **Đã sửa về cấu trúc (Task 2)** — `File(value).exists()` → `localDraftStore`, upload nhận bytes. Chưa đo |
| 7 | Sửa khoản chi có ảnh | **Đã sửa về cấu trúc (Task 2)** — cùng đường ghi ảnh với dòng 6. Chưa đo |
| 8 | Xóa mềm rồi vĩnh viễn xóa | **Đã sửa về cấu trúc (Task 5 + Task 2)** — `:187` → `evictReceiptImage`, nhánh local → `localDraftStore.delete`. Chưa đo |
| 9 | Nút tải ảnh về máy | **Đã sửa về cấu trúc (Task 4)** — `Gal` sau `gallery_saver_io.dart`, web dùng blob + `<a download>`, lỗi không còn bị nuốt. **Điều kiện review Task 4 vòng 1 vẫn mở**: phải đo "tệp JPEG có thực sự xuất hiện trong mục Tải xuống" — không làm được vì nút nằm ở feed, cần đăng nhập → chuyển thẳng sang Plan 3 |
| 10 | Dọn ảnh draft sau lưu/hủy form | **Đã sửa về cấu trúc (Task 2)** — `File(...)`/`existsSync()` → `localDraftStore.delete`. Chưa đo |
| 11 | Mở form chọn "mức độ" | **Hệ quả của dòng 6/7** — hết chặn ở tầng code, nhưng vẫn chưa đo vì cần phiên + ảnh |
| 12 | Cảnh báo ngân sách 80/90/100% | **Đã thêm đường web (Task 6)** — `Notification` qua `package:web`, chỉ gửi khi `permission == 'granted'`. **Chưa đo được cảnh báo thật**: cần dữ liệu vượt ngưỡng. Đo được một nửa: `Notification.permission` trên Chromium automation vẫn là `default` sau khi app bắn lời hỏi (xem dòng 14) |
| 13 | Đăng xuất → dọn cache ảnh | **Đã sửa một nửa (Task 5)** — `clearReceiptCache()` bản web chỉ đụng `imageCache`; tầng HTTP cache của browser nằm ngoài tầm với của trang, phải có service worker → **Còn (Plan 3)**. Hành vi "ảnh còn hiện sau logout + login lại" chưa đo |
| 14 | Onboarding: bấm `BẮT ĐẦU` | **CÓ LỖI MỚI, ĐÃ ĐO VÀ ĐÃ SỬA** — xem mục dưới |

### Dòng 14 chi tiết: `BẮT ĐẦU` treo trên web, và bằng chứng trước/sau

**Trước khi sửa** (bản debug commit `a624d0e`, `WebReceiptNotifier.requestPermission()` dùng
`await web.Notification.requestPermission().toDart`):

- Bấm `BẮT ĐẦU` trên trang 3 → 0 console error, **không ném gì**, nhưng
  `localStorage` vẫn `[]` (tức `completeOnboarding()` không bao giờ chạy) và semantics vẫn là
  trang onboarding cũ. `Notification.permission` == `default`.
- Nguyên nhân: lời hứa permission của browser **chỉ hoàn thành khi người dùng bấm vào chip**;
  chip không tự được trả lời trong automation, nên `await` treo vĩnh viễn và chuỗi
  `_finish()` dừng ngay trước `completeOnboarding()`. Người dùng thật cũng treo y hệt nếu họ
  lờ chip đi — đây là màn hình chặn toàn bộ app.

**Sau khi sửa** (`requestPermission()` bắn lời hỏi rồi `ignore()`, không chờ):

- Cùng một lượt bấm: `clicked:TIẾP TỤC`, `clicked:TIẾP TỤC`, `clicked:BẮT ĐẦU` →
  `localStorage` có `flutter.onboarding_complete="true"`, semantics chuyển sang màn đăng nhập
  (`Đăng nhập để đồng bộ chi tiêu của bạn trên Cloud`, `Email`, `Mật khẩu`, `ĐĂNG NHẬP`,
  `Tiếp tục với Google`), `Notification.permission` vẫn `default`, **0 console error / 0 warning**.
- Nghĩa là: lời hỏi quyền vẫn được gửi (browser hiển thị chip), nhưng onboarding không còn bị
  giữ làm con tin. `showBudgetAlert` vẫn đòi `granted`, nên người dùng phải bấm cho phép thì
  mới nhận cảnh báo — đúng ý nghĩa của quyền này.

### Đo được trong lượt 3 (không cần đăng nhập)

| Hạng mục | Bằng chứng |
|---|---|
| Boot bản debug ở cổng 3000 | `Total messages: 3 (Errors: 0, Warnings: 0)` — không có `Unsupported operation: _Namespace` nào, kể cả sau khi đi hết onboarding |
| Onboarding 3 trang | Semantics đọc được `Chào mừng đến với Pixket` → `Đồng bộ an toàn trên Cloud` → `Không vượt quá ngân sách ... mốc 80%, 90% và 100%` |
| `BẮT ĐẦU` → login | `flutter.onboarding_complete="true"` + semantics màn đăng nhập (xem mục trên) |
| `Notification` có thật trên browser | `Notification.permission == "default"` (đọc được property → `_isSupported` true; không phải đường `catch (_)`) |
| `shared_preferences` web | `localStorage` ghi `flutter.onboarding_complete` dưới dạng chuỗi có dấu nháy (`"true"`), khớp hành vi Lượt 1 |
| `.env` vẫn bị đóng gói | `GET http://127.0.0.1:3000/assets/.env` → `env_status=200`, tệp 382 byte — **không đổi sau Plan 2** (đúng Ruling F: vệ sinh cấu hình, tiền đề deploy của Plan 3). Không đọc nội dung |

## Việc còn lại cho Plan 3


Task 7 sẽ đối chiếu lại bảng này và mở rộng mục này; danh sách hiện tại:

1. **Tiền đề deploy (bắt buộc trước khi đưa bản web lên hosting thật):** `.env`
   không được nằm trong asset bundle web. Hiện `pubspec.yaml:39` khai báo nó là
   asset nên `flutter build web` đóng gói thành `build/web/assets/.env` và mọi
   `http.server` phục vụ công khai. Nội dung chỉ có `SUPABASE_URL` +
   `SUPABASE_ANON_KEY` (tên biến — giá trị không đọc), nên đây là việc **vệ sinh**,
   chưa phải leak đang hoạt động; nhưng bước kiểm tra "bản build web không phục vụ
   `/assets/.env"` phải là gate trước khi deploy, và nếu một key không-anon nào đó
   lọt vào file thì việc này đổi cấp độ thành khẩn cấp.
2. **Cấu hình OAuth:** `SITE_URL` trỏ cổng 3000 — hoặc giữ 3000 làm cổng phục vụ
   web vĩnh viễn, hoặc đổi `SITE_URL`; không phải code.
3. **`camera_web`:** chỉ cân nhắc sau khi đo được `takePicture()` trên web (xem hệ
   quả số 2), kèm đường thoát cho trạng thái `Đang mở camera…`.
4. **Lượt có đăng nhập chưa chạy:** 9 dòng Dự đoán vẫn cần tài khoản + dữ liệu ảnh
   thật, serve ở cổng 3000, bằng bản debug. Lượt 3 đã đóng được phần không cần
   đăng nhập (boot, onboarding, `BẮT ĐẦU` → login, `Notification` có thật, `.env`
   vẫn bị đóng gói), nên danh sách này còn đúng một nửa: các dòng ảnh/upload/xóa/cảnh báo.
5. **Điều kiện review Task 4 vòng 1 chưa đóng:** "bấm nút tải ảnh trên browser thật,
   kiểm tệp JPEG xuất hiện trong mục Tải xuống kèm tên và đuôi `.jpg`" — dòng 9 bảng
   trên. Cần tài khoản có ảnh, nên thuộc lượt có đăng nhập.
6. **Cảnh báo ngân sách trên web mới chỉ đo được một nửa:** lời hỏi quyền được bắn đi
   và onboarding không còn treo, nhưng chưa từng có một cảnh báo thật hiện ra (cần dữ
   liệu vượt ngưỡng + người dùng bấm "Cho phép").
7. **Tầng cache HTTP của browser:** `clearReceiptCache()` bản web chỉ xóa `imageCache`
   trong RAM; muốn dọn thật khi đăng xuất thì cần service worker + Cache API, tức là
   việc của shell PWA (Plan 3).

## Hệ quả cho thứ tự Task 2..6

Bằng chứng ủng hộ thứ tự hiện tại, với các điều chỉnh sau:

1. **Task 2 vẫn là nút cổ chai số 1, và nó chặn cả Task 3 lẫn Task 4 đo được.**
   Hai đường vào form khoản chi (chụp, chọn ảnh) chết ngay ở `File(...)`
   (`camera_screen.dart:159`, `:180`), nên không bao giờ tới được form, upload,
   hay nút tải ảnh. `Unsupported operation: _Namespace` là chữ ký của `dart:io`
   trên web — đúng những gì Task 2 (`squareBytes` + `LocalDraftStore`) bọc lại.
2. **Đã bác được một giả định của spec; phần còn lại chỉ là MỘT PHƯƠNG ÁN, chưa
   phải quyết định giảm phạm vi Task 3.** Phần đã đo: `camera_web` có đăng ký
   plugin và ống ngắm render thật trên web (một `<video>` với `srcObject` là
   `MediaStream`, 1280×720, `readyState=4`) — đúng là falsify "camera không có
   implementation web". Phần **chưa** đo: `takePicture()` chưa chạy lần nào, và
   chính Lượt 1 ghi được một dấu hiệu ngược — khi quyền camera của browser còn ở
   `prompt`, màn hình **treo vĩnh viễn ở `Đang mở camera…`**. Chuỗi đó hiện ra ở
   `camera_screen.dart:564`, tức là `PixelLoading` indicator; `camera_screen.dart`
   **không tự xin quyền** (file này không import `permission_handler`), nên một
   `getUserMedia` bị từ chối không bao giờ đưa app ra khỏi trạng thái khởi tạo.
   Vì vậy không được đọc bằng chứng này thành "Task 3 nhẹ hơn, bỏ được seam":
   Task 3 vẫn phải giữ `image_picker` làm đường an toàn và phải có đường thoát
   khỏi `Đang mở camera…`; `camera_web` chỉ đáng cân nhắc ở Plan 3, sau khi đo
   được `takePicture()`.
3. **Task 5 cần đo lại có chủ đích.** Ảnh render qua `CachedNetworkImage`
   (`pixel_receipt_image.dart:160`) **không** lộ ra console, vì `errorWidget`
   ở `:176` nuốt lỗi và biến nó thành placeholder. Nghĩa là sau Task 5, audit lại
   không thể chỉ nhìn console để xác nhận "hết lỗi" — phải nhìn ảnh hiện lên.
   Tương tự `app.dart:98` fire-and-forget `_clearUserCaches()`.
4. **Task 6 vẫn đúng như spec mô tả**: trên web, cảnh báo ngân sách im lặng chứ
   không crash (`initialize()` không ném, chỉ `show()` là vô nghĩa).
5. **Điểm mới, chưa có trong plan**: bản release web tắt `debugPrint`
   (`main.dart:15-17`), nên mọi `catch` có `debugPrint` (`camera_screen.dart:164`,
   `:184`) trở thành nuốt lỗi hoàn toàn với người dùng web. Task 4 ("bỏ lỗi bị
   nuốt") nên cân nhắc mở rộng cho hai chỗ đó, không chỉ `save_to_gallery.dart`.

---

## Footer

- **Phiên bản Flutter:** Flutter 3.47.6 • channel stable • Framework revision
  `5fc346839b` (2026-09-30) • Engine hash `b8c8d3d8d5d0095127057f8a29ca8cc53da2167c`
  (revision `692136cb65`) • Dart 3.13.5 • DevTools 2.60.0.
- **Commit được audit:** `8868aee` (`8868aeee0054f5e98fd05358cc271d4856fd453f`),
  branch `web-boundary`, worktree `.worktrees/web-boundary`. (Bản báo cáo này được
  commit lần đầu ở `817ae66`, rồi sửa theo vòng review 1 — vẫn trên cùng commit
  `8868aee` của code được audit; không có code nào thay đổi nên không cần đo lại.)
- **Build đã audit:** `flutter build web --debug --output=build/web-debug` (nguồn
  duy nhất của các chuỗi nguyên nhân lỗi) và `flutter build web` (release, exit 0 →
  `√ Built build\web`) cho chuỗi user-visible. Lượt lại **bắt buộc** dùng bản debug
  + cổng 3000 (xem callout đầu file).
- **Màn đã đi qua (đo thật):** onboarding 3 trang; `BỎ QUA` và `BẮT ĐẦU` (đường
  `_finish` → `onboarding_screen.dart:52-53`, không lỗi); màn đăng nhập; đăng nhập với
  email sai; màn đăng ký (`Tạo tài khoản mới`) mở từ login; bấm "Tiếp tục với
  Google" (chuỗi redirect tới trang lỗi); boot với
  phiên giả trong `localStorage` → MainScreen/tab camera; ống ngắm (2 trạng thái:
  live và `cameraNotReadable`, cộng trạng thái treo `Đang mở camera…` khi quyền =
  `prompt`); "Chụp khoản chi"; "Chọn ảnh từ thư viện" kèm chọn
  tệp thật; drawer → Tổng quan, Thống kê, Ngân sách, Quản lý danh mục, Thùng rác,
  Cài đặt; toggle dark/light; dialog đăng xuất và đăng xuất thật.
- **Màn chưa đi qua + lý do:** feed có ảnh, form khoản chi, lưu, sửa, xóa, vĩnh
  viễn xóa, danh mục mức độ ("mức độ"), thống kê có dữ liệu, nút tải ảnh, cảnh báo
  ngân sách — tất cả cần tài khoản và dữ liệu thật (Lượt 2, brief giao cho chủ dự
  án); riêng OAuth còn bị chặn thêm bởi cổng callback 3000 ≠ cổng audit 8080.
- **Trạng thái worktree lúc sửa vòng 1:** `git status --porcelain` **sạch về
  `windows/flutter/`** — 3 file `generated_plugin_registrant.cc/.h` +
  `generated_plugins.cmake` không còn dirty, không cần `git checkout --` nào.
- **Không sửa code nào.** File duy nhất bị sửa là báo cáo này; không đụng spec,
  plan hay `lib/`. *(Ngoại lệ duy nhất, ở Lượt 3: lỗi treo `BẮT ĐẦU` đo được trong lượt
  này đã sửa ngay trong `lib/core/platform/receipt_notifier_web.dart` (kèm comment ở
  `lib/screens/onboarding/onboarding_screen.dart`), vì không có cách nào đi tiếp mà không sửa — xem dòng 14.)*
