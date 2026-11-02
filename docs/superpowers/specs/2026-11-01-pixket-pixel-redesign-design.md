# Thiết kế Chi Tiêu phiên bản Pixel (A) — Spec

- **Ngày:** 2026-11-01
- **Trạng thái:** Chờ duyệt
- **Phạm vi:** Giao diện Pixel toàn app + các tính năng đã chốt + gia cố Supabase
- **Tài liệu tham chiếu:** `docs/requirements.md` v2.2, mockup `pixel-vs-handdrawn.html` (phương án A)

## 1. Bối cảnh

Chi Tiêu hiện là app Flutter ghi chi tiêu bằng ảnh kiểu Locket, dữ liệu cloud-first trên
Supabase. Giao diện đang dùng Material + `google_fonts` tải font lúc chạy, icon Material
có sẵn nên bị "máy móc", thiếu bản sắc. Người dùng đã chọn hướng **Pixel** sau khi so
sánh trực quan với hướng Vẽ tay.

Spec này chốt toàn bộ ngôn ngữ thiết kế Pixel, các thay đổi kiến trúc đi kèm, và các
tính năng còn thiếu đã thống nhất: quên mật khẩu, chỉnh ngày giờ, định dạng tiền có dấu
chấm, xuất CSV, private bucket + signed URL, keep-alive Supabase.

## 2. Mục tiêu

1. Toàn bộ giao diện mang phong cách pixel đồng nhất, thân thiện, không dùng icon
   Material hay ảnh stock.
2. Theme sáng/tối hoàn chỉnh, không còn màu hardcode chỉ dùng cho light mode.
3. Giữ nguyên toàn bộ nghiệp vụ hiện có; chỉ thay lớp trình bày và các điểm dữ liệu
   cần thiết.
4. Vá các lỗ hổng: bucket ảnh public, SQL không idempotent, upload thiếu rollback.
5. Thêm 4 tính năng đã chốt + keep-alive chống Supabase pause.

### Trong phạm vi

- Bộ design token & theme Pixel, font bundle, ~59 icon pixel tự vẽ.
- Redesign: onboarding, login, register, feed/camera, form khoản chi, xem ảnh,
  lưới ảnh, tổng quan, thống kê, ngân sách, danh mục, thùng rác, cài đặt, drawer,
  dialog, bottom sheet, snackbar, empty/error/loading.
- Quên mật khẩu + deep link đặt lại mật khẩu.
- Chọn ngày giờ khoản chi (không cho tương lai).
- Input tiền tự chấm hàng nghìn trong mọi ô nhập tiền.
- Xuất CSV và chia sẻ.
- Private bucket, signed URL, batch signing, rollback upload/insert.
- SQL idempotent + bảo mật + ràng buộc dữ liệu.
- GitHub Actions keep-alive + tài liệu cron-job.org.

### Ngoài phạm vi

- OCR hóa đơn, thay ảnh khoản chi đã lưu.
- Đa tiền tệ, Apple/Facebook login.
- Đồng bộ xung đột nâng cao, realtime đa thiết bị.
- Web/desktop layout; app vẫn ưu tiên mobile dọc.
- Pixel hóa ảnh người dùng (ảnh hóa đơn luôn giữ nguyên chất lượng).
- Đổi schema cột lưu ảnh hoặc mã icon danh mục.

## 3. Ngôn ngữ thiết kế Pixel

### 3.1 Nguyên tắc

- **Khung cứng, nội dung mềm:** viền 2–3 px màu mực, bóng cứng lệch 3–4 px, bo góc
  2–4 px; bên trong vẫn thoáng và dễ đọc.
- **Màu kem làm nền, mint làm điểm nhấn, mực làm cấu trúc.** Năm màu accent
  (mint, butter, peach, sky, rose) dùng cho badge danh mục/mức độ, không dùng tùy tiện.
- **Pixel ở chrome, không ở nội dung:** số liệu, tiêu đề, nhãn, icon là pixel; đoạn văn
  dài, ghi chú, thông báo lỗi dùng font thường để đọc tốt.
- **Một điểm nhấn mỗi màn hình:** hero total, ảnh feed, hoặc empty state; tránh nhiều
  khối tranh nhau nổi bật.
- **Trạng thái rõ ràng:** mọi tiến trình/trạng thái có cả màu và chữ; không dựa vào màu.

### 3.2 Design tokens

ThemeExtension `AppPalette`. Light là mặc định; dark đảo nền mực, giữ nguyên accent.

| Token | Light | Dark | Dùng cho |
| --- | --- | --- | --- |
| `canvas` | `#FFF6E3` | `#1A130D` | nền toàn app |
| `surface` | `#FFFDF6` | `#241A12` | panel, card, sheet |
| `surfaceAlt` | `#FFF1D6` | `#302318` | hàng list, segmented track |
| `ink` | `#2B2118` | `#FFF6E3` | chữ chính, icon chính |
| `inkMuted` | `#7A6A58` | `#C9B79E` | chữ phụ (≥4.5:1 trên canvas) |
| `line` | `#1B140E` | `#6B553F` | viền 1–2 px |
| `lineStrong` | `#1B140E` | `#FFF6E3` | viền panel chính 2–3 px |
| `shadow` | `#1B140E` | `#000000` | bóng cứng |
| `mint` | `#7BD8A8` | `#7BD8A8` | tiến trình, badge, CTA |
| `mintStrong` | `#2F9E6E` | `#3FBF86` | viền/nền nhấn đậm |
| `mintInk` | `#1F7A52` | `#9BE9C2` | chữ trên nền sáng/tối |
| `butter` | `#FFD86B` | `#FFD86B` | cảnh báo mềm, highlight |
| `peach` | `#FFB38A` | `#FFB38A` | accent danh mục |
| `sky` | `#8ECAE6` | `#8ECAE6` | accent danh mục |
| `rose` | `#F28C9A` | `#F28C9A` | vượt ngân sách, nguy hiểm |
| `onAccent` | `#1B140E` | `#1B140E` | chữ/icon trên accent |
| `danger` | `#C0392B` | `#FF8A7A` | lỗi, xóa |
| `feedBg` | `#14100B` | `#0D0A07` | nền feed/camera |
| `feedPanel` | `#1E1710` | `#17110B` | caption panel |
| `feedInk` | `#FFF6E3` | `#FFF6E3` | chữ trên feed |
| `feedMuted` | `#C9B79E` | `#C9B79E` | chữ phụ trên feed |

Quy ước:

- Mọi cặp chữ/nền phải ≥ 4.5:1; chữ lớn (≥ 24 px đậm hoặc ≥ 32 px) ≥ 3:1.
- Accent chỉ dùng làm **nền** kèm `onAccent`, hoặc làm **viền/khối trang trí**; chữ
  accent trên nền sáng dùng biến thể `*Ink` đủ tương phản (ví dụ `mintInk`).
- Màu danh mục suy ra ổn định từ `id` (hoặc `name` nếu chưa có id) qua 5 accent, không
  lưu DB, không đổi schema.
- Mức độ cần thiết: 0 Thiết yếu → mint, 1 Rất cần → sky, 2 Cần vừa → butter,
  3 Chưa cần → rose.
- Không còn dùng `Colors.*` trực tiếp trong UI, trừ trắng/đen cho ảnh và overlay.

### 3.3 Typography

**Quyết định: font hybrid, bundle tĩnh, bỏ `google_fonts`.**

| Vai trò | Font | Size / weight | Ghi chú |
| --- | --- | --- | --- |
| Display số tiền, tổng | VT323 Regular | 32–48 px | dùng `FittedBox` khi text scale lớn |
| Tiêu đề màn hình | VT323 Regular | 26–30 px, uppercase | letterSpacing 0.5 |
| Nhãn nhỏ (label/HUD) | VT323 Regular | 16–18 px, uppercase | letterSpacing 0.8 |
| Số liệu phụ, chip số | VT323 Regular | 20–24 px | |
| Body, ghi chú, lỗi | Be Vietnam Pro | 14–16 px, w400/w500 | line-height 1.5 |
| Nút, field label | Be Vietnam Pro | 15–16 px, w600 | |
| Caption | Be Vietnam Pro | 12–13 px, w500 | không dưới 12 px |

Lý do: VT323 là một trong hai font pixel trên Google Fonts có bộ ký tự tiếng Việt đầy
đủ (cùng Handjet); VT323 dễ đọc hơn Handjet ở cỡ lớn nhưng không phù hợp cho đoạn văn
dài. Body dùng Be Vietnam Pro để giữ khả năng đọc và tương thích tiếng Việt.

Triển khai:

- Tải `VT323-Regular.ttf` + Be Vietnam Pro (Regular, Medium, SemiBold, Bold) vào
  `assets/fonts/`, khai báo `family: VT323`, `family: BeVietnamPro` trong `pubspec.yaml`.
- Kèm file license OFL trong `assets/fonts/OFL.txt` (gộp giấy phép của hai font).
- Xóa dependency `google_fonts` sau khi không còn tham chiếu.
- Không tải font từ mạng lúc chạy; app hoạt động đầy đủ khi offline (trừ dữ liệu cloud).
- Không viết hoa toàn bộ tiếng Việt ở body; chỉ viết hoa nhãn ngắn (dấu tiếng Việt
  hiển thị đúng ở VT323).

### 3.4 Hệ icon pixel tự vẽ

**Quyết định: glyph pixel dạng lưới ký tự, paint bằng `CustomPainter` — không dùng
Material Icons, không dùng emoji, không thêm `flutter_svg`.**

- `lib/core/icons/pixel_glyphs.dart`: `Map<String, List<String>>` với **16 hàng × 16 cột**.
  Ký tự: `.` trong suốt, `#` màu chính, `+` màu phụ (mặc định 55% alpha của màu chính).
- `PixelGlyph` widget: `CustomPaint` vẽ từng ô thành hình chữ nhật, `isAntiAlias = false`,
  kích thước ưu tiên bội số của 16 (16/32/48) để pixel sắc nét; màu lấy từ theme.
- `AppIcon` (`lib/widgets/pixel/app_icon.dart`): bọc `PixelGlyph` + `Semantics(label:)`,
  size mặc định 32; có `PixelIconButton` đảm bảo vùng chạm ≥ 48×48.
- `IconHelper` giữ nguyên API và 19 khóa danh mục (`forkKnife`, `coffee`, …,
  `dotsThreeOutline`), chỉ đổi phần render sang `AppIcon`, giữ map emoji cũ để dữ liệu
  cũ vẫn hiển thị. Không migration DB.
- Khóa lạ → glyph `label` (khung nhãn) thay vì icon Material.
- Bộ glyph dự kiến (~59):
  - **Danh mục (19):** forkKnife, coffee, car, shoppingBag, receipt, gameController,
    heartbeat, graduationCap, house, airplane, gift, pawPrint, barbell, filmStrip,
    tShirt, deviceMobile, bank, wallet, dotsThreeOutline.
  - **Điều hướng/UI (40):** menu, close, back, chevronRight, chevronDown, plus, minus,
    check, edit, trash, search, filter, calendar, clock, image, camera, flipCamera,
    shutter, grid, chart, tag, settings, cloud, cloudOff, share, download, alert, info,
    refresh, undo, eye, eyeOff, mail, lock, logout, user, sun, moon, sparkle, label.
- Test registry: mọi glyph đúng 16×16, chỉ chứa `. # +`, không rỗng; mọi khóa
  `IconHelper` có glyph; không trùng khóa.
- Icon thương hiệu Google: không vẽ logo; dùng ô chữ "G" pixel + nhãn "Google".

### 3.5 Component kit

Thư mục `lib/widgets/pixel/`:

| Thành phần | Mô tả |
| --- | --- |
| `PixelPanel` | Container nền `surface`, viền 2 px `lineStrong`, bóng cứng lệch (3,4), bo 4 px; có `accent` tùy chọn |
| `PixelButton` | Primary (mint, chữ `onAccent`), secondary (surface + viền), ghost; pressed dịch (2,2) và bỏ bóng |
| `PixelIconButton` | Nút icon ≥48 dp, nền tròn vuông 4 px, có `tooltip`/`semanticLabel` |
| `PixelChip` | Nhãn chọn/badge, viền 2 px, trạng thái chọn đảo màu; luôn kèm chữ |
| `PixelProgress` | Thanh tiến trình chia 10 khối, màu theo ngưỡng, có nhãn % |
| `PixelSegmented` | Chọn khoảng thời gian/tab dạng khối liền nhau |
| `PixelTextField` | Input nền `surfaceAlt`, viền 2 px, label luôn hiển thị, lỗi ngay dưới field |
| `PixelDialog` | Dialog vuông vắn, title VT323, nội dung body, hàng nút |
| `PixelSheet` | Bottom sheet bo 0, viền trên 3 px, kéo để đóng |
| `PixelSnackBar` | Nền ink, viền mint/rose, hành động "Hoàn tác" màu butter |
| `PixelBadge` | Badge danh mục/mức độ: ô icon màu + nhãn chữ |
| `PixelEmptyState` | Glyph lớn 64, tiêu đề VT323, mô tả, CTA |
| `PixelLoading` | 3 khối nhấp nháy theo nhịp 4 frame, không shimmer mượt |
| `PixelDivider` | Đường 1 px dashed/đứt khúc bằng nét 2 px |
| `PixelStatTile` | Ô số liệu nhỏ: nhãn + số VT323 + delta |

`ExpenseCard`, `GlassCard`, `CategoryIconBadge`, `ScreenBackground` cũ được thay thế;
xóa component không còn dùng, không giữ shim.

### 3.6 Biểu đồ pixel (bỏ `fl_chart`)

- **Phân bổ danh mục:** danh sách thanh ngang chia khối, mỗi danh mục một hàng:
  badge icon + tên + thanh tỉ lệ + số tiền + %; thay cho donut. Lý do: đọc tốt hơn
  trên màn nhỏ, không phụ thuộc màu, dễ tương phản.
- **Mức độ cần thiết:** 4 khối xếp chồng theo tỉ lệ, kèm legend chữ và số tiền.
- **Theo ngày:** bar chart pixel tự vẽ (`dailyTotals` đã có sẵn), trục ngày thưa,
  chạm cột hiện tooltip dạng panel nhỏ; tháng dài thu gọn nhãn.
- Mọi biểu đồ có bảng/tóm tắt chữ tương đương cho screen reader.
- Xóa `fl_chart` khỏi `pubspec.yaml` sau khi thay xong.

### 3.7 Feed ảnh & camera

- Nền `feedBg`; ảnh full-bleed, **không áp filter/pixelate**.
- HUD trên: nút menu 48 dp, nhãn "NHẬT KÝ" + tháng (VT323 uppercase), đếm số ảnh,
  nút lưới; nền gradient mực nhẹ để chữ đọc được trên ảnh sáng.
- Panel caption dưới: `feedPanel` 92% opacity, viền trên 2 px mint; badge danh mục,
  badge mức độ, số tiền VT323 34 px, ghi chú tối đa 3 dòng, ngày giờ; nút sửa/xóa 48 dp.
- Camera: khung ngắm 4 góc pixel, HUD nhãn "CAMERA", nút chụp vuông 72 dp viền 4 px,
  nút thư viện/lật camera 48 dp. Ẩn HUD khi vuốt feed; chạm để hiện lại.
- Lưới ảnh: 3 cột, gutter 4 px, thumbnail vuông, header mực; chạm ảnh nhảy đúng vị trí
  trong feed.
- Ảnh lỗi/không tải được: khối `surfaceAlt` + glyph `cloudOff` + "Không tải được ảnh".

### 3.8 Chuyển động & phản hồi

- Thời lượng 120–180 ms, `easeOutCubic`; không bounce/elastic.
- Chuyển màn hình: fade + dịch 8 px; tab trong màn: cross-fade 120 ms.
- Nút nhấn: dịch (2,2), bóng xẹp; nhả về 120 ms.
- Loading: khối nhấp nháy 4 frame (bước), không quay tròn mượt.
- Tôn trọng `MediaQuery.disableAnimations` (giảm còn fade 0 ms).
- Haptic nhẹ khi chụp ảnh, lưu thành công, xóa và hoàn tác (nếu thiết bị hỗ trợ).

### 3.9 Accessibility

- Vùng chạm ≥ 48×48 dp, khoảng cách ≥ 8 dp.
- Icon-only luôn có `Semantics`/tooltip tiếng Việt.
- Tương phản: test tự động các cặp token chính ở cả 2 theme (≥ 4.5:1; chữ lớn ≥ 3:1).
- Text scale: kiểm tra 1.3×; số tiền hero dùng `FittedBox`, panel co giãn, không cắt chữ.
- Lỗi form hiển thị ngay dưới field, có `Semantics(liveRegion: true)`; lỗi toàn cục
  dùng snackbar kèm nội dung chữ.
- Trạng thái không chỉ dựa vào màu: ưu tiên/mức độ luôn có nhãn chữ; quá ngân sách có
  nhãn "QUÁ NGÂN SÁCH".
- Thứ tự đọc hợp lý; nút đóng có nhãn "Đóng"; ảnh có `semanticLabel` mô tả khoản chi.

## 4. Kiến trúc kỹ thuật

### 4.1 Theme layer

- `lib/core/theme/app_palette.dart`: `AppPalette extends ThemeExtension<AppPalette>`
  với các token ở §3.2, `lerp`, `copyWith`.
- `lib/core/theme/app_theme.dart`: `AppTheme.light` / `AppTheme.dark` dựng `ThemeData`
  từ palette; `ColorScheme` map đầy đủ; `textTheme` dùng font bundle; style cho
  AppBar, Card, Dialog, BottomSheet, InputDecoration, SnackBar, DatePicker, TimePicker,
  Switch, ProgressIndicator, Divider, Tooltip.
- Helper `context.palette` (extension) để truy cập token.
- `AppColors` cũ được thay bằng palette; không giữ hằng số legacy.
- `themeMode` giữ nguyên qua `appSettingsProvider` (đã có).

### 4.2 Dữ liệu ảnh: private bucket + signed URL

Giữ nguyên schema `expenses.image_url`; đổi **nội dung lưu** từ public URL sang
**storage path** (`<user_id>/<timestamp>_<len>.jpg`).

- `SupabaseStorageService`:
  - `uploadReceiptImage` trả về `path`, không trả URL.
  - `createSignedUrls(List<String> paths, {int expiresIn = 86400})` chia lô 50 path,
    trả `Map<path, signedUrl>`.
  - `signedUrlFor(path)` cho ảnh đơn.
  - `storagePathFromUrl(urlOrPath)` xử lý: path thuần, public URL cũ
    (`/storage/v1/object/public/expense-receipts/...`), signed URL
    (`/storage/v1/object/sign/expense-receipts/...`); trả null nếu lạ.
- `Expense`: thêm field transient `displayImageUrl` (không đưa vào `toMap`, không lưu DB);
  `imagePath` giữ nguyên tên nhưng chứa path hoặc URL legacy. `copyWith` giữ/hỗ trợ
  `displayImageUrl` để chỉnh sửa khoản chi không làm mất URL đang hiển thị.
- `ExpenseRepository`:
  - Khi đọc danh sách: chuẩn hóa path → batch sign → gán `displayImageUrl`.
  - `getExpenses(..., {int? limit, int? offset})` thêm tham số phân trang cho CSV; các
    lời gọi cũ giữ nguyên hành vi (không giới hạn).
  - Khi ghi mới: upload lấy path, lưu path; nếu insert thất bại → xóa file vừa upload
    (best-effort) rồi ném lỗi.
  - Khi xóa vĩnh viễn: lấy path từ `imagePath` (hoặc URL legacy) → xóa storage → xóa DB.
- UI ảnh dùng `displayImageUrl`, `CachedNetworkImage` với `cacheKey: imagePath` để
  signed URL đổi vẫn dùng cache; `errorWidget` pixel.
- Signed URL hết hạn sau 24 h; mỗi lần load lại danh sách/refresh sẽ ký mới. Feed giữ
  cache ảnh; nếu ảnh mới lỗi có nút thử lại.
- Không có fallback public; bucket private là bắt buộc.

### 4.3 SQL hardening (`supabase_setup.sql`)

Viết lại theo hướng **idempotent** (chạy lại nhiều lần không lỗi):

- `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`.
- Policy: `DROP POLICY IF EXISTS` trước `CREATE POLICY` (cho cả bảng và storage).
- Bucket: `ON CONFLICT (id) DO UPDATE SET public = false`; bucket private.
- Storage policies owner-only: select/insert/update/delete đều yêu cầu
  `bucket_id = 'expense-receipts'` **và** `(storage.foldername(name))[1] = auth.uid()::text`.
- Danh mục mặc định: **dọn trùng trước** — chuyển `expenses.category_id` của bản trùng
  sang bản có `id` nhỏ nhất; với `budgets` cũng chuyển `category_id` rồi xóa dòng xung
  đột theo `(user_id, month)` (giữ `id` nhỏ nhất); sau đó xóa danh mục trùng và tạo
  unique index:
  - `UNIQUE (user_id, name) WHERE user_id IS NOT NULL`
  - `UNIQUE (lower(name)) WHERE user_id IS NULL`
  Seed `ON CONFLICT DO NOTHING` dựa trên index để không nhân bản.
- Ràng buộc: `amount > 0`, `priority BETWEEN 0 AND 3`, `length(trim(caption)) > 0`;
  budgets `amount >= 0`, `month ~ '^\d{4}-\d{2}$'`.
- Thêm `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()` bằng
  `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` cho `categories`, `expenses`, `budgets`;
  trigger `set_updated_at()` cập nhật khi UPDATE (profiles đã có sẵn cột).
- Hàm `handle_new_user()` thêm `SET search_path = public` để tránh hijack search_path.
- Policy storage bổ sung quyền `UPDATE` owner-only (dù app chưa dùng, tránh lỗ hổng sau).
- Index: `expenses(user_id, created_at DESC)`, `expenses(user_id, category_id)`,
  `budgets(user_id, month)`, `categories(user_id)`.
- Script kiểm tra sau chạy: `SELECT` đếm policy/bucket public để người dùng xác nhận.
- Không chứa khóa bí mật; chỉ DDL/policy/seed.

### 4.4 Định dạng tiền & ngày giờ

- `ThousandsSeparatorInputFormatter` (`lib/core/utils/`):
  - Nhận mọi ký tự, giữ chữ số, tối đa 12 chữ số; định dạng `1.234.567`.
  - Giữ vị trí con trỏ hợp lý khi gõ/xóa giữa chuỗi.
  - `CurrencyFormatter.parseInput(String)` → `double?` (bỏ dấu chấm, trả null nếu rỗng).
  - `CurrencyFormatter.format` giữ nguyên định dạng VND hiện tại (`đ`).
- Áp dụng cho: số tiền khoản chi, ngân sách tổng, ngân sách danh mục, lọc min/max.
- Ô tiền hiển thị suffix `đ`, `keyboardType: number`, `inputFormatters` tương ứng.
- Chọn ngày giờ trong form khoản chi:
  - Hàng "Ngày" + "Giờ" dạng 2 ô bấm, mở `showDatePicker`/`showTimePicker` đã theme.
  - `firstDate = now - 10 năm`, `lastDate = now`; chặn giờ tương lai (> now + 1 phút)
    bằng validate và thông báo.
  - Nút "Bây giờ" đặt lại `DateTime.now()`.
  - Lưu/sửa dùng `createdAt` (model đã hỗ trợ `copyWith`); danh sách và feed sắp xếp lại.

### 4.5 Quên mật khẩu & đặt lại mật khẩu

- `AuthRepository.resetPassword(email)` gọi
  `resetPasswordForEmail(email, redirectTo: 'io.supabase.pixket://login-callback/')`.
- `AuthNotifier` lắng nghe `onAuthStateChange`; khi `event == AuthChangeEvent.passwordRecovery`
  bật `recoveryMode = true`.
- `app.dart` ưu tiên: nếu `recoveryMode` → `ResetPasswordScreen`, không phụ thuộc
  onboarding/đăng nhập.
- `ResetPasswordScreen`: mật khẩu mới + xác nhận, tối thiểu 8 ký tự, hiện/ẩn, nút lưu;
  gọi `updateUser(password)`, thành công → đăng xuất → về Login với thông báo.
- Link hết hạn/không hợp lệ → màn hình giải thích + nhập email gửi lại.
- Login: liên kết "Quên mật khẩu?" mở sheet nhập email; sau khi gửi luôn hiện thông báo
  trung tính ("Nếu email tồn tại, bạn sẽ nhận được liên kết đặt lại") để tránh dò tài khoản.
- Deep link Android đã có (`io.supabase.pixket://login-callback`), không đổi manifest;
  tài liệu hóa việc thêm URL này vào Supabase Redirect URLs.

### 4.6 Xuất CSV

- `lib/data/services/expense_csv_service.dart`:
  - `String buildCsv(List<Expense> expenses, Map<int, String> categoryNames)` — hàm thuần,
    test được.
  - Cột: `Ngày,Giờ,Số tiền (VND),Danh mục,Mức độ cần thiết,Ghi chú`.
  - Sắp xếp mới nhất trước; mức độ map 0..3 → "Thiết yếu/Rất cần/Cần vừa/Chưa cần".
  - RFC 4180: bọc field chứa `,` `"` `\n`; nhân đôi `"`; luôn escape an toàn.
  - UTF-8 **có BOM** để Excel mở đúng tiếng Việt.
- Tải dữ liệu: phân trang 1000 bản ghi/lần qua repository cho tới hết, chỉ khoản chưa xóa.
- Ghi file tạm bằng `path_provider`, tên `pixket_yyyyMMdd_HHmm.csv`, rồi mở share sheet
  bằng `share_plus`. Xóa file tạm sau khi share (best-effort).
- Entry: Cài đặt → "Xuất CSV"; loading + lỗi snackbar; không có dữ liệu → empty state.
- Dependencies thêm: `share_plus`, `path_provider`. Không thêm package CSV.

### 4.7 Keep-alive Supabase

- `.github/workflows/supabase-keepalive.yml`:
  - `schedule: cron '0 3 */2 * *'` (mỗi 2 ngày) + `workflow_dispatch`.
  - Bước gọi `GET ${SUPABASE_URL}/rest/v1/categories?select=id&limit=1` với headers
    `apikey` và `Authorization: Bearer <anon>` từ **GitHub Secrets**.
  - Fail nếu HTTP ≥ 400; log chỉ status code, không log key.
- Secrets cần tạo: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (người dùng tự thêm).
- Tài liệu `docs/supabase-keepalive.md`:
  - Cách thêm secrets, chạy tay workflow, kiểm tra log.
  - Phương án dự phòng cron-job.org (URL + headers), vì GitHub tắt schedule sau 60 ngày
    repo không hoạt động.
  - Lưu ý không dán service_role key vào bất kỳ đâu.

### 4.8 Phiên bản & tài liệu

- `lib/core/constants/app_info.dart`: tên app, `version = '2.2.0'`, `build = 3`,
  `tagline = 'PIXEL JOURNAL'`.
- `pubspec.yaml` version `2.2.0+3`.
- Settings/drawer đọc từ `AppInfo`, không hardcode.
- Cập nhật README (tính năng mới, số test thực tế, hướng dẫn SQL/private bucket/CSV/
  keep-alive), `docs/requirements.md` (FR mới + trạng thái), `docs/project-structure.md`
  (thư mục pixel, services).
- Không tuyên bố "đã kiểm thử trên thiết bị" nếu chưa chạy thực tế.

## 5. Thiết kế màn hình

### 5.1 Onboarding
3 trang: ví pixel, cloud, ngân sách. Nền kem, minh họa glyph 96 trong panel mint/butter,
tiêu đề VT323, mô tả Be Vietnam Pro, chấm tiến trình dạng khối, nút "TIẾP TỤC"/"BẮT ĐẦU",
"BỎ QUA" góc phải. Giữ nguyên luồng xin quyền camera/thông báo.

### 5.2 Đăng nhập / Đăng ký
Logo ô mint + tên app VT323; panel form viền mực; field email/mật khẩu, hiện/ẩn mật khẩu;
"Quên mật khẩu?"; nút primary; phân cách "HOẶC"; nút Google viền; link chuyển đăng ký.
Cảnh báo thiếu cấu hình Supabase dạng panel butter. Lỗi map tiếng Việt như hiện tại,
thêm lỗi mạng rõ ràng.

### 5.3 Feed / Camera (màn mặc định)
Theo §3.7. Trang đầu là camera; vuốt dọc sang feed. Nút menu mở drawer; nút lưới mở
gallery; nút chụp mở form với ảnh vừa chụp.

### 5.4 Form khoản chi
Sheet toàn màn hình nền kem: ảnh vuông viền mực, nút đổi ảnh (không cho đổi khi đang sửa),
số tiền lớn VT323 + formatter, mô tả, lưới danh mục (chip icon + tên, chọn rõ ràng),
4 mức độ, ngày/giờ, nút "LƯU KHOẢN CHI". Validate inline; loading khi upload; lỗi cloud
hiển thị và giữ dữ liệu đã nhập.

### 5.5 Tổng quan
Lời chào + ngày; hero panel mint "CHI THÁNG NÀY" số lớn, thanh ngân sách segmented,
3 stat tile (hôm nay/tuần/số khoản); hàng tìm kiếm + lọc; danh sách khoản chi nhóm theo
ngày, mỗi dòng badge icon + tên + ghi chú + số tiền + giờ; vuốt xóa mềm có hoàn tác;
empty state pixel.

### 5.6 Thống kê
Segmented khoảng (Hôm nay/Tuần/Tháng/Năm/Tùy chọn); hero tổng; panel "THEO DANH MỤC"
thanh khối; panel "MỨC ĐỘ" 4 khối + legend; panel "THEO NGÀY" bar chart pixel; panel
"Nhận xét" các dòng glyph sparkle. Tùy chọn khoảng ngày dùng date range picker đã theme.

### 5.7 Ngân sách
Cuộn được toàn bộ (sửa lỗi tràn khi bàn phím mở). Chọn tháng; panel ngân sách tổng với
input formatter + segmented progress; trạng thái vượt → "QUÁ NGÂN SÁCH: X" màu rose;
danh sách ngân sách danh mục; dialog thêm/sửa/xóa. Không còn màu chỉ dành light mode.

### 5.8 Danh mục
Danh sách badge icon + tên + nhãn "MẶC ĐỊNH" cho danh mục hệ thống; nút thêm; dialog
sửa/thêm với lưới glyph 19 khóa (khớp `IconHelper.categoryIconKeys`, cuộn, chọn viền mint);
xóa có xác nhận và giải thích
chuyển khoản chi sang "Khác"; lỗi trùng tên hiển thị rõ.

### 5.9 Thùng rác
Danh sách khoản đã xóa: ảnh nhỏ/không ảnh, số tiền, ngày xóa; nút "KHÔI PHỤC" và
"XÓA VĨNH VIỄN" (xác nhận); empty state; xóa vĩnh viễn xóa cả ảnh storage.

### 5.10 Cài đặt
Panel hồ sơ (avatar chữ cái pixel, email); nhóm "DỮ LIỆU": Xuất CSV, Danh mục, Thùng rác;
nhóm "GIAO DIỆN": công tắc sáng/tối dạng pixel; nhóm "TÀI KHOẢN": đăng xuất (xác nhận);
"VỀ APP": phiên bản từ `AppInfo`, tagline.

### 5.11 Drawer
Nền `surface` (theme-aware), rộng ~300; header avatar + email; các mục: Nhật ký ảnh,
Tổng quan, Thống kê, Ngân sách, Danh mục, Thùng rác, Cài đặt; mục đang chọn nền mint +
viền trái 4 px ink; công tắc sáng/tối; footer trạng thái cloud + phiên bản. Không còn
gradient tối cố định.

### 5.12 Dialog / sheet / snackbar
Dùng component kit; không dùng dialog mặc định Material trần. Nút hủy secondary, nút
hành động primary/rose. Sheet kéo đóng được. Snackbar nền ink, chữ kem, action butter.

## 6. Trạng thái rỗng, lỗi, tải

- Empty chung: glyph 64 + tiêu đề VT323 + 1–2 câu hướng dẫn + CTA phù hợp.
  - Feed trống: "Chưa có khoản chi nào" + "Mở camera và chụp khoản chi đầu tiên."
  - Tìm kiếm/lọc không kết quả: "Không tìm thấy khoản chi" + nút "Xóa bộ lọc".
  - Thống kê trống: "Chưa có dữ liệu trong khoảng này."
  - Ngân sách trống: "Chưa đặt ngân sách" + nút đặt.
  - Thùng rác trống: "Thùng rác đang trống."
- Loading: pixel blocks, không spinner tròn; skeleton cho danh sách (3–5 dòng).
- Lỗi: panel/ snackbar có chữ + hành động "THỬ LẠI"; lỗi cloud không làm mất dữ liệu
  đang nhập; lỗi ảnh riêng lẻ không làm hỏng cả feed.
- Mất mạng: thông báo rõ "Không có kết nối mạng" (map từ lỗi Supabase) và không lưu giả.

## 7. Luồng dữ liệu then chốt

**Lưu khoản chi mới**
1. Người dùng chụp/chọn ảnh → file tạm.
2. Form validate (ảnh, số tiền > 0, mô tả, danh mục, thời điểm không tương lai).
3. `ExpenseRepository.insert`: upload ảnh → nhận path → insert row (path) → nếu lỗi insert
   thì xóa file vừa upload → ném lỗi.
4. Xóa file tạm trên máy; refresh provider (dashboard/budget/statistics); snackbar thành công.

**Đọc danh sách ảnh**
1. Query expenses → chuẩn hóa `imagePath` (path hoặc URL cũ).
2. Batch sign 50 path/lô, hạn 24 h.
3. Gán `displayImageUrl`; UI dùng `cacheKey = imagePath`.
4. Lỗi ký → ảnh hiện placeholder + thử lại; danh sách vẫn hiển thị.

**Đặt lại mật khẩu**
1. Login → Quên mật khẩu → nhập email → Supabase gửi link với `redirectTo`.
2. Người dùng mở link → app nhận deep link → `passwordRecovery` → `ResetPasswordScreen`.
3. Cập nhật mật khẩu → đăng xuất → Login + thông báo.
4. Link hết hạn → màn hình lỗi + gửi lại.

**Xuất CSV**
1. Settings → Xuất CSV → loading.
2. Tải phân trang toàn bộ khoản chi (kèm tên danh mục).
3. Build CSV (BOM) → ghi file tạm → share sheet.
4. Xóa file tạm; lỗi → snackbar, không crash.

## 8. Kiểm thử

Hiện có **69 test**. Bổ sung:

**Unit**
- `ThousandsSeparatorInputFormatter`: định dạng, xóa, dán, giới hạn 12 số, vị trí con trỏ.
- `CurrencyFormatter.parseInput`: chuỗi rỗng, có dấu chấm, ký tự lạ, số rất lớn.
- CSV: BOM, header, thứ tự, escaping dấu phẩy/ngoặc kép/xuống dòng, tiếng Việt, rỗng.
- `storagePathFromUrl`: path thuần, public URL cũ, signed URL, URL lạ, null.
- Chia lô signed URL (nếu tách helper thuần).
- Glyph registry: kích thước, ký tự hợp lệ, phủ đủ khóa `IconHelper`.
- Palette contrast: các cặp chữ/nền chính ở light & dark ≥ 4.5:1.
- Auth: map lỗi reset/update, thông báo trung tính, validate mật khẩu mới.

**Widget**
- Login có "Quên mật khẩu?" và luồng gửi email trung tính (fake auth).
- Form khoản chi: nhập 1234567 hiện `1.234.567`; có ô ngày/giờ; chặn tương lai.
- Tổng quan: empty state, danh sách render, theme sáng/tối không lỗi overflow ở 1.3×.
- Settings: có mục Xuất CSV, phiên bản đúng.
- Reset password: validate độ dài/xác nhận, nút hiện/ẩn.
- Pixel components: `PixelButton`, `PixelChip`, `PixelProgress`, `PixelEmptyState`,
  `AppIcon` semantics.

**Lệnh xác minh bắt buộc**
```bash
flutter analyze
flutter test
flutter build apk --debug
```

Không chấp nhận bàn giao khi còn lỗi analyze/test/build.

## 9. Rủi ro & xác minh thủ công

| Rủi ro | Giảm thiểu |
| --- | --- |
| VT323 khó đọc tiếng Việt ở cỡ nhỏ | Hybrid font, nhãn ≥16 px, body Be Vietnam Pro, test text scale |
| Signed URL hết hạn | Hạn 24 h, ký lại khi load/refresh, `cacheKey`, nút thử lại |
| Ảnh cũ đang là public URL | Chuẩn hóa URL → path, không đổi object; test 3 dạng URL |
| Private bucket làm ảnh cũ hỏng nếu policy sai | SQL owner-only, test bằng tài khoản thật sau khi chạy |
| Khối lượng ~59 glyph | Dữ liệu lưới + test registry + fallback `label`; làm theo màn hình |
| Bỏ `google_fonts`/`fl_chart` gây lỗi sót | Grep toàn bộ tham chiếu trước khi xóa dependency |
| CSV lớn gây chậm/bộ nhớ | Phân trang 1000, build chuỗi một lần, thông báo loading |
| Deep link reset không test được local | Ghi rõ bước cấu hình Redirect URLs + checklist thủ công |
| Keep-alive bị GitHub tắt sau 60 ngày | Tài liệu cron-job.org dự phòng |

**Cần người dùng xác minh thủ công (không có thiết bị/emulator trong phiên):**
1. Chạy `supabase_setup.sql` mới; kiểm tra bucket private và ảnh cũ vẫn mở được.
2. Thêm GitHub Secrets và chạy workflow keep-alive; xem log status 200.
3. Cấu hình Supabase Redirect URLs cho link đặt lại mật khẩu; thử trên Android thật.
4. Chụp ảnh, lưu khoản chi, xem feed/lưới, sửa ngày giờ.
5. Xuất CSV, mở bằng Excel/Google Sheets kiểm tra tiếng Việt.
6. Kiểm tra sáng/tối và text scale 1.3 trên thiết bị.

## 10. Tiêu chí nghiệm thu

- [ ] Không còn icon Material/emoji trong UI; mọi icon là glyph pixel tự vẽ.
- [ ] Không còn `google_fonts` hay `fl_chart`; app không tải font từ mạng.
- [ ] Không còn màu hardcode light-only trong UI; sáng/tối đều đạt tương phản.
- [ ] Toàn bộ màn hình trong §5 dùng component kit và token.
- [ ] Feed hiển thị ảnh chất lượng gốc từ bucket private qua signed URL.
- [ ] Quên mật khẩu → nhận email → đặt lại mật khẩu thành công trên Android.
- [ ] Sửa được ngày giờ khoản chi; chặn tương lai; danh sách sắp xếp lại đúng.
- [ ] Mọi ô nhập tiền tự chấm hàng nghìn và parse đúng.
- [ ] Xuất CSV mở đúng tiếng Việt trong Excel; chia sẻ được.
- [ ] SQL chạy lại nhiều lần không lỗi; bucket private; policy owner-only.
- [ ] Workflow keep-alive chạy tay thành công, không lộ khóa.
- [ ] `flutter analyze` sạch, `flutter test` pass toàn bộ, build APK debug thành công.
- [ ] README/requirements/project-structure phản ánh đúng tính năng, version và số test.
