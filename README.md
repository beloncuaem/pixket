<p align="center">
  <img src="https://raw.githubusercontent.com/beloncuaem/chi_tieu/main/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="96" height="96" alt="Piket Logo" />
</p>

<h1 align="center">Piket — Pixel Expense Journal</h1>

<p align="center">
  <b>Nhật ký chi tiêu bằng ảnh kiểu Locket, giao diện Pixel tự vẽ, lưu trực tiếp trên Supabase (Auth, PostgreSQL RLS, Storage private) và bắt buộc đăng nhập.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Supabase-Cloud%20Database-3ECF8E?logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/State-Riverpod%202.6-blue" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Database-PostgreSQL-4169E1" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Tests-274%20Passed%20(100%25)-success" alt="Tests" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## 🌟 Giới thiệu

**Piket** là ứng dụng quản lý tài chính cá nhân với trải nghiệm **nhật ký ảnh**:
mở app là camera, chụp hóa đơn hoặc khoảnh khắc chi tiêu, rồi lướt dọc để xem lại
từng khoản chi như một dòng thời gian. Điều hướng chính dùng nút **3 gạch** ở góc trên
trái thay cho thanh tab đáy.

Giao diện theo ngôn ngữ **Pixel**: bảng ký tự 16×16, icon tự vẽ bằng `CustomPainter`,
panel viền vuông và font VT323 — không dùng icon hệ thống, không gradient.

Toàn bộ khoản chi, danh mục, ngân sách và ảnh được lưu **trực tiếp trên Supabase**;
không có bản sao dữ liệu tài chính trên thiết bị và không cần thao tác đồng bộ thủ công.

---

## 🚀 Tính năng nổi bật

### 1. 📸 Nhật ký ảnh kiểu Locket
- Trang đầu tiên là **camera trực tiếp** với nút chụp, thư viện và đổi camera.
- Vuốt dọc để xem lần lượt các khoản chi có ảnh, **mới nhất trước**.
- Ảnh toàn màn hình kèm danh mục, mức độ cần thiết, số tiền, ghi chú, ngày giờ.
- Nút sửa/xóa là nút pixel viền vuông; xóa chuyển vào thùng rác kèm hoàn tác trong 5 giây.
- Ảnh cloud tải qua **signed URL hạn 24 giờ** và hiển thị bằng glyph `receipt` khi chưa tải được.
- Nút góc phải mở **xem ảnh dạng lưới**, chạm một ảnh để nhảy tới đúng khoảnh khắc trong feed.

### 2. ☰ Điều hướng bằng Drawer
- Nút 3 gạch pixel cố định ở góc trên trái của mọi màn hình chính.
- Drawer gồm: hồ sơ người dùng, **Nhật ký ảnh**, **Tổng quan**, **Thống kê**, **Ngân sách**,
  quản lý danh mục, thùng rác, cài đặt và chuyển sáng/tối.
- Hiển thị trạng thái cloud (đang kết nối / chưa cấu hình) ngay trong drawer.

### 3. 🎮 Giao diện Pixel
- **42 glyph 16×16** tự vẽ trong `lib/core/icons/pixel_glyph_data.dart`, render bằng
  `CustomPainter` qua `AppIcon`; không còn ký hiệu `Icons.*` nào trong `lib/`.
- Panel viền vuông 2–3 px, bóng cứng lệch `(3, 4)`, không gradient ở `lib/screens/`.
- Bảng màu `AppPalette` (ThemeExtension): nền kem `#FFF6E3` + nhấn mint `#7BD8A8`,
  có phiên bản tối cho nhật ký ảnh.
- Font **VT323** (tiêu đề, số tiền) + **Be Vietnam Pro** (nội dung), bundle offline trong
  `assets/fonts/` kèm OFL — không dùng `google_fonts`, không tải font lúc chạy.
- Nút/chip đổi trạng thái trong 120 ms, chuyển trang 160 ms — ngắn và có chủ đích.
- Mọi mục chạm đều ≥ 48 dp; hỗ trợ text scale 1.3× (đã test ở 360×520).

### 4. 🔐 Xác thực Supabase
- Đăng nhập/đăng ký **Email & Mật khẩu**.
- **Google OAuth** qua trình duyệt, quay lại app bằng deep link
  `io.supabase.chitieu://login-callback/`.
- **Quên mật khẩu**: gửi link PKCE, mở link để về màn đặt lại mật khẩu trong app.
- Bắt buộc đăng nhập; không có chế độ khách hay ngoại tuyến.
- Kiểm tra provider Google trước khi mở trình duyệt để báo lỗi rõ ràng thay vì trang JSON.

### 5. ☁️ Cloud-first & Bảo mật RLS
- PostgreSQL + Row Level Security: mỗi người dùng chỉ thấy dữ liệu của mình.
- Hồ sơ `profiles` tạo tự động bằng trigger khi đăng ký.
- Ảnh hóa đơn upload lên bucket **private** `expense-receipts`, cột `image_url` lưu
  storage path chứ không lưu URL công khai.
- Rollback: ghi DB thất bại thì ảnh vừa upload bị xóa, không để lại tệp mồ côi.
- Không lưu dữ liệu tài chính hay ảnh hóa đơn trên máy; ảnh tạm được dọn sau khi lưu.
- Khi mất mạng hoặc upload thất bại, app báo lỗi và không lưu khoản chi.

### 6. 📊 Thống kê & Ngân sách
- Biểu đồ pixel tự vẽ: thanh phân bổ theo danh mục, chồng tích lũy, cột theo mức độ cần thiết.
- Thống kê hôm nay/tuần/tháng/năm hoặc khoảng ngày tùy chọn.
- Ngân sách tổng hoặc theo danh mục, thanh tiến trình đổi màu theo hạn mức.
- Vượt hạn mức hiển thị **"Quá ngân sách: X"**, không hiển thị số còn lại âm.
- Cảnh báo một lần ở các mốc 80%, 90%, 100% ngân sách tháng.
- Thùng rác cho phép khôi phục hoặc xóa hẳn khoản chi đã xóa.

### 7. 🧮 Nhập liệu an toàn
- Ô số tiền tự chèn dấu chấm nhóm nghìn, chặn ký tự lạ, tối đa 12 chữ số.
- Mọi chỗ đọc số tiền dùng `CurrencyFormatter.parseInput` — không `int.parse` trực tiếp.
- Khoản chi chọn được ngày giờ, chặn tương lai và chặn xa quá 10 năm, có nút "Bây giờ".

---

## 🛠️ Công nghệ sử dụng

| Tầng | Công nghệ / Thư viện | Mục đích |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.47+ (Dart 3.13+) | Ứng dụng Android |
| **State Management** | `flutter_riverpod` ^2.6.1 | StateNotifier, quản lý trạng thái |
| **Cloud Database** | `supabase_flutter` ^2.8.3 | Auth, PostgreSQL RLS, Storage private + signed URL |
| **Cài đặt cục bộ** | `sqflite` ^2.4.2 | Chỉ lưu onboarding và mức độ cần thiết |
| **Giao diện** | `AppPalette` (ThemeExtension), font bundle VT323 + Be Vietnam Pro | Pixel sáng/tối, không dùng `google_fonts` |
| **Icon** | `pixel_glyph_data.dart` + `CustomPainter` | 42 glyph 16×16 tự vẽ, không dùng `Icons.*` |
| **Biểu đồ** | Widget pixel tự vẽ (`PixelShareBar`, `PixelStackedShare`, `PixelBarChart`) | Không dùng `fl_chart` |
| **Camera & Ảnh** | `camera`, `image_picker`, `cached_network_image` | Chụp, chọn, cache ảnh cloud |
| **Chia sẻ** | `share_plus` ^13.3.1 | Gửi file CSV qua share sheet |
| **Môi trường** | `flutter_dotenv` ^5.2.1 | Đọc `.env` |
| **Kiểm thử** | `flutter_test` | 274 Unit & Widget tests |

---

## 📁 Cấu trúc Thư mục

```text
piket/
├── .github/workflows/         # supabase-keepalive.yml + build-apk.yml
├── android/                   # Manifest, quyền, OAuth deep link, icon pixel
├── assets/fonts/              # VT323 + Be Vietnam Pro bundle offline (OFL)
├── docs/                      # Cấu trúc, yêu cầu, OAuth, keep-alive, brand
├── lib/
│   ├── core/
│   │   ├── icons/             # pixel_glyph_data.dart (42 glyph 16×16)
│   │   ├── theme/             # app_palette, app_theme, pixel_text_theme
│   │   ├── constants/         # AppInfo (Piket, 2.2.0+3), AppStrings
│   │   ├── config/            # supabase_config.dart
│   │   └── utils/             # formatter, csv_builder, icon_helper, storage_paths
│   ├── data/
│   │   ├── models/            # Expense, Category, Budget, PriorityLevel
│   │   └── repositories/      # auth, expense, category, budget, csv_export_service
│   ├── providers/             # Riverpod StateNotifier
│   ├── screens/
│   │   ├── main_screen.dart   # Scaffold + Drawer + 4 khu vực
│   │   ├── auth/              # Login, Register, quên/đặt lại mật khẩu
│   │   ├── camera/            # Locket feed, camera, form, lưới ảnh
│   │   ├── home/              # Tổng quan + lọc khoản chi
│   │   ├── statistics/        # Thống kê + biểu đồ pixel
│   │   ├── budget/            # Ngân sách
│   │   ├── categories/        # Danh mục + bảng glyph
│   │   ├── settings/          # Cài đặt + xuất CSV
│   │   ├── trash/             # Thùng rác
│   │   └── onboarding/        # Giới thiệu lần đầu
│   └── widgets/
│       ├── app_drawer.dart    # Drawer 3 gạch
│       └── pixel/             # 23 widget pixel (button, chip, panel, chart, ...)
├── test/                      # 274 Unit & Widget tests
├── supabase_setup.sql         # Bảng + RLS + Storage
├── .env.example               # Mẫu biến môi trường
└── pubspec.yaml
```

Chi tiết xem tại [docs/project-structure.md](docs/project-structure.md).

---

## ⚡ Hướng dẫn Cài đặt & Khởi chạy

### 1. Yêu cầu môi trường
- Flutter SDK 3.47+.
- Android Studio / VS Code + Android SDK + JDK 17 (để build APK tại máy).
- Tài khoản Supabase.

### 2. Tải mã nguồn
```bash
git clone https://github.com/beloncuaem/chi_tieu.git
cd chi_tieu
flutter pub get
```

### 3. Cấu hình Supabase
1. Tạo project tại [supabase.com](https://supabase.com).
2. Mở **SQL Editor**, chạy toàn bộ [supabase_setup.sql](supabase_setup.sql).
3. Tạo `.env` từ mẫu (**file này là asset bắt buộc trong `pubspec.yaml`, thiếu là không build được**):
   ```bash
   cp .env.example .env
   ```
   Điền thông tin từ **Project Settings → API**:
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   ```
4. Trong **Authentication → Providers**, bật **Email**.
5. Muốn dùng Google: bật **Google** và cấu hình OAuth Client ID/Secret.
   Làm theo [docs/google-oauth-troubleshooting.md](docs/google-oauth-troubleshooting.md).
6. Trong **Authentication → URL Configuration**, thêm redirect:
   ```text
   io.supabase.chitieu://login-callback/
   ```

> Không commit `.env` (đã nằm trong `.gitignore`). Chỉ anon/publishable key được nhúng
> vào app; tuyệt đối không dùng `service_role` key trong client hay trong workflow.

Bucket `expense-receipts` là **private**: app lưu đúng storage path `<user_id>/<file>`
vào cột `image_url` và hiển thị ảnh qua **signed URL hạn 24 giờ**. Ảnh cũ dạng public URL
vẫn đọc được vì client tự quy về path, nhưng app không ghi mới URL public.

### 3b. Giữ Supabase hoạt động

Supabase free tier tạm dừng project sau 7 ngày không có hoạt động. Bật workflow
keep-alive và theo dõi hướng dẫn tại [docs/supabase-keepalive.md](docs/supabase-keepalive.md).

### 4. Chạy ứng dụng
```bash
flutter run
```

### 5. Xuất APK

Cách 1 — GitHub Actions (khuyến nghị, không cần máy có Android SDK):
mở tab **Actions** → workflow **Build APK** → **Run workflow**. Workflow chạy
`flutter analyze` + `flutter test` trước, rồi build và đính kèm artifact
`piket-release-apk` chứa `app-release.apk`. Cần thêm hai repository secret
`SUPABASE_URL` và `SUPABASE_ANON_KEY` (anon key, không phải `service_role`).

Cách 2 — build tại máy (cần Android SDK + JDK 17):
```bash
flutter build apk --release
```
File: `build/app/outputs/flutter-apk/app-release.apk`

> Máy phát triển của dự án này chưa cài Android SDK/JDK nên `flutter build apk`
> không chạy được tại chỗ; hãy dùng Cách 1.

---

## 💾 Sao lưu & khôi phục dữ liệu

- **Xuất CSV**: Cài đặt → Xuất CSV (sao lưu). File `piket_YYYYMMDD_HHmm.csv` mở bằng
  Excel/LibreOffice/Google Sheets (BOM UTF-8); cột `ảnh` ghi đường dẫn trong bucket
  `expense-receipts`, không chứa ảnh nhúng. Danh sách dài được phân trang 1000 dòng.
- **Khôi phục ảnh**: muốn mang ảnh theo sang project Supabase khác phải tải riêng từng object
  qua Storage API; CSV không tự tải ảnh.
- **Nhập lại CSV**: chưa hỗ trợ. CSV là bản sao lưu để đọc và để nhập tay vào công cụ khác.
- **Quên mật khẩu**: Màn hình đăng nhập → "Quên mật khẩu?" → nhập email. Supabase gửi link đặt lại;
  mở link trên chính thiết bị đã cài app để deep link `io.supabase.chitieu://login-callback/`
  đưa app về màn đặt mật khẩu mới.

---

## 🧪 Kiểm thử

```bash
flutter analyze     # No issues found!
flutter test        # 274/274 passed
```

- **Unit Tests**: model, formatter VND/ngày, `ThousandsSeparatorInputFormatter`,
  `CurrencyFormatter.parseInput`, giới hạn ngày giờ, `CsvBuilder`, `StoragePaths`,
  `pixel_allocate`, trạng thái ngân sách/thống kê/auth, ánh xạ icon + hợp lệ 42 glyph,
  sắp xếp feed ảnh, `PixelReceiptImage`.
- **Widget Tests**: Login/Register/Quên mật khẩu/Đặt lại mật khẩu, onboarding, dashboard,
  form khoản chi, camera + ảnh toàn màn hình + lưới ảnh, thống kê, ngân sách, danh mục,
  thùng rác, cài đặt, AppDrawer, và bộ widget pixel (nút, chip, panel, empty state,
  segmented, badge, ô nhập, hộp thoại xác nhận).
- **Test chốt đường lùi**: `test/widget/legacy_cleanup_test.dart` bảo đảm `lib/` không còn
  `AppColors`, `Icons.`, `GlassCard`, `fl_chart`, `google_fonts`, gradient hay 8 file widget
  cũ — kế hoạch sau này lỡ thêm lại sẽ bị test đỏ.

### Đã xác minh trên emulator Android API 35 (trước đợt redesign Pixel)
- Onboarding và cấp quyền camera/thông báo.
- Đăng nhập email sai → Supabase trả `Invalid login credentials`
  → app hiển thị **"Email hoặc mật khẩu không chính xác."** (xác nhận kết nối backend).
- Feed dọc, nút 3 gạch, drawer và 4 khu vực hiển thị đúng.
- Google OAuth được chặn rõ ràng khi provider chưa bật (xem tài liệu troubleshooting).
- **Bản release APK** cài trên emulator: trang ảnh Locket mở đúng, drawer chuyển trang hoạt động,
  icon status bar đổi theo nền sáng/tối.

### Chưa xác minh trên thiết bị
Những mục dưới đây **chỉ được chứng minh bằng widget test và `flutter analyze`**, chưa chạy
th thủ công trên máy thật sau đợt redesign Pixel:
1. Feed Locket + trang camera: bố cục pixel thật trên màn hình, camera preview có bị che
   bởi HUD hay không.
2. Keyboard khi nhập số tiền/chọn ngày giờ trong bottom sheet (inset, cuộn, che nút).
3. Tải ảnh thật từ bucket private qua signed URL trên thiết bị, và ảnh legacy còn hiển thị.
4. Share sheet Android với file `.csv` và hiệu năng phân trang khi > 5000 khoản chi.
5. Email đặt lại mật khẩu + deep link mở lại app, và `updateUser(password:)` có đòi
   reauthentication hay không (tùy cấu hình project Supabase).

---

## 🔧 Khắc phục sự cố Google OAuth

Lỗi phổ biến khi cài APK:

```json
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: provider is not enabled"}
```

Nguyên nhân: **Google provider chưa được bật trong Supabase Dashboard**, không phải lỗi APK.
Chi tiết bằng chứng và các bước sửa:
[docs/google-oauth-troubleshooting.md](docs/google-oauth-troubleshooting.md).

---

## ✅ Việc người dùng cần tự làm

1. Chạy lại `supabase_setup.sql` (bucket private + unique index `budgets`).
2. Thêm repository secret `SUPABASE_URL`, `SUPABASE_ANON_KEY` cho workflow keep-alive và build APK.
3. Chạy workflow **Supabase keep-alive** một lần và xác nhận `HTTP 200`; đặt cron-job.org làm dự phòng.
4. Bật Google provider trong Supabase nếu muốn đăng nhập Google.
5. Giữ project Supabase có hoạt động hằng ngày để không bị pause lại sau 7 ngày.

---

## 📄 Giấy phép

Dự án phát hành theo **MIT License**.
