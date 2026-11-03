# Cấu trúc dự án Pixket (v2.5 — Pixel Journal)

> Cập nhật: 2026-11-03. Tài liệu phản ánh kiến trúc Cloud-only (Supabase), xác thực bắt buộc,
> giao diện Pixel tự vẽ (icon 16×16 phong cách tàu vũ trụ, panel viền cứng), điều hướng
> full-screen bằng drawer/vuốt ngang và ảnh hóa đơn bucket private + signed URL.

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
│   │   │   ├── app_info.dart            # Tên "Pixket", version 2.5.1, build 7, tagline
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
│   │       ├── currency_formatter.dart      # format / parseInput / toEditableText
│   │       ├── date_formatter.dart          # dd/MM/yyyy, Hôm nay/Hôm qua + HH:mm
│   │       ├── expense_date_limits.dart     # Chặn tương lai và quá 10 năm
│   │       ├── icon_helper.dart             # normalizeIconKey, availableIcons → AppIcon
│   │       ├── pixel_allocate.dart          # Chia ô cho biểu đồ pixel
│   │       ├── save_to_gallery.dart         # Tải ảnh khoản chi về thư viện máy (gal)
│   │       ├── square_image.dart            # Cắt ô vuông 1:1 + nén JPEG 1200px + marker _sq
│   │       └── storage_paths.dart           # storagePathOf: URL public cũ → path trong bucket
│   ├── data/
│   │   ├── database/database_helper.dart    # SQLite: onboarding + mức độ cần thiết
│   │   ├── models/                          # Expense, Category, Budget, PriorityLevel
│   │   └── repositories/
│   │       ├── auth_repository.dart         # Email/Google OAuth + quên mật khẩu + preflight
│   │       ├── expense_image_mapping.dart   # Đường dẫn ảnh ↔ storage path
│   │       ├── expense_repository.dart      # Supabase: upload ảnh vuông, signed URL, migration lazy ảnh legacy
│   │       ├── expense_row_writer.dart      # Ghi dòng expenses + repointImage khi đổi path ảnh
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
│   │   ├── app_settings_provider.dart          # onboarding, theme + effectsProvider (chỉ còn chart_spend_ramp)
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── main_screen.dart                   # Drawer + starfield + vuốt ngang, fade/scale 4 khu vực
│   │   ├── onboarding/                        # Onboarding 3 bước
│   │   ├── auth/                              # Login, Register, Quên mật khẩu, Đặt lại mật khẩu
│   │   ├── camera/
│   │   │   ├── camera_screen.dart             # Feed Locket: PageView dọc, camera ở trang 0
│   │   │   ├── expense_datetime_field.dart    # Chọn ngày giờ + nút "Bây giờ"
│   │   │   ├── expense_form_sheet.dart        # Nhập số tiền/danh mục/mức độ, lưu cloud
│   │   │   ├── feed_grid_screen.dart          # Lưới ảnh pixel, chạm để nhảy tới feed
│   │   │   ├── feed_helpers.dart              # Lọc ảnh + sắp xếp mới nhất trước
│   │   │   └── feed_photo_page.dart           # Ảnh vuông 1:1 + panel thông tin bên dưới
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
│   │   │   └── settings_screen.dart           # 4 nhóm DỮ LIỆU/GIAO DIỆN & BIỂU ĐỒ/TÀI KHOẢN/VỀ APP
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
│           ├── pixel_star_field.dart    # Nền sao (chỉ dark): nhấp nháy + trôi + sao băng, PixelStarSafe keep-out
│           ├── pixel_iris.dart          # Ống kính pixel khép–mở khi chụp, onCovered mở form
│           └── pixel_star_flash.dart    # 5 sao pixel lóe rồi tan tại nút lưu
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

`MainScreen` **không có thanh tab đáy**: 4 khu vực (CHỤP/SỔ/BIỂU/NGÂN) chuyển qua
**drawer** mở bằng nút 3 gạch pixel ở góc trên trái mỗi màn (`PixelScreenHeader`) hoặc
bằng **vuốt ngang**. Ở khu vực CHỤP, vuốt ngang chỉ bắt trong dải mép trái 24 px
(`ValueKey('edge-swipe-area')`) để không tranh cử chỉ với `PageView` dọc của feed;
ba khu vực còn lại nhận vuốt ở toàn màn. Ngưỡng mở drawer: tổng `dx` > 40 px hoặc
`primaryVelocity` > 180. Các màn pushed dùng nút back cùng glyph.

```text
MainScreen (Scaffold + Drawer + PixelStarField nền, không bottomNavigationBar)
├── AnimatedSwitcher fade + scale 0.98→1, 180 ms (Duration.zero khi giảm chuyển động)
│   ├── AppSection.feed        → CameraScreen (Locket PageView dọc, HUD tối)
│   ├── AppSection.dashboard   → HomeScreen (nền trong suốt để sao lộ ra)
│   ├── AppSection.statistics  → StatisticsScreen
│   └── AppSection.budget      → BudgetScreen
└── Drawer (chọn khu vực + tiện ích, nền sao, mục chọn viền mint + glow)
    → push ManageCategoriesScreen / TrashScreen / SettingsScreen
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
- Mọi ảnh/icon do app tự vẽ: `AppIcon` đọc bảng **63 glyph 16×16** trong
  `pixel_glyph_data.dart` (bảng ký tự `.#kw1-6`), vẽ bằng `CustomPainter`; không dùng
  `Icons.*` hay emoji. Glyph khu vực và tiện ích vẽ theo bảng điều khiển tàu vũ trụ
  (`holocam`, `bridge`, `radar`, `cargo`, `console`, `airlock`, `engine`), mỗi glyph ≥ 3 màu.
- `PixelLogo` là mark "Lens Orbit" dựng thủ tục bằng `buildLogoGrid(n)`: vành ống kính khía
  sáu rãnh, quỹ đạo nghiêng `-26°`, vì sao vàng bốn cánh giữa ống kính, hành tinh lục ngồi
  trên mép vành và sao nền `*` chỉ vẽ ở theme tối (`logoCellColor`). Hằng số đo trên lưới
  chuẩn 24×24 rồi nhân theo `n / 24`, với `n = logoGridSize(size)` làm tròn xuống bội số 8,
  nên cùng một nét ở header 24 dp, drawer 40 dp và launcher 192 px. Icon launcher Android và
  `docs/brand/pixket_icon_1024.png` được sinh lại từ chính logo này
  (`test/tool/launcher_icons_test.dart`, chạy với `PIXKET_GEN_ICONS=1`).
- Ảnh demo trong `docs/screenshots/` cũng do test sinh:
  `test/tool/demo_screenshots_test.dart`, chạy với `PIXKET_GEN_SHOTS=1`, render
  6 màn bằng widget thật nên không cần thiết bị.
- `PixelPanel` viền cứng 2–3px, bóng lệch `(3,4)` không blur; `PixelButton`/`PixelChip`/
  `PixelIconButton` có vùng chạm ≥ 48dp.
- Tiêu đề và số dùng VT323, chữ nội dung dùng Be Vietnam Pro (bundle trong `assets/fonts/`).

### Hiệu ứng thương hiệu

Không còn khoá bật/tắt cho hiệu ứng chuyển động: sao, iris và sao lóe **luôn bật**;
chỉ `chart_spend_ramp` còn là toggle, lưu trong bảng `app_settings` (SQLite) qua
`effectsProvider` (`lib/providers/app_settings_provider.dart`) và bật/tắt ở
**Cài đặt → GIAO DIỆN & BIỂU ĐỒ**. Mọi hiệu ứng vẽ bậc rời (`floor`, không tween mượt),
`isAntiAlias: false`, seed cố định (`20261102` cho sao, `20261103` cho sao lóe), và tôn
trọng `MediaQuery.disableAnimations` (rút duration/giảm bậc nhưng vẫn hoàn tất, callback
chạy đúng một lần). DB lỗi thì về mặc định, không crash.

| Hiệu ứng | Widget | Nội dung |
|---|---|---|
| Bầu trời sao (chỉ theme dark) | `pixel_star_field.dart` | 1 ô / 2200 px² (tối đa 220 ô): 62% ô 2 px + 38% ô 4 px, 10% nhuốm `palette.star`, 20% nhấp nháy chu kỳ 1400 ms; trôi theo sin ±3/±2 px chu kỳ 30 s; một sao băng (đầu 4 px + 6 ô đuôi 2 px, alpha tam giác) dài ~1,8 s mỗi chu kỳ; `PixelStarSafe` báo vùng keep-out (nở 4 px). Đặt ở màn chính, drawer, `PixelSheet`, login/onboarding, thùng rác, danh mục, lưới ảnh và toàn trang xem ảnh (một field full-bleed làm nền quanh ảnh vuông, một field riêng trong panel dưới) |
| Chụp ảnh | `pixel_iris.dart` | 4 góc pixel khép (easeIn) rồi mở (easeOut) trong 260 ms, bọc `RepaintBoundary`; `onCovered` bắn ở mốc 0.5 và được gọi lại khi animation hoàn tất nên form mở đúng một lần |
| Lưu khoản chi | `pixel_star_flash.dart` | 5 sao 4 cánh nở nhanh–tan chậm 350 ms (120 ms khi reduced motion) tại toạ độ nút lưu, gắn root overlay + `IgnorePointer`; kèm toast "Đã lưu khoản chi." |
| Đổi khu vực | `main_screen.dart` | `AnimatedSwitcher` fade + scale 0.98→1, 180 ms, easeOut/easeIn, `Duration.zero` khi reduced motion; child key theo khu vực nên chuyển cảnh hủy được giữa chừng |
| `chart_spend_ramp` (toggle) | `pixel_progress`/`pixel_bar_chart`/`pixel_share_bar`/`pixel_stacked_share` | Tô theo bậc `rampFill(value/mốc)`; mốc = max của kỳ đang xem (progress = hạn mức). Luôn kèm nhãn chữ `rampLabel` (WCAG 1.4.1) |

> Đã gỡ hoàn toàn `rainbow_rule.dart`, `rainbow_sweep.dart`, `pixel_confetti.dart`,
> `mosaic_wipe.dart`, `pixel_tab_bar.dart` và 5 khoá `fx_*`; `legacy_cleanup_test.dart`
> chốt không cho thêm lại.

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
flutter test             # 372 passed, 7 skip (test sinh icon + 6 test sinh ảnh demo,
                         # cần PIXKET_GEN_ICONS=1 / PIXKET_GEN_SHOTS=1)
```

- Unit: model, formatter VND/ngày, giới hạn ngày khoản chi, parse số có dấu nghìn,
  `AppPalette`/glyph pixel, `resolveReceiptImage`, storage path, cắt ảnh vuông + migration,
  tải ảnh về máy, state ngân sách/thống kê/auth.
- Widget: onboarding/login/register/forgot password, dashboard, form khoản chi, camera/feed/grid,
  ảnh feed, thống kê, ngân sách, danh mục, thùng rác, cài đặt, `AppDrawer`,
  `main_navigation_test` (không tab bar đáy, đổi khu vực qua drawer, vuốt mép mở drawer,
  sao chỉ hiện ở theme tối), hiệu ứng `PixelIris`/`PixelStarFlash`/`PixelStarField`, kit pixel
  và `legacy_cleanup_test` (gate dọn dẹp).
- Test độ bền hiển thị: mỗi màn có case text scale 1.3× và/hoặc viewport hẹp 360dp;
  test vùng chạm 48dp cho icon, chip, ô glyph, expense tile.
- Đã xác minh trên emulator `codex_api35` (Android API 35) ở các bản trước:
  onboarding → login → email sai trả lỗi từ Supabase → feed Locket → drawer.
- **Chưa** xác minh lại bằng tay sau đợt redesign Pixel: màn hình thật, camera, keyboard inset,
  signed URL, cắt vuông khi chụp và tải ảnh vào thư viện máy (xem mục "Chưa xác minh trên thiết
  bị" của README).
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
