<p align="center">
  <img src="https://raw.githubusercontent.com/beloncuaem/chi_tieu/main/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="96" height="96" alt="Chi Tiêu Logo" />
</p>

<h1 align="center">Chi Tiêu — Locket Expense Journal</h1>

<p align="center">
  <b>Nhật ký chi tiêu bằng ảnh kiểu Locket, giao diện Fintech hiện đại, lưu trực tiếp trên Supabase (Auth, PostgreSQL RLS, Storage) và bắt buộc đăng nhập.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Supabase-Cloud%20Database-3ECF8E?logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/State-Riverpod%202.6-blue" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Database-PostgreSQL-4169E1" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Tests-66%20Passed%20(100%25)-success" alt="Tests" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## 🌟 Giới thiệu

**Chi Tiêu** là ứng dụng quản lý tài chính cá nhân với trải nghiệm **nhật ký ảnh**:
mở app là camera, chụp hóa đơn hoặc khoảnh khắc chi tiêu, rồi lướt dọc để xem lại
từng khoản chi như một dòng thời gian. Điều hướng chính dùng nút **3 gạch** ở góc trên
trái thay cho thanh tab đáy.

Toàn bộ khoản chi, danh mục, ngân sách và ảnh được lưu **trực tiếp trên Supabase**;
không có bản sao dữ liệu tài chính trên thiết bị và không cần thao tác đồng bộ thủ công.

---

## 🚀 Tính năng nổi bật

### 1. 📸 Nhật ký ảnh kiểu Locket
- Trang đầu tiên là **camera trực tiếp** với nút chụp, thư viện và đổi camera.
- Vuốt dọc để xem lần lượt các khoản chi có ảnh, **mới nhất trước**.
- Ảnh toàn màn hình kèm danh mục, mức độ cần thiết, số tiền, ghi chú, ngày giờ.
- Nút sửa/xóa dạng kính mờ; xóa chuyển vào thùng rác kèm hoàn tác trong 5 giây.
- Ảnh cloud dùng `cached_network_image`; ảnh tạm trên máy được xóa sau khi lưu thành công.
- Nút góc phải mở **xem ảnh dạng lưới**, chạm một ảnh để nhảy tới đúng khoảnh khắc trong feed.

### 2. ☰ Điều hướng bằng Drawer
- Nút 3 gạch cố định ở góc trên trái của mọi màn hình chính.
- Drawer gồm: hồ sơ người dùng, **Nhật ký ảnh**, **Tổng quan**, **Thống kê**, **Ngân sách**,
  quản lý danh mục, thùng rác, cài đặt và chuyển sáng/tối.
- Hiển thị trạng thái **Cloud Sync** ngay trong drawer.

### 3. 💎 Giao diện Fintech hiện đại
- Tông **Deep Slate** kết hợp **Emerald Green**, phông **Be Vietnam Pro**.
- Thẻ kính mờ (glassmorphism), gradient, huy hiệu icon pastel.
- Hỗ trợ đầy đủ Light Mode và Dark Mode.

### 4. 🔐 Xác thực Supabase
- Đăng nhập/đăng ký **Email & Mật khẩu**.
- **Google OAuth** qua trình duyệt, quay lại app bằng deep link
  `io.supabase.chitieu://login-callback/`.
- Bắt buộc đăng nhập; không có chế độ khách hay ngoại tuyến.
- Kiểm tra provider Google trước khi mở trình duyệt để báo lỗi rõ ràng thay vì trang JSON.

### 5. ☁️ Cloud-first & Bảo mật RLS
- PostgreSQL + Row Level Security: mỗi người dùng chỉ thấy dữ liệu của mình.
- Hồ sơ `profiles` tạo tự động bằng trigger khi đăng ký.
- Ảnh hóa đơn được upload tự động lên bucket `expense-receipts` khi lưu khoản chi.
- Không lưu dữ liệu tài chính hay ảnh hóa đơn trên máy; ảnh tạm được dọn sau khi lưu.
- Khi mất mạng hoặc upload thất bại, app báo lỗi và không lưu khoản chi.

### 6. 📊 Thống kê & Ngân sách
- Biểu đồ tròn phân bổ theo danh mục, biểu đồ thanh theo mức độ cần thiết.
- Thống kê hôm nay/tuần/tháng/năm hoặc khoảng ngày tùy chọn.
- Ngân sách tổng hoặc theo danh mục, thanh tiến trình đổi màu theo hạn mức.
- Vượt hạn mức hiển thị **"Quá ngân sách: X"**, không hiển thị số còn lại âm.
- Cảnh báo một lần ở các mốc 80%, 90%, 100% ngân sách tháng.
- Thùng rác cho phép khôi phục khoản chi đã xóa.

---

## 🛠️ Công nghệ sử dụng

| Tầng | Công nghệ / Thư viện | Mục đích |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart 3.13+) | Ứng dụng đa nền tảng |
| **State Management** | `flutter_riverpod` ^2.6.1 | StateNotifier, quản lý trạng thái |
| **Cloud Database** | `supabase_flutter` ^2.8.3 | Auth, PostgreSQL RLS, Storage private + signed URL |
| **Cài đặt cục bộ** | `sqflite` ^2.4.2 | Chỉ lưu tùy chọn onboarding và mức độ cần thiết |
| **Giao diện** | `google_fonts`, Material 3 | Be Vietnam Pro, Light/Dark |
| **Biểu đồ** | `fl_chart` ^0.70.2 | Donut và bar chart |
| **Camera & Ảnh** | `camera`, `image_picker`, `cached_network_image` | Chụp, chọn, cache ảnh |
| **Môi trường** | `flutter_dotenv` ^5.2.1 | Đọc `.env` |
| **Kiểm thử** | `flutter_test` | 66 Unit & Widget tests |

---

## 📁 Cấu trúc Thư mục

```text
chi_tieu/
├── android/                   # Manifest, quyền, OAuth deep link
├── docs/                      # Cấu trúc, yêu cầu, hướng dẫn OAuth
├── lib/
│   ├── core/                  # config, constants, navigation, services, theme, utils
│   ├── data/                  # models, repositories Supabase, storage
│   ├── providers/             # Riverpod StateNotifier
│   ├── screens/
│   │   ├── main_screen.dart   # Scaffold + Drawer + 4 khu vực
│   │   ├── auth/              # Login, Register
│   │   ├── camera/            # Locket feed, camera, form khoản chi
│   │   ├── home/              # Tổng quan
│   │   ├── statistics/        # Thống kê
│   │   ├── budget/            # Ngân sách
│   │   ├── categories/        # Danh mục
│   │   ├── settings/          # Cài đặt
│   │   ├── trash/             # Thùng rác
│   │   └── onboarding/        # Giới thiệu lần đầu
│   └── widgets/               # AppDrawer, GlassCard, ExpenseCard, ...
├── test/                      # Unit & Widget tests
├── supabase_setup.sql         # Bảng + RLS + Storage
├── .env.example               # Mẫu biến môi trường
└── pubspec.yaml
```

Chi tiết xem tại [docs/project-structure.md](docs/project-structure.md).

---

## ⚡ Hướng dẫn Cài đặt & Khởi chạy

### 1. Yêu cầu môi trường
- Flutter SDK 3.27+ (khuyến nghị 3.47+).
- Android Studio / VS Code + Android SDK.
- Tài khoản Supabase nếu muốn dùng cloud.

### 2. Tải mã nguồn
```bash
git clone https://github.com/beloncuaem/chi_tieu.git
cd chi_tieu
flutter pub get
```

### 3. Cấu hình Supabase
1. Tạo project tại [supabase.com](https://supabase.com).
2. Mở **SQL Editor**, chạy toàn bộ [supabase_setup.sql](supabase_setup.sql).
3. Tạo `.env` từ mẫu:
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

> Không commit `.env`. Chỉ anon/publishable key được nhúng vào app;
> tuyệt đối không dùng `service_role` key trong client.

Bucket `expense-receipts` là **private** (từ v2.2): app lưu đúng storage path
`<user_id>/<file>` vào cột `image_url` và hiển thị ảnh qua **signed URL hạn 24 giờ**.
Ảnh cũ dạng public URL vẫn đọc được vì client tự quy về path, nhưng app không ghi mới URL public.

### 3b. Giữ Supabase hoạt động

Supabase free tier tạm dừng project sau 7 ngày không có hoạt động. Bật workflow
keep-alive và theo dõi hướng dẫn tại [docs/supabase-keepalive.md](docs/supabase-keepalive.md).

### 4. Chạy ứng dụng
```bash
flutter run
```

### 5. Xuất APK
```bash
flutter build apk --release
```
File: `build/app/outputs/flutter-apk/app-release.apk`

---

## 💾 Sao lưu & khôi phục dữ liệu

- **Xuất CSV**: Cài đặt → Xuất CSV (sao lưu). File `piket_YYYYMMDD_HHmm.csv` mở bằng
  Excel/LibreOffice/Google Sheets; cột `ảnh` ghi đường dẫn trong bucket `expense-receipts`,
  không chứa ảnh nhúng.
- **Khôi phục ảnh**: muốn mang ảnh theo sang project Supabase khác phải tải riêng từng object
  qua Storage API; CSV không tự tải ảnh.
- **Nhập lại CSV**: chưa hỗ trợ. CSV là bản sao lưu để đọc và để nhập tay vào công cụ khác.
- **Quên mật khẩu**: Màn hình đăng nhập → "Quên mật khẩu?" → nhập email. Supabase gửi link đặt lại;
  mở link trên chính thiết bị đã cài app để deep link `io.supabase.chitieu://login-callback/`
  đưa app về màn đặt mật khẩu mới.

---

## 🧪 Kiểm thử

```bash
flutter analyze     # không có lỗi biên dịch
flutter test        # 181/181 passed
```

- **Unit Tests**: model, formatter VND/ngày, trạng thái ngân sách/thống kê/auth,
  ánh xạ icon, sắp xếp feed ảnh.
- **Widget Tests**: Login/Settings/Trash, ExpenseCard, PriorityBadge, CategoryChip,
  AppDrawer (điều hướng, tiện ích, hồ sơ cloud).

### Đã xác minh trên emulator Android API 35
- Onboarding và cấp quyền camera/thông báo.
- Đăng nhập email sai → Supabase trả `Invalid login credentials`
  → app hiển thị **"Email hoặc mật khẩu không chính xác."** (xác nhận kết nối backend).
- Feed dọc, nút 3 gạch, drawer và 4 khu vực hiển thị đúng.
- Google OAuth được chặn rõ ràng khi provider chưa bật (xem tài liệu troubleshooting).
- **Bản release APK** cài trên emulator: trang ảnh Locket mở đúng, drawer chuyển trang hoạt động,
  icon status bar đổi theo nền sáng/tối, Google preflight hiển thị thông báo tiếng Việt và
  đăng nhập email sai nhận lỗi trực tiếp từ Supabase (APK kết nối backend bình thường).
- Bản **debug APK** sau đợt sửa camera, ngân sách và nhật ký ảnh build thành công
  (`build/app/outputs/flutter-apk/app-debug.apk`).

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

## ❓ Chưa xác minh trong môi trường phát triển này

- Nhận email đặt lại mật khẩu và deep link mở lại app (cần thiết bị + hộp thư thật).
- `updateUser(password:)` có bị Supabase đòi reauthentication hay không, tùy cấu hình project.
- Share sheet trên Android và cách từng app xử lý file `.csv` (cần thiết bị).
- Hiệu năng phân trang CSV khi > 5000 khoản chi (cần dữ liệu thật).
- `flutter build apk --debug` trên máy phát triển: chưa chạy được vì chưa có Android SDK/JDK;
  APK do workflow GitHub Actions build.

---

## 📄 Giấy phép

Dự án phát hành theo **MIT License**.
