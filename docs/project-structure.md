# Cấu trúc dự án Pixket (v2.3 — Pixel Journal)

> Cập nhật: 2026-11-01. Tài liệu phản ánh kiến trúc Cloud-only (Supabase), xác thực bắt buộc,
> giao diện Pixel tự vẽ (icon 16×16, panel viền cứng) và ảnh hóa đơn bucket private + signed URL.

## 1. Cây thư mục

```text
pixket/
├── assets/fonts/                        # VT323 + Be Vietnam Pro bundle offline (kèm OFL)
├── lib/
│   ├── main.dart                        # Entry point: dotenv, Supabase, SQLite, ProviderScope
│   ├── app.dart                         # MaterialApp, theme, onboarding/auth gate
│   ├── core/
│   │   ├── config/supabase_config.dart  # Đọc .env, khởi tạo Supabase, isInitialized
│   │   ├── constants/
│   │   │   ├── app_info.dart            # Tên "Pixket", version 2.3.0, build 4, tagline
│   │   │   └── app_strings.dart         # Nhãn cố định (mức độ cần thiết, v.v.)
│   │   ├── icons/pixel_glyph_data.dart  # Bảng glyph pixel 16×16 (chuỗi hàng + palette index)
│   │   ├── navigation/app_section.dart  # enum 4 khu vực: feed / dashboard / statistics / budget
│   │   ├── services/notification_service.dart
│   │   ├── theme/
│   │   │   ├── app_palette.dart         # AppPalette (ThemeExtension) — nguồn màu duy nhất
│   │   │   ├── app_theme.dart           # Sinh ThemeData từ AppPalette
│   │   │   └── pixel_text_theme.dart    # Scale chữ VT323 / Be Vietnam Pro
│   │   └── utils/
│   │       ├── amount_input_formatter.dart  # Dấu chấm nhóm nghìn, chặn ký tự lạ, ≤12 chữ số
│   │       ├── csv_builder.dart             # BOM UTF-8 + dòng CSV
│   │       ├── currency_formatter.dart      # format / parseInput / toEditableText
│   │       ├── date_formatter.dart          # dd/MM/yyyy, Hôm nay/Hôm qua + HH:mm
│   │       ├── expense_date_limits.dart     # Chặn tương lai và quá 10 năm
│   │       ├── icon_helper.dart             # normalizeIconKey, availableIcons → AppIcon
│   │       ├── pixel_allocate.dart          # Chia ô cho biểu đồ pixel
│   │       └── storage_paths.dart           # storagePathOf: URL public cũ → path trong bucket
│   ├── data/
│   │   ├── database/database_helper.dart    # SQLite: onboarding + mức độ cần thiết
│   │   ├── models/                          # Expense, Category, Budget, PriorityLevel
│   │   └── repositories/
│   │       ├── auth_repository.dart         # Email/Google OAuth + quên mật khẩu + preflight
│   │       ├── csv_export_service.dart      # Phân trang 1000 dòng, export file CSV
│   │       ├── expense_image_mapping.dart   # Đường dẫn ảnh ↔ storage path
│   │       ├── expense_repository.dart      # Chỉ Supabase, upload ảnh + signed URL
│   │       ├── expense_row_writer.dart      # Ghi dòng expenses (dùng chung cho import/export)
│   │       ├── category_repository.dart
│   │       ├── budget_repository.dart       # Chọn dòng ngân sách tổng mới nhất
│   │       ├── budget_alert_repository.dart
│   │       ├── app_settings_repository.dart # onboarding (SQLite)
│   │       ├── priority_repository.dart     # mức độ cần thiết (SQLite)
│   │       └── supabase_storage_service.dart
│   ├── providers/                             # Riverpod StateNotifier
│   │   ├── auth_provider.dart
│   │   ├── expense_provider.dart
│   │   ├── category_provider.dart
│   │   ├── budget_provider.dart
│   │   ├── statistics_provider.dart
│   │   ├── priority_provider.dart
│   │   ├── app_settings_provider.dart          # onboarding, theme + effectsProvider (6 khoá hiệu ứng)
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── main_screen.dart                   # Scaffold + Drawer + PixelTabBar + MosaicWipe 4 khu vực
│   │   ├── onboarding/                        # Onboarding 3 bước
│   │   ├── auth/                              # Login, Register, Quên mật khẩu, Đặt lại mật khẩu
│   │   ├── camera/
│   │   │   ├── camera_screen.dart             # Feed Locket: PageView dọc, camera ở trang 0
│   │   │   ├── expense_datetime_field.dart    # Chọn ngày giờ + nút "Bây giờ"
│   │   │   ├── expense_form_sheet.dart        # Nhập số tiền/danh mục/mức độ, lưu cloud
│   │   │   ├── feed_grid_screen.dart          # Lưới ảnh pixel, chạm để nhảy tới feed
│   │   │   ├── feed_helpers.dart              # Lọc ảnh + sắp xếp mới nhất trước
│   │   │   └── feed_photo_page.dart           # Trang ảnh toàn màn hình + HUD
│   │   ├── categories/
│   │   │   ├── category_glyph_grid.dart       # Lưới chọn icon pixel 48dp
│   │   │   └── manage_categories_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart               # Dashboard tổng quan
│   │   │   ├── dashboard_summary.dart         # Số hôm nay/tuần/tháng
│   │   │   ├── budget_progress_card.dart      # Thẻ tiến độ ngân sách
│   │   │   └── expense_filter_sheet.dart      # Lọc danh mục/mức độ/khoảng ngày
│   │   ├── statistics/
│   │   │   ├── statistics_screen.dart         # StatRange + PixelStatTile
│   │   │   └── statistics_charts.dart         # dailySeries + biểu đồ pixel
│   │   ├── budget/budget_screen.dart          # Ngân sách theo tháng (yyyy-MM)
│   │   ├── settings/
│   │   │   ├── settings_screen.dart           # 4 nhóm DỮ LIỆU/GIAO DIỆN & HIỆU ỨNG/TÀI KHOẢN/VỀ APP
│   │   │   └── csv_export_sheet.dart          # showCsvExportSheet
│   │   └── trash/trash_screen.dart            # Hàng khoản đã xóa + khôi phục
│   └── widgets/
│       ├── app_drawer.dart                    # Menu 3 gạch: hồ sơ + không gian + tiện ích
│       ├── hamburger_button.dart
│       └── pixel/                             # Bộ kit pixel dùng chung
│           ├── app_icon.dart                  # AppIcon + PixelIconButton (vùng chạm 48dp)
│           ├── feed_hud.dart                  # HUD tối cho camera/feed
│           ├── pixel_badge.dart, pixel_button.dart, pixel_chip.dart,
│           ├── pixel_dialog.dart, pixel_divider.dart, pixel_empty_state.dart,
│           ├── pixel_expense_tile.dart, pixel_glyph.dart, pixel_loading.dart,
│           ├── pixel_logo.dart, pixel_panel.dart, pixel_progress.dart,
│           ├── pixel_receipt_image.dart, pixel_screen_header.dart,
│           ├── pixel_segmented.dart, pixel_share_bar.dart, pixel_sheet.dart,
│           ├── pixel_snack_bar.dart, pixel_stacked_share.dart,
│           ├── pixel_stat_tile.dart, pixel_bar_chart.dart, pixel_text_field.dart,
│           ├── pixel_star_field.dart    # Nền sao (chỉ dark) + PixelStarSafe keep-out
│           ├── rainbow_rule.dart        # Dải cầu vồng 6 drawRect dưới header
│           ├── pixel_tab_bar.dart       # Tab bar đáy 4 khu vực
│           ├── rainbow_sweep.dart       # Vệt cầu vồng quét sau khi chụp
│           ├── pixel_confetti.dart      # Pháo giấy khi lưu khoản chi
│           └── mosaic_wipe.dart         # Lật lưới mosaic khi đổi khu vực
├── test/
│   ├── unit/                              # Model, formatter, state, palette, glyph, feed helper
│   └── widget/                            # Screen, kit pixel, drawer, gate dọn dẹp
├── docs/
│   ├── project-structure.md
│   ├── requirements.md
│   ├── supabase-keepalive.md
│   ├── brand/pixket_icon_1024.png
│   └── google-oauth-troubleshooting.md
├── .github/workflows/                     # keep-alive Supabase + build APK
├── android/                               # Manifest, quyền, OAuth deep link, icon pixel
├── supabase_setup.sql                     # Bảng + RLS + Storage bucket private
├── .env / .env.example                    # SUPABASE_URL, SUPABASE_ANON_KEY
└── pubspec.yaml
```

Widget cũ của nền Material/gradient (`glass_card`, `screen_background`, `expense_card`,
`category_icon_badge`, `category_chip`, `priority_badge`, `amount_display`, `app_colors`)
đã bị xóa; `test/widget/legacy_cleanup_test.dart` giữ gate để không quay lại.

## 2. Kiến trúc dữ liệu

```text
Screen / Widget
      ↓ ref.watch / ref.read
Riverpod StateNotifier
      ↓
Repository
      ↓
Supabase (bắt buộc đăng nhập)
      ↓
PostgreSQL + RLS + Storage bucket private `expense-receipts`
```

- **Cloud-only**: mọi thao tác đọc/ghi khoản chi, danh mục, ngân sách đều đi thẳng Supabase;
  không có fallback SQLite và không có đồng bộ thủ công.
- **Lỗi mạng**: repository ném `StateError`, UI hiển thị thông báo và không lưu dữ liệu.
- **Ảnh**: file tạm upload lên Storage ngay khi lưu; DB chỉ giữ storage path
  `<user_id>/<file>`; khi đọc, app xin **signed URL hạn 24h** rồi hiển thị qua
  `PixelReceiptImage`. Tệp tạm bị xóa sau khi lưu thành công hoặc khi hủy form.

## 3. Xác thực và điều hướng

```text
main() → SupabaseConfig.initialize() → PixketApp
                                        │
                        chưa hoàn tất onboarding?
                              ├── có → OnboardingScreen
                              └── không ↓
                      chưa đăng nhập?
                              ├── có → LoginScreen (email / Google / Quên mật khẩu)
                              └── không → MainScreen
```

- `AuthStatus`: `initial → loading → authenticated | unauthenticated | error`.
- Đăng nhập Google dùng OAuth trong trình duyệt hệ thống, quay về app qua deep link
  `io.supabase.pixket://login-callback/` (khai báo trong `android/app/src/main/AndroidManifest.xml`).
- Trước khi mở trình duyệt, `AuthRepository.isGoogleProviderEnabled()` gọi
  `GET /auth/v1/settings`; nếu `external.google = false`, app hiện thông báo ngay.
- Quên mật khẩu: `resetPasswordForEmail` (PKCE) → link đưa app về `ResetPasswordScreen`.
- Không có chế độ khách hay ngoại tuyến; khi đăng xuất, các provider dữ liệu được invalidate.

## 4. Điều hướng giao diện

`MainScreen` điều hướng bằng **`PixelTabBar` đáy** (4 khu vực: CHỤP/SỔ/BIỂU/NGÂN) cộng với
nút **3 gạch** pixel ở góc trên trái mỗi màn (`PixelScreenHeader`); các màn pushed dùng nút
back cùng glyph. Đổi khu vực thì `MosaicWipe` lật lưới (tắt mặc định, xem bảng hiệu ứng).

```text
MainScreen (Scaffold + Drawer + PixelTabBar + PixelStarField nền)
├── AppSection.feed        → CameraScreen (Locket PageView dọc, HUD tối)
├── AppSection.dashboard   → HomeScreen (nền kem + pastel pixel)
├── AppSection.statistics  → StatisticsScreen
└── AppSection.budget      → BudgetScreen

Drawer → push ManageCategoriesScreen / TrashScreen / SettingsScreen
```

### Locket feed

- `PageView.builder` theo chiều dọc; trang 0 là camera trực tiếp.
- Trang 1..n: các khoản chi có ảnh, mới nhất trước (`buildFeedPhotos`).
- Sau khi lưu khoản chi mới, feed tự cuộn tới ảnh vừa tạo.
- Nút lưới ở góc phải mở `FeedGridScreen`; chạm ảnh để nhảy tới đúng trang trong feed.
- Ảnh chỉ render qua `PixelReceiptImage`; ảnh lỗi/thiếu hiện placeholder "Không tải được ảnh".
- Xóa khoảnh khắc hiện snackbar hoàn tác 5 giây; snackbar cũ được ẩn trước khi hiện cái mới.
- Chuyển camera trước/sau giải phóng `CameraController` cũ trước khi khởi tạo camera mới,
  có rollback nếu camera mới không mở được.

### Ngôn ngữ giao diện Pixel

- `AppPalette` (ThemeExtension) là nguồn màu duy nhất: sáng = nền kem `0xFFFFF6E3` + mint
  `0xFF7BD8A8`; tối = nền mực ấm; feed/camera dùng `feedBg`/`feedPanel` tối.
- Mọi ảnh/icon do app tự vẽ: `AppIcon` đọc bảng glyph 16×16 trong `pixel_glyph_data.dart`,
  vẽ bằng `CustomPainter`; không dùng `Icons.*` hay emoji.
- `PixelPanel` viền cứng 2–3px, bóng lệch `(3,4)` không blur; `PixelButton`/`PixelChip`/
  `PixelIconButton` có vùng chạm ≥ 48dp.
- Tiêu đề và số dùng VT323, chữ nội dung dùng Be Vietnam Pro (bundle trong `assets/fonts/`).

### Hiệu ứng thương hiệu

6 khoá lưu trong bảng `app_settings` (SQLite) qua `effectsProvider`
(`lib/providers/app_settings_provider.dart`), bật/tắt ở **Cài đặt → GIAO DIỆN & HIỆU ỨNG**.
Mọi hiệu ứng vẽ bậc rời (`floor`, không tween mượt), `isAntiAlias: false`, seed `20261102`,
và tôn trọng `MediaQuery.disableAnimations` (giảm bậc nhưng vẫn hoàn tất, callback chạy đúng
một lần). DB lỗi thì về mặc định, không crash.

| Khoá | Mặc định | Widget | Nội dung |
|---|---|---|---|
| `fx_stars` | bật (chỉ dark) | `pixel_star_field.dart` | Nền sao 1 ô/3600px², nhấp nháy 1400 ms; `PixelStarSafe` khai báo vùng keep-out (nở 4 px) cho header/panel |
| `fx_rainbow_rule` | bật | `rainbow_rule.dart` | Dải 6 `drawRect` màu phẳng dưới header, trượt một lần 1600 ms/14 bậc |
| `fx_capture_sweep` | bật | `rainbow_sweep.dart` | Vệt cầu vồng nghiêng −12° quét 660 ms sau khi chụp; `onCovered` ở bậc che kín để mở form |
| `fx_confetti` | bật | `pixel_confetti.dart` | 24 ô 4×4 nổ 480 ms khi lưu khoản chi, gắn vào root overlay |
| `fx_mosaic` | **tắt** | `mosaic_wipe.dart` | Lưới 8×14 lật 260 ms khi đổi khu vực, đổi con ở mốc 0.5 |
| `chart_spend_ramp` | bật | `pixel_progress/pixel_bar_chart/pixel_share_bar/pixel_stacked_share` | Tô theo bậc `rampFill(value/mốc)`; mốc = max của kỳ đang xem (progress = hạn mức). Luôn kèm nhãn chữ `rampLabel` (WCAG 1.4.1) |

## 5. Bảng dữ liệu

### SQLite

Chỉ dùng cho tùy chọn cục bộ, không chứa dữ liệu tài chính:

| Bảng | Nội dung |
| --- | --- |
| `priority_levels` | Danh sách mức độ cần thiết (seed mặc định) |
| `app_settings` | Trạng thái onboarding |

### Supabase PostgreSQL

| Bảng / bucket | Nội dung |
| --- | --- |
| `profiles` | Hồ sơ người dùng, tạo tự động bằng trigger |
| `categories` | Danh mục theo `user_id` |
| `expenses` | Khoản chi theo `user_id`, ảnh là đường dẫn trong bucket |
| `budgets` | Ngân sách theo `user_id` và tháng; mỗi tháng một dòng tổng (`category_id IS NULL`) nhờ unique index `uniq_budgets_total_per_month` |
| `budget_alerts` | Đánh dấu đã gửi cảnh báo 80/90/100% theo tháng |
| `expense-receipts` | Storage bucket **private** chứa ảnh hóa đơn |

> Bản cũ dùng `upsert` cho ngân sách tổng nên có thể sinh nhiều dòng trùng.
> Repository hiện chọn dòng mới nhất, dọn dòng trùng khi lưu và xóa toàn bộ khi đặt ngân sách về 0.
> Với database đã tạo trước bản này, chạy lại phần `budgets` trong `supabase_setup.sql`
> để dọn dữ liệu cũ và tạo unique index.

## 6. Kiểm thử

```bash
flutter analyze          # No issues found!
flutter test             # 369/369 passed
```

- Unit: model, formatter VND/ngày, giới hạn ngày khoản chi, parse số có dấu nghìn,
  `AppPalette`/glyph pixel, `resolveReceiptImage`, storage path, state ngân sách/thống kê/auth,
  builder CSV.
- Widget: onboarding/login/register/forgot password, dashboard, form khoản chi, camera/feed/grid,
  ảnh feed, thống kê, ngân sách, danh mục, thùng rác, cài đặt, `AppDrawer`, kit pixel và
  `legacy_cleanup_test` (gate dọn dẹp).
- Test độ bền hiển thị: mỗi màn có case text scale 1.3× và/hoặc viewport hẹp 360dp;
  test vùng chạm 48dp cho icon, chip, ô glyph, expense tile.
- Đã xác minh trên emulator `codex_api35` (Android API 35) ở các bản trước:
  onboarding → login → email sai trả lỗi từ Supabase → feed Locket → drawer.
- **Chưa** xác minh lại bằng tay sau đợt redesign Pixel: màn hình thật, camera, keyboard inset,
  signed URL, share sheet CSV (xem mục "Chưa xác minh trên thiết bị" của README).
- `flutter build apk --debug` trên máy phát triển này báo `No Android SDK found`;
  APK release do workflow GitHub Actions build.

## 7. Lưu ý khi nâng cấp

1. Giữ nguyên scheme/host deep link nếu đổi package Android; cập nhật đồng thời Supabase Redirect URLs.
2. Không commit `.env`; chỉ commit `.env.example`.
3. Nếu thêm provider OAuth mới, cập nhật preflight trong `auth_repository.dart` và tài liệu troubleshooting.
4. Nếu đổi cấu trúc bảng, cập nhật cả `database_helper.dart`, `supabase_setup.sql` và model `toMap/fromMap`.
5. Cảnh báo ngân sách nối với `NotificationService` ở các mốc 80/90/100% và được đánh dấu
   trong bảng `budget_alerts`; kiểm tra quyền thông báo nếu không nhận được.
6. Database tạo trước v2.2 cần chạy phần dọn dữ liệu + unique index của `budgets` trong
   `supabase_setup.sql`.
7. Thêm icon mới: vẽ glyph trong `pixel_glyph_data.dart` (kích thước vẽ là bội số 16),
   rồi đăng ký key trong `IconHelper.availableIcons`; không quay lại `Icons.*`.
8. Màu mới: thêm token vào `AppPalette` cho cả light và dark, không hard-code hex trong widget.
9. Phiên bản app chỉ đổi ở `AppInfo` và `pubspec.yaml` (gate test bắt hai nơi khớp nhau).
