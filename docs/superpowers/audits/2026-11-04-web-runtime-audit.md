# Audit runtime bản web — Task 0, Plan 2 (ranh giới nền tảng)

Bằng chứng thu được bằng **chạy thật** trong trình duyệt, không phải bằng
`flutter build web` exit 0. dart2js im lặng: `dart:io` và MethodChannel compile
fine rồi mới ném lúc chạy, nên bảng dưới đây là thứ duy nhất nói cho Task 2..6
biết chỗ nào gãy thật.

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

| Màn / hành động | Chuỗi lỗi nguyên văn | Nguyên nhân dự đoán | Mức | Plan |
|---|---|---|---|---|
| Chọn ảnh từ thư viện (màn camera), sau khi chọn tệp ảnh | `Error picking image: Unsupported operation: _Namespace` (bản debug) → user thấy `Không thể mở thư viện ảnh.` (bản release) | `camera_screen.dart:180` gọi `File(image.path)`; `dart:io` trên web ném `UnsupportedError` ở `_Namespace`. `image_picker` **không** hỏng — file chooser mở được và trả về tệp | Chặn luồng | Task 2 (`writeSquareCopy`) + Task 3 (`PhotoCapture`) |
| Bấm "Chụp khoản chi" khi ống ngắm đã sẵn sàng | `Không thể chụp ảnh. Vui lòng thử lại.` (không kèm nguyên nhân trong bản release — `debugPrint` bị tắt) | `camera_screen.dart:159` `writeSquareCopy(File(picture.path))`; cùng kiểu `Unsupported operation: _Namespace` như dòng trên. Chưa xác nhận được `takePicture()` có trả về trước đó hay không | Chặn luồng | Task 2 + Task 3 |
| Bấm "Tiếp tục với Google" | `net::ERR_CONNECTION_REFUSED`; trang lỗi trình duyệt ghi `This site can't be reached` / `localhost refused to connect.` | Không phải seam nền tảng. Chuỗi redirect: app → `/auth/v1/authorize?provider=google&flow_type=pkce` → Google → `/auth/v1/callback` → **`http://localhost:3000/?code=<đã che>`** (mã OAuth đã bị che). Supabase trả về `SITE_URL` = cổng 3000, trong khi bản audit serve ở cổng 8080, nên phiên không bao giờ quay về app | Chặn luồng | NGOÀI PHẠM VI — cấu hình `SITE_URL` phía Supabase; audit/lượt 2 phải serve đúng cổng 3000 |
| Feed, ảnh đã upload (chưa đo được) | `chưa đo (cần đăng nhập)` | `pixel_receipt_image.dart:160` `CachedNetworkImage` → `flutter_cache_manager` → `dart:io`. `errorWidget` (`:176`) nuốt lỗi nên khả năng cao chỉ hiện placeholder, không ném ra console | Chặn luồng | Task 5 |
| Feed, khoản chi chỉ còn ảnh local (chưa đo được) | `chưa đo (cần đăng nhập)` | `pixel_receipt_image.dart:179-180` `Image.file(File(localPath!))` → `Unsupported operation: _Namespace` | Sẹt góc | Task 5 (`ReceiptLocalImage`) |
| Lưu khoản chi mới (form khoản chi) (chưa đo được) | `chưa đo (cần đăng nhập)` | `expense_repository.dart:61` `await File(value).exists()` ném trước khi tới `StateError('Không tìm thấy ảnh để tải lên Cloud.')` ở `:71`; kể cả qua được thì `:64` `writeSquareCopy` (`square_image.dart:59,62`) và `supabase_storage_service.dart:27` `File(localFilePath)` đều ném | Chặn luồng | Task 2 |
| Sửa khoản chi có ảnh (chưa đo được) | `chưa đo (cần đăng nhập)` | Cùng đường ghi ảnh: `expense_repository.dart:61,64` | Chặn luồng | Task 2 |
| Xóa mềm rồi vĩnh viễn xóa khoản chi (chưa đo được) | `chưa đo (cần đăng nhập)` | `expense_provider.dart:187` `CachedNetworkImage.evictFromCache(...)` và nhánh local `:192-193` `File(local)`/`file.exists()` | Sẹt góc | Task 5 (`receipt_cache.dart`) |
| Nút tải ảnh về máy (chưa đo được) | `chưa đo (cần đăng nhập)` | `save_to_gallery.dart:53` `File(path)` khi không có signed URL; `:26` `Gal.putImageBytes` — `gal` không có implementation web. `catch (_)` ở `:32-34` nuốt hết, user chỉ thấy `Không lưu được ảnh về máy.` | Sẹt góc | Task 4 |
| Dọn ảnh draft sau khi lưu / khi hủy form (chưa đo được) | `chưa đo (cần đăng nhập)` | `expense_form_sheet.dart:130-133` `File(sourceImagePath)`+`exists()`+`delete()`; `:175-176` `File(draftPath)`+`existsSync()`+`delete()` | Sẹt góc | Task 2 (`LocalDraftStore`) |
| Mở form khoản chi để chọn "mức độ" (chưa đo được) | `chưa đo (cần đăng nhập)` | Không vào được form: hai đường mở form (chụp / chọn ảnh) đều chết ở `dart:io` như 2 dòng đầu bảng. Bản thân danh sách mức độ đọc từ Supabase, không có seam riêng | Chặn luồng | (hệ quả của Task 2/3, không phải lỗi của Task 6) |
| Cảnh báo ngân sách 80/90/100% (chưa đo được) | `chưa đo (cần đăng nhập)` | `notification_service.dart:48` `_plugin.show(...)` — `flutter_local_notifications` không có implementation web. Trên web người dùng **im lặng không nhận được gì**, không có lỗi hiện ra | Sẹt góc | Task 6 |
| Đăng xuất → dọn cache ảnh (đã bấm, chưa kết luận được) | (không có lỗi trong console sau khi đăng xuất) | `app.dart:98` gọi `unawaited(_clearUserCaches())`; `app.dart:70` `DefaultCacheManager().emptyCache()`. Không thấy lỗi, nhưng cũng **không** thấy IndexedDB/Cache Storage nào được tạo (`indexedDB.databases()` = `[]`, `caches.keys()` = `[]`), và lời gọi bị fire-and-forget nên không phân biệt được "chạy im lặng thành công" với "hỏng bị nuốt" | Sẹt góc | Task 5 |

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
| `camera` (ống ngắm) | `camera_web` **có** đăng ký cho web. Khi quyền camera = `granted` và thiết bị rảnh: có 1 phần tử `<video>` với `srcObject` là `MediaStream` thật, `videoWidth=1280`, `videoHeight=720`, `readyState=4` — ống ngắm chạy được. Khi thiết bị bận: `Error listing cameras: CameraException(cameraNotReadable, The camera is not readable due to a hardware error that prevented access to the device.)` và app hiện trạng thái `CAMERA CHƯA SẴN SÀNG / Không tìm thấy máy ảnh trên thiết bị.` (xử lý graceful, không crash) |
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
| Serve bản web ra ngoài | (không có lỗi — đây là phát hiện, không phải crash) | `.env` được khai báo là asset trong `pubspec.yaml:39`, nên `flutter build web` **đóng gói luôn** thành `build/web/assets/.env` (382 byte) và `python -m http.server` phục vụ nó công khai: `GET http://localhost:8080/assets/.env => [200] OK`. Tôi không đọc và không dán nội dung file. Mọi giá trị trong `.env` — kể cả key chỉ-dùng-cho-frontend — đều thành đối tượng tải được bởi khách lạ; nếu có key nào khác lọt vào `.env` thì đó là rò rỉ thật | Chặn luồng (bảo mật) | NGOÀI PHẠM VI — cần chủ dự án quyết: tách secret khỏi asset bundle web / không phục vụ `.env` trong bản build web |
| OAuth web callback | `net::ERR_CONNECTION_REFUSED` | `SITE_URL` của Supabase trỏ cổng 3000; audit serve 8080. Không thuộc seam nào trong 6 seam | Chặn luồng | NGOÀI PHẠM VI — cấu hình, không phải code |

## Hệ quả cho thứ tự Task 2..6

Bằng chứng ủng hộ thứ tự hiện tại, với hai điều chỉnh:

1. **Task 2 vẫn là nút cổ chai số 1, và nó chặn cả Task 3 lẫn Task 4 đo được.**
   Hai đường vào form khoản chi (chụp, chọn ảnh) chết ngay ở `File(...)`
   (`camera_screen.dart:159`, `:180`), nên không bao giờ tới được form, upload,
   hay nút tải ảnh. `Unsupported operation: _Namespace` là chữ ký của `dart:io`
   trên web — đúng những gì Task 2 (`squareBytes` + `LocalDraftStore`) bọc lại.
2. **Task 3 nhẹ hơn dự kiến.** `camera_web` đã render ống ngắm thật trên web
   (MediaStream 1280x720 đo được) và `image_picker` đã mở file chooser. Phần
   seam còn lại chủ yếu là `takePicture()` → bytes và quyền camera, không phải
   "ống ngắm không tồn tại trên web".
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
  branch `web-boundary`, worktree `.worktrees/web-boundary`.
- **Build đã audit:** `flutter build web` (release) exit 0 → `√ Built build\web`;
  và `flutter build web --debug --output=build/web-debug` (chỉ để đọc nguyên nhân lỗi).
- **Màn đã đi qua (đo thật):** onboarding 3 trang; màn đăng nhập; đăng nhập với
  email sai; màn đăng ký (`Tạo tài khoản mới`) mở từ login; bấm "Tiếp tục với
  Google" (chuỗi redirect tới trang lỗi); boot với
  phiên giả trong `localStorage` → MainScreen/tab camera; ống ngắm (2 trạng thái:
  live và `cameraNotReadable`); "Chụp khoản chi"; "Chọn ảnh từ thư viện" kèm chọn
  tệp thật; drawer → Tổng quan, Thống kê, Ngân sách, Quản lý danh mục, Thùng rác,
  Cài đặt; toggle dark/light; dialog đăng xuất và đăng xuất thật.
- **Màn chưa đi qua + lý do:** feed có ảnh, form khoản chi, lưu, sửa, xóa, vĩnh
  viễn xóa, danh mục mức độ ("mức độ"), thống kê có dữ liệu, nút tải ảnh, cảnh báo
  ngân sách — tất cả cần tài khoản và dữ liệu thật (Lượt 2, brief giao cho chủ dự
  án); riêng OAuth còn bị chặn thêm bởi cổng callback 3000 ≠ cổng audit 8080.
- **Không sửa code nào.** File duy nhất tạo ra là báo cáo này.
