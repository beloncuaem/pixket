# Pixel Screen Redesign Implementation Plan (4/4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vẽ lại toàn bộ 14 màn hình của app Chi Tiêu theo ngôn ngữ Pixel đã chốt ở plan nền tảng, thay `fl_chart` bằng biểu đồ pixel tự vẽ, xoá hết widget glassmorphism + `AppColors`, và phủ state rỗng / lỗi / tải cho từng màn.

**Architecture:** Màn hình chỉ còn là assembly của component kit `lib/widgets/pixel/*`; mọi màu đi qua `context.palette` (ThemeExtension), mọi icon đi qua `AppIcon(name:)`. Ảnh hóa đơn tập trung vào một widget duy nhất `PixelReceiptImage` dùng `displayImageUrl` + `cacheKey` mà plan 1 đã định nghĩa. Biểu đồ tách thành helper thuần `lib/core/utils/pixel_allocate.dart` (phân bổ ô theo largest remainder) để unit test không cần render, widget chart chỉ vẽ. `home_screen.dart` (1142 dòng) được tách thành 3 file theo trách nhiệm.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13.5, Riverpod 2.6.1, `intl`, `cached_network_image` 3.4.1, `flutter_test`. **Không thêm dependency mới.** Bỏ `fl_chart` và `google_fonts`.

**Spec:** `docs/superpowers/specs/2026-11-01-chi-tieu-pixel-redesign-design.md` — mục 3.6 (biểu đồ), 3.7 (feed/camera), 3.8 (chuyển động), 3.9 (accessibility), 5.1–5.12 (thiết kế từng màn), 6 (state rỗng/lỗi/tải), 8 (kiểm thử), 9 (rủi ro).

**Kế hoạch trước (phải xong trước khi chạy plan này):**
1. `docs/superpowers/plans/2026-11-01-cloud-signed-url-keepalive.md` — `Expense.displayImageUrl`, `storagePathOf`, xoá object theo path.
2. `docs/superpowers/plans/2026-11-01-pixel-foundation.md` — `AppPalette`, `AppTheme.light`/`AppTheme.dark`, glyph registry + `AppIcon`, component kit `lib/widgets/pixel/*`, `AppInfo`, drawer/`AppSection` pixel.
3. `docs/superpowers/plans/2026-11-01-chi-tieu-features.md` — `ThousandsSeparatorInputFormatter`, `CurrencyFormatter.parseInput/toEditableText`, `ExpenseDateLimits`, `ExpenseDateTimeField`, quên mật khẩu, `CsvBuilder`/`CsvExportService`.

**Gate bắt buộc trước khi bắt đầu Task 1** (chạy và dán output vào báo cáo):

```bash
export PATH="$PATH:/c/flutter/bin"
flutter pub get
grep -c "class AppPalette" lib/core/theme/app_palette.dart
grep -c "class AppIcon" lib/widgets/pixel/app_icon.dart
ls lib/widgets/pixel/ | wc -l
grep -rn "displayImageUrl" lib/data/models/expense.dart | head -3
grep -rn "ThousandsSeparatorInputFormatter" lib/core/utils/amount_input_formatter.dart | head -2
flutter analyze
flutter test
```

Expected: mỗi `grep -c` trả `1`, `ls | wc -l` = **16** (plan 2 tạo đúng 16 file trong `lib/widgets/pixel/`), hai grep sau có kết quả, `flutter analyze` không issue, `flutter test` PASS với tổng số **lớn hơn 69** (69 là mốc repo gốc trước mọi plan; plan 1–3 đã thêm test nên con số thật cao hơn — **ghi lại đúng số thực tế làm mốc tính net của plan 4**). Nếu bất kỳ điều kiện nào fail → **dừng, không sửa chồng lên**, hoàn tất plan tương ứng trước.

## Global Constraints

- **Mọi flutter command phải có** `export PATH="$PATH:/c/flutter/bin"` trước (SDK ở `C:\flutter`, không có trên PATH của Git Bash).
- **Không dùng `AppColors` trong code mới.** Màu chỉ lấy từ `context.palette` (`AppPalette`). Task 14 xoá hẳn `AppColors`.
- **Không dùng `Icons.*` (Material icon) và không dùng emoji làm icon** trong code mới; mọi icon là `AppIcon(name: '<glyph>')`.
- **Không thêm glyph mới.** Plan 4 chỉ được dùng 55 khóa đã có sau plan 2:
  - fallback: `label`
  - điều hướng/UI (33): `menu, close, back, chevronRight, chevronDown, plus, minus, check, edit, trash, search, filter, calendar, clock, refresh, undo, eye, eyeOff, mail, lock, logout, user, sun, moon, alert, info, settings, cloud, cloudOff, grid, share, download, sparkle`
  - danh mục (19): `forkKnife, coffee, car, shoppingBag, receipt, gameController, heartbeat, graduationCap, house, airplaneTilt, gift, pawPrint, barbell, filmStrip, tShirt, deviceMobile, bank, wallet, dotsThreeOutline`
  - shell (3): `camera, chart, tag`
  Nếu một màn cần hình chưa có → **dùng khóa gần nhất trong danh sách trên**, không mở rộng registry (registry là của plan 2).
- **Kích thước glyph chỉ dùng bội số 16 logical px** (lưới `PixelGlyph` 16×16): **16 / 32 / 48**, hero onboarding dùng 64. Cấm 12/18/20/24/28/36/56 vì lưới 16 ô không chia đều → pixel lem.
- **Không dùng `fl_chart`** từ Task 10; dependency bị gỡ ở Task 10 bằng `flutter pub remove fl_chart`.
- **Vùng chạm ≥ 48×48 dp, khoảng cách ≥ 8 dp**: mọi nút icon-only phải là `PixelIconButton`/`PixelButton` (đã 48dp) hoặc được bọc `SizedBox(width: 48, height: 48)`. Mỗi task UI có test assert điều này.
- **Chữ không dựa riêng vào màu**: mức độ ưu tiên, quá ngân sách, danh mục hệ thống đều phải có nhãn chữ (`AppPalette.priorityLabel`, "QUÁ NGÂN SÁCH", "MẶC ĐỊNH").
- **Ảnh trong feed không bị filter/pixelate** (spec §3.7): chỉ HUD và panel caption được sơn pixel; `PixelReceiptImage` không áp `ColorFiltered`, không đổi `filterQuality`.
- **Text scale 1.3×**: số tiền hero và tiêu đề VT323 bọc `FittedBox(fit: BoxFit.scaleDown)`; mỗi task màn chính có test `MediaQuery(textScaleFactor: 1.3)`.
- **Giữ nguyên hành vi nghiệp vụ**: soft delete + hoàn tác (`expenseProvider.deleteExpense` / `restoreExpense`), filter, đổi tháng ngân sách, luồng camera, validate form. Plan 4 chỉ đổi cách hiển thị; nếu phải sửa logic để test được thì tách helper thuần, không đổi semantics.
- **Không gọi mạng/Supabase trong test.** Widget test màn hình dùng `provider.overrideWith` với notifier giả theo idiom có sẵn trong `test/widget/screens_test.dart` (`class _FakeXNotifier extends StateNotifier<S> implements XNotifier { @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i); }`).
- **Không commit, push, merge, tạo PR** khi chưa được người dùng ủy quyền rõ. Mỗi task ghi bước commit là "khi được ủy quyền".
- **Không in nội dung `.env`**, không để lộ anon key, không dùng `service_role`.
- **Trả lời/tài liệu bằng tiếng Việt**, giữ thuật ngữ kỹ thuật tiếng Anh. Nhãn UI tiếng Việt, uppercase cho nhãn VT323 ngắn (`LƯU KHOẢN CHI`, `QUÁ NGÂN SÁCH`).
- **Thay đổi tối thiểu ngoài phạm vi redesign**: không refactor repository/provider/model, không sửa SQL, không đụng GitHub workflow.
- **Mọi test phải đi trước code** (TDD): viết test → chạy thấy fail đúng thông báo → implement → chạy thấy pass → `flutter analyze` sạch → rồi mới sang task kế.
- **Số lượng test không được giảm.** Cuối mỗi task ghi `flutter test` total. Plan 4 thêm 91 test (Task 1:8, 2:4, 3:18, 4:6, 5:8, 6:4, 7:5, 8:3, 9:5, 10:6, 11:6, 12:6, 13:7, 14:5) và xóa 10 test widget cũ ở Task 14 → **net +81**; cuối plan số test phải ≥ baseline + 75.
- **Không được để lỗi analyze/test/build "cho xong"**; sửa hoặc dừng và báo rõ.

## File Structure

**Tạo mới (component dùng chung)**
| File | Trách nhiệm |
| --- | --- |
| `lib/widgets/pixel/pixel_receipt_image.dart` | Một chỗ duy nhất render ảnh khoản chi (file tạm / signed URL / placeholder + THỬ LẠI) |
| `lib/widgets/pixel/pixel_screen_header.dart` | Header chung cho dashboard/statistics/budget/categories/trash/settings: hamburger 48dp + title VT323 + subtitle + trailing |
| `lib/widgets/pixel/pixel_expense_tile.dart` | Dòng khoản chi trong danh sách + `Dismissible` xóa mềm |
| `lib/core/utils/pixel_allocate.dart` | Helper thuần: phân bổ ô theo largest remainder, `%`, làm thưa nhãn trục |
| `lib/widgets/pixel/pixel_share_bar.dart` | Một hàng "tỉ trọng": badge + tên + thanh khối + số tiền + % |
| `lib/widgets/pixel/pixel_stacked_share.dart` | 4 khối mức độ xếp theo tỉ lệ + legend chữ |
| `lib/widgets/pixel/pixel_bar_chart.dart` | Bar chart pixel theo ngày + chạm hiện tooltip panel |

**Tạo mới (màn hình)**
| File | Trách nhiệm |
| --- | --- |
| `lib/screens/home/dashboard_summary.dart` | Hero "CHI THÁNG NÀY" + `PixelProgress` segmented + 3 `PixelStatTile` |
| `lib/screens/home/budget_progress_card.dart` | Panel tiến độ ngân sách tháng, nhãn QUÁ NGÂN SÁCH |
| `lib/screens/home/expense_filter_sheet.dart` | `ExpenseFilter` (public) + `ExpenseFilterSheet` pixel |
| `lib/screens/statistics/statistics_charts.dart` | Assembly 3 panel biểu đồ từ widget pixel |
| `lib/screens/categories/category_glyph_grid.dart` | Lưới 19 glyph chọn icon danh mục |

**Sửa (màn chính)**
`lib/screens/onboarding/onboarding_screen.dart`, `lib/screens/auth/login_screen.dart`, `lib/screens/auth/register_screen.dart`, `lib/screens/home/home_screen.dart`, `lib/screens/camera/expense_form_sheet.dart`, `lib/screens/camera/camera_screen.dart`, `lib/screens/camera/feed_grid_screen.dart`, `lib/screens/camera/feed_photo_page.dart`, `lib/screens/statistics/statistics_screen.dart`, `lib/screens/budget/budget_screen.dart`, `lib/screens/categories/manage_categories_screen.dart`, `lib/screens/trash/trash_screen.dart`, `lib/screens/settings/settings_screen.dart`.

**Sửa (nền tảng, chỉ để gỡ dependency / version)**
`pubspec.yaml` (Task 10, 14), `lib/core/navigation/app_section.dart` (không đổi — chỉ verify), `docs/project-structure.md`, `docs/requirements.md`, `README.md`.

**Xoá (Task 14)**
`lib/widgets/glass_card.dart`, `lib/widgets/screen_background.dart`, `lib/widgets/category_icon_badge.dart`, `lib/widgets/expense_card.dart`, `lib/widgets/priority_badge.dart`, `lib/widgets/category_chip.dart`, `lib/widgets/amount_display.dart`, `lib/core/constants/app_colors.dart` và các group test tương ứng trong `test/widget/widgets_test.dart`, `test/unit/auth_and_supabase_test.dart`.

**Test mới**
`test/unit/pixel_receipt_image_test.dart`, `test/unit/pixel_allocate_test.dart`, `test/widget/pixel_receipt_image_test.dart`, `test/widget/pixel_expense_tile_test.dart`, `test/widget/pixel_charts_test.dart`, `test/widget/onboarding_login_test.dart`, `test/widget/dashboard_pixel_test.dart`, `test/widget/filter_sheet_test.dart`, `test/widget/expense_form_pixel_test.dart`, `test/widget/feed_hud_test.dart`, `test/widget/feed_photo_test.dart`, `test/widget/statistics_pixel_test.dart`, `test/widget/budget_pixel_test.dart`, `test/widget/categories_pixel_test.dart`, `test/widget/trash_settings_pixel_test.dart`, `test/widget/legacy_cleanup_test.dart`.

---

### Task 1: `PixelReceiptImage` — một chỗ duy nhất render ảnh khoản chi

**Files:**
- Create: `lib/widgets/pixel/pixel_receipt_image.dart`
- Create: `test/unit/pixel_receipt_image_test.dart`
- Create: `test/widget/pixel_receipt_image_test.dart`

**Interfaces:**
- Consumes: `AppIcon` (plan 2 Task 5), `context.palette` (Task 2), `storagePathOf` + `Expense.displayImageUrl` (plan 1 Task 1 & 3), `cached_network_image`.
- Produces:
  - `enum ReceiptImageSource { signedUrl, localFile, none }`
  - `({ReceiptImageSource source, String? url, String? localPath, String? cacheKey}) resolveReceiptImage({String? imagePath, String? displayImageUrl})` — pure, không đụng `dart:io`
  - `class PixelReceiptImage extends StatelessWidget { const PixelReceiptImage({Key? key, String? localPath, String? displayUrl, String? cacheKey, double? width, double? height, BoxFit fit = BoxFit.cover, String? semanticLabel, double radius = 12, VoidCallback? onTap}); }`
  - `PixelReceiptImage.fromExpense(Expense expense, {double? width, double? height, String? semanticLabel, BoxFit fit, VoidCallback? onTap})`
  - `Widget receiptPlaceholder({double size = 32})` — dùng lại cho grid/feed khi ảnh lẻ lỗi

- [ ] **Step 1: Viết test pure failing**

Tạo `test/unit/pixel_receipt_image_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/widgets/pixel/pixel_receipt_image.dart';

void main() {
  group('resolveReceiptImage', () {
    test('uu tien signed URL khi co', () {
      final r = resolveReceiptImage(
        imagePath: 'uuid/a.png',
        displayImageUrl: 'https://x/signed/a.png',
      );
      expect(r.source, ReceiptImageSource.signedUrl);
      expect(r.url, 'https://x/signed/a.png');
      expect(r.cacheKey, 'uuid/a.png');
      expect(r.localPath, isNull);
    });

    test('duong dan local la file tam khi chua upload xong', () {
      final r = resolveReceiptImage(imagePath: '/data/user/0/tmp/IMG_1.jpg');
      expect(r.source, ReceiptImageSource.localFile);
      expect(r.localPath, '/data/user/0/tmp/IMG_1.jpg');
      expect(r.url, isNull);
      expect(r.cacheKey, isNull);
    });

    test('URL cu khong co chu ky thi van la localFile duong dan', () {
      final r = resolveReceiptImage(
        imagePath: 'https://old.public/uuid/b.png',
      );
      expect(r.source, ReceiptImageSource.none);
      expect(r.url, isNull);
    });

    test('khong co anh thi none', () {
      expect(resolveReceiptImage().source, ReceiptImageSource.none);
      expect(
        resolveReceiptImage(imagePath: '', displayImageUrl: null).source,
        ReceiptImageSource.none,
      );
    });
  });
}
```

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/unit/pixel_receipt_image_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../pixel_receipt_image.dart'`.

- [ ] **Step 2: Implement helper pure + widget**

Tạo `lib/widgets/pixel/pixel_receipt_image.dart`:

```dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/storage_paths.dart';
import '../../data/models/expense.dart';
import 'app_icon.dart';

enum ReceiptImageSource { signedUrl, localFile, none }

typedef ReceiptImageTarget = ({
  ReceiptImageSource source,
  String? url,
  String? localPath,
  String? cacheKey,
});

ReceiptImageTarget resolveReceiptImage({
  String? imagePath,
  String? displayImageUrl,
}) {
  if (displayImageUrl != null && displayImageUrl.isNotEmpty) {
    return (
      source: ReceiptImageSource.signedUrl,
      url: displayImageUrl,
      localPath: null,
      cacheKey: storagePathOf(imagePath),
    );
  }
  final path = imagePath;
  if (path != null && path.isNotEmpty && !path.startsWith('http')) {
    return (
      source: ReceiptImageSource.localFile,
      url: null,
      localPath: path,
      cacheKey: null,
    );
  }
  return (
    source: ReceiptImageSource.none,
    url: null,
    localPath: null,
    cacheKey: null,
  );
}

/// Ô placeholder chung cho mọi ảnh lỗi/thiếu trong app.
Widget receiptPlaceholder({double size = 32}) {
  return Builder(
    builder: (context) {
      final palette = context.palette;
      return ColoredBox(
        color: palette.surfaceAlt,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(name: 'cloudOff', size: size, color: palette.inkMuted),
              const SizedBox(height: 6),
              Text(
                'Không tải được ảnh',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class PixelReceiptImage extends StatelessWidget {
  const PixelReceiptImage({
    super.key,
    this.localPath,
    this.displayUrl,
    this.cacheKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.radius = 12,
    this.onTap,
  });

  factory PixelReceiptImage.fromExpense(
    Expense expense, {
    double? width,
    double? height,
    String? semanticLabel,
    BoxFit fit = BoxFit.cover,
    VoidCallback? onTap,
  }) {
    final target = resolveReceiptImage(
      imagePath: expense.imagePath,
      displayImageUrl: expense.displayImageUrl,
    );
    return PixelReceiptImage(
      localPath: target.localPath,
      displayUrl: target.url,
      cacheKey: target.cacheKey,
      width: width,
      height: height,
      fit: fit,
      onTap: onTap,
      semanticLabel:
          semanticLabel ??
          (expense.caption.isEmpty
              ? 'Ảnh khoản chi ${expense.amount.toInt()}'
              : 'Ảnh khoản chi: ${expense.caption}'),
    );
  }

  final String? localPath;
  final String? displayUrl;
  final String? cacheKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget image;
    if (displayUrl != null) {
      image = CachedNetworkImage(
        imageUrl: displayUrl!,
        cacheKey: cacheKey,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) =>
            ColoredBox(color: palette.surfaceAlt, child: Center(
              child: AppIcon(name: 'dotsThreeOutline', size: 16,
                  color: palette.inkMuted),
            )),
        errorWidget: (_, __, ___) => receiptPlaceholder(),
      );
    } else if (localPath != null) {
      image = Image.file(
        File(localPath!),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => receiptPlaceholder(),
      );
    } else {
      image = receiptPlaceholder();
    }

    final framed = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.line, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 2),
        child: image,
      ),
    );

    if (onTap == null) {
      return Semantics(
        image: true,
        label: semanticLabel,
        child: framed,
      );
    }
    return Semantics(
      image: true,
      button: true,
      label: semanticLabel,
      child: GestureDetector(onTap: onTap, child: framed),
    );
  }
}
```

`context.palette` đến từ extension `BuildContextPalette` đã định nghĩa trong `lib/core/theme/app_palette.dart` (plan 2 Task 2) → thêm `import '../../core/theme/app_palette.dart';`. `storagePathOf` do plan 1 Task 1 tạo tại `lib/core/utils/storage_paths.dart` (đúng đường dẫn này — plan 1 ghi file đó trong Files của Task 1, và `lib/core/utils/` hiện chỉ có `currency_formatter.dart`, `date_formatter.dart`, `icon_helper.dart`) → thêm `import '../../core/utils/storage_paths.dart';`.

Run: `flutter test test/unit/pixel_receipt_image_test.dart`
Expected: PASS 4 test.

- [ ] **Step 3: Viết test widget**

Tạo `test/widget/pixel_receipt_image_test.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/widgets/pixel/app_icon.dart';
import 'package:chi_tieu/widgets/pixel/pixel_receipt_image.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SizedBox(width: 200, height: 200, child: child)),
    );

void main() {
  testWidgets('không có nguồn ảnh → placeholder cloudOff + chữ',
      (tester) async {
    await tester.pumpWidget(_wrap(const PixelReceiptImage()));
    expect(find.text('Không tải được ảnh'), findsOneWidget);
    expect(find.byType(AppIcon), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('đường dẫn file không tồn tại → placeholder, không crash',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const PixelReceiptImage(localPath: '/tmp/khong_co_file.jpg')),
    );
    expect(find.text('Không tải được ảnh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fromExpense dùng displayImageUrl và cacheKey là path',
      (tester) async {
    final expense = Expense(
      id: 1,
      caption: 'Ăn trưa',
      amount: 35000,
      categoryId: 2,
      priority: 1,
      imagePath: 'uuid-1/noon.png',
      createdAt: DateTime(2026, 11, 1, 12),
    );
    final withUrl = expense.copyWith(
      displayImageUrl: 'https://signed/noon.png',
    );
    await tester.pumpWidget(
      _wrap(PixelReceiptImage.fromExpense(withUrl)),
    );
    final network = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(network.imageUrl, 'https://signed/noon.png');
    expect(network.cacheKey, 'uuid-1/noon.png');
  });

  testWidgets('có semanticLabel và bắt chạm khi có onTap', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(PixelReceiptImage(
        localPath: '/tmp/khong_co_file.jpg',
        semanticLabel: 'Ảnh khoản cà phê',
        onTap: () {},
      )),
    );
    expect(find.bySemanticsLabel('Ảnh khoản cà phê'), findsOneWidget);
    handle.dispose();
  });
}
```

`Expense` constructor **không phải `const`** và `createdAt` là `required DateTime` (đã xác minh ở `lib/data/models/expense.dart:7-22`) — vì vậy test tạo expense bằng `Expense(...)` thường. `withUrl` dùng `copyWith(displayImageUrl:)` do plan 1 Task 3 thêm vào; nếu `copyWith` chưa có tham số đó thì plan 1 chưa xong → dừng và hoàn tất plan 1.

- [ ] **Step 4: Chạy và sửa**

Run: `flutter test test/widget/pixel_receipt_image_test.dart && flutter analyze`
Expected: PASS 4 test, analyze sạch. Nếu `bySemanticsLabel` không tìm thấy: bật `tester.ensureSemantics()` (bọc trong `try/finally`) — **không** bỏ test.

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/widgets/pixel/pixel_receipt_image.dart test/unit/pixel_receipt_image_test.dart test/widget/pixel_receipt_image_test.dart
git commit -m "feat(pixel): single receipt image widget with signed url and placeholder"
```

---

### Task 2: `PixelScreenHeader` + `PixelExpenseTile`

**Files:**
- Create: `lib/widgets/pixel/pixel_screen_header.dart`
- Create: `lib/widgets/pixel/pixel_expense_tile.dart`
- Create: `test/widget/pixel_expense_tile_test.dart`

**Interfaces:**
- Consumes: `AppIcon`, `PixelIconButton`, `PixelBadge`, `context.palette`, `pixelTextTheme` (plan 2), `Expense`, `DateFormatter.formatTime`, `CurrencyFormatter.format`, `AppStrings.priorityLabels` (plan 2/3 giữ nguyên), `PixelReceiptImage` (Task 1).
- Produces:
  - `PixelScreenHeader({Key? key, required String title, String? subtitle, VoidCallback? onMenuTap, Widget? leading, Widget? trailing, Color? background, VoidCallback? onBackTap})` — widget thường, **không** implement `PreferredSizeWidget`, chiều cao tối thiểu 64. Thứ tự leading: `leading` nếu có → ngược lại `IconButton` 48dp glyph `menu` nếu `onMenuTap != null` → ngược lại `IconButton` 48dp glyph `back` nếu `onBackTap != null` → ngược lại `SizedBox(width: 8)`. Title VT323 qua `text.headlineSmall` + `FittedBox`, subtitle `bodySmall` `inkMuted`, viền dưới 3px `lineStrong`.
  - `Widget pixelAppBar(Widget header)` — helper cùng file để đặt header vào `Scaffold.appBar:`; vì `PixelScreenHeader` không phải `PreferredSizeWidget`, mọi màn dùng `appBar:` phải viết `appBar: pixelAppBar(PixelScreenHeader(...))`.
  - `PixelExpenseTile({Key? key, required Expense expense, required String categoryName, String categoryIconKey = 'tag', ValueChanged<Expense>? onTap, ValueChanged<Expense>? onDismiss, bool showTime = true})`
  - `Widget pixelGroupHeader(String label)` — dòng "HÔM NAY", "HÔM QUA", ngày; dùng trong dashboard và feed.

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/pixel_expense_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/widgets/pixel/pixel_expense_tile.dart';
import 'package:chi_tieu/widgets/pixel/pixel_screen_header.dart';

void main() {
  Expense makeExpense() => Expense(
        caption: 'Mua cà phê',
        amount: 45000,
        categoryId: 3,
        priority: 0,
        createdAt: DateTime(2026, 11, 1, 13, 25),
      );

  Widget _wrap(Widget child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: SizedBox(width: 420, child: child)),
      );

  testWidgets('tile hiện tên danh mục, ghi chú, số tiền và giờ',
      (tester) async {
    await tester.pumpWidget(_wrap(PixelExpenseTile(
      expense: makeExpense(),
      categoryName: 'Cà phê',
      onTap: (_) {},
    )));
    expect(find.text('Cà phê'), findsOneWidget);
    expect(find.text('Mua cà phê'), findsOneWidget);
    expect(find.textContaining('45.000'), findsOneWidget);
    expect(find.text('13:25'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tile có Dismissible với key theo id khi có onDismiss',
      (tester) async {
    final expense = makeExpense();
    await tester.pumpWidget(_wrap(PixelExpenseTile(
      expense: expense,
      categoryName: 'Cà phê',
      onDismiss: (_) {},
    )));
    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect((dismissible.key as ValueKey<String>).value, isNotNull);
    expect(find.byKey(ValueKey('delete-bg-${expense.id}')), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);
  });

  testWidgets('không có onDismiss thì không có Dismissible', (tester) async {
    await tester.pumpWidget(_wrap(PixelExpenseTile(
      expense: makeExpense(),
      categoryName: 'Cà phê',
    )));
    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets('header có nút menu 48dp, title và subtitle', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(PixelScreenHeader(
      title: 'TỔNG QUAN',
      subtitle: 'tháng 11/2026',
      onMenuTap: () => taps++,
    )));
    expect(find.text('TỔNG QUAN'), findsOneWidget);
    expect(find.text('tháng 11/2026'), findsOneWidget);
    final menu = find.byType(IconButton);
    expect(menu, findsOneWidget);
    final size = tester.getSize(menu);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(menu);
    expect(taps, 1);
    expect(tester.getSize(find.byType(PixelScreenHeader)).height,
        greaterThanOrEqualTo(64));
  });
}
```

Chữ ký `Expense` đã đọc trước khi viết plan (`lib/data/models/expense.dart:13-22`): `id` là `int?` **không required**, `caption`/`amount`/`categoryId`/`createdAt` **required**, `priority` default `0`, `deletedAt` optional. `makeExpense()` ở trên truyền đúng `caption, amount, categoryId, priority, createdAt` nên `id` để trống vẫn hợp lệ; `constructor` **không `const`** → không bọc `const` quanh `Expense(...)`. `PixelExpenseTile` **không** đọc icon từ model — icon danh mục truyền qua tham số `categoryIconKey`, nên test không assert icon.

Run: `flutter test test/widget/pixel_expense_tile_test.dart`
Expected: FAIL — URI `pixel_expense_tile.dart` / `pixel_screen_header.dart` không tồn tại.

- [ ] **Step 2: Implement `PixelScreenHeader`**

Tạo `lib/widgets/pixel/pixel_screen_header.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

/// Header pixel dùng cho mọi màn trừ feed/camera (màn đó có HUD tối riêng).
class PixelScreenHeader extends StatelessWidget {
  const PixelScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuTap,
    this.onBackTap,
    this.leading,
    this.trailing,
    this.background,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;
  final Widget? leading;
  final Widget? trailing;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: background ?? palette.canvas,
        border: Border(bottom: BorderSide(color: palette.lineStrong, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading ?? _buildLeading(palette),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: text.headlineSmall),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildLeading(AppPalette palette) {
    final isBack = onMenuTap == null && onBackTap != null;
    final onTap = onMenuTap ?? onBackTap;
    if (onTap == null) return const SizedBox(width: 8);
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onTap,
        tooltip: isBack ? 'Quay lại' : 'Mở menu',
        padding: EdgeInsets.zero,
        icon: AppIcon(
          name: isBack ? 'back' : 'menu',
          size: 32,
          color: palette.ink,
        ),
      ),
    );
  }
}

/// Đặt header không-phải-AppBar vào `Scaffold.appBar:` và giữ chỗ cho status bar.
Widget pixelAppBar(Widget header) {
  return Builder(
    builder: (context) {
      final top = MediaQuery.paddingOf(context).top;
      return PreferredSize(
        preferredSize: Size(0, 64 + top),
        child: Padding(padding: EdgeInsets.only(top: top), child: header),
      );
    },
  );
}

Widget pixelGroupHeader(String label) {
  return Builder(
    builder: (context) {
      final palette = context.palette;
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
        child: Row(
          children: [
            AppIcon(name: 'chevronRight', size: 16, color: palette.mintInk),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: palette.inkMuted),
            ),
          ],
        ),
      );
    },
  );
}
```

`AppIcon` **không có tham số `onTap`** (chữ ký plan 2 Task 5: `AppIcon({required String name, double size = 32, Color? color, Color? secondary, String? semanticLabel, bool functional = false})`) — nên mọi nút icon phải bọc `IconButton`/`PixelIconButton` như ở trên, `AppIcon` chỉ là nội dung hình. Chạy `grep -n "class AppIcon" -A 20 lib/widgets/pixel/app_icon.dart` để xác nhận chữ ký thật trước khi gõ; nếu plan 2 đã đổi tên tham số thì theo plan 2.

Run: `flutter analyze lib/widgets/pixel/pixel_screen_header.dart`
Expected: No issues.

- [ ] **Step 3: Implement `PixelExpenseTile`**

Tạo `lib/widgets/pixel/pixel_expense_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/expense.dart';
import 'app_icon.dart';
import 'pixel_receipt_image.dart';

class PixelExpenseTile extends StatelessWidget {
  const PixelExpenseTile({
    super.key,
    required this.expense,
    required this.categoryName,
    this.categoryIconKey = 'tag',
    this.onTap,
    this.onDismiss,
    this.showTime = true,
  });

  final Expense expense;
  final String categoryName;
  final String categoryIconKey;
  final ValueChanged<Expense>? onTap;
  final ValueChanged<Expense>? onDismiss;
  final bool showTime;

  static const double rowHeight = 72;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final accent = palette.accentForCategory(categoryName);
    final priorityInk = palette.priorityColor(expense.priority);

    final row = InkWell(
      onTap: onTap == null ? null : () => onTap!(expense),
      child: Container(
        height: rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(bottom: BorderSide(color: palette.line, width: 1)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: expense.imagePath == null
                  ? _CategoryBadge(
                      iconKey: categoryIconKey,
                      accent: accent,
                      palette: palette,
                    )
                  : PixelReceiptImage.fromExpense(
                      expense,
                      width: 52,
                      height: 52,
                      radius: 8,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.caption.isEmpty ? '—' : expense.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.format(expense.amount),
                    style: text.titleMedium?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      color: priorityInk,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      showTime
                          ? DateFormatter.formatTime(expense.createdAt)
                          : expense.priorityLabel,
                      style: text.labelSmall?.copyWith(color: palette.inkMuted),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onDismiss == null) return row;

    return Dismissible(
      key: ValueKey('expense-row-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        key: ValueKey('delete-bg-${expense.id}'),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: palette.danger,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Xóa',
              style: text.labelLarge?.copyWith(color: palette.onAccent),
            ),
            const SizedBox(width: 8),
            AppIcon(name: 'trash', size: 32, color: palette.onAccent),
          ],
        ),
      ),
      onDismissed: (_) => onDismiss!(expense),
      child: row,
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.iconKey,
    required this.accent,
    required this.palette,
  });

  final String iconKey;
  final Color accent;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent,
        border: Border.all(color: palette.lineStrong, width: 2),
      ),
      child: Center(
        child: AppIcon(name: iconKey, size: 32, color: palette.onAccent),
      ),
    );
  }
}
```

`expense.imagePath` khác `null` thì dòng dùng ảnh thumbnail 52×52 (Task 1); không có ảnh thì dùng badge danh mục. Dashboard truyền `categoryIconKey` từ map danh mục (`categoriesById[expense.categoryId]?.icon`), model `Expense` không chứa icon.

- [ ] **Step 4: Chạy test và gate**

Run: `flutter test test/widget/pixel_expense_tile_test.dart && flutter analyze`
Expected: PASS 4 test; analyze sạch.

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test`
Expected: PASS toàn bộ, số test = baseline + 12 (Task 1 thêm 8, Task 2 thêm 4).

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/widgets/pixel/pixel_screen_header.dart lib/widgets/pixel/pixel_expense_tile.dart test/widget/pixel_expense_tile_test.dart
git commit -m "feat(pixel): shared screen header and expense row tile"
```

---

### Task 3: Helper phân bổ ô + 3 widget biểu đồ pixel (bỏ `fl_chart` ở Task 10)

**Files:**
- Create: `lib/core/utils/pixel_allocate.dart`
- Create: `lib/widgets/pixel/pixel_share_bar.dart`
- Create: `lib/widgets/pixel/pixel_stacked_share.dart`
- Create: `lib/widgets/pixel/pixel_bar_chart.dart`
- Create: `test/unit/pixel_allocate_test.dart`
- Create: `test/widget/pixel_charts_test.dart`

**Interfaces:**
- Consumes: `AppIcon`, `PixelBadge`, `context.palette`, `CurrencyFormatter.format`, `DateFormatter.formatDate`.
- Produces:
  - `int pixelFilledCells(double ratio, int cells)` — clamp 0..cells, ratio NaN/∞ → 0
  - `List<int> allocateCells(List<double> values, int cells)` — largest remainder, tổng luôn bằng `cells` khi `sum > 0`, toàn 0 khi `sum <= 0`
  - `String sharePercent(double part, double total)` — `'0%'` khi total ≤ 0, không NaN
  - `List<int> pickAxisIndices(int count, int maxLabels)` — index tăng dần, luôn gồm index cuối
  - `PixelShareBar({Key? key, required String label, required String glyph, required double value, required double total, required String valueText, int cells = 14})`
  - `PixelStackedShare({Key? key, required List<String> labels, required List<String> glyphs, required List<double> values, required List<Color> colors, required List<String> valueTexts, int cells = 24})`
  - `PixelBarChart({Key? key, required List<DateTime> dates, required List<double> values, required List<String> valueTexts, int rows = 8, int maxBars = 31, Color? barColor})` + `String pixelBarChartSemantics(List<DateTime> dates, List<double> values, List<String> valueTexts)` (pure)

- [ ] **Step 1: Viết test pure failing**

Tạo `test/unit/pixel_allocate_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/utils/pixel_allocate.dart';

void main() {
  group('pixelFilledCells', () {
    test('clamp 0..cells', () {
      expect(pixelFilledCells(0, 10), 0);
      expect(pixelFilledCells(0.049, 10), 0);
      expect(pixelFilledCells(0.05, 10), 1);
      expect(pixelFilledCells(0.5, 10), 5);
      expect(pixelFilledCells(1, 10), 10);
      expect(pixelFilledCells(3, 10), 10);
      expect(pixelFilledCells(-2, 10), 0);
    });
    test('NaN và vô cùng không làm crash', () {
      expect(pixelFilledCells(double.nan, 10), 0);
      expect(pixelFilledCells(double.infinity, 10), 10);
    });
  });

  group('allocateCells', () {
    test('tổng phần bằng tổng ô khi sum > 0', () {
      expect(allocateCells([1, 1, 1], 10).reduce((a, b) => a + b), 10);
      expect(allocateCells([0.33, 0.33, 0.34], 24).reduce((a, b) => a + b), 24);
    });
    test('largest remainder ưu tiên phần dư lớn nhất, tie theo index nhỏ', () {
      expect(allocateCells([2, 1], 3), [2, 1]);
      expect(allocateCells([1, 1, 1], 5), [2, 2, 1]);
      expect(allocateCells([1, 1], 1), [1, 0]);
    });
    test('sum <= 0 trả toàn 0, không NaN', () {
      expect(allocateCells([0, 0, 0], 12), [0, 0, 0]);
      expect(allocateCells([], 12), isEmpty);
      expect(allocateCells([-1, -2], 5), [0, 0]);
    });
    test('một phần chiếm hết', () {
      expect(allocateCells([0, 7], 6), [0, 6]);
    });
  });

  group('sharePercent', () {
    test('total <= 0 trả 0%', () {
      expect(sharePercent(0, 0), '0%');
      expect(sharePercent(5, 0), '0%');
      expect(sharePercent(5, -1), '0%');
    });
    test('làm tròn không dấu phẩy', () {
      expect(sharePercent(50, 200), '25%');
      expect(sharePercent(1, 3), '33%');
      expect(sharePercent(2, 3), '67%');
      expect(sharePercent(3, 3), '100%');
    });
  });

  group('pickAxisIndices', () {
    test('count <= maxLabels lấy hết', () {
      expect(pickAxisIndices(3, 8), [0, 1, 2]);
      expect(pickAxisIndices(0, 8), isEmpty);
    });
    test('thưa dần và luôn gồm index cuối', () {
      final idx = pickAxisIndices(31, 6);
      expect(idx.length, lessThanOrEqualTo(6));
      expect(idx.last, 30);
      expect(idx.first, 0);
      for (var i = 1; i < idx.length; i++) {
        expect(idx[i] > idx[i - 1], isTrue);
      }
    });
  });

  group('pixelBarChartSemantics', () {
    test('tóm tắt đủ từng dòng cho screen reader', () {
      final s = pixelBarChartSemantics(
        [DateTime(2026, 11, 1), DateTime(2026, 11, 2)],
        [10000, 20000],
        ['10.000 đ', '20.000 đ'],
      );
      expect(s, contains('10.000 đ'));
      expect(s, contains('20.000 đ'));
      expect(s.split('\n').length, 2);
    });
    test('rỗng trả chuỗi trống', () {
      expect(pixelBarChartSemantics([], [], []), isEmpty);
    });
  });
}
```

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/unit/pixel_allocate_test.dart`
Expected: FAIL — URI `pixel_allocate.dart` không tồn tại.

- [ ] **Step 2: Implement helper thuần**

Tạo `lib/core/utils/pixel_allocate.dart`:

```dart
/// Tính số ô được tô cho một tỉ lệ, luôn nằm trong [0, cells].
int pixelFilledCells(double ratio, int cells) {
  if (cells <= 0) return 0;
  if (ratio.isNaN) return 0;
  if (ratio.isInfinite) return ratio > 0 ? cells : 0;
  final filled = (ratio * cells).round();
  return filled.clamp(0, cells);
}

/// Chia [cells] ô cho các phần tử của [values] theo largest remainder.
/// Tổng kết quả đúng bằng cells khi total > 0, ngược lại toàn 0.
List<int> allocateCells(List<double> values, int cells) {
  if (values.isEmpty) return const [];
  if (cells <= 0) return List<int>.filled(values.length, 0);
  var total = 0.0;
  for (final v in values) {
    if (v > 0) total += v;
  }
  if (total <= 0) return List<int>.filled(values.length, 0);

  final exact = [
    for (final v in values) (v > 0 ? v : 0.0) / total * cells,
  ];
  final result = [for (final e in exact) e.floor()];
  var used = result.fold<int>(0, (a, b) => a + b);

  final order = [for (var i = 0; i < exact.length; i++) i]
    ..sort((a, b) {
      final ra = exact[a] - result[a];
      final rb = exact[b] - result[b];
      final c = rb.compareTo(ra);
      return c != 0 ? c : a.compareTo(b);
    });

  var cursor = 0;
  while (used < cells) {
    result[order[cursor % order.length]] += 1;
    used += 1;
    cursor += 1;
  }
  return result;
}

/// '12%' — không bao giờ trả NaN hay dấu phẩy thập phân.
String sharePercent(double part, double total) {
  if (total <= 0) return '0%';
  final percent = (part / total * 100).round();
  return '${percent.clamp(0, 100)}%';
}

/// Chọn index nhãn trục, luôn có index đầu và cuối, thưa đều.
List<int> pickAxisIndices(int count, int maxLabels) {
  if (count <= 0) return const [];
  if (count <= maxLabels) return [for (var i = 0; i < count; i++) i];
  final step = (count - 1) / (maxLabels - 1);
  final indices = <int>[];
  for (var k = 0; k < maxLabels; k++) {
    final i = (k * step).round();
    if (indices.isEmpty || i != indices.last) indices.add(i);
  }
  if (indices.last != count - 1) indices.add(count - 1);
  return indices;
}

/// Tóm tắt chữ cho screen reader của bar chart (spec §3.6).
String pixelBarChartSemantics(
  List<DateTime> dates,
  List<double> values,
  List<String> valueTexts,
) {
  if (dates.isEmpty || values.isEmpty) return '';
  final n = [dates.length, values.length, valueTexts.length]
      .reduce((a, b) => a < b ? a : b);
  final lines = <String>[];
  for (var i = 0; i < n; i++) {
    final d = dates[i];
    lines.add(
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}: ${valueTexts[i]}',
    );
  }
  return lines.join('\n');
}
```

Run: `flutter test test/unit/pixel_allocate_test.dart`
Expected: PASS 12 test (4 nhóm `pixelFilledCells`/`allocateCells`/`sharePercent`/`pickAxisIndices` + `pixelBarChartSemantics`).

- [ ] **Step 3: Viết test widget failing**

Tạo `test/widget/pixel_charts_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/widgets/pixel/pixel_bar_chart.dart';
import 'package:chi_tieu/widgets/pixel/pixel_share_bar.dart';
import 'package:chi_tieu/widgets/pixel/pixel_stacked_share.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(width: 380, child: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('PixelShareBar hiện nhãn, số tiền, % và đủ 14 ô', (tester) async {
    await tester.pumpWidget(_wrap(const PixelShareBar(
      label: 'Ăn uống',
      glyph: 'forkKnife',
      value: 500000,
      total: 1000000,
      valueText: '500.000 đ',
    )));
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('500.000 đ'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byKey(const ValueKey('share-cells-Ăn uống')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelShareBar total = 0 không chia zero-division',
      (tester) async {
    await tester.pumpWidget(_wrap(const PixelShareBar(
      label: 'Khác',
      glyph: 'receipt',
      value: 0,
      total: 0,
      valueText: '0 đ',
    )));
    expect(find.text('0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelStackedShare hiện legend đủ 4 mức', (tester) async {
    await tester.pumpWidget(_wrap(const PixelStackedShare(
      labels: ['Cần thiết', 'Nên có', 'Muốn có', 'Không cần'],
      glyphs: ['check', 'sparkle', 'gift', 'close'],
      values: [3, 1, 1, 1],
      colors: [Color(0xFF2F9E6E), Color(0xFF3D8BFD), Color(0xFFF5C24A),
        Color(0xFFE5484D)],
      valueTexts: ['300 đ', '100 đ', '100 đ', '100 đ'],
      cells: 24,
    )));
    expect(find.text('Cần thiết'), findsOneWidget);
    expect(find.text('Không cần'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('17%'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelBarChart vẽ và chạm hiện tooltip', (tester) async {
    await tester.pumpWidget(_wrap(PixelBarChart(
      dates: [DateTime(2026, 11, 1), DateTime(2026, 11, 2)],
      values: [10000, 20000],
      valueTexts: ['10.000 đ', '20.000 đ'],
    )));
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bar-1')));
    await tester.pump();
    expect(find.textContaining('20.000 đ'), findsWidgets);
  });

  testWidgets('PixelBarChart rỗng hiện dòng chữ hướng dẫn', (tester) async {
    await tester.pumpWidget(_wrap(const PixelBarChart(
      dates: [],
      values: [],
      valueTexts: [],
    )));
    expect(find.text('Chưa có dữ liệu trong khoảng này.'), findsOneWidget);
  });

  testWidgets('PixelBarChart cắt về maxBars cuối', (tester) async {
    final dates = [for (var i = 0; i < 40; i++) DateTime(2026, 10, 1).add(Duration(days: i))];
    await tester.pumpWidget(_wrap(PixelBarChart(
      dates: dates,
      values: [for (var i = 0; i < 40; i++) 1000.0 * i],
      valueTexts: [for (var i = 0; i < 40; i++) '$i đ'],
      maxBars: 10,
    )));
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-9')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-10')), findsNothing);
  });
}
```

Run: `flutter test test/widget/pixel_charts_test.dart`
Expected: FAIL — các URI `pixel_share_bar.dart`, `pixel_stacked_share.dart`, `pixel_bar_chart.dart` không tồn tại.

- [ ] **Step 4: Implement `PixelShareBar`**

Tạo `lib/widgets/pixel/pixel_share_bar.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/pixel_allocate.dart';
import 'app_icon.dart';

/// Một hàng tỉ trọng: badge icon + tên + thanh khối + số tiền + %.
class PixelShareBar extends StatelessWidget {
  const PixelShareBar({
    super.key,
    required this.label,
    required this.glyph,
    required this.value,
    required this.total,
    required this.valueText,
    this.cells = 14,
  });

  final String label;
  final String glyph;
  final double value;
  final double total;
  final String valueText;
  final int cells;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final accent = palette.accentForCategory(label);
    final filled = pixelFilledCells(total <= 0 ? 0 : value / total, cells);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent,
              border: Border.all(color: palette.lineStrong, width: 2),
            ),
            child: Center(
              child: AppIcon(name: glyph, size: 16, color: palette.onAccent),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: cells * 7,
            child: Row(
              key: ValueKey('share-cells-$label'),
              children: [
                for (var i = 0; i < cells; i++)
                  Container(
                    width: 6,
                    height: 14,
                    margin: const EdgeInsets.only(right: 1),
                    color: i < filled ? accent : palette.surfaceAlt,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valueText,
                    style: text.bodyMedium?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  sharePercent(value, total),
                  style: text.labelSmall?.copyWith(color: palette.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

Run: `flutter test test/widget/pixel_charts_test.dart -n "PixelShareBar"`
Expected: PASS 2 test.

- [ ] **Step 5: Implement `PixelStackedShare`**

Tạo `lib/widgets/pixel/pixel_stacked_share.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/pixel_allocate.dart';
import 'app_icon.dart';

/// 4 khối mức độ xếp theo tỉ lệ trong [cells] ô, kèm legend chữ + số tiền.
class PixelStackedShare extends StatelessWidget {
  const PixelStackedShare({
    super.key,
    required this.labels,
    required this.glyphs,
    required this.values,
    required this.colors,
    required this.valueTexts,
    this.cells = 24,
  });

  final List<String> labels;
  final List<String> glyphs;
  final List<double> values;
  final List<Color> colors;
  final List<String> valueTexts;
  final int cells;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final allocation = allocateCells(values, cells);
    final total = values.fold<double>(0, (a, b) => a + (b > 0 ? b : 0));

    final bars = <Widget>[];
    for (var i = 0; i < allocation.length; i++) {
      for (var k = 0; k < allocation[i]; k++) {
        bars.add(Container(
          width: 8,
          height: 26,
          margin: const EdgeInsets.only(right: 1),
          color: colors[i % colors.length],
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            key: const ValueKey('stacked-cells'),
            height: 30,
            decoration: BoxDecoration(
              border: Border.all(color: palette.lineStrong, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(mainAxisSize: MainAxisSize.min, children: bars),
          ),
        ),
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: i < colors.length ? colors[i] : palette.surfaceAlt,
                ),
                const SizedBox(width: 8),
                AppIcon(
                  name: i < glyphs.length ? glyphs[i] : 'label',
                  size: 16,
                  color: palette.inkMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    labels[i],
                    style: text.bodyMedium?.copyWith(color: palette.ink),
                  ),
                ),
                Text(
                  i < valueTexts.length ? valueTexts[i] : '',
                  style: text.bodyMedium?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    sharePercent(i < values.length ? values[i] : 0, total),
                    textAlign: TextAlign.end,
                    style: text.labelSmall?.copyWith(color: palette.inkMuted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
```

Run: `flutter test test/widget/pixel_charts_test.dart -n "PixelStackedShare"`
Expected: PASS 1 test.

- [ ] **Step 6: Implement `PixelBarChart`**

Tạo `lib/widgets/pixel/pixel_bar_chart.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/pixel_allocate.dart';

class PixelBarChart extends StatefulWidget {
  const PixelBarChart({
    super.key,
    required this.dates,
    required this.values,
    required this.valueTexts,
    this.rows = 8,
    this.maxBars = 31,
    this.barColor,
    this.axisLabels = 6,
  });

  final List<DateTime> dates;
  final List<double> values;
  final List<String> valueTexts;
  final int rows;
  final int maxBars;
  final Color? barColor;
  final int axisLabels;

  @override
  State<PixelBarChart> createState() => _PixelBarChartState();
}

class _PixelBarChartState extends State<PixelBarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final barColor = widget.barColor ?? palette.mint;

    final count = [
      widget.values.length,
      widget.dates.length,
      widget.valueTexts.length,
    ].reduce((a, b) => a < b ? a : b);
    if (count == 0) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: Text(
          'Chưa có dữ liệu trong khoảng này.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: palette.inkMuted),
        ),
      );
    }

    final skip = count > widget.maxBars ? count - widget.maxBars : 0;
    final dates = widget.dates.sublist(skip, count);
    final values = widget.values.sublist(skip, count);
    final texts = widget.valueTexts.sublist(skip, count);
    final maxValue = values.fold<double>(0, (a, b) => b > a ? b : a);
    final width = (dates.length * 14).clamp(0, 10000).toDouble();

    return Semantics(
      container: true,
      excludeSemantics: false,
      label: pixelBarChartSemantics(dates, values, texts),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selected != null && _selected! < texts.length)
            Container(
              key: const ValueKey('bar-tooltip'),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border.all(color: palette.lineStrong, width: 2),
              ),
              child: Text(
                '${DateFormatter.formatDate(dates[_selected!])} • ${texts[_selected!]}',
                style: text.labelLarge?.copyWith(color: palette.ink),
              ),
            ),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width.toDouble(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < dates.length; i++)
                      _buildBar(i, dates[i], values[i], texts[i], maxValue,
                          barColor, palette),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 18,
            child: Row(
              children: [
                for (final i in pickAxisIndices(dates.length, widget.axisLabels))
                  SizedBox(
                    width: 14,
                    child: Text(
                      '${dates[i].day}',
                      textAlign: TextAlign.center,
                      style: text.labelSmall?.copyWith(color: palette.inkMuted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    int i,
    DateTime date,
    double value,
    String valueText,
    double maxValue,
    Color barColor,
    AppPalette palette,
  ) {
    final filled = maxValue <= 0
        ? 0
        : pixelFilledCells(value / maxValue, widget.rows);
    final isSelected = _selected == i;

    return GestureDetector(
      key: ValueKey('bar-$i'),
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = isSelected ? null : i),
      child: Semantics(
        label: '${DateFormatter.formatDate(date)}: $valueText',
        child: SizedBox(
          width: 14,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var r = widget.rows - 1; r >= 0; r--)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 1),
                  color: r < filled
                      ? (isSelected ? palette.mintInk : barColor)
                      : palette.surfaceAlt,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`DateFormatter.formatDate` nhận đúng một tham số `DateTime` và `formatTime` cũng vậy (đã xác minh `lib/core/utils/date_formatter.dart:4,19`), nên code biểu đồ không cần `BuildContext` để định dạng ngày.

Run: `flutter test test/widget/pixel_charts_test.dart && flutter analyze`
Expected: PASS 6 test, analyze sạch.

- [ ] **Step 7: Gate toàn bộ**

Run: `flutter test`
Expected: PASS, số test = baseline + 30 (Task 1: 8, Task 2: 4, Task 3: 18 = 12 unit `pixel_allocate_test.dart` + 6 widget `pixel_charts_test.dart`).

- [ ] **Step 8: Commit (khi được ủy quyền)**

```bash
git add lib/core/utils/pixel_allocate.dart lib/widgets/pixel/pixel_share_bar.dart lib/widgets/pixel/pixel_stacked_share.dart lib/widgets/pixel/pixel_bar_chart.dart test/unit/pixel_allocate_test.dart test/widget/pixel_charts_test.dart
git commit -m "feat(pixel): block-based share bars and daily bar chart"
```

---

### Task 4: Onboarding + Đăng nhập + Đăng ký theo pixel (spec §5.1, §5.2)

**Files:**
- Modify: `lib/screens/onboarding/onboarding_screen.dart` (toàn bộ 147 dòng)
- Modify: `lib/screens/auth/login_screen.dart` (toàn bộ 361 dòng)
- Modify: `lib/screens/auth/register_screen.dart` (toàn bộ 214 dòng)
- Create: `test/widget/onboarding_login_test.dart`
- Modify: `test/widget/screens_test.dart:34-45` (group `OnboardingScreen Widget Tests` — đổi nhãn, giữ group)

**Interfaces:**
- Consumes: `PixelPanel`, `PixelButton`, `PixelTextField`, `PixelDivider`, `AppIcon`, `context.palette`, `AppInfo`, `showForgotPasswordSheet` (plan 3 Task 6), `appSettingsProvider` (override giả trong test).
- Produces:
  - `const List<String> onboardingGlyphs = ['wallet', 'cloud', 'chart']` (dùng glyph đã có, không thêm mới)
  - Login: `Key loginEmailField`, `Key loginPasswordField`, `Key loginSubmitButton`, `Text('Quên mật khẩu?')`
  - Register: `Key registerNameField`, `Key registerEmailField`, `Key registerPasswordField`, `Key registerConfirmField`

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/onboarding_login_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/providers/app_settings_provider.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/screens/auth/login_screen.dart';
import 'package:chi_tieu/screens/auth/register_screen.dart';
import 'package:chi_tieu/screens/onboarding/onboarding_screen.dart';
import 'package:chi_tieu/widgets/pixel/pixel_button.dart';
import 'package:chi_tieu/widgets/pixel/pixel_text_field.dart';

class _FakeAppSettingsNotifier extends StateNotifier<AppSettingsState>
    implements AppSettingsNotifier {
  _FakeAppSettingsNotifier()
      : super(
          const AppSettingsState(
            isLoading: false,
            onboardingComplete: true,
          ),
        );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  // `StateNotifier.state` là @protected (state_notifier 1.0.0) nên không gán
  // được từ ngoài class; truyền state khởi tạo qua constructor.
  _FakeAuthNotifier([
    AppAuthState initial =
        const AppAuthState(status: AuthStatus.unauthenticated),
  ]) : super(initial);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child, {AppAuthState? auth}) => ProviderScope(
      overrides: [
        if (auth != null)
          authProvider.overrideWith((ref) => _FakeAuthNotifier(auth)),
        appSettingsProvider.overrideWith((ref) => _FakeAppSettingsNotifier()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

void main() {
  testWidgets('Onboarding dùng glyph pixel, 3 trang, nhãn BỎ QUA/BẮT ĐẦU',
      (tester) async {
    await tester.pumpWidget(_wrap(const OnboardingScreen()));
    expect(find.text('Chào mừng đến với Chi Tiêu'), findsOneWidget);
    expect(find.text('BỎ QUA'), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsOneWidget);
    expect(find.byType(PixelButton), findsWidgets);
    expect(find.byIcon(Icons.attach_money_rounded), findsNothing);
    expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    expect(find.byIcon(Icons.notifications_active_outlined), findsNothing);
    expect(tester.takeException(), isNull);

    // Duyệt bằng nút TIẾP TỤC (không gọi _finish).
    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();
    expect(find.text('Đồng bộ an toàn trên Cloud'), findsOneWidget);
    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();
    expect(find.text('Không vượt quá ngân sách'), findsOneWidget);
    expect(find.text('BẮT ĐẦU'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // KHÔNG tap 'BỎ QUA' hay 'BẮT ĐẦU': _finish() gọi
    // Permission.camera.request() -> MissingPluginException trong flutter_test.
  });

  testWidgets('Login có 2 PixelTextField, nút đăng nhập và Quên mật khẩu?',
      (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    expect(find.byType(PixelTextField), findsNWidgets(2));
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.byType(PixelButton), findsWidgets);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login báo lỗi validate khi nộp trống, không gọi auth',
      (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });

  testWidgets('Register có 4 PixelTextField, nút ĐĂNG KÝ, không có TextFormField',
      (tester) async {
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    expect(find.byType(PixelTextField), findsNWidgets(4));
    expect(find.text('ĐĂNG KÝ'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login không dùng AppColors gradient cũ', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    final decorated = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    for (final d in decorated) {
      final dec = d.decoration;
      if (dec is BoxDecoration) expect(dec.gradient, isNull);
    }
  });

  testWidgets('Login 1.3x text scale không vỡ layout', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          appSettingsProvider
              .overrideWith((ref) => _FakeAppSettingsNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.drag(find.byType(LoginScreen), const Offset(0, -300));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
```

Ghi chú bắt buộc khi viết test (đừng đoán):
- `LoginScreen` có tham số gì thì theo `grep -n "const LoginScreen" -A 4 lib/screens/auth/login_screen.dart` (hiện tại `const LoginScreen({super.key})`, có thể nhận `onRegisterTap` — nếu có thì truyền handler giả).
- `_FakeAppSettingsNotifier` là bắt buộc vì `OnboardingScreen._finish()` đọc `appSettingsProvider` (`lib/screens/onboarding/onboarding_screen.dart:46`); `AppSettingsNotifier` khởi tạo gọi `AppSettingsRepository` (shared_preferences) nên không override là test đụng plugin thật. Idiom `implements` + `noSuchMethod` lấy từ `_MockThemeNotifier` trong `test/widget/screens_test.dart`; `AppSettingsState` có constructor const với `isLoading`/`onboardingComplete` (`lib/providers/app_settings_provider.dart:9-12`). `_wrap` override luôn cho mọi test.
- `AuthStatus` chỉ có 5 giá trị đã xác minh ở `lib/providers/auth_provider.dart:8`: `initial, authenticated, unauthenticated, loading, error` — **không có `unknown`**.
- `noSuchMethod` giả sẽ ném `NoSuchMethodError` nếu `LoginScreen` thật sự gọi `signInWithEmail` — đó chính là điều test "nộp trống" mong đợi **không** xảy ra (validate chặn trước). Nếu test fail vì `NoSuchMethodError`, nghĩa là validate chưa chặn → sửa implementation, không sửa test.
- **Không** tap `BỎ QUA`/`BẮT ĐẦU` trong widget test: `_finish()` gọi `Permission.camera.request()` (permission_handler) và `NotificationService.instance.requestPermission()`, cả hai là method channel không có trong flutter_test → `MissingPluginException`. Duyệt trang bằng nút `TIẾP TỤC` là đủ phủ 3 trang mà không chạm `_finish`.

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/widget/onboarding_login_test.dart`
Expected: FAIL — `PixelTextField` không xuất hiện, `find.text('Quên mật khẩu?')` không tìm thấy.

- [ ] **Step 2: Vẽ lại Onboarding**

Sửa `lib/screens/onboarding/onboarding_screen.dart`:
- Thêm import: `../../core/theme/app_palette.dart`, `../../widgets/pixel/app_icon.dart`, `../../widgets/pixel/pixel_button.dart`, `../../widgets/pixel/pixel_panel.dart`.
- `_pages`: đổi field `icon: IconData` → `glyph: String` với `onboardingGlyphs = const ['wallet', 'cloud', 'chart']`; **giữ nguyên 3 title/description hiện có** (dòng 22–33), không đổi copy nghiệp vụ.
- `_OnboardingPage.build`: thay `Icon(icon, size: 112)` bằng

```dart
          PixelPanel(
            background: palette.mint,
            padding: const EdgeInsets.all(28),
            child: AppIcon(
              name: glyph,
              size: 64,
              color: palette.onAccent,
              secondary: palette.mintInk,
            ),
          ),
```

(`palette = context.palette;` lấy ở đầu `build`. Alternating nền panel theo index: trang 0 `mint`, 1 `sky`, 2 `butter` — truyền `panelColor` vào `_OnboardingPage`.)
- Dots tiến trình: thay `AnimatedContainer` bo tròn bằng khối vuông 8×8 (`margin: EdgeInsets.all(4)`, `borderRadius: BorderRadius.zero`), trang hiện tại `palette.ink`, còn lại `palette.line`; **bỏ hiệu ứng width 24→8** (spec §3.8: 120–180ms, không bounce) → chỉ đổi màu `Duration(milliseconds: 120)`.
- `TextButton('Bỏ qua')` → `PixelButton(label: 'BỎ QUA', variant: PixelButtonVariant.ghost, onPressed: _finish)` trong `Align(centerRight)`.
- `FilledButton` → `PixelButton(label: isLastPage ? 'BẮT ĐẦU' : 'TIẾP TỤC', icon: isLastPage ? 'check' : 'chevronRight', onPressed: ...)` giữ `key: ValueKey('onboarding-next')`.
- `_finish()` và `Permission.camera.request()` / `NotificationService.instance.requestPermission()` / `completeOnboarding()` **giữ nguyên thứ tự và nội dung**.
- Nền `Scaffold(backgroundColor: palette.canvas)`, bỏ `SafeArea` thừa nếu trùng.
- Xóa `import '../../core/constants/app_colors.dart';` (onboarding không import file này, kiểm tra bằng grep).

Run: `flutter test test/widget/onboarding_login_test.dart -n "Onboarding"`
Expected: PASS 1 test.

- [ ] **Step 3: Vẽ lại Login**

Sửa `lib/screens/auth/login_screen.dart` theo khối:
1. Xóa import `app_colors.dart`, thêm `app_palette.dart`, `pixel_panel.dart`, `pixel_button.dart`, `pixel_text_field.dart`, `pixel_divider.dart`, `app_icon.dart`, `forgot_password_sheet.dart` (plan 3).
2. Giữ nguyên `_formKey`, `_emailController`, `_passwordController`, `_handleLogin()` (dòng 29–52), `_handleGoogleSignIn()` (dòng 53–~85) và toàn bộ logic validate.
3. Body: `Scaffold(backgroundColor: palette.canvas)` → `SafeArea` → `SingleChildScrollView(padding: EdgeInsets.all(20))` → `Column(crossAxisAlignment: stretch)`:
   - Logo: `Container(64×64, color: palette.mint, border: Border.all(color: palette.lineStrong, width: 3))` chứa `AppIcon(name: 'wallet', size: 32, color: palette.onAccent)`; dưới là `Text(AppInfo.name, style: text.displaySmall)` (VT323 do theme) và `Text(AppInfo.tagline, style: text.bodySmall)`. **Bỏ mọi `LinearGradient`.**
   - Panel form: `PixelPanel(child: Form(key: _formKey, child: Column(...)))`.
   - Email: `PixelTextField(key: const Key('loginEmailField'), label: 'Email', hint: 'you@example.com', controller: _emailController, keyboardType: TextInputType.emailAddress, validator: _validateEmail, suffixGlyph: 'mail')`. Không thêm state lỗi riêng — `PixelTextField.validator` (plan 2 Task 8, bản `TextFormField`) đã hiển thị lỗi dưới field trong `Semantics(liveRegion: true)`.
   - Mật khẩu: `PixelTextField(key: const Key('loginPasswordField'), label: 'Mật khẩu', controller: _passwordController, obscureToggle: true, validator: _validatePassword)`.
   - `Align(alignment: Alignment.centerLeft, child: PixelButton(key: const Key('forgotPasswordButton'), label: 'Quên mật khẩu?', variant: PixelButtonVariant.ghost, onPressed: () => showForgotPasswordSheet(context)))`. `PixelButton` render `label` nguyên văn (không tự uppercase trong widget) — copy phải khớp chính xác `'Quên mật khẩu?'` vì test assert chuỗi này.
   - Nút đăng nhập: `PixelButton(key: const Key('loginSubmitButton'), label: 'ĐĂNG NHẬP', expanded: true, icon: 'logout', isLoading: authState.status == AuthStatus.loading, onPressed: authState.status == AuthStatus.loading ? null : _handleLogin)`. **Không thêm field `_isLoading`** — `login_screen.dart` đã suy trạng thái từ `authState = ref.watch(authProvider)` (đang dùng ở `login_screen.dart:229-247`), giữ đúng semantics cũ.
   - Phân cách: `PixelDivider()` + `Text('HOẶC', style: text.labelSmall)`.
   - Google: `PixelButton(label: 'Tiếp tục với Google', variant: PixelButtonVariant.secondary, icon: 'user', expanded: true, onPressed: authState.status == AuthStatus.loading ? null : _handleGoogleSignIn)`. Giữ nguyên nội dung `_handleGoogleSignIn` (kiểm tra provider Google trước khi mở trình duyệt — FR-18). **Không dùng `Icons.g_mobiledata_rounded`.**
   - Link: `TextButton` đổi thành `PixelButton(label: 'Chưa có tài khoản? Đăng ký', variant: PixelButtonVariant.ghost, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())))` — chính là handler `GestureDetector` hiện có ở `login_screen.dart:335-342`, chỉ đổi widget.
   - Panel cảnh báo thiếu cấu hình (dòng 145–178): `PixelPanel(background: palette.butter, borderColor: palette.lineStrong)` + `AppIcon(name: 'alert', color: palette.butterInk)` + giữ nguyên text `SupabaseConfig.initializationError ?? '...'`.
   - Lỗi auth: xóa `SnackBar` màu `AppColors.priority3`, dùng `showPixelSnackBar(context, message, tone: PixelTone.danger)` — message vẫn lấy từ `authState.errorMessage` (đã map tiếng Việt).

Hai validator là hàm top-level private trong `login_screen.dart`, copy **đúng chuỗi lỗi đang có** (dòng 189-195 và 217-226) vì test assert chuỗi này:

```dart
String? _validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) {
    return 'Vui lòng nhập email';
  }
  if (!v.contains('@')) return 'Email không hợp lệ';
  return null;
}

String? _validatePassword(String? v) {
  if (v == null || v.isEmpty) {
    return 'Vui lòng nhập mật khẩu';
  }
  if (v.length < 6) return 'Mật khẩu từ 6 ký tự trở lên';
  return null;
}
```

4. `grep -n "AppColors\|Icons\." lib/screens/auth/login_screen.dart` → Expected: **không còn kết quả nào**.

- [ ] **Step 4: Vẽ lại Register**

Sửa `lib/screens/auth/register_screen.dart` tương tự: 4 `PixelTextField` (tên, email, mật khẩu với `obscureToggle: true`, xác nhận mật khẩu), `PixelPanel` bọc form, `PixelButton(label: 'ĐĂNG KÝ', expanded: true, isLoading: authState.status == AuthStatus.loading, onPressed: authState.status == AuthStatus.loading ? null : _handleRegister)` — `authState = ref.watch(authProvider)` đã có sẵn tại `register_screen.dart:58`, nút back là `PixelIconButton(icon: 'back', tooltip: 'Quay lại', onPressed: () => Navigator.pop(context))` (đúng handler đang có ở `register_screen.dart:65`), xóa `AppColors`/`Icons.`/`LinearGradient`. Giữ `_handleRegister()` và các validator nguyên văn.

Run: `grep -n "AppColors\|Icons\." lib/screens/auth/register_screen.dart`
Expected: không có kết quả.

- [ ] **Step 5: Cập nhật `test/widget/screens_test.dart`**

Group `OnboardingScreen Widget Tests` (dòng 34–45) vẫn assert copy cũ nên fail sau Step 2. Sửa 3 dòng: giữ nguyên `expect(find.text('Chào mừng đến với Chi Tiêu'), findsOneWidget);` và đổi 2 nhãn còn lại:

```dart
      expect(find.text('BỎ QUA'), findsOneWidget);
      expect(find.text('Chào mừng đến với Chi Tiêu'), findsOneWidget);
      expect(find.text('TIẾP TỤC'), findsOneWidget);
```

Không đổi các group khác (`SettingsScreen`, `ManageCategoriesScreen`, `TrashScreen`) — Task 12 và 13 mới đụng nhãn của chúng.

- [ ] **Step 6: Chạy test và gate**

Run: `flutter test test/widget/onboarding_login_test.dart && flutter test && flutter analyze`
Expected: PASS 6 test mới; toàn bộ PASS (kể cả `screens_test.dart` đã cập nhật); analyze sạch.

Chạy gate copy: `grep -rn "LOCKET JOURNAL\|Locket Journal\|Phiên bản 2.1" lib/`
Expected: chỉ còn `settings_screen.dart` (Task 13 xử lý) — **không** được xuất hiện trong 3 file vừa sửa.

- [ ] **Step 7: Commit (khi được ủy quyền)**

```bash
git add lib/screens/onboarding/onboarding_screen.dart lib/screens/auth/login_screen.dart lib/screens/auth/register_screen.dart test/widget/onboarding_login_test.dart test/widget/screens_test.dart
git commit -m "feat(ui): pixel onboarding, login and register screens"
```

---

### Task 5: Tách `home_screen.dart` và vẽ lại Tổng quan (spec §5.5, §6)

`lib/screens/home/home_screen.dart` hiện 1142 dòng chứa 6 lớp private. Tách 3 phần ra file riêng rồi mới swap giao diện — mỗi phần có test riêng, không đổi logic.

**Files:**
- Create: `lib/screens/home/dashboard_summary.dart`
- Create: `lib/screens/home/budget_progress_card.dart`
- Modify: `lib/screens/home/home_screen.dart` (xoá `_SummaryCards:494-648`, `_BudgetProgressCard:650-752`, `_ExpenseTile:754-897`, `_PhotoPreviewDialog:423-492`; viết lại `build` + `_buildGroupedExpenses`)
- Modify: `lib/screens/main_screen.dart:91-97` (thời lượng chuyển section)
- Create: `test/widget/dashboard_pixel_test.dart`

**Interfaces:**
- Consumes: `PixelScreenHeader`, `pixelGroupHeader`, `PixelExpenseTile`, `PixelStatTile`, `PixelProgress`, `PixelPanel`, `PixelEmptyState`, `PixelLoading`, `showPixelSnackBar`, `showPixelSheet`, `AppIcon`, `context.palette`, `CurrencyFormatter.format`, `DateFormatter.formatDate`.
- Produces:
  - `DashboardSummary({Key? key, required double month, required double today, required double week, required int expenseCount})`
  - `BudgetProgressCard({Key? key, required double spent, required double budget, required VoidCallback? onTap})` — `budget <= 0` nghĩa là chưa đặt
  - `HomeScreen({Key? key, VoidCallback? onMenuTap})` giữ nguyên chữ ký hiện có

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/dashboard_pixel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/budget.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/models/priority_level.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/providers/budget_provider.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/providers/expense_provider.dart';
import 'package:chi_tieu/providers/priority_provider.dart';
import 'package:chi_tieu/screens/home/budget_progress_card.dart';
import 'package:chi_tieu/screens/home/dashboard_summary.dart';
import 'package:chi_tieu/screens/home/home_screen.dart';
import 'package:chi_tieu/widgets/pixel/pixel_expense_tile.dart';
import 'package:chi_tieu/widgets/pixel/pixel_progress.dart';

class _FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _FakeExpenseNotifier(this._initial) : super(_initial);
  final ExpenseState _initial;
  @override
  dynamic noSuchMethod(Invocation invocation) => _initial;
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePriorityNotifier extends StateNotifier<PriorityState>
    implements PriorityNotifier {
  _FakePriorityNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBudgetNotifier extends StateNotifier<BudgetState>
    implements BudgetNotifier {
  _FakeBudgetNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ExpenseState expenseState(List<Expense> items, {bool loading = false}) =>
    ExpenseState(
      expenses: items,
      todayTotal: 50000,
      weekTotal: 200000,
      monthTotal: 1200000,
      isLoading: loading,
    );

Expense makeExpense({int id = 1, String caption = 'Cà phê'}) => Expense(
      id: id,
      caption: caption,
      amount: 45000,
      categoryId: 10,
      priority: 0,
      createdAt: DateTime.now(),
    );

Widget harness(
  Widget child, {
  ExpenseState? expenses,
  List<Category> categories = const [],
  List<PriorityLevel> priorities = const [],
  BudgetState? budget,
}) {
  final expenseItems = expenses?.expenses ?? const [];
  return ProviderScope(
    overrides: [
      expenseProvider.overrideWith(
        (ref) => _FakeExpenseNotifier(expenses ?? expenseState(const [])),
      ),
      categoryProvider.overrideWith(
        (ref) => _FakeCategoryNotifier(CategoryState(categories: categories)),
      ),
      priorityProvider.overrideWith(
        (ref) => _FakePriorityNotifier(PriorityState(levels: priorities)),
      ),
      budgetProvider.overrideWith(
        (ref) => _FakeBudgetNotifier(
          budget ?? BudgetState(month: '11/2026', totalSpent: 0),
        ),
      ),
      authProvider.overrideWith(
        (ref) => _FakeAuthNotifier(const AppAuthState()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  testWidgets('DashboardSummary hiện hero và 3 stat tile', (tester) async {
    await tester.pumpWidget(harness(const DashboardSummary(
      month: 1200000,
      today: 50000,
      week: 200000,
      expenseCount: 12,
    )));
    expect(find.text('CHI THÁNG NÀY'), findsOneWidget);
    expect(find.textContaining('1.200.000'), findsOneWidget);
    expect(find.text('HÔM NAY'), findsOneWidget);
    expect(find.text('TUẦN NÀY'), findsOneWidget);
    expect(find.text('SỐ KHOẢN'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('BudgetProgressCard hiện QUÁ NGÂN SÁCH khi vượt', (tester) async {
    await tester.pumpWidget(harness(const BudgetProgressCard(
      spent: 7000000,
      budget: 5000000,
      onTap: null,
    )));
    expect(find.textContaining('QUÁ NGÂN SÁCH'), findsOneWidget);
    expect(find.textContaining('2.000.000'), findsOneWidget);
    final progress = tester.widget<PixelProgress>(find.byType(PixelProgress));
    expect(progress.value, greaterThanOrEqualTo(1));
  });

  testWidgets('BudgetProgressCard chưa đặt ngân sách hiện CÒN LẠI',
      (tester) async {
    await tester.pumpWidget(harness(const BudgetProgressCard(
      spent: 1000000,
      budget: 5000000,
      onTap: null,
    )));
    expect(find.textContaining('Còn lại'), findsOneWidget);
    expect(find.textContaining('4.000.000'), findsOneWidget);
  });

  testWidgets('BudgetProgressCard chưa đặt hiện hướng dẫn đặt',
      (tester) async {
    await tester.pumpWidget(harness(const BudgetProgressCard(
      spent: 1000000,
      budget: 0,
      onTap: null,
    )));
    expect(find.text('Chưa đặt ngân sách'), findsOneWidget);
  });

  testWidgets('HomeScreen rỗng hiện PixelEmptyState', (tester) async {
    await tester.pumpWidget(harness(const HomeScreen(),
        expenses: ExpenseState(expenses: [])));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có khoản chi nào'), findsOneWidget);
    expect(find.text('Mở camera và chụp khoản chi đầu tiên.'), findsOneWidget);
  });

  testWidgets('HomeScreen render PixelExpenseTile theo danh mục',
      (tester) async {
    final today = DateTime.now();
    await tester.pumpWidget(harness(
      const HomeScreen(),
      expenses: expenseState([makeExpense(caption: 'Đồ ăn trưa')]),
      categories: [Category(id: 10, name: 'Ăn uống', icon: 'forkKnife')],
      priorities: const [PriorityLevel(id: 0, name: 'Cần thiết', colorValue: 0xFF7BD8A8, sortOrder: 0)],
    ));
    await tester.pumpAndSettle();
    expect(find.byType(PixelExpenseTile), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Đồ ăn trưa'), findsOneWidget);
  });

  testWidgets('HomeScreen loading hiện PixelLoading, không spinner tròn',
      (tester) async {
    await tester.pumpWidget(harness(
      const HomeScreen(),
      expenses: expenseState(const [], loading: true),
    ));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('HomeScreen 1.3x text scale không overflow', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        expenseProvider.overrideWith(
          (ref) => _FakeExpenseNotifier(expenseState(
            [makeExpense(id: 1), makeExpense(id: 2)],
          )),
        ),
        categoryProvider.overrideWith(
          (ref) => _FakeCategoryNotifier(CategoryState(categories: [
            Category(id: 10, name: 'Ăn uống', icon: 'forkKnife'),
          ])),
        ),
        priorityProvider.overrideWith(
          (ref) => _FakePriorityNotifier(const PriorityState(levels: [
            PriorityLevel(id: 0, name: 'Cần thiết', colorValue: 0xFF7BD8A8, sortOrder: 0),
          ])),
        ),
        budgetProvider.overrideWith(
          (ref) => _FakeBudgetNotifier(BudgetState(
            month: '11/2026',
            totalSpent: 900000,
            totalBudget: Budget(month: '11/2026', amount: 1000000),
          )),
        ),
        authProvider.overrideWith(
          (ref) => _FakeAuthNotifier(const AppAuthState()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: const HomeScreen(),
            )),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
```

Bốn ràng buộc đã đọc trực tiếp trong repo, test ở trên đã viết theo đúng:
- `Category` (`lib/data/models/category.dart:8-14`): constructor **không `const`**, `name`/`icon` required, `id` optional → `CategoryState(categories: [Category(...)])`, không bọc `const` quanh list.
- `PriorityLevel` (`lib/data/models/priority_level.dart:9-14`): constructor **có `const`** nhưng **cả 4 tham số đều required** (`id, name, colorValue, sortOrder`) → mọi `PriorityLevel(...)` trong test phải có `colorValue:` và `sortOrder:`; test dùng hex accent Pixel (`0xFF7BD8A8` mint cho priority 0, `0xFFF28C9A` rose cho priority 3) để không phụ thuộc `AppColors`.
- `BudgetState` (`lib/providers/budget_provider.dart:31-43`): constructor `const`, **`month` required**, `totalBudgetAmount` **không phải tham số** mà là getter `totalBudget?.amount ?? 0` (dòng 45) → dựng `totalBudget: Budget(...)`; test overflow `BudgetState(month: '11/2026', totalSpent: 900000)` và `BudgetProgressCard` nhận `budget` từ `state.totalBudget?.amount ?? 0`.
- `_FakeExpenseNotifier.noSuchMethod` trả `_initial` (không gọi `super.noSuchMethod`) để `loadExpenses`/`refreshDashboard` là no-op thay vì ném lỗi — bắt buộc vì `HomeScreen.initState` gọi nạp dữ liệu.

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/widget/dashboard_pixel_test.dart`
Expected: FAIL — URI `dashboard_summary.dart` / `budget_progress_card.dart` không tồn tại.

- [ ] **Step 2: Tạo `DashboardSummary`**

Tạo `lib/screens/home/dashboard_summary.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_stat_tile.dart';

class DashboardSummary extends StatelessWidget {
  const DashboardSummary({
    super.key,
    required this.month,
    required this.today,
    required this.week,
    required this.expenseCount,
  });

  final double month;
  final double today;
  final double week;
  final int expenseCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return PixelPanel(
      background: palette.mint,
      borderColor: palette.lineStrong,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHI THÁNG NÀY',
            style: text.labelLarge?.copyWith(color: palette.mintInk),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(month),
              style: text.displayLarge?.copyWith(
                color: palette.onAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PixelStatTile(
                  label: 'HÔM NAY',
                  value: CurrencyFormatter.short(today),
                  glyph: 'calendar',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelStatTile(
                  label: 'TUẦN NÀY',
                  value: CurrencyFormatter.short(week),
                  glyph: 'filmStrip',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelStatTile(
                  label: 'SỐ KHOẢN',
                  value: '$expenseCount',
                  glyph: 'receipt',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

`CurrencyFormatter.short(double)` **chưa tồn tại** → thêm vào `lib/core/utils/currency_formatter.dart` (đây là file plan 3 đã sửa, giữ nguyên `format`/`parseInput`/`toEditableText`):

```dart
  /// '1.2 Tr' / '950 K' — dùng trong stat tile hẹp.
  static String short(double amount) {
    if (amount.abs() >= 1e9) {
      return '${(amount / 1e9).toStringAsFixed(1).replaceAll('.', ',')} T';
    }
    if (amount.abs() >= 1e6) {
      final millions = (amount / 1e6).toStringAsFixed(1);
      return '${millions.replaceAll('.', ',')} Tr';
    }
    if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} K';
    }
    return format(amount);
  }
```

Test stat tile không assert chuỗi ngắn cụ thể → an toàn. Nhưng test `DashboardSummary` assert `find.text('12')` cho SỐ KHOẢN (dùng `'$expenseCount'`), khớp.

- [ ] **Step 3: Tạo `BudgetProgressCard`**

Tạo `lib/screens/home/budget_progress_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_progress.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.spent,
    required this.budget,
    this.onTap,
  });

  final double spent;
  final double budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    if (budget <= 0) {
      return PixelPanel(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AppIcon(name: 'wallet', size: 32, color: palette.inkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chưa đặt ngân sách',
                style: text.bodyMedium?.copyWith(color: palette.ink),
              ),
            ),
            AppIcon(name: 'chevronRight', size: 16, color: palette.inkMuted),
          ],
        ),
      );
    }

    final ratio = spent / budget;
    final isOver = spent > budget;
    final remaining = budget - spent;

    return PixelPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NGÂN SÁCH THÁNG',
                  style: text.labelLarge?.copyWith(color: palette.inkMuted),
                ),
              ),
              Text(
                CurrencyFormatter.format(budget),
                style: text.bodyMedium?.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PixelProgress(
            value: ratio,
            segments: 10,
            fillColor: isOver ? palette.rose : palette.mint,
          ),
          const SizedBox(height: 8),
          Text(
            'Đã chi: ${CurrencyFormatter.format(spent)}',
            style: text.bodySmall?.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isOver
                  ? 'QUÁ NGÂN SÁCH: ${CurrencyFormatter.format(-remaining)}'
                  : 'Còn lại: ${CurrencyFormatter.format(remaining)}',
              style: text.titleSmall?.copyWith(
                color: isOver ? palette.danger : palette.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

`PixelProgress` render `showLabel` riêng nên ở đây tắt; `value` là tỉ lệ thô (widget tự clamp — plan 2 Task 7). Nhãn `'QUÁ NGÂN SÁCH'` giữ đúng copy FR-20.

Run: `flutter test test/widget/dashboard_pixel_test.dart -n "DashboardSummary\|BudgetProgressCard"`
Expected: PASS 4 test.

- [ ] **Step 4: Vẽ lại `HomeScreen`**

Sửa `lib/screens/home/home_screen.dart`:
1. **Xoá** 4 lớp private `_PhotoPreviewDialog` (423-492), `_SummaryCards` (494-648), `_BudgetProgressCard` (650-752), `_ExpenseTile` (754-897) và import `glass_card.dart`, `screen_background.dart`, `category_icon_badge.dart`, `priority_badge.dart`, `app_colors.dart`, `expense_card.dart` nếu có.
2. Thêm import: `dashboard_summary.dart`, `budget_progress_card.dart`, `expense_filter_sheet.dart` (Task 6 — tạm giữ `_FilterSheet` cũ tới hết Task 6), `../../widgets/pixel/pixel_screen_header.dart`, `../../widgets/pixel/pixel_expense_tile.dart`, `../../widgets/pixel/pixel_empty_state.dart`, `../../widgets/pixel/pixel_loading.dart`, `../../widgets/pixel/pixel_snack_bar.dart`, `../../widgets/pixel/pixel_button.dart`, `../../widgets/pixel/pixel_text_field.dart`, `../../widgets/pixel/pixel_chip.dart`.
3. Đổi `_ExpenseFilter` → `ExpenseFilter` **ở Task 6**; task này giữ nguyên tên private nhưng **không** sửa `_FilterSheet` (Task 6 sẽ thay cả cụm). Vì `_buildGroupedExpenses` dùng `_filter.isActive` → giữ nguyên.
4. `build`: bỏ `appBar:`; body là `Column` với `PixelScreenHeader(title: 'TỔNG QUAN', subtitle: 'Chào $displayName • ${DateFormatter.formatDate(DateTime.now())}', onMenuTap: widget.onMenuTap)` — `displayName` tính ngay trong `build` bằng đúng công thức `main_screen.dart:68-73`: `final user = ref.watch(authProvider).user; final email = user?.email; final name = (user?.userMetadata?['full_name'] as String?)?.trim(); final displayName = (name == null || name.isEmpty) ? (email != null ? email.split('@').first : 'Bạn') : name;` (thêm import `../../providers/auth_provider.dart` và `../../core/utils/date_formatter.dart`) rồi `Expanded(child: RefreshIndicator(onRefresh: _refresh, child: ListView(...)))`. ListView children:
   - `DashboardSummary(month: expenseState.monthTotal, today: expenseState.todayTotal, week: expenseState.weekTotal, expenseCount: expenseState.expenses.length)`
   - `BudgetProgressCard(spent: budgetState.totalSpent, budget: budgetState.totalBudget?.amount ?? 0, onTap: widget.onOpenBudget ?? _openBudget)` — thêm `final VoidCallback? onOpenBudget;` vào `HomeScreen` và trong `MainScreen` truyền `() => _selectSection(AppSection.budget)`.
   - Hàng tìm kiếm: `Row` gồm `Expanded(PixelTextField(key: const Key('dashboardSearch'), label: 'Tìm kiếm', hint: 'Tìm ghi chú, danh mục...', controller: _searchController, textInputAction: search, suffixGlyph: 'search', onSuffixTap: _applySearch, onSubmitted: (_) => _applySearch()))`, `SizedBox(width: 8)`, và `PixelIconButton(icon: 'filter', tooltip: 'Lọc giao dịch', onPressed: _showFilters)`; khi `_filter.isActive` vẽ thêm `Container(width: 8, height: 8, color: palette.butter)` ở góc trên trái nút lọc (không dùng `Badge` của Material). `PixelTextField` không có `textInputAction` trong API plan 2 → **không thêm tham số mới**, chỉ dùng `onSubmitted` + `onSuffixTap`.
   - Header danh sách: `Row` với `Text(_filter.isActive ? 'Kết quả lọc' : 'Giao dịch gần đây')` và `PixelButton(label: 'Xóa lọc', variant: ghost)` khi đang lọc.
   - `if (expenseState.errorMessage != null)` → `PixelPanel(background: palette.rose)` + `AppIcon('alert')` + message + `PixelButton(label: 'THỬ LẠI', onPressed: _refresh)`.
   - loading → `PixelLoading(blocks: 3, label: 'Đang tải…')`; **không còn `CircularProgressIndicator`**.
   - rỗng → `PixelEmptyState(glyph: 'receipt', title: 'Chưa có khoản chi nào', message: 'Mở camera và chụp khoản chi đầu tiên.', actionLabel: 'MỞ CAMERA', onAction: widget.onOpenFeed)`; thêm `final VoidCallback? onOpenFeed;` vào `HomeScreen`, `MainScreen` truyền `() => _selectSection(AppSection.feed)`. Nếu `_filter.isActive` thì title `Không tìm thấy khoản chi` / message `Thử bỏ bớt bộ lọc.` và actionLabel `XÓA BỘ LỌC` gọi reset filter.
   - khác → `..._buildGroupedExpenses(...)`.
5. `_buildGroupedExpenses`: giữ nguyên grouping bằng `DateUtils.dateOnly`; thay dòng header ngày bằng `pixelGroupHeader(DateFormatter.formatDate(entry.key))`; thay `_ExpenseTile(...)` bằng

```dart
          PixelExpenseTile(
            expense: expense,
            categoryName: categoryMap[expense.categoryId]?.name ?? 'Khác',
            categoryIconKey: categoryMap[expense.categoryId]?.icon ?? 'tag',
            onTap: (_) => _showEditSheet(expense),
            onDismiss: (_) => _moveToTrash(expense),
          ),
```

và tách logic trash vào method mới:

```dart
  Future<void> _moveToTrash(Expense expense) async {
    final id = expense.id;
    if (id == null) return;
    await ref.read(expenseProvider.notifier).moveToTrash(id);
    if (!mounted) return;
    showPixelSnackBar(
      context,
      'Đã chuyển khoản chi vào thùng rác.',
      actionLabel: 'Hoàn tác',
      onAction: () =>
          ref.read(expenseProvider.notifier).restoreExpense(id),
      tone: PixelTone.warning,
    );
  }
```

`onDismiss` của `Dismissible` làm row biến mất khỏi list — vì source of truth là `expenseProvider` và `moveToTrash` update state, danh sách tự rebuild; **không** dùng `ListView` key ổn định nào khác. Sau khi hoàn tác (`restoreExpense`) row xuất hiện lại.
6. Ảnh fullscreen: **không** giữ `_PhotoPreviewDialog`/`_showImageDialog` — Task 5 xóa cả hai vì sau khi `PixelExpenseTile.onTap` mở form sửa, không còn nơi gọi. Ảnh phóng to thuộc về feed (Task 9) qua `FeedPhotoPage`; không thêm `onLongPress` (YAGNI).
7. `MainScreen`: `AnimatedSwitcher(duration: const Duration(milliseconds: 160), child: ...)` (spec §3.8 120–180ms), và thêm `onOpenBudget` / `onOpenFeed` vào lời gọi `HomeScreen(...)` ở `main_screen.dart:48-51`.

- [ ] **Step 5: Chạy test và gate**

Run: `flutter test test/widget/dashboard_pixel_test.dart && flutter analyze`
Expected: PASS 8 test; analyze sạch (không còn `_PhotoPreviewDialog` unused).

Run: `grep -n "GlassCard\|ScreenBackground\|AppColors\|Icons\.\|LinearProgressIndicator\|CircularProgressIndicator" lib/screens/home/home_screen.dart`
Expected: không có kết quả.
Run: `wc -l lib/screens/home/home_screen.dart`
Expected: ≤ 520 dòng (giảm từ 1142).

Run: `flutter test`
Expected: PASS toàn bộ, số test = trước + 8.

- [ ] **Step 6: Commit (khi được ủy quyền)**

```bash
git add lib/screens/home/ lib/screens/main_screen.dart lib/core/utils/currency_formatter.dart test/widget/dashboard_pixel_test.dart
git commit -m "feat(ui): pixel dashboard with extracted summary and budget cards"
```

---

### Task 6: Sheet lọc khoản chi bằng component pixel (spec §5.12)

**Files:**
- Create: `lib/screens/home/expense_filter_sheet.dart`
- Modify: `lib/screens/home/home_screen.dart` (xoá `_ExpenseFilter:899-944` + `_FilterSheet:946-1141`, đổi `_showFilters` sang `ExpenseFilterSheet`)
- Modify: `test/widget/screens_test.dart` (nếu có test tham chiếu filter)
- Create: `test/widget/filter_sheet_test.dart`

**Interfaces:**
- Consumes: `showPixelSheet`, `PixelChip`, `PixelTextField`, `PixelButton`, `PixelDivider`, `AppIcon`, `ThousandsSeparatorInputFormatter` + `CurrencyFormatter.parseInput` (plan 3 Task 1-2).
- Produces:
  - `class ExpenseFilter` với `final String search; final DateTimeRange? dateRange; final int? categoryId; final int? priorityId; final double? minAmount; final double? maxAmount;` + `const ExpenseFilter({...})` + `bool get isActive` + `ExpenseFilter copyWith({...})` — **behavior đổi duy nhất**: tham số xóa phải clear được, nên dùng `Object? value = _sentinel`? **Không**: giữ nguyên semantics cũ (`copyWith` bỏ trống = giữ giá trị) và sheet luôn build object mới toàn phần như `_FilterSheet` hiện tại (dòng 1122-1130).
  - `Future<ExpenseFilter?> openExpenseFilterSheet(BuildContext context, {required ExpenseFilter initial, required List<Category> categories, required List<PriorityLevel> priorities})`

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/filter_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/priority_level.dart';
import 'package:chi_tieu/screens/home/expense_filter_sheet.dart';
import 'package:chi_tieu/widgets/pixel/pixel_chip.dart';
import 'package:chi_tieu/widgets/pixel/pixel_text_field.dart';

void main() {
  final categories = [
    Category(id: 1, name: 'Ăn uống', icon: 'forkKnife'),
    Category(id: 2, name: 'Đi lại', icon: 'car'),
  ];
  const priorities = [
    PriorityLevel(id: 0, name: 'Cần thiết', colorValue: 0xFF7BD8A8, sortOrder: 0),
    PriorityLevel(id: 3, name: 'Không cần', colorValue: 0xFFF28C9A, sortOrder: 3),
  ];

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(builder: (context) => Scaffold(
            body: Center(
              child: PixelButton(
                label: 'Lọc',
                onPressed: () => openExpenseFilterSheet(
                  context,
                  initial: const ExpenseFilter(),
                  categories: categories,
                  priorities: priorities,
                ),
              ),
            ),
          )),
    ));
    await tester.tap(find.text('Lọc'));
    await tester.pumpAndSettle();
  }

  testWidgets('sheet có chip danh mục, mức độ và 2 ô số tiền',
      (tester) async {
    await openSheet(tester);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Cần thiết'), findsOneWidget);
    expect(find.byType(PixelChip), findsWidgets);
    expect(find.byType(PixelTextField), findsNWidgets(2));
    expect(find.text('Từ số tiền'), findsOneWidget);
    expect(find.text('Đến số tiền'), findsOneWidget);
  });

  testWidgets('nhập 1000000 được parse qua CurrencyFormatter',
      (tester) async {
    await openSheet(tester);
    final fields = find.byType(PixelTextField);
    await tester.enterText(fields.first, '1000000');
    await tester.pump();
    expect(find.text('1.000.000'), findsOneWidget);
    await tester.tap(find.text('ÁP DỤNG'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('chip danh mục bật/tắt đúng một lần chạm', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Ăn uống'));
    await tester.pump();
    final chip = tester.widget<PixelChip>(
      find.ancestor(of: find.text('Ăn uống'), matching: find.byType(PixelChip)),
    );
    expect(chip.selected, isTrue);
    await tester.tap(find.text('Ăn uống'));
    await tester.pump();
    final chip2 = tester.widget<PixelChip>(
      find.ancestor(of: find.text('Ăn uống'), matching: find.byType(PixelChip)),
    );
    expect(chip2.selected, isFalse);
  });

  testWidgets('nút XÓA BỘ LỌC trả về filter rỗng', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('XÓA BỘ LỌC'));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseFilterSheet), findsNothing);
  });
}
```

Đã chốt bằng cách đọc repo: `Category` **không** có constructor `const` (`lib/data/models/category.dart:8`) nên `categories` là `final`, còn `PriorityLevel` **có** constructor `const` (`lib/data/models/priority_level.dart:9`) nên `const priorities = [...]` giữ nguyên — chỉ cần thêm `colorValue:` và `sortOrder:` vì cả 4 tham số đều required. Thêm `import 'package:chi_tieu/widgets/pixel/pixel_button.dart';` cho nút 'Lọc'.

Run: `flutter test test/widget/filter_sheet_test.dart`
Expected: FAIL — URI `expense_filter_sheet.dart` không tồn tại.

- [ ] **Step 2: Tạo `ExpenseFilter` + `ExpenseFilterSheet`**

Tạo `lib/screens/home/expense_filter_sheet.dart` — **copy nguyên trạng** `_ExpenseFilter` (dòng 899-944) và `_FilterSheetState._pickDateRange`/`initState`/controllers (dòng 961-1000) từ `home_screen.dart` sang, đổi tên thành public `ExpenseFilter` / `ExpenseFilterSheet`, rồi thay phần `build` (dòng 1000-1141) bằng pixel components:

```dart
    return showPixelSheet<ExpenseFilter>(
      context: context,
      title: 'Lọc giao dịch',
      builder: (_) => ExpenseFilterSheet(
        initial: initial,
        categories: categories,
        priorities: priorities,
      ),
    );
```

Bên trong `ExpenseFilterSheet.build`:
- `Padding(EdgeInsets.all(20))` → `Column(crossAxisAlignment: stretch)` bọc trong `SingleChildScrollView` + `Form`? Không cần `Form` (không validate) → dùng `Column` với `PixelTextField` tự quản lý.
- `Text('Khoảng thời gian', style: text.titleSmall)`.
- `PixelButton(label: _dateRange == null ? 'CHỌN KHOẢNG NGÀY' : '${DateFormatter.formatDate(_dateRange!.start)} – ${DateFormatter.formatDate(_dateRange!.end)}', icon: 'calendar', variant: PixelButtonVariant.secondary, expanded: true, onPressed: _pickDateRange)`.
- `if (_dateRange != null) PixelButton(key: const ValueKey('clear-date'), label: 'Bỏ lọc thời gian', icon: 'close', variant: PixelButtonVariant.ghost, onPressed: () => setState(() => _dateRange = null))`.
- `Text('Danh mục', ...)` + `Wrap(spacing: 8, runSpacing: 8, children: [PixelChip(label: 'Tất cả', icon: 'dotsThreeOutline', selected: _categoryId == null, onTap: () => setState(() => _categoryId = null)), for (final c in categories) PixelChip(label: c.name, icon: IconHelper.normalizeIconKey(c.icon), selected: _categoryId == c.id, onTap: () => setState(() => _categoryId = _categoryId == c.id ? null : c.id))])`.
- `Text('Mức độ cần thiết', ...)` + `Wrap` tương tự với `priorities`, `accent: palette.priorityColor(p.id)`.
- `Row` hai `Expanded`: `PixelTextField(key: const Key('filterMin'), label: 'Từ số tiền', controller: _minController, keyboardType: TextInputType.number, inputFormatters: [const ThousandsSeparatorInputFormatter()])` và `PixelTextField(key: const Key('filterMax'), label: 'Đến số tiền', ...)`; giữa là `SizedBox(width: 12)`.
- `PixelDivider()` rồi `Row`: `PixelButton(key: const ValueKey('clear-filter'), label: 'XÓA BỘ LỌC', variant: ghost, onPressed: () => Navigator.pop(context, const ExpenseFilter()))` + `Spacer()` + `PixelButton(label: 'ÁP DỤNG', icon: 'check', onPressed: _apply)`.
- `_apply()` build `ExpenseFilter(search: widget.initial.search, dateRange: _dateRange, categoryId: _categoryId, priorityId: _priorityId, minAmount: CurrencyFormatter.parseInput(_minController.text), maxAmount: CurrencyFormatter.parseInput(_maxController.text))` rồi `Navigator.pop(context, filter)`.

`PixelChip.onTap` (plan 2 Task 7) thay cho `ChoiceChip.onSelected`; `showCheck` để mặc định `true` cho danh mục, `false` cho 'Tất cả'.

- [ ] **Step 3: Nối vào HomeScreen**

Sửa `lib/screens/home/home_screen.dart`:
- Xoá toàn bộ `_ExpenseFilter` và `_FilterSheet`/`_FilterSheetState`.
- `import 'expense_filter_sheet.dart';`, field `ExpenseFilter _filter = const ExpenseFilter();`.
- `_showFilters()` thành:

```dart
  Future<void> _showFilters() async {
    final selected = await openExpenseFilterSheet(
      context,
      initial: _filter,
      categories: ref.read(categoryProvider).categories,
      priorities: ref.read(priorityProvider).levels,
    );
    if (selected == null) return;
    _searchController.text = selected.search;
    setState(() => _filter = selected);
    await _loadFilteredExpenses();
  }
```

- `_loadFilteredExpenses()` và `_applySearch()` giữ nguyên, chỉ đổi kiểu `_filter` → `_filter.dateRange` / `.search` / `.categoryId` / `.priorityId` / `.minAmount` / `.maxAmount` (giống hệt field cũ).
- `grep -n "_ExpenseFilter\|_FilterSheet" lib/screens/home/home_screen.dart` → Expected: không còn kết quả.

- [ ] **Step 4: Chạy test và gate**

Run: `flutter test test/widget/filter_sheet_test.dart && flutter test && flutter analyze`
Expected: PASS 4 test mới, toàn bộ PASS, analyze sạch.

Run: `grep -rn "TextInputType.number" lib/screens/home/expense_filter_sheet.dart`
Expected: 2 kết quả, mỗi chỗ kèm `inputFormatters: [const ThousandsSeparatorInputFormatter()]`.

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/screens/home/expense_filter_sheet.dart lib/screens/home/home_screen.dart test/widget/filter_sheet_test.dart
git commit -m "feat(ui): pixel expense filter sheet"
```

---

### Task 7: Form khoản chi pixel (spec §5.4)

**Files:**
- Modify: `lib/screens/camera/expense_form_sheet.dart` (viết lại `build`, giữ nguyên `_saveExpense`, `dispose`, `_didSave`)
- Modify: `lib/screens/camera/camera_screen.dart:170-192` (`_openExpenseForm`)
- Create: `test/widget/expense_form_pixel_test.dart`

**Interfaces:**
- Consumes: `showPixelSheet(context:, title:, fullScreen: true, builder:)` (plan 2 Task 8), `PixelReceiptImage`, `PixelChip`, `PixelButton`, `PixelTextField`, `AppIcon`, `context.palette`, `ThousandsSeparatorInputFormatter` + `CurrencyFormatter.parseInput/toEditableText` (plan 3 Task 1-2), `ExpenseDateTimeField` (plan 3 Task 4), `IconHelper.normalizeIconKey`.
- Produces:
  - `ExpenseFormSheet({Key? key, String? imagePath, Expense? expense})` — chữ ký **không đổi**
  - `Future<void> openExpenseForm(BuildContext context, {String? imagePath, Expense? expense})` trong `expense_form_sheet.dart` — bọc `showPixelSheet`, để `camera_screen.dart` và dashboard cùng dùng một đường mở

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/expense_form_pixel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/models/priority_level.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/providers/expense_provider.dart';
import 'package:chi_tieu/providers/priority_provider.dart';
import 'package:chi_tieu/screens/camera/expense_form_sheet.dart';
import 'package:chi_tieu/widgets/pixel/pixel_button.dart';
import 'package:chi_tieu/widgets/pixel/pixel_chip.dart';
import 'package:chi_tieu/widgets/pixel/pixel_receipt_image.dart';
import 'package:chi_tieu/widgets/pixel/pixel_text_field.dart';

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePriorityNotifier extends StateNotifier<PriorityState>
    implements PriorityNotifier {
  _FakePriorityNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _FakeExpenseNotifier() : super(const ExpenseState());
  @override
  dynamic noSuchMethod(Invocation invocation) => const ExpenseState();
}

final categories = [
  Category(id: 1, name: 'Ăn uống', icon: 'forkKnife'),
  Category(id: 2, name: 'Khác', icon: 'receipt'),
];

Widget sheet(Widget child) => ProviderScope(
      overrides: [
        categoryProvider.overrideWith(
          (ref) => _FakeCategoryNotifier(CategoryState(categories: categories)),
        ),
        priorityProvider.overrideWith(
          (ref) => _FakePriorityNotifier(const PriorityState(levels: [
            PriorityLevel(id: 0, name: 'Cần thiết', colorValue: 0xFF7BD8A8, sortOrder: 0),
            PriorityLevel(id: 3, name: 'Không cần', colorValue: 0xFFF28C9A, sortOrder: 3),
          ])),
        ),
        expenseProvider.overrideWith((ref) => _FakeExpenseNotifier()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showPixelSheet<void>(
                  context: context,
                  title: 'Thêm khoản chi',
                  fullScreen: true,
                  builder: (_) => child,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('form mới dùng PixelReceiptImage + 2 PixelTextField + chip',
      (tester) async {
    await tester.pumpWidget(sheet(
      const ExpenseFormSheet(imagePath: '/tmp/khong_co_file.jpg'),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PixelReceiptImage), findsOneWidget);
    expect(find.byType(PixelTextField), findsNWidgets(2));
    expect(find.byType(PixelChip), findsWidgets);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Không chọn danh mục sẽ tự xếp vào Khác.'),
        findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('nhập 1234567 hiển thị 1.234.567', (tester) async {
    await tester.pumpWidget(sheet(
      const ExpenseFormSheet(imagePath: '/tmp/khong_co_file.jpg'),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expenseAmountField')),
      '1234567',
    );
    await tester.pump();
    expect(find.text('1.234.567'), findsOneWidget);
  });

  testWidgets('số tiền 0 bị chặn, không gọi provider', (tester) async {
    await tester.pumpWidget(sheet(
      const ExpenseFormSheet(imagePath: '/tmp/khong_co_file.jpg'),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PixelButton).last);
    await tester.pump();
    expect(find.text('Nhập số tiền lớn hơn 0'), findsOneWidget);
  });

  testWidgets('đang sửa: ảnh là PixelReceiptImage và có ghi chú không đổi ảnh',
      (tester) async {
    final expense = Expense(
      id: 5,
      caption: 'Đồ ăn',
      amount: 30000,
      categoryId: 1,
      priority: 0,
      imagePath: 'uuid/a.png',
      createdAt: DateTime(2026, 11, 1, 12),
    );
    await tester.pumpWidget(sheet(ExpenseFormSheet(expense: expense)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa khoản chi'), findsOneWidget);
    expect(find.text('Ảnh không thể thay đổi sau khi đã lưu.'), findsOneWidget);
    expect(find.text('LƯU THAY ĐỔI'), findsOneWidget);
  });

  testWidgets('form có ô ngày giờ của plan 3', (tester) async {
    await tester.pumpWidget(sheet(
      const ExpenseFormSheet(imagePath: '/tmp/khong_co_file.jpg'),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Ngày giờ ghi nhận'), findsOneWidget);
    expect(find.text('Bây giờ'), findsOneWidget);
  });
}
```

Thêm `import 'package:chi_tieu/widgets/pixel/pixel_sheet.dart';` vào file test (cho `showPixelSheet`). Kiểm tra `PriorityState` có constructor `const PriorityState({levels, isLoading})` (đã xác minh `lib/providers/priority_provider.dart:10`) và `CategoryState(categories: ...)` **không const** — sửa test theo nếu grep cho kết quả khác.

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/widget/expense_form_pixel_test.dart`
Expected: FAIL — vẫn là `TextFormField`, chưa có `Key('expenseAmountField')`.

- [ ] **Step 2: Viết lại `build` của `ExpenseFormSheet`**

Giữ **nguyên văn** `_saveExpense()` (dòng 47-127), `dispose()` (dòng 130-141), `initState()` và các field `_formKey/_captionController/_amountController/_selectedCategoryId/_selectedPriority/_isSaving/_didSave` + `_occurredAt/_dateError` (plan 3 Task 4).

`build` mới (thay toàn bộ từ `return Padding(` đến hết widget):

```dart
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: PixelReceiptImage.fromExpenseSource(
                    localPath: _sourceImagePath,
                    expense: widget.expense,
                    semanticLabel: 'Ảnh khoản chi',
                  ),
                ),
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Ảnh không thể thay đổi sau khi đã lưu.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: palette.inkMuted),
                  ),
                ),
              const SizedBox(height: 16),
              PixelTextField(
                label: 'Ghi chú (tùy chọn)',
                hint: 'Ví dụ: Ăn trưa, mua sữa...',
                controller: _captionController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              PixelTextField(
                key: const Key('expenseAmountField'),
                label: 'Số tiền (VND)',
                hint: '35000',
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsSeparatorInputFormatter()],
                validator: (value) {
                  final amount = CurrencyFormatter.parseInput(value ?? '');
                  return amount == null || amount <= 0
                      ? 'Nhập số tiền lớn hơn 0'
                      : null;
                },
              ),
              const SizedBox(height: 20),
              ExpenseDateTimeField(
                value: _occurredAt,
                maxNow: widget.$maxNow,
                onChanged: (next) => setState(() => _occurredAt = next),
              ),
              if (_dateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _dateError!,
                    style: text.bodySmall?.copyWith(color: palette.danger),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Danh mục', style: text.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Không chọn danh mục sẽ tự xếp vào Khác.',
                style: text.bodySmall?.copyWith(color: palette.inkMuted),
              ),
              const SizedBox(height: 8),
              if (categoryState.isLoading && categoryState.categories.isEmpty)
                const PixelLoading(blocks: 3)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in categoryState.categories)
                      PixelChip(
                        label: category.name,
                        icon: IconHelper.normalizeIconKey(category.icon),
                        selected: _selectedCategoryId == category.id,
                        accent: palette.accentForCategory(category.name),
                        onTap: () => setState(() {
                          _selectedCategoryId =
                              _selectedCategoryId == category.id
                              ? null
                              : category.id;
                        }),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              Text('Mức độ cần thiết', style: text.titleSmall),
              const SizedBox(height: 8),
              if (priorityState.levels.isEmpty)
                const PixelLoading(blocks: 3)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final level in priorityState.levels)
                      PixelChip(
                        label: level.name,
                        selected: _selectedPriority == level.id,
                        accent: palette.priorityColor(level.id),
                        onTap: () =>
                            setState(() => _selectedPriority = level.id),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              PixelButton(
                label: _isEditing ? 'LƯU THAY ĐỔI' : 'LƯU KHOẢN CHI',
                icon: 'check',
                expanded: true,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveExpense,
              ),
            ],
          ),
        ),
      ),
    );
```

Ba chỗ phải chỉnh cho khớp code thật, **không được để code sai trong file**:
1. `PixelReceiptImage.fromExpenseSource(...)` không tồn tại → thay bằng `PixelReceiptImage.fromExpense(widget.expense!)` khi sửa, và `PixelReceiptImage(localPath: _isLocalDraft ? _sourceImagePath : null, displayUrl: _sourceImagePath?.startsWith('http') == true ? _sourceImagePath : null, cacheKey: _isLocalDraft ? null : _sourceImagePath)` khi tạo mới. **Đơn giản hoá**: thêm vào `pixel_receipt_image.dart` (Task 1) một factory nữa:

```dart
  factory PixelReceiptImage.source(
    String? path, {
    Expense? expense,
    String? semanticLabel,
  }) {
    if (expense != null) return PixelReceiptImage.fromExpense(expense);
    if (path == null || path.isEmpty) return PixelReceiptImage(semanticLabel: semanticLabel);
    return PixelReceiptImage(
      localPath: path.startsWith('http') ? null : path,
      displayUrl: path.startsWith('http') ? path : null,
      cacheKey: path.startsWith('http') ? path : null,
      semanticLabel: semanticLabel,
    );
  }
```
(`cacheKey` cho draft http là chính URL — `CachedNetworkImage` vẫn cache đúng.) Dùng `PixelReceiptImage.source(_sourceImagePath, expense: widget.expense, semanticLabel: 'Ảnh khoản chi')` trong form, và **thêm test factory này vào `test/unit/pixel_receipt_image_test.dart` ở Task 1** (2 case: path local → `localPath`, path http → `displayUrl`).
2. `widget.$maxNow` không tồn tại → `ExpenseDateTimeField` của plan 3 nhận `maxNow` để test chèn thời gian. `ExpenseFormSheet` không có field đó → **thêm vào `ExpenseFormSheet`**: `@visibleForTesting final DateTime? maxNow;` trong constructor (`const`? không — constructor hiện là `const ExpenseFormSheet({super.key, this.imagePath, this.expense})`; giữ `const` không được vì thêm field có default → vẫn `const` được nếu `DateTime? maxNow` là final field với default `null`. Viết: `this.maxNow`). Truyền `maxNow: maxNow` xuống `ExpenseDateTimeField`.
3. `PixelLoading` cần `import '.../pixel_loading.dart';`, `ThousandsSeparatorInputFormatter` cần `import '../../core/utils/amount_input_formatter.dart';`.

`_saveExpense` đổi 2 dòng theo plan 3 (parse + createdAt):
- `final amount = CurrencyFormatter.parseInput(_amountController.text);` (thay `double.tryParse(text.replaceAll(...))`)
- `createdAt: _occurredAt` trong `Expense(...)` và `copyWith(createdAt: _occurredAt)` khi sửa.

- [ ] **Step 3: Đường mở sheet thống nhất**

Thêm vào cuối `lib/screens/camera/expense_form_sheet.dart`:

```dart
Future<void> openExpenseForm(
  BuildContext context, {
  String? imagePath,
  Expense? expense,
}) => showPixelSheet<void>(
  context: context,
  title: expense == null ? 'Thêm khoản chi' : 'Chỉnh sửa khoản chi',
  fullScreen: true,
  builder: (_) => ExpenseFormSheet(imagePath: imagePath, expense: expense),
);
```

Sửa `camera_screen.dart:174-180`: thay khối `await showModalBottomSheet(...)` bằng `await openExpenseForm(context, imagePath: imagePath, expense: expense);`. `ExpenseFormSheet` bên trong gọi `Navigator.of(context).pop()` → vẫn đóng sheet vì sheet là một route.
Sửa `home_screen.dart` `_showEditSheet(expense)` (dòng 112-120) tương tự bằng `openExpenseForm(context, expense: expense)`.
Giữ `import 'package:flutter/material.dart'` (vẫn cần cho `StatefulWidget`). Xóa `_buildSquareImage()` (dòng 306-340) cùng `import 'dart:io';` và `import 'package:cached_network_image/cached_network_image.dart';` khi không còn dùng trong file.

Run: `grep -n "showModalBottomSheet\|CachedNetworkImage\|Image.file" lib/screens/camera/expense_form_sheet.dart`
Expected: không có kết quả.

- [ ] **Step 4: Chạy test và gate**

Run: `flutter test test/widget/expense_form_pixel_test.dart && flutter test && flutter analyze`
Expected: PASS 5 test mới, toàn bộ PASS, analyze sạch.

Run: `grep -rn "CachedNetworkImage" lib/screens/`
Expected: không còn kết quả nào sau Task 9 (task này chỉ còn feed). Ghi lại file còn lại để Task 9 xoá.

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/screens/camera/expense_form_sheet.dart lib/screens/camera/camera_screen.dart lib/screens/home/home_screen.dart lib/widgets/pixel/pixel_receipt_image.dart test/widget/expense_form_pixel_test.dart
git commit -m "feat(ui): pixel expense form sheet"
```

---

### Task 8: HUD camera / feed tối theo pixel (spec §3.7)

**Files:**
- Modify: `lib/screens/camera/camera_screen.dart` (790 dòng; các khối 302-345 build, 347-414 `_buildTopBar`, 416-484 `_buildCameraControls`, 485-546 `_CameraFeedPage`, 574-646 `_FeedNoticeCard`, 647-693 `_CountBadge`, 694-729 `_RoundOverlayButton`, 730-790 `_ShutterButton`)
- Create: `test/widget/feed_hud_test.dart`

**Interfaces:**
- Consumes: `AppIcon`, `PixelIconButton`, `PixelBadge`, `PixelPanel`, `PixelButton`, `PixelEmptyState`, `PixelLoading`, `HamburgerButton(light: true)` (plan 2 Task 9 giữ chữ ký `onTap`/`light`), `context.palette` (token `feedBg/feedPanel/feedInk/feedMuted`), `openExpenseForm` (Task 7).
- Produces:
  - `LinearGradient hudTopGradient(AppPalette palette)` và `LinearGradient hudBottomGradient(AppPalette palette)` — helper private trong `camera_screen.dart`, dùng `palette.feedBg.withValues(alpha: …)`, **không** dùng `AppColors`.
  - Mapping icon cũ → glyph (bắt buộc dùng đúng bảng này, mọi khóa đều đã có trong registry):

| `Icons.` đang dùng (dòng) | Glyph |
| --- | --- |
| `grid_view_rounded` (403) | `grid` |
| `keyboard_arrow_up_rounded` (443) | `chevronDown` (nhãn 'Thu gọn' — chiều mũi tên đảo khi thu) |
| `photo_library_rounded` (454, 634) | `filmStrip` |
| `flip_camera_ios_rounded` (465) | `refresh` |
| `add_a_photo_rounded` (471) | `plus` |
| `no_photography_rounded` (522) | `cloudOff` |
| `auto_awesome_rounded` (535) | `sparkle` |
| `camera_alt_rounded` (781) | `camera` |

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/feed_hud_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/providers/expense_provider.dart';
import 'package:chi_tieu/providers/priority_provider.dart';
import 'package:chi_tieu/screens/camera/camera_screen.dart';
import 'package:chi_tieu/widgets/hamburger_button.dart';
import 'package:chi_tieu/widgets/pixel/app_icon.dart';
import 'package:chi_tieu/widgets/pixel/pixel_badge.dart';

class _FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _FakeExpenseNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePriorityNotifier extends StateNotifier<PriorityState>
    implements PriorityNotifier {
  _FakePriorityNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget feed() => ProviderScope(
      overrides: [
        expenseProvider.overrideWith((ref) => _FakeExpenseNotifier(const ExpenseState())),
        categoryProvider.overrideWith(
          (ref) => _FakeCategoryNotifier(const CategoryState()),
        ),
        priorityProvider.overrideWith(
          (ref) => _FakePriorityNotifier(const PriorityState()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const CameraScreen(onMenuTap: _noop),
      ),
    );

void _noop() {}

void main() {
  testWidgets('HUD hiện nhãn NHẬT KÝ + nút menu 48dp, không còn Icons.*',
      (tester) async {
    await tester.pumpWidget(feed());
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('NHẬT KÝ'), findsOneWidget);
    expect(find.byType(HamburgerButton), findsOneWidget);
    expect(find.byIcon(Icons.grid_view), findsNothing);
    expect(find.byIcon(Icons.camera_alt), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nút lưới ẩn khi chưa có ảnh', (tester) async {
    await tester.pumpWidget(feed());
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(PixelBadge), findsNothing);
  });

  testWidgets('màn camera không dùng AppColors gradient cũ', (tester) async {
    await tester.pumpWidget(feed());
    await tester.pump(const Duration(milliseconds: 50));
    for (final d in tester.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
      final dec = d.decoration;
      if (dec is BoxDecoration && dec.gradient is LinearGradient) {
        final colors = (dec.gradient as LinearGradient).colors;
        for (final c in colors) {
          expect(c.a, greaterThanOrEqualTo(0), reason: 'gradient phải hợp lệ');
        }
      }
    }
    expect(find.byType(AppIcon), findsWidgets);
  });
}
```

`CategoryState` **có** constructor `const` (`lib/providers/category_provider.dart:11-15`, mọi field đều có default) nên `const CategoryState()` hợp lệ. `CameraScreen({super.key, this.onMenuTap})` (`lib/screens/camera/camera_screen.dart:19-27`). Camera plugin không init được trong test → `_isCameraInitializing`/`_cameraError` khiến `_CameraFeedPage` hiện notice card: **đây chính là đường test mong đợi**, không mock `camera`.

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/widget/feed_hud_test.dart`
Expected: FAIL — `find.textContaining('NHẬT KÝ')` không thấy (label đang là 'Chi Tiêu'), `find.byIcon(Icons.camera_alt)` vẫn có.

- [ ] **Step 2: Sửa HUD**

`camera_screen.dart`:
1. Xóa `import '../../core/constants/app_colors.dart';`; thêm `../../core/theme/app_palette.dart`, `../../widgets/pixel/app_icon.dart`, `../../widgets/pixel/app_icon.dart` (`AppIcon` **và** `PixelIconButton` cùng sống trong file này — đã xác minh plan 2 Task 5; không có file `pixel_icon_button.dart`), `../../widgets/pixel/pixel_badge.dart`, `../../widgets/pixel/pixel_panel.dart`, `../../widgets/pixel/pixel_button.dart`, `../../widgets/pixel/pixel_empty_state.dart`, `../../widgets/pixel/pixel_loading.dart`.
2. `Scaffold(backgroundColor: palette.feedBg)` — `final palette = context.palette;` lấy trong `build` và truyền xuống các widget private qua tham số hoặc dùng `context.palette` tại chỗ (chọn cách sau: các private widget tự đọc `context.palette`).
3. `_buildTopBar`: `DecoratedBox(decoration: BoxDecoration(gradient: hudTopGradient(palette)))`; `HamburgerButton(onTap: widget.onMenuTap, light: true)` giữ nguyên; `Text('Chi Tiêu')` → `Text('NHẬT KÝ ${DateFormat('MM/yyyy').format(DateTime.now())}', style: text.titleMedium?.copyWith(color: palette.feedInk))` (VT323 do theme, `FittedBox`); subtitle `color: palette.feedMuted`, `AnimatedSwitcher` rút xuống `Duration(milliseconds: 120)`.
4. `_CountBadge` → `PixelBadge(glyph: 'grid', label: isCameraPage ? '${photos.length} ảnh' : '$_pageIndex/$_total', accent: palette.feedPanel, ink: palette.feedInk)` và `onTap`: `PixelBadge` không có `onTap` → bọc `PixelIconButton(icon: 'grid', tooltip: 'Xem lưới ảnh', onPressed: _openPhotoGrid, background: palette.feedPanel, iconColor: palette.feedInk)` + `PixelBadge` kế bên trong một `Row`. **Bỏ hoàn toàn class `_CountBadge`** (dòng 647-693).
5. `_buildCameraControls`: gradient bottom qua `hudBottomGradient(palette)`; `Text` → `style: text.labelLarge?.copyWith(color: palette.feedMuted)`; `_RoundOverlayButton` (694-729) **xóa**, thay mọi chỗ bằng `PixelIconButton(..., background: palette.feedPanel, iconColor: palette.feedInk)` với glyph theo bảng; `_ShutterButton` (730-790) **xóa**, thay bằng widget mới khai báo cuối file:

```dart
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed, required this.enabled});

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: 'Chụp khoản chi',
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: enabled ? palette.mint : palette.feedPanel,
            border: Border.all(color: palette.feedInk, width: 4),
          ),
          child: Center(
            child: AppIcon(
              name: 'camera',
              size: 32,
              color: enabled ? palette.onAccent : palette.feedMuted,
            ),
          ),
        ),
      ),
    );
  }
}
```

6. `_CameraFeedPage` (485-546): `AppColors.pageGradientDark` → `ColoredBox(color: palette.feedBg)`; `Icons.no_photography_rounded` → `AppIcon(name: 'cloudOff', size: 48, color: palette.feedMuted)`; `Icons.auto_awesome_rounded` → `AppIcon(name: 'sparkle', …)`; 2 nút `ElevatedButton`/`TextButton` → `PixelButton(label: 'MỞ CAMERA', icon: 'camera', onPressed: ...)` và `PixelButton(label: 'CHỌN ẢNH TỪ THƯ VIỆN', icon: 'filmStrip', variant: PixelButtonVariant.secondary, onPressed: onPickFromGallery)`; loading camera → `PixelLoading(label: 'Đang mở camera…')` (thay `CircularProgressIndicator`).
7. `_FeedNoticeCard` (574-646): đổi `Container`+`borderRadius` → `PixelPanel(background: palette.feedPanel, borderColor: palette.mint, child: Row(AppIcon + 2 Text + PixelButton(label:'MỞ THƯ VIỆN', icon:'filmStrip', variant: ghost)))`; `Icon(icon, color: AppColors.primaryLight)` → `AppIcon(name: iconKey, color: palette.mint)` với `iconKey` là `String` (thay field `IconData icon` hiện có thành `String glyph`).
8. Khung ngắm 4 góc (spec §3.7): trong `_CameraFeedPage`, bọc `_FullScreenCameraPreview` (547-573) bằng `Stack` + 4 `Positioned` mỗi cái là `Container(width: 24, height: 24, decoration: border chỉ 2 cạnh, color: palette.feedInk)`; **không** áp filter/pixelate lên `CameraPreview`.
9. `AppColors.` / `Icons.` còn sót: `grep -n "AppColors\.\|Icons\." lib/screens/camera/camera_screen.dart` → Expected: không kết quả.

- [ ] **Step 3: Chạy test và gate**

Run: `flutter test test/widget/feed_hud_test.dart && flutter analyze`
Expected: PASS 3 test, analyze sạch.

Run: `grep -c "PixelIconButton" lib/screens/camera/camera_screen.dart`
Expected: ≥ 3 (grid, thư viện/lật camera, chụp ảnh gallery).

- [ ] **Step 4: Commit (khi được ủy quyền)**

```bash
git add lib/screens/camera/camera_screen.dart test/widget/feed_hud_test.dart
git commit -m "feat(ui): pixel HUD for camera and feed chrome"
```

---

### Task 9: Lưới ảnh và trang ảnh trong feed (spec §3.7, FR-19)

**Files:**
- Modify: `lib/screens/camera/feed_grid_screen.dart` (173 dòng)
- Modify: `lib/screens/camera/camera_screen.dart:260-269` (call site duy nhất của `FeedGridScreen`)
- Modify: `lib/screens/camera/feed_photo_page.dart` (275 dòng)
- Modify: `test/unit/feed_helpers_test.dart` (chỉ khi `buildFeedPhotos` đổi — **không đổi**)
- Create: `test/widget/feed_photo_test.dart`

**Interfaces:**
- Consumes: `PixelReceiptImage`, `PixelIconButton`, `PixelBadge`, `PixelEmptyState`, `AppIcon`, `context.palette`, `CurrencyFormatter.format`, `DateFormatter.formatDate/formatTime`, `openExpenseForm` (Task 7), `buildFeedPhotos`.
- Produces:
  - `FeedGridScreen({Key? key, required List<Expense> expenses, Map<int, Category> categoriesById})` với `categoriesById` default `const {}` — trả `int?` index qua `Navigator.pop(context, index)` như cũ
  - `FeedPhotoPage({Key? key, required Expense expense, required VoidCallback onEdit, required VoidCallback onDelete, Category? category, PriorityLevel? priority})` — **chữ ký không đổi so với repo** (`feed_photo_page.dart:22-29`): `onEdit`/`onDelete` required, `category`/`priority` nullable
  - `class FeedCaptionPanel extends StatelessWidget` (mới, trong `feed_photo_page.dart`): `FeedCaptionPanel({required Expense expense, required String categoryName, required String priorityName})`

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/feed_photo_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/models/priority_level.dart';
import 'package:chi_tieu/widgets/pixel/pixel_badge.dart';
import 'package:chi_tieu/widgets/pixel/pixel_receipt_image.dart';
import 'package:chi_tieu/screens/camera/feed_grid_screen.dart';
import 'package:chi_tieu/screens/camera/feed_photo_page.dart';

final photos = [
  Expense(
    id: 1,
    caption: 'Bún chả',
    amount: 60000,
    categoryId: 10,
    priority: 0,
    imagePath: 'u/a.png',
    createdAt: DateTime(2026, 11, 1, 12, 30),
  ),
  Expense(
    id: 2,
    caption: 'Xe bus',
    amount: 7000,
    categoryId: 11,
    priority: 3,
    createdAt: DateTime(2026, 11, 1, 9),
  ),
];

final categories = <int, Category>{
  10: Category(id: 10, name: 'Ăn uống', icon: 'forkKnife'),
  11: Category(id: 11, name: 'Đi lại', icon: 'car'),
};

Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: SizedBox(width: 400, height: 800, child: child)),
    );

void main() {
  testWidgets('lưới 3 cột, đủ số ảnh, chạm trả index', (tester) async {
    await tester.pumpWidget(wrap(FeedGridScreen(
      expenses: photos,
      categoriesById: categories,
    )));
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(find.byType(PixelReceiptImage), findsNWidgets(2));
    expect(find.text('2 ảnh'), findsOneWidget);
  });

  testWidgets('lưới rỗng hiện empty state', (tester) async {
    await tester.pumpWidget(wrap(const FeedGridScreen(
      expenses: [],
      categoriesById: {},
    )));
    expect(find.text('Chưa có khoản chi nào'), findsOneWidget);
    expect(find.text('Mở camera và chụp khoản chi đầu tiên.'), findsOneWidget);
  });

  testWidgets('trang ảnh hiện panel: badge, số tiền, ghi chú, ngày giờ',
      (tester) async {
    await tester.pumpWidget(wrap(FeedPhotoPage(
      expense: photos.first,
      category: categories[10],
      priority: const PriorityLevel(id: 0, name: 'Cần thiết', colorValue: 0xFF7BD8A8, sortOrder: 0),
      onEdit: () {},
      onDelete: () {},
    )));
    expect(find.byType(PixelReceiptImage), findsOneWidget);
    expect(find.byType(PixelBadge), findsNWidgets(2));
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Cần thiết'), findsOneWidget);
    expect(find.textContaining('60.000'), findsOneWidget);
    expect(find.text('Bún chả'), findsOneWidget);
    expect(find.textContaining('12:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nút sửa và xóa có nhãn tiếng Việt và 48dp', (tester) async {
    await tester.pumpWidget(wrap(FeedPhotoPage(
      expense: photos.first,
      category: categories[10],
      priority: const PriorityLevel(id: 0, name: 'Cần thiết', colorValue: 0xFF7BD8A8, sortOrder: 0),
      onEdit: () {},
      onDelete: () {},
    )));
    for (final key in ['feed-edit', 'feed-delete']) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(find.byTooltip('Chỉnh sửa khoản chi'), findsOneWidget);
    expect(find.byTooltip('Chuyển vào thùng rác'), findsOneWidget);
  });

  testWidgets('không còn _GlassPill/PriorityBadge trong trang ảnh',
      (tester) async {
    await tester.pumpWidget(wrap(FeedPhotoPage(
      expense: photos.first,
      category: categories[10],
      priority: const PriorityLevel(id: 0, name: 'Cần thiết', colorValue: 0xFF7BD8A8, sortOrder: 0),
      onEdit: () {},
      onDelete: () {},
    )));
    expect(find.byType(PixelReceiptImage), findsOneWidget);
    expect(find.text('Ảnh không khả dụng'), findsNothing);
  });
}
```

`categories` ở trên là `final` (không `const`) vì `Category` không có constructor `const`; `PriorityLevel` thì có `const` nên `const PriorityLevel(...)` giữ nguyên. `FeedPhotoPage` giữ chữ ký hiện tại (`lib/screens/camera/feed_photo_page.dart:22-29`): `expense`, `onEdit`, `onDelete` **required**, `category` và `priority` là `... ?` optional — nên test nào dựng widget này đều phải truyền đủ `onEdit:`/`onDelete:`.

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/widget/feed_photo_test.dart`
Expected: FAIL — `FeedGridScreen` chưa nhận `categoriesById`, `find.text('2 ảnh')` không thấy, còn `Icons.`.

- [ ] **Step 2: Vẽ lại `FeedGridScreen`**

Sửa `lib/screens/camera/feed_grid_screen.dart`:
- Bỏ import `app_colors.dart`, `cached_network_image`, `dart:io`; thêm `pixel_receipt_image.dart`, `pixel_empty_state.dart`, `pixel_screen_header.dart` (`pixelGroupHeader` không dùng ở đây), `app_icon.dart`, `app_palette.dart`.
- Signature: `photos` đổi thành `expenses` và thêm `final Map<int, Category> categoriesById;` với `const FeedGridScreen({super.key, required this.expenses, this.categoriesById = const {}})`. **Đổi luôn call site duy nhất** ở `lib/screens/camera/camera_screen.dart:267`: `FeedGridScreen(photos: photos)` → đọc `ref.read(categoryProvider).categories` dựng map theo id rồi gọi `FeedGridScreen(expenses: photos, categoriesById: categoriesById)`; thêm `import '../../providers/category_provider.dart';` nếu file chưa có.
- `Scaffold(backgroundColor: palette.feedBg)`; `AppBar` thay bằng: leading `PixelIconButton(icon: 'close', tooltip: 'Đóng', onPressed: () => Navigator.pop(context), background: palette.feedPanel, iconColor: palette.feedInk)`, title `Text('${expenses.length} ảnh', style: text.titleMedium)` qua `title: ...` của `AppBar` (giữ `AppBar` cho route này vì nó là màn đẩy từ HUD — nền `palette.feedBg`, foreground `palette.feedInk`).
- Lưới: `GridView.builder(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4, itemBuilder: (_, i) => _GridTile(expense: expenses[i], categoryName: categoriesById[expenses[i].categoryId]?.name, onTap: () => Navigator.pop(context, i)))`.
- `_GridTile` (73-173): bỏ `Image.file`/`CachedNetworkImage`/`Icons.broken_image_rounded`, thay bằng

```dart
      Stack(
        fit: StackFit.expand,
        children: [
          PixelReceiptImage.fromExpense(expense, semanticLabel: label),
          if (categoryName != null)
            Positioned(
              left: 4,
              bottom: 4,
              child: ColoredBox(
                color: palette.feedPanel.withValues(alpha: 0.85),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    categoryName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.feedInk,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
```

`label` = `'Ảnh khoản chi ${expense.caption.isEmpty ? expense.amount.toInt() : expense.caption}'`; bọc `GestureDetector`/`InkWell` cao bằng rộng (square) qua `AspectRatio(aspectRatio: 1, child: ...)`.
- Rỗng: `if (expenses.isEmpty) return PixelEmptyState(glyph: 'filmStrip', title: 'Chưa có khoản chi nào', message: 'Mở camera và chụp khoản chi đầu tiên.')` trong `body` (không có lưới).

- [ ] **Step 3: Vẽ lại `FeedPhotoPage` + panel caption**

Sửa `lib/screens/camera/feed_photo_page.dart`:
- Ảnh: thay widget ảnh private (~182-213, gồm `AppColors.feedBackground`, `Icons.broken_image_rounded`, text 'Ảnh không khả dụng') bằng `PixelReceiptImage.fromExpense(expense, fit: BoxFit.cover, semanticLabel: ...)` full-bleed; **giữ `gesture` chạm để ẩn/hiện HUD** nếu camera screen truyền (`grep -n "onTap\|showHud" lib/screens/camera/feed_photo_page.dart`; nếu route này không có behaviour đó thì không thêm — YAGNI).
- Overlay trên: `DecoratedBox(decoration: BoxDecoration(gradient: hudTopGradient(palette)))` — helper đang private trong `camera_screen.dart`; **nâng lên** `lib/widgets/pixel/feed_hud.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

LinearGradient hudTopGradient(AppPalette palette) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        palette.feedBg.withValues(alpha: 0.92),
        palette.feedBg.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    );

LinearGradient hudBottomGradient(AppPalette palette) => LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        palette.feedBg.withValues(alpha: 0.94),
        palette.feedBg.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    );
```
`camera_screen.dart` (Task 8) import file này thay vì khai báo local.
- Panel dưới: `Container(color: palette.feedPanel.withValues(alpha: 0.92), border: Border(top: BorderSide(color: palette.mint, width: 2)))` chứa `FeedCaptionPanel`.
- `FeedCaptionPanel`: `Row` badge danh mục (`PixelBadge(glyph: IconHelper.normalizeIconKey(category?.icon ?? 'tag'), label: categoryName, accent: palette.accentForCategory(categoryName), ink: palette.onAccent)`), badge mức độ (`PixelBadge(glyph: 'sparkle', label: priorityName ?? expense.priorityLabel, accent: palette.priorityColor(expense.priority), ink: palette.onAccent)`) → `FittedBox` số tiền `CurrencyFormatter.format(expense.amount)` style `text.displaySmall` color `palette.feedInk` → ghi chú `maxLines: 3, overflow: ellipsis` → `Text('${DateFormatter.formatDate(expense.createdAt)} • ${DateFormatter.formatTime(expense.createdAt)}', color: palette.feedMuted)`.
- Nút sửa/xóa: `PixelIconButton(key: const ValueKey('feed-edit'), icon: 'edit', tooltip: 'Chỉnh sửa khoản chi', onPressed: onEdit, background: palette.feedPanel, iconColor: palette.feedInk)` và `key: ValueKey('feed-delete')`, `icon: 'trash'`, `tooltip: 'Chuyển vào thùng rác'`. `PixelIconButton` (plan 2 Task 5) là `const PixelIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.background, this.iconColor, this.iconSize = 32})` với `onPressed` là `VoidCallback?` bắt buộc phải truyền (truyền `null` = nút disabled): vùng chạm cố định 48×48, glyph bên trong `iconSize` (32 = bội số 16). Task 9 dùng `key:` và `background`/`iconColor` đúng API này, không sửa plan 2.
- **Xóa** `_GlassPill` (214-231) và `_FeedActionButton` (232-275); xóa import `../../widgets/priority_badge.dart`.
- `grep -n "AppColors\.\|Icons\.\|_GlassPill\|PriorityBadge" lib/screens/camera/feed_photo_page.dart` → Expected: không kết quả.

- [ ] **Step 4: Chạy test và gate**

Run: `flutter test test/widget/feed_photo_test.dart && flutter test && flutter analyze`
Expected: PASS 5 test mới; toàn bộ PASS; analyze sạch.

Run: `grep -rn "CachedNetworkImage\|Image.file" lib/`
Expected: chỉ còn 2 kết quả trong `lib/widgets/pixel/pixel_receipt_image.dart` **và** các kết quả trong `lib/screens/trash/trash_screen.dart` (màn Thùng rác còn render ảnh riêng, được gom về `PixelReceiptImage` ở Task 13). Nếu còn ở file khác ngoài hai file này → chưa gom về một chỗ, sửa tiếp. Gate nghiêm (chỉ `pixel_receipt_image.dart`) chạy ở Task 13 Step 6.

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/widgets/pixel/feed_hud.dart lib/screens/camera/feed_grid_screen.dart lib/screens/camera/feed_photo_page.dart lib/screens/camera/camera_screen.dart lib/widgets/pixel/app_icon.dart test/widget/feed_photo_test.dart
git commit -m "feat(ui): pixel feed grid and photo page"
```

---

### Task 10: Thống kê pixel + gỡ `fl_chart` (spec §3.6, §5.6)

**Files:**
- Create: `lib/screens/statistics/statistics_charts.dart`
- Modify: `lib/screens/statistics/statistics_screen.dart` (428 dòng; xóa `import 'package:fl_chart/fl_chart.dart'` dòng 3, `PieChart:197-240`, `BarChart:303-352`, `_buildBar:415-428`, `GlassCard:150`, `ScreenBackground:103`, `AppColors` 181/357-372)
- Modify: `pubspec.yaml` (`flutter pub remove fl_chart`)
- Create: `test/widget/statistics_pixel_test.dart`

**Interfaces:**
- Consumes: `PixelSegmented`, `PixelShareBar`, `PixelStackedShare`, `PixelBarChart`, `PixelPanel`, `PixelStatTile`, `PixelEmptyState`, `PixelLoading`, `AppIcon`, `context.palette`, `CurrencyFormatter.format`, `AppStrings.priorityLabels`, `StatisticsState`.
- Produces:
  - `enum StatRange { today, week, month, year, custom }` + `String statRangeLabel(StatRange r)` (public trong `statistics_screen.dart`)
  - `class StatisticsCharts extends ConsumerWidget { const StatisticsCharts({super.key}); }` — tự đọc `statisticsProvider` + `categoryProvider`, không nhận data từ screen (test override hai provider này)
  - `({List<DateTime> dates, List<double> values, List<String> valueTexts}) dailySeries(Map<String, double> dailyTotals)` — pure helper đặt ở cuối `statistics_charts.dart` (sort theo key, parse `yyyy-MM-dd`)

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/statistics_pixel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/providers/statistics_provider.dart';
import 'package:chi_tieu/screens/statistics/statistics_charts.dart';
import 'package:chi_tieu/screens/statistics/statistics_screen.dart';
import 'package:chi_tieu/widgets/pixel/pixel_bar_chart.dart';
import 'package:chi_tieu/widgets/pixel/pixel_screen_header.dart';
import 'package:chi_tieu/widgets/pixel/pixel_segmented.dart';
import 'package:chi_tieu/widgets/pixel/pixel_share_bar.dart';
import 'package:chi_tieu/widgets/pixel/pixel_stacked_share.dart';

class _FakeStatsNotifier extends StateNotifier<StatisticsState>
    implements StatisticsNotifier {
  _FakeStatsNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget harness(Widget child, {StatisticsState? stats}) => ProviderScope(
      overrides: [
        statisticsProvider.overrideWith(
          (ref) => _FakeStatsNotifier(
            stats ??
                StatisticsState(
                  categoryTotals: const {10: 500000, 11: 250000},
                  priorityTotals: const {0: 400000, 3: 350000},
                  dailyTotals: const {
                    '2026-10-30': 100000,
                    '2026-10-31': 200000,
                    '2026-11-01': 450000,
                  },
                  totalAmount: 750000,
                  insights: const ['Ăn uống chiếm 67% tổng chi.'],
                ),
          ),
        ),
        categoryProvider.overrideWith(
          (ref) => _FakeCategoryNotifier(CategoryState(categories: [
            Category(id: 10, name: 'Ăn uống', icon: 'forkKnife'),
            Category(id: 11, name: 'Đi lại', icon: 'car'),
          ])),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

void main() {
  test('dailySeries sort tăng dần và text đã format', () {
    final s = dailySeries(const {
      '2026-11-02': 20,
      '2026-11-01': 10,
    });
    expect(s.dates.first.day, 1);
    expect(s.values, [10, 20]);
    expect(s.valueTexts.length, 2);
  });

  test('dailySeries chuỗi ngày hỏng bị bỏ qua', () {
    final s = dailySeries(const {'abc': 5, '2026-11-01': 10});
    expect(s.values, [10]);
  });

  testWidgets('StatisticsCharts render 3 loại biểu đồ pixel', (tester) async {
    await tester.pumpWidget(harness(const SingleChildScrollView(
      child: StatisticsCharts(),
    )));
    expect(find.byType(PixelShareBar), findsNWidgets(2));
    expect(find.byType(PixelStackedShare), findsOneWidget);
    expect(find.byType(PixelBarChart), findsOneWidget);
    expect(find.text('THEO DANH MỤC'), findsOneWidget);
    expect(find.text('MỨC ĐỘ CẦN THIẾT'), findsOneWidget);
    expect(find.text('THEO NGÀY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StatisticsCharts rỗng hiện hướng dẫn', (tester) async {
    await tester.pumpWidget(harness(
      const SingleChildScrollView(child: StatisticsCharts()),
      stats: StatisticsState(
        categoryTotals: const {},
        priorityTotals: const {},
        dailyTotals: const {},
        totalAmount: 0,
        insights: const [],
      ),
    ));
    expect(find.text('Chưa có dữ liệu trong khoảng này.'), findsWidgets);
  });

  testWidgets('StatisticsScreen dùng PixelSegmented, không còn fl_chart',
      (tester) async {
    await tester.pumpWidget(harness(const StatisticsScreen()));
    expect(find.byType(PixelSegmented<StatRange>), findsOneWidget);
    expect(find.text('Tháng này'), findsWidgets); // segment + subtitle
    expect(find.byType(PixelScreenHeader), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StatisticsScreen 1.3x text scale không vỡ', (tester) async {
    await tester.pumpWidget(harness(const StatisticsScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
```

Ba ràng buộc đã xác minh, test và implementation phải khớp:
- `StatisticsState` **không** có constructor `const` (`lib/providers/statistics_provider.dart:14-21`); các default là `categoryTotals = {}`, `priorityTotals = {}`, `dailyTotals = {}`, `totalAmount = 0.0`, `insights = []`, `isLoading = false` → test rỗng viết `StatisticsState()` là đủ, không `const`.
- `StatisticsScreen({super.key, this.onMenuTap})` với `onMenuTap` **optional** (`lib/screens/statistics/statistics_screen.dart:15-17`) → `const StatisticsScreen()` hợp lệ, test không truyền gì.
- `Category(...)` trong list test cũng **không** `const`; nếu analyzer báo `prefer_const_literals_to_create_immutables` thì xóa `final`/`const` thừa ở biến dựng list, không đổi production code.

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/widget/statistics_pixel_test.dart`
Expected: FAIL — URI `statistics_charts.dart` không tồn tại, `AppBar`/`PieChart` còn nguyên.

- [ ] **Step 2: Tạo `statistics_charts.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/category_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_bar_chart.dart';
import '../../widgets/pixel/pixel_empty_state.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_share_bar.dart';
import '../../widgets/pixel/pixel_stacked_share.dart';

typedef DailySeries = ({
  List<DateTime> dates,
  List<double> values,
  List<String> valueTexts,
});

/// Sort theo ngày tăng dần; key không parse được bị bỏ qua (không ném lỗi).
DailySeries dailySeries(Map<String, double> dailyTotals) {
  final parser = DateFormat('yyyy-MM-dd');
  final keys = dailyTotals.keys.toList()..sort();
  final dates = <DateTime>[];
  final values = <double>[];
  final texts = <String>[];
  for (final key in keys) {
    try {
      final date = parser.parseStrict(key);
      dates.add(date);
      values.add(dailyTotals[key] ?? 0);
      texts.add(CurrencyFormatter.format(dailyTotals[key] ?? 0));
    } on FormatException {
      continue;
    }
  }
  return (dates: dates, values: values, valueTexts: texts);
}

class StatisticsCharts extends ConsumerWidget {
  const StatisticsCharts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final stats = ref.watch(statisticsProvider);
    final categories = ref.watch(categoryProvider).categories;
    final nameById = {
      for (final c in categories) if (c.id != null) c.id!: c.name,
    };
    final iconById = {
      for (final c in categories) if (c.id != null) c.id!: c.icon,
    };

    if (stats.isLoading && stats.totalAmount == 0) {
      return PixelPanel(
        child: Center(child: PixelLoading(label: 'Đang tính thống kê…')),
      );
    }

    final catEntries = stats.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final series = dailySeries(stats.dailyTotals);
    final priorityValues = [
      for (var p = 0; p < AppStrings.priorityLabels.length; p++)
        stats.priorityTotals[p] ?? 0,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (catEntries.isEmpty)
          const PixelEmptyState(
            glyph: 'chart',
            title: 'Chưa có dữ liệu',
            message: 'Chưa có dữ liệu trong khoảng này.',
          )
        else
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THEO DANH MỤC', style: text.labelLarge),
                const SizedBox(height: 10),
                for (final entry in catEntries)
                  PixelShareBar(
                    label: nameById[entry.key] ?? 'Khác',
                    glyph: iconById[entry.key] ?? 'tag',
                    value: entry.value,
                    total: stats.totalAmount,
                    valueText: CurrencyFormatter.format(entry.value),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MỨC ĐỘ CẦN THIẾT', style: text.labelLarge),
              const SizedBox(height: 10),
              priorityValues.every((v) => v == 0)
                  ? Text(
                      'Chưa có dữ liệu trong khoảng này.',
                      style: text.bodyMedium?.copyWith(color: palette.inkMuted),
                    )
                  : PixelStackedShare(
                      labels: AppStrings.priorityLabels,
                      glyphs: const ['check', 'sparkle', 'gift', 'close'],
                      values: priorityValues,
                      colors: [
                        for (var p = 0; p < AppStrings.priorityLabels.length; p++)
                          palette.priorityColor(p),
                      ],
                      valueTexts: [
                        for (final v in priorityValues)
                          CurrencyFormatter.format(v),
                      ],
                    ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THEO NGÀY', style: text.labelLarge),
              const SizedBox(height: 10),
              PixelBarChart(
                dates: series.dates,
                values: series.values,
                valueTexts: series.valueTexts,
              ),
            ],
          ),
        ),
        if (stats.insights.isNotEmpty) ...[
          const SizedBox(height: 12),
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NHẬN XÉT', style: text.labelLarge),
                const SizedBox(height: 8),
                for (final insight in stats.insights)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppIcon(
                          name: 'sparkle',
                          size: 16,
                          color: palette.butterInk,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight,
                            style: text.bodyMedium?.copyWith(color: palette.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
```

`AppStrings.priorityLabels` là `List<String>` 4 phần tử `'Thiết yếu', 'Rất cần', 'Cần vừa', 'Chưa cần'` (`lib/core/constants/app_strings.dart:4-9`, đã xác minh). `PixelEmptyState` (plan 2 Task 8) là `const PixelEmptyState({required this.glyph, required this.title, required this.message, this.actionLabel, this.onAction})` — constructor **có** `const`, nên giữ nguyên `const PixelEmptyState(...)` trong code trên.

- [ ] **Step 3: Sửa `StatisticsScreen`**

1. Xóa `import 'package:fl_chart/fl_chart.dart';` và toàn bộ `PieChart`(197-240) / `BarChart`(303-352) / `_buildBar`(415-428) / `AppColors.priority0..3`(357-372) / `GlassCard`(150-181) / `ScreenBackground`(103).
2. `enum StatRange { today, week, month, year, custom }` + `String statRangeLabel(StatRange r) => switch (r) { StatRange.today => 'Hôm nay', StatRange.week => 'Tuần này', StatRange.month => 'Tháng này', StatRange.year => 'Năm nay', StatRange.custom => 'Tùy chọn' };`
3. Đổi field `String _selectedRange = 'Tháng này'` → `StatRange _selectedRange = StatRange.month`; `_setRange(String)` → `_setRange(StatRange range)` với `switch` giữ **nguyên công thức ngày** hiện có (dòng 63-86), `custom` không gọi `_loadData()`.
4. Xóa `appBar: AppBar(...)` (dòng 94-100, gồm `HamburgerButton(onTap: widget.onMenuTap)` trong `title`), thay bằng `appBar: pixelAppBar(PixelScreenHeader(...))` ở dưới. Header: `PixelScreenHeader(title: 'THỐNG KÊ', subtitle: _selectedRange == StatRange.custom ? '${DateFormatter.formatDate(_startDate)} – ${DateFormatter.formatDate(_endDate)}' : statRangeLabel(_selectedRange), onMenuTap: widget.onMenuTap, trailing: PixelIconButton(icon: 'calendar', tooltip: 'Chọn khoảng ngày', onPressed: _pickCustomRange, background: palette.surface, iconColor: palette.ink))` (thêm import `../../core/utils/date_formatter.dart`; `_startDate`/`_endDate` là field thật ở `statistics_screen.dart:25-26`). `_pickCustomRange` = body của `showDateRangePicker` hiện có (dòng 36-62) tách thành method.
5. Body: `ListView(padding: EdgeInsets.all(12))` với children: `PixelSegmented<StatRange>(items: [for (final r in StatRange.values) PixelSegmentItem(value: r, label: statRangeLabel(r))], selected: _selectedRange, onChanged: _setRange)`, `PixelStatTile(label: 'TỔNG CHI', value: CurrencyFormatter.format(statsState.totalAmount), glyph: 'wallet')`, `const StatisticsCharts()`.
6. Lỗi/tải: `if (statsState.isLoading) PixelLoading(...)`; `errorMessage != null` → `PixelPanel(background: palette.rose)` + `PixelButton(label: 'THỬ LẠI', onPressed: () => _loadData())`.
7. `flutter pub remove fl_chart` rồi `flutter pub get`.
8. `grep -rn "fl_chart" lib/ pubspec.yaml` → Expected: không kết quả.

- [ ] **Step 4: Chạy test và gate**

Run: `flutter test test/widget/statistics_pixel_test.dart && flutter test && flutter analyze`
Expected: PASS 6 test mới; toàn bộ PASS; analyze sạch.

Run: `grep -rn "PieChart\|BarChart\|BarChartGroupData" lib/ | grep -v pixel_bar_chart`
Expected: không kết quả.

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/screens/statistics/ pubspec.yaml pubspec.lock test/widget/statistics_pixel_test.dart
git commit -m "feat(ui): pixel statistics charts, drop fl_chart"
```

---

### Task 11: Ngân sách pixel + sửa lỗi tràn khi bàn phím mở (spec §5.7)

**Files:**
- Modify: `lib/screens/budget/budget_screen.dart` (391 dòng)
- Create: `test/widget/budget_pixel_test.dart`

**Interfaces:**
- Consumes: `PixelScreenHeader`, `PixelSegmented`, `PixelPanel`, `PixelProgress`, `PixelTextField` + `ThousandsSeparatorInputFormatter` (plan 3), `CurrencyFormatter.parseInput/toEditableText` (plan 3), `PixelButton`, `PixelIconButton`, `showPixelSnackBar`, `showPixelDialog`, `AppIcon`, `context.palette`, `BudgetState`.
- Produces:
  - `enum BudgetMode { total, byCategory }`
  - `BudgetScreen({Key? key, VoidCallback? onMenuTap})` — không đổi
  - `({double spent, double budget}) budgetTotals(BudgetState state)` — pure, đặt cuối file (budget = `state.totalBudget?.amount ?? 0`)

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/budget_pixel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/budget.dart';
import 'package:chi_tieu/providers/budget_provider.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/screens/budget/budget_screen.dart';
import 'package:chi_tieu/widgets/pixel/pixel_progress.dart';
import 'package:chi_tieu/widgets/pixel/pixel_segmented.dart';
import 'package:chi_tieu/widgets/pixel/pixel_text_field.dart';

class _FakeBudgetNotifier extends StateNotifier<BudgetState>
    implements BudgetNotifier {
  _FakeBudgetNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BudgetState stateWith({double budget = 0, double spent = 0, String month = '11/2026'}) =>
    BudgetState(
      month: month,
      totalBudget: budget > 0
          ? Budget(id: 1, amount: budget, month: month)
          : null,
      totalSpent: spent,
    );

Widget harness(BudgetState budget) => ProviderScope(
      overrides: [
        budgetProvider.overrideWith((ref) => _FakeBudgetNotifier(budget)),
        categoryProvider.overrideWith(
          (ref) => _FakeCategoryNotifier(CategoryState(categories: [
            Category(id: 1, name: 'Ăn uống', icon: 'forkKnife'),
          ])),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: BudgetScreen(onMenuTap: () {}),
      ),
    );

void main() {
  test('budgetTotals không âm và an toàn khi chưa đặt', () {
    expect(budgetTotals(stateWith()).budget, 0);
    expect(budgetTotals(stateWith(budget: 5, spent: 7)).budget, 5);
  });

  testWidgets('màn ngân sách có PixelSegmented và ô nhập có formatter',
      (tester) async {
    await tester.pumpWidget(harness(stateWith(budget: 5000000, spent: 1000000)));
    expect(find.byType(PixelSegmented<BudgetMode>), findsOneWidget);
    expect(find.byType(PixelTextField), findsWidgets);
    expect(find.text('NGÂN SÁCH TỔNG'), findsOneWidget);
    final field = tester.widget<PixelTextField>(
      find.byKey(const Key('totalBudgetField')),
    );
    expect(field.inputFormatters, isNotNull);
    expect(field.controller?.text, '5.000.000');
  });

  testWidgets('vượt ngân sách hiện QUÁ NGÂN SÁCH bằng chữ', (tester) async {
    await tester.pumpWidget(harness(stateWith(budget: 5000000, spent: 7000000)));
    expect(find.textContaining('QUÁ NGÂN SÁCH'), findsOneWidget);
    final progress = tester.widget<PixelProgress>(find.byType(PixelProgress));
    expect(progress.value, greaterThanOrEqualTo(1));
    expect(progress.fillColor, isNotNull);
  });

  testWidgets('chưa đặt ngân sách hiện hướng dẫn đặt', (tester) async {
    await tester.pumpWidget(harness(stateWith(spent: 800000)));
    expect(find.text('Chưa đặt ngân sách'), findsOneWidget);
  });

  testWidgets('chế độ theo danh mục liệt kê từng danh mục', (tester) async {
    await tester.pumpWidget(harness(stateWith()));
    await tester.tap(find.text('THEO DANH MỤC'));
    await tester.pumpAndSettle();
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.byKey(const Key('categoryBudget-1')), findsOneWidget);
  });

  testWidgets('bàn phím mở không gây overflow', (tester) async {
    await tester.pumpWidget(harness(stateWith(budget: 5000000, spent: 1000000)));
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness(stateWith(budget: 5000000, spent: 1000000)));
    await tester.tap(find.byKey(const Key('totalBudgetField')));
    await tester.pump();
    // Mô phỏng bàn phím: viewInsets.bottom lớn.
    await tester.binding.setSurfaceSize(const Size(400, 260));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
```

`Budget` constructor đã đọc (`lib/data/models/budget.dart:7`): `Budget({int? id, required this.month, this.categoryId, required this.amount})` — **không có `type`**; `categoryId == null` chính là ngân sách tổng (`BudgetMode.total`). `month` của `BudgetState` trong app thật theo format `MM/yyyy` (`budget_screen.dart:135` `DateFormat('MM/yyyy')`) nên test dùng `month: '11/2026'` cho khớp.

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/widget/budget_pixel_test.dart`
Expected: FAIL — chưa có `BudgetMode`, `PixelSegmented<BudgetMode>`, `Key('totalBudgetField')`.

- [ ] **Step 2: Sửa layout để khỏi tràn**

`budget_screen.dart` hiện dùng `Column` + `Expanded(child: ListView...)` + nút lưu pinned (dòng 139-205) → khi `viewInsets.bottom` lớn, `Expanded` bị nén dưới chiều cao nội dung và tràn. Thay bằng **một** `SingleChildScrollView` chứa toàn bộ, `Column(mainAxisSize: MainAxisSize.min)` với `ListView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics())` cho phần danh mục:

```dart
    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PixelScreenHeader(
              title: 'NGÂN SÁCH',
              subtitle: 'tháng $monthLabel',
              onMenuTap: widget.onMenuTap,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelIconButton(icon: 'back', tooltip: 'Tháng trước', onPressed: _previousMonth),
                  PixelIconButton(icon: 'chevronRight', tooltip: 'Tháng sau', onPressed: _nextMonth),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PixelSegmented<BudgetMode>(...),
                    const SizedBox(height: 12),
                    if (_mode == BudgetMode.total)
                      _buildTotalBudgetView(budgetState)
                    else
                      _buildCategoryBudgetView(categoryState.categories, budgetState),
                    const SizedBox(height: 16),
                    PixelButton(
                      key: const Key('saveBudgetButton'),
                      label: 'LƯU NGÂN SÁCH',
                      icon: 'check',
                      expanded: true,
                      isLoading: _isSavingBudget,
                      onPressed: _isSavingBudget ? null : _saveBudget,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
```

Đổi field `bool _isTotalBudget = true;` → `BudgetMode _mode = BudgetMode.total;` và sửa 2 nhánh `_saveBudget()` (`if (_isTotalBudget)` → `if (_mode == BudgetMode.total)`), bỏ mọi `Expanded` bên trong 2 view.
Thêm dịch tháng:

```dart
  int _monthOffset = 0;

  String get _monthLabel {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month + _monthOffset);
    return DateFormat('MM/yyyy').format(d);
  }

  void _previousMonth() {
    setState(() => _monthOffset -= 1);
    ref.read(budgetProvider.notifier).loadBudgets(_monthLabel);
  }

  void _nextMonth() {
    if (_monthOffset >= 0) return;
    setState(() => _monthOffset += 1);
    ref.read(budgetProvider.notifier).loadBudgets(_monthLabel);
  }
```
và thay `final currentMonth = DateFormat('MM/yyyy').format(DateTime.now());` (dòng 135) bằng `_monthLabel` ở mọi chỗ (`setTotalBudget(month:)`, `setCategoryBudgets(month:)`). `_loadData()` giữ `Future.microtask`, nhưng gọi `loadBudgets(_monthLabel)` thay vì phụ thuộc tháng hiện tại.

- [ ] **Step 3: Vẽ lại 2 view**

`_buildTotalBudgetView`:
- `PixelPanel(child: Column(...))` với `Text('NGÂN SÁCH TỔNG', style: text.labelLarge)`.
- `PixelTextField(key: const Key('totalBudgetField'), label: 'Số tiền (VND)', controller: _totalBudgetController, keyboardType: TextInputType.number, inputFormatters: const [ThousandsSeparatorInputFormatter()], hint: '5.000.000')` — label field không trùng `'NGÂN SÁCH TỔNG'` để test `find.text('NGÂN SÁCH TỔNG')` chỉ thấy 1 lần.
- `if (budget > 0)`: `PixelProgress(value: spent / budget, segments: 10, fillColor: isOver ? palette.rose : palette.mint)`; `Text('Đã chi: ...')` + `Text('${(rawPercent * 100).toStringAsFixed(1)}%')`; `Text(isOver ? 'QUÁ NGÂN SÁCH: ${CurrencyFormatter.format(-remaining)}' : 'Còn lại: ${CurrencyFormatter.format(remaining)}', color: isOver ? palette.danger : palette.success)`; **xóa** `Colors.teal/orange/red` (dòng 215-219) và `LinearProgressIndicator` (dòng 703 của home không liên quan; ở đây là dòng 703-710 của budget).
- `else`: `Text('Chưa đặt ngân sách')` + `AppIcon(name:'wallet', color: palette.inkMuted)` + `Text('Nhập số tiền rồi bấm LƯU NGÂN SÁCH.', style: bodySmall)`.
- `_saveBudget`: `CurrencyFormatter.parseInput(_totalBudgetController.text)` thay `double.tryParse(...replaceAll(',', ''))` (2 chỗ, dòng 74 và 82).

`_buildCategoryBudgetView`: `ListView(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), children: [for (final cat in categories) PixelPanel(key: ValueKey('panel-${cat.id}'), child: Row(AppIcon(cat.icon), Text(cat.name), Expanded(PixelTextField(key: ValueKey('categoryBudget-${cat.id}'), label: '', controller: _categoryControllers[cat.id], keyboardType: number, inputFormatters: [const ThousandsSeparatorInputFormatter()])), Text('Đã chi …')))])`. `PixelTextField.label` là `required` → dùng `label: 'Số tiền'`; để không loãng, đặt `label: cat.name` và bỏ `Text(cat.name)` riêng. Test assert `find.byKey(ValueKey('categoryBudget-1'))` vẫn đúng.
Seeding controller: `_categoryControllers[cat.id!] = TextEditingController(text: CurrencyFormatter.toEditableText(amount))` (plan 3) thay `amount.toInt().toString()`.

`grep -n "AppColors\|Icons\.\|GlassCard\|ScreenBackground\|LinearProgressIndicator\|Colors.teal\|Colors.orange\|Colors.red" lib/screens/budget/budget_screen.dart` → Expected: không kết quả.

- [ ] **Step 4: Chạy test và gate**

Run: `flutter test test/widget/budget_pixel_test.dart && flutter test && flutter analyze`
Expected: PASS 6 test mới; toàn bộ PASS; analyze sạch.

Run: `grep -rn "GlassCard\|ScreenBackground" lib/`
Expected: không kết quả (home xong Task 5, statistics Task 10, budget Task 11).

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/screens/budget/budget_screen.dart test/widget/budget_pixel_test.dart
git commit -m "fix(ui): pixel budget screen, scrollable with keyboard open"
```

---

### Task 12: Quản lý danh mục — lưới glyph pixel, form trong dialog, nhãn MẶC ĐỊNH

Spec §5.8: "Danh sách badge icon + tên + nhãn 'MẶC ĐỊNH' cho danh mục hệ thống; nút thêm; dialog thêm/sửa/xóa."

**Files:**
- Create: `lib/screens/categories/category_glyph_grid.dart`
- Modify: `lib/screens/categories/manage_categories_screen.dart` (toàn bộ `build`, `_showCategoryDialog`, `_confirmDelete`)
- Modify: `test/widget/screens_test.dart:46-62` (group `ManageCategoriesScreen Widget Tests` — đổi nhãn, không xóa group)
- Create: `test/widget/categories_pixel_test.dart`

**Interfaces:**
- Consumes: `IconHelper.availableIcons` (19 khóa, plan 2 Task 6), `IconHelper.normalizeIconKey`, `PixelScreenHeader` + `pixelGroupHeader` (Task 2), `PixelPanel` (`onTap`, `background`, `padding`, `borderWidth`), `PixelButton`, `PixelIconButton` (`size` 48 mặc định sau Task 9), `PixelTextField` (`errorText`, `autofocus`, `textCapitalization`), `PixelBadge`, `PixelEmptyState`, `PixelLoading`, `showPixelDialog`, `showPixelSnackBar`, `AppIcon`, `context.palette`, `accentForCategory(Object)`.
- Provider thật (đã xác minh `lib/providers/category_provider.dart:29-66`): `CategoryState{categories, isLoading, errorMessage}`, `CategoryNotifier.loadCategories()/addCategory(String name, String icon)/updateCategory(Category)/deleteCategory(int id)`.
- Model (đã xác minh `lib/data/models/category.dart`): `Category` **không** có constructor `const`; ctor `Category({int? id, required String name, required String icon, bool isDefault = false, DateTime? createdAt})`; có `copyWith({id, name, icon, isDefault, createdAt})`. Test phải dùng `Category(...)` không `const`.
- Produces:
  - `class CategoryGlyphGrid extends StatelessWidget { const CategoryGlyphGrid({Key? key, required String selected, required ValueChanged<String> onChanged, List<String>? glyphs}); }` — mỗi ô `SizedBox` 48×48 với `key: ValueKey('glyph-cell-$key')` (`key` là String khóa glyph đang vẽ).
  - `String? validateCategoryName(String raw, List<String> existingNames)` — top-level **pure** trong `manage_categories_screen.dart`, trả `null` khi hợp lệ, không import thêm gì.
  - `class ManageCategoriesScreen extends ConsumerWidget { const ManageCategoriesScreen({super.key}); }` — giữ nguyên signature (đang được gọi ở `main_screen.dart` và `settings_screen.dart`).

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/categories_pixel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/screens/categories/category_glyph_grid.dart';
import 'package:chi_tieu/screens/categories/manage_categories_screen.dart';
import 'package:chi_tieu/widgets/pixel/app_icon.dart';
import 'package:chi_tieu/widgets/pixel/pixel_badge.dart';
import 'package:chi_tieu/widgets/pixel/pixel_button.dart';
import 'package:chi_tieu/widgets/pixel/pixel_screen_header.dart';
import 'package:chi_tieu/widgets/pixel/pixel_text_field.dart';

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(this._categories)
      : super(CategoryState(categories: _categories));

  final List<Category> _categories;
  final List<String> added = [];

  @override
  Future<void> addCategory(String name, String icon) async {
    added.add('$name:$icon');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child, List<Category> categories) => ProviderScope(
      overrides: [
        categoryProvider.overrideWith((ref) => _FakeCategoryNotifier(categories)),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

Category _c(int id, String name, {String icon = 'coffee', bool d = false}) =>
    Category(id: id, name: name, icon: icon, isDefault: d);

void main() {
  test('validateCategoryName: rỗng / trùng / trùng bỏ qua hoa thường / hợp lệ', () {
    expect(validateCategoryName('  ', const ['Cà phê']), 'Nhập tên danh mục.');
    expect(validateCategoryName('Cà phê', const ['Cà phê']),
        contains('đã tồn tại'));
    expect(validateCategoryName('cÀ PHÊ', const ['Cà phê']),
        contains('đã tồn tại'));
    expect(validateCategoryName('Xe hơi', const ['Cà phê']), isNull);
  });

  testWidgets('Danh mục: header pixel, MẶC ĐỊNH cho hệ thống, không còn FAB',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const ManageCategoriesScreen(),
      [_c(1, 'Ăn uống', d: true), _c(2, 'Cà phê')],
    ));
    expect(find.byType(PixelScreenHeader), findsOneWidget);
    expect(find.text('QUẢN LÝ DANH MỤC'), findsOneWidget);
    expect(find.text('MẶC ĐỊNH'), findsOneWidget);
    expect(find.byType(PixelBadge), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byType(PixelButton), findsWidgets);
  });

  testWidgets('Danh mục hệ thống không có nút sửa/xóa', (tester) async {
    await tester.pumpWidget(
      _wrap(const ManageCategoriesScreen(), [_c(1, 'Ăn uống', d: true)]),
    );
    expect(find.byTooltip('Sửa danh mục'), findsNothing);
    expect(find.byTooltip('Xóa danh mục'), findsNothing);
  });

  testWidgets('Mở thêm danh mục: lưới 19 ô 48dp, chọn ô, lưu gọi addCategory',
      (tester) async {
    final fake = _FakeCategoryNotifier([_c(2, 'Cà phê')]);
    await tester.pumpWidget(ProviderScope(
      overrides: [categoryProvider.overrideWith((ref) => fake)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ManageCategoriesScreen(),
      ),
    ));
    await tester.tap(find.text('THÊM DANH MỤC'));
    await tester.pumpAndSettle();

    expect(find.text('DANH MỤC MỚI'), findsOneWidget);
    expect(find.byType(CategoryGlyphGrid), findsOneWidget);
    expect(find.byKey(const ValueKey('glyph-cell-forkKnife')), findsOneWidget);
    expect(find.byType(PixelTextField), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('glyph-cell-'),
      ),
      findsNWidgets(19),
    );

    final cell = tester.getSize(
      find.byKey(const ValueKey('glyph-cell-coffee')),
    );
    expect(cell.width, greaterThanOrEqualTo(48));
    expect(cell.height, greaterThanOrEqualTo(48));
    expect(find.byType(AppIcon), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('glyph-cell-forkKnife')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('categoryNameField')),
      'Ăn vặt',
    );
    await tester.tap(find.text('LƯU'));
    await tester.pumpAndSettle();

    expect(fake.added, ['Ăn vặt:forkKnife']);
    expect(find.text('DANH MỤC MỚI'), findsNothing); // dialog đã đóng
  });

  testWidgets('Tên trùng hiện lỗi dưới field, không lưu', (tester) async {
    await tester.pumpWidget(
      _wrap(const ManageCategoriesScreen(), [_c(2, 'Cà phê')]),
    );
    await tester.tap(find.text('THÊM DANH MỤC'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('categoryNameField')),
      'Cà phê',
    );
    await tester.tap(find.text('LƯU'));
    await tester.pump();
    expect(find.textContaining('đã tồn tại'), findsOneWidget);
    expect(find.byType(PixelTextField), findsOneWidget);
  });

  testWidgets('Danh mục 1.3x text scale không vỡ', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: ProviderScope(
          overrides: [
            categoryProvider.overrideWith(
              (ref) => _FakeCategoryNotifier([_c(1, 'Ăn uống', d: true)]),
            ),
          ],
          child: const ManageCategoriesScreen(),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
```

`CategoryState` đã xác minh `lib/providers/category_provider.dart:6-27`: `const CategoryState({List<Category> categories = const [], bool isLoading = false, String? errorMessage})` → `super(CategoryState(categories: _categories))` hợp lệ, không cần `const`.

`_FakeCategoryNotifier` chỉ override `addCategory`; `updateCategory`/`deleteCategory`/`loadCategories` rơi vào `noSuchMethod` → `StateNotifier.noSuchMethod` ném `NoSuchMethodError`. Vì test 4 và 5 chỉ đi qua `addCategory`, không gọi ba method kia; nếu mở rộng test thì override thêm method tương ứng.

- [ ] **Step 2: Chạy test, xác nhận fail đúng**

Run: `flutter test test/widget/categories_pixel_test.dart`
Expected: FAIL — compile error `Target of URI doesn't exist: 'package:chi_tieu/screens/categories/category_glyph_grid.dart'`. Đây là fail dự kiến của Step 1; **không** dùng `@Skip` hay comment test để làm cho fail biến mất.

- [ ] **Step 3: Tạo `category_glyph_grid.dart`**

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/icon_helper.dart';
import '../../widgets/pixel/app_icon.dart';

class CategoryGlyphGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final List<String>? glyphs;

  const CategoryGlyphGrid({
    Key? key,
    required this.selected,
    required this.onChanged,
    this.glyphs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final keys = glyphs ?? IconHelper.availableIcons;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final glyphKey in keys)
          Semantics(
            button: true,
            selected: glyphKey == selected,
            label: 'Biểu tượng $glyphKey',
            child: GestureDetector(
              key: ValueKey('glyph-cell-$glyphKey'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(glyphKey),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: glyphKey == selected ? palette.mint : palette.surfaceAlt,
                  border: Border.all(
                    color: glyphKey == selected
                        ? palette.mintStrong
                        : palette.line,
                    width: glyphKey == selected ? 3 : 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: AppIcon(
                    name: glyphKey,
                    size: 32,
                    color: glyphKey == selected
                        ? palette.onAccent
                        : palette.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

`PixelGlyph` vẽ lưới 16×16 nên kích thước glyph chỉ dùng bội số 16: **16 / 32 / 48** (Global Constraints + plan 2 §3.4). Ô trong lưới 48×48 dùng `AppIcon(size: 32)`. Test không assert thứ tự `availableIcons`: `IconHelper.categoryIconKeys` là `const Set` (plan 2 Task 6) nên thứ tự duyệt không được đảm bảo — chỉ assert **đúng 19 ô** và **từng khóa cụ thể tồn tại**.

- [ ] **Step 4: Viết lại `manage_categories_screen.dart`**

Import mới (đường dẫn đã xác minh theo plan 2): `../../core/theme/app_palette.dart`, `../../core/utils/icon_helper.dart` (giữ), `../../widgets/pixel/app_icon.dart` (`AppIcon` **và** `PixelIconButton` cùng file này — plan 2 Task 5), `../../widgets/pixel/pixel_badge.dart`, `../../widgets/pixel/pixel_button.dart` (`PixelButton`, `PixelButtonVariant`), `../../widgets/pixel/pixel_empty_state.dart`, `../../widgets/pixel/pixel_loading.dart`, `../../widgets/pixel/pixel_panel.dart`, `../../widgets/pixel/pixel_screen_header.dart`, `../../widgets/pixel/pixel_dialog.dart` (`showPixelDialog`, `showPixelConfirm` — plan 2 Task 8), `../../widgets/pixel/pixel_text_field.dart`, `category_glyph_grid.dart`, `package:flutter_riverpod/flutter_riverpod.dart` (giữ). Màn này không import `app_colors.dart` (xác minh bằng grep trước và sau).

Pure validator, đặt ở đầu file sau import:

```dart
String? validateCategoryName(String raw, List<String> existingNames) {
  final name = raw.trim();
  if (name.isEmpty) return 'Nhập tên danh mục.';
  final lower = name.toLowerCase();
  for (final existing in existingNames) {
    if (existing.toLowerCase() == lower) {
      return 'Danh mục “$name” đã tồn tại.';
    }
  }
  return null;
}
```

`_showCategoryDialog`:

```dart
  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) async {
    final selfId = category?.id;
    final existingNames = [
      for (final c in ref.read(categoryProvider).categories)
        if (selfId == null || c.id != selfId) c.name,
    ];
    await showPixelDialog<void>(
      context: context,
      title: category == null ? 'DANH MỤC MỚI' : 'SỬA DANH MỤC',
      content: _CategoryForm(
        category: category,
        existingNames: existingNames,
      ),
    );
  }
```

Title thêm mới là `DANH MỤC MỚI` chứ không phải `THÊM DANH MỤC` để `find.text('THÊM DANH MỤC')` luôn chỉ trỏ về nút, kể cả khi dialog đang mở (dialog có barrier nên tap vào nút phía sau sẽ fail).

Lý do không dùng `actions:` của `showPixelDialog`: `actions` được dựng **ngoài** `content`, nên không đọc được `name`/`icon` đang thay đổi trong form. Form tự dựng hàng nút trong `content`.

`_CategoryForm` (ConsumerStatefulWidget private, cùng file — cần `ref` để lưu nên không đặt trong `content` của `showPixelDialog` dạng stateless):

```dart
class _CategoryForm extends ConsumerStatefulWidget {
  final Category? category;
  final List<String> existingNames;

  const _CategoryForm({required this.category, required this.existingNames});

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.category?.name ?? '');
  late String _icon = IconHelper.normalizeIconKey(
    widget.category?.icon ?? 'dotsThreeOutline',
  );
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = validateCategoryName(_name.text, widget.existingNames);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final name = _name.text.trim();
    setState(() => _isSaving = true);
    final notifier = ref.read(categoryProvider.notifier);
    final category = widget.category;
    if (category == null) {
      await notifier.addCategory(name, _icon);
    } else {
      await notifier.updateCategory(category.copyWith(name: name, icon: _icon));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pixelGroupHeader('BIỂU TƯỢNG'),
        CategoryGlyphGrid(
          selected: _icon,
          onChanged: (value) => setState(() => _icon = value),
        ),
        const SizedBox(height: 16),
        PixelTextField(
          key: const ValueKey('categoryNameField'),
          label: 'Tên danh mục',
          hint: 'Ví dụ: Cà phê, Du lịch',
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          errorText: _error,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PixelButton(
                label: 'HỦY',
                variant: PixelButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PixelButton(
                label: 'LƯU',
                icon: 'check',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

Hai quyết định thiết kế của đoạn trên: (1) `_CategoryForm` là `ConsumerStatefulWidget` vì `_submit` cần `ref.read(categoryProvider.notifier)` mà `content` của dialog không nằm trong widget cây có `ref` của `build(context, ref)`; (2) không có ghi chú "danh mục hệ thống chỉ sửa ở mã nguồn" — `ManageCategoriesScreen` không cho mở form khi `category.isDefault == true` (giữ hành vi cũ `onTap: null`), nên dòng chữ đó không bao giờ hiển thị. Dialog chỉ đến từ danh mục tùy chỉnh và từ nút `THÊM DANH MỤC`.

`_confirmDelete` đổi body sang `showPixelConfirm`:

```dart
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final shouldDelete = await showPixelConfirm(
      context,
      title: 'XÓA DANH MỤC?',
      message:
          'Các khoản chi thuộc “${category.name}” sẽ chuyển sang “Khác”. '
          'Ngân sách của danh mục này sẽ bị xóa.',
      confirmLabel: 'XÓA',
    );
    if (shouldDelete && category.id != null) {
      await ref.read(categoryProvider.notifier).deleteCategory(category.id!);
    }
  }
```

Giữ nguyên **từng chữ** nội dung cảnh báo (copy nghiệp vụ đã có ở `manage_categories_screen.dart:131-134`), chỉ đổi hoa/nhãn nút.

`build`:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final state = ref.watch(categoryProvider);
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: pixelAppBar(
        PixelScreenHeader(
          title: 'QUẢN LÝ DANH MỤC',
          subtitle: '${state.categories.length} danh mục',
          onBackTap: () => Navigator.of(context).pop(),
          trailing: AppIcon(name: 'tag', size: 32, color: palette.inkMuted),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: PixelButton(
          key: const ValueKey('addCategoryButton'),
          label: 'THÊM DANH MỤC',
          icon: 'plus',
          expanded: true,
          onPressed: () => _showCategoryDialog(context, ref),
        ),
      ),
      body: state.isLoading && state.categories.isEmpty
          ? const PixelLoading(label: 'Đang tải danh mục')
          : state.categories.isEmpty
          ? const PixelEmptyState(
              glyph: 'tag',
              title: 'Chưa có danh mục',
              message: 'Thêm danh mục để phân loại khoản chi.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              children: [
                if (state.errorMessage != null)
                  PixelPanel(
                    background: palette.butter,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        AppIcon(
                          name: 'alert',
                          size: 32,
                          color: palette.butterInk,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: text.bodyMedium
                                ?.copyWith(color: palette.butterInk),
                          ),
                        ),
                        PixelButton(
                          label: 'THỬ LẠI',
                          variant: PixelButtonVariant.secondary,
                          onPressed: () =>
                              ref.read(categoryProvider.notifier).loadCategories(),
                        ),
                      ],
                    ),
                  ),
                for (final category in state.categories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CategoryRow(
                      category: category,
                      onEdit: () => _showCategoryDialog(
                        context,
                        ref,
                        category: category,
                      ),
                      onDelete: () => _confirmDelete(context, ref, category),
                    ),
                  ),
              ],
            ),
    );
  }
```

`PixelScreenHeader` nhận `trailing` là `Widget?` và `background` là `Color?` (Task 2). `PixelLoading` và `PixelEmptyState` đều có constructor `const` (plan 2 Task 8) nên giữ `const` như trên.

`_CategoryRow` — `StatelessWidget` private, cùng file:

```dart
class _CategoryRow extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final accent = palette.accentForCategory(category.id ?? category.name);
    return PixelPanel(
      key: ValueKey('category-row-${category.id}'),
      padding: const EdgeInsets.all(8),
      onTap: category.isDefault ? null : onEdit,
      child: Row(
        children: [
          AppIcon(
            name: IconHelper.normalizeIconKey(category.icon),
            size: 32,
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    category.name,
                    style: text.titleMedium,
                  ),
                ),
                Text(
                  category.isDefault
                      ? 'Danh mục hệ thống'
                      : 'Chạm để chỉnh sửa',
                  style: text.bodySmall?.copyWith(color: palette.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (category.isDefault)
            PixelBadge(
              glyph: 'lock',
              label: 'MẶC ĐỊNH',
              accent: palette.surfaceAlt,
              ink: palette.inkMuted,
            )
          else ...[
            PixelIconButton(
              icon: 'edit',
              tooltip: 'Sửa danh mục',
              onPressed: onEdit,
            ),
            const SizedBox(width: 8),
            PixelIconButton(
              icon: 'trash',
              tooltip: 'Xóa danh mục',
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
```

`ValueKey('category-row-...')` truyền vào `PixelPanel` — `PixelPanel` có `super.key` ✓. `icon-only` luôn có `tooltip` (spec §3.9), `MẶC ĐỊNH` là nhãn **chữ** chứ không chỉ màu.

- [ ] **Step 5: Cập nhật `test/widget/screens_test.dart`**

Trong group `ManageCategoriesScreen Widget Tests` (dòng 46–62), đổi 2 assertion nhãn và giữ nguyên 2 assertion dữ liệu:

```dart
      expect(find.text('QUẢN LÝ DANH MỤC'), findsOneWidget);
      expect(find.text('THÊM DANH MỤC'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Nhà ở'), findsOneWidget);
```

Lý do: redesign đổi nhãn uppercase theo spec §3.3; vẫn giữ group để tổng số test không giảm. `_MockCategoryNotifier` trong file này dùng `Category(id: 1, name: 'Ăn uống', icon: '🍜', isDefault: true)` — map emoji vẫn render được vì `normalizeIconKey('🍜')` → `forkKnife` (plan 2 Task 6 giữ `_emojiToIconName`).

- [ ] **Step 6: Chạy test và gate**

Run: `flutter test test/widget/categories_pixel_test.dart && flutter test && flutter analyze`
Expected: PASS 6 test mới; toàn bộ PASS; analyze `No issues found!`.

Run:
```bash
grep -n "AppColors\|Icons\." lib/screens/categories/manage_categories_screen.dart
grep -n "FloatingActionButton" lib/screens/categories/manage_categories_screen.dart
grep -rn "FloatingActionButton" lib/
```
Expected: cả ba không kết quả (toàn repo chỉ còn FAB ở màn danh mục, vừa gỡ).

- [ ] **Step 7: Commit (khi được ủy quyền)**

```bash
git add lib/screens/categories/category_glyph_grid.dart lib/screens/categories/manage_categories_screen.dart test/widget/categories_pixel_test.dart test/widget/screens_test.dart
git commit -m "feat(ui): pixel category manager with glyph picker grid"
```

---

### Task 13: Thùng rác và Cài đặt — hàng khoản đã xóa, nhóm cài đặt pixel

Spec §5.9: "ảnh nhỏ/không ảnh, số tiền, ngày xóa; nút KHÔI PHỤC và XÓA VĨNH VIỄN (xác nhận); empty state". Spec §5.10: "Panel hồ sơ (avatar chữ cái pixel, email); nhóm DỮ LIỆU: Xuất CSV, Danh mục, Thùng rác; nhóm GIAO DIỆN: công tắc sáng/tối dạng pixel; nhóm TÀI KHOẢN: đăng xuất (xác nhận); VỀ APP: phiên bản từ `AppInfo`, tagline."

`getDeletedExpenses` đã được ký URL ở plan 1 (`docs/superpowers/plans/2026-11-01-cloud-signed-url-keepalive.md:1093`), nên `PixelReceiptImage.fromExpense` hoạt động ngay trong thùng rác mà không cần đụng repository.

**Files:**
- Modify: `lib/screens/trash/trash_screen.dart` (viết lại `_buildThumbnail`, `build`, `_restore`, `_deleteForever`)
- Modify: `lib/screens/settings/settings_screen.dart` (viết lại `build`)
- Modify: `test/widget/screens_test.dart:26,29-30,79` (4 assertion)
- Create: `test/widget/trash_settings_pixel_test.dart`

**Interfaces:**
- Consumes: `PixelScreenHeader` + `pixelGroupHeader` (Task 2), `PixelReceiptImage.fromExpense` (Task 1), `PixelPanel`, `PixelButton` + `PixelButtonVariant`, `PixelChip`, `PixelEmptyState`, `PixelLoading`, `showPixelConfirm` (plan 2 Task 8, `lib/widgets/pixel/pixel_dialog.dart`), `showPixelSnackBar` + `PixelTone` (`lib/widgets/pixel/pixel_snack_bar.dart`), `AppIcon`, `context.palette`, `IconHelper.normalizeIconKey`, `CurrencyFormatter.format`, `DateFormatter.formatDate`.
- Đã xác minh:
  - `ExpenseState` có ctor `const ExpenseState({expenses = const [], todayTotal = 0, weekTotal = 0, monthTotal = 0, isLoading = false, errorMessage})` (`lib/providers/expense_provider.dart:13-26`).
  - `Expense` có `final DateTime? deletedAt` và `bool get isDeleted => deletedAt != null` (`lib/data/models/expense.dart:11,26`).
  - `ExpenseNotifier`: `Future<List<Expense>> getDeletedExpenses()` (`:152`), `Future<void> restoreExpense(int id)` (`:143`), `Future<void> permanentlyDeleteExpense(Expense expense)` (`:155`).
  - `AppAuthState{status, user, errorMessage, isConfigured}` (`lib/providers/auth_provider.dart:10-14`), `AuthNotifier.signOut()` (`:167`), `ThemeNotifier.toggleTheme()` (`lib/providers/theme_provider.dart`).
  - `SupabaseConfig.isInitialized` là `static bool get` (`lib/core/config/supabase_config.dart:7`).
  - `AppInfo.name/tagline/aboutLabel` (plan 2 Task 3).
  - `showCsvExportSheet(BuildContext context)` và nhãn `'Xuất CSV (sao lưu)'` (plan 3 Task 10) — **phải giữ đúng chuỗi này**, plan 3 đã test nó.
- Produces: không có API công khai mới. `_NavRow` và `_CategoryRow` là widget private trong từng file, không export.

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/trash_settings_pixel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/providers/expense_provider.dart';
import 'package:chi_tieu/providers/theme_provider.dart';
import 'package:chi_tieu/screens/settings/settings_screen.dart';
import 'package:chi_tieu/screens/trash/trash_screen.dart';
import 'package:chi_tieu/widgets/pixel/app_icon.dart';
import 'package:chi_tieu/widgets/pixel/pixel_button.dart';
import 'package:chi_tieu/widgets/pixel/pixel_screen_header.dart';

Expense _deleted(int id) => Expense(
  id: id,
  caption: 'Cà phê $id',
  amount: 45000,
  categoryId: 1,
  createdAt: DateTime(2026, 10, 30, 9),
  deletedAt: DateTime(2026, 10, 5, 18),
);

class _FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _FakeExpenseNotifier(this._deletedRows) : super(const ExpenseState());

  final List<Expense> _deletedRows;
  final List<int> restored = [];
  final List<int> purged = [];
  bool failPurge = false;

  @override
  Future<List<Expense>> getDeletedExpenses() async => _deletedRows;

  @override
  Future<void> restoreExpense(int id) async => restored.add(id);

  @override
  Future<void> permanentlyDeleteExpense(Expense expense) async {
    if (failPurge) throw Exception('network');
    purged.add(expense.id!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier()
    : super(
        CategoryState(
          categories: [Category(id: 1, name: 'Ăn uống', icon: 'coffee')],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
    : super(const AppAuthState(status: AuthStatus.authenticated));

  int signOutCalls = 0;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThemeNotifier extends StateNotifier<ThemeMode>
    implements ThemeNotifier {
  _FakeThemeNotifier() : super(ThemeMode.light);

  int toggles = 0;

  @override
  Future<void> toggleTheme() async {
    toggles++;
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _trash(List<Expense> rows, {_FakeExpenseNotifier? fake}) {
  final notifier = fake ?? _FakeExpenseNotifier(rows);
  return ProviderScope(
    overrides: [
      expenseProvider.overrideWith((ref) => notifier),
      categoryProvider.overrideWith((ref) => _FakeCategoryNotifier()),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const TrashScreen()),
  );
}

Widget _settings({_FakeAuthNotifier? auth, _FakeThemeNotifier? theme}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => auth ?? _FakeAuthNotifier()),
      themeProvider.overrideWith((ref) => theme ?? _FakeThemeNotifier()),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
  );
}

void main() {
  testWidgets('Thùng rác: hai nút hiện ra, không còn PopupMenuButton', (
    tester,
  ) async {
    await tester.pumpWidget(_trash([_deleted(7)]));
    await tester.pumpAndSettle();

    expect(find.byType(PixelScreenHeader), findsOneWidget);
    expect(find.text('THÙNG RÁC'), findsOneWidget);
    expect(find.byKey(const ValueKey('trash-restore-7')), findsOneWidget);
    expect(find.byKey(const ValueKey('trash-purge-7')), findsOneWidget);
    expect(find.text('XÓA VĨNH VIỄN'), findsWidgets);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    expect(find.textContaining('05/10/2026'), findsOneWidget); // ngày xóa = deletedAt
  });

  testWidgets('Thùng rác: KHÔI PHỤC gọi restoreExpense', (tester) async {
    final fake = _FakeExpenseNotifier([_deleted(7)]);
    await tester.pumpWidget(_trash(const [], fake: fake));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trash-restore-7')));
    await tester.pumpAndSettle();
    expect(fake.restored, [7]);
  });

  testWidgets('Thùng rác trống hiện empty state pixel', (tester) async {
    await tester.pumpWidget(_trash(const []));
    await tester.pumpAndSettle();
    expect(find.text('Thùng rác đang trống.'), findsOneWidget);
    expect(find.byType(AppIcon), findsWidgets);
  });

  testWidgets('XÓA VĨNH VIỄN phải xác nhận; HỦY không xóa', (tester) async {
    final fake = _FakeExpenseNotifier([_deleted(7)]);
    await tester.pumpWidget(_trash(const [], fake: fake));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trash-purge-7')));
    await tester.pumpAndSettle();
    expect(find.text('XÓA VĨNH VIỄN?'), findsOneWidget);
    await tester.tap(find.text('HỦY'));
    await tester.pumpAndSettle();
    expect(fake.purged, isEmpty);

    // Nút trong dialog mang cùng nhãn với nút trên hàng, nên lấy `.last`
    // (dialog được push sau => đứng cuối hàng widget đang render).
    await tester.tap(find.byKey(const ValueKey('trash-purge-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XÓA VĨNH VIỄN').last);
    await tester.pumpAndSettle();
    expect(fake.purged, [7]);
  });

  testWidgets('Cài đặt: 4 nhóm, mục CSV giữ nhãn plan 3, không SwitchListTile', (
    tester,
  ) async {
    await tester.pumpWidget(_settings());
    await tester.pumpAndSettle();

    for (final label in ['DỮ LIỆU', 'GIAO DIỆN', 'TÀI KHOẢN', 'VỀ APP']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('CÀI ĐẶT'), findsOneWidget);
    expect(find.text('Xuất CSV (sao lưu)'), findsOneWidget);
    expect(find.text('Quản lý danh mục'), findsOneWidget);
    expect(find.text('Thùng rác'), findsOneWidget);
    expect(find.text('Chế độ tối'), findsOneWidget);
    expect(find.text('Phiên bản 2.2.0 • PIXEL JOURNAL'), findsOneWidget);
    expect(find.text('Phiên bản 2.1.0 • Locket Journal'), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsNothing);

    for (final box in tester.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
      final decoration = box.decoration;
      if (decoration is BoxDecoration) expect(decoration.gradient, isNull);
    }
  });

  testWidgets('Cài đặt: công tắc đổi theme, đăng xuất cần xác nhận', (
    tester,
  ) async {
    final auth = _FakeAuthNotifier();
    final theme = _FakeThemeNotifier();
    await tester.pumpWidget(_settings(auth: auth, theme: theme));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('darkModeToggle')));
    await tester.pumpAndSettle();
    expect(theme.toggles, 1);

    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('ĐĂNG XUẤT?'), findsOneWidget);
    expect(auth.signOutCalls, 0);
    await tester.tap(find.text('ĐĂNG XUẤT'));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 1);
  });

  testWidgets('Thùng rác + Cài đặt 1.3x text scale không vỡ', (tester) async {
    for (final home in <Widget>[const TrashScreen(), const SettingsScreen()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: ProviderScope(
            overrides: [
              expenseProvider.overrideWith(
                (ref) => _FakeExpenseNotifier([_deleted(7)]),
              ),
              categoryProvider.overrideWith((ref) => _FakeCategoryNotifier()),
              authProvider.overrideWith((ref) => _FakeAuthNotifier()),
              themeProvider.overrideWith((ref) => _FakeThemeNotifier()),
            ],
            child: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
```

Hai chi tiết đã xác minh để test không phải đoán: (1) `DateFormatter.formatDate` trả **`Hôm nay`/`Hôm qua` cho hai ngày gần nhất**, chỉ các ngày khác mới in `dd/MM/yyyy` (`lib/core/utils/date_formatter.dart:4-17`) — nên `deletedAt` phải là ngày đủ cũ (`DateTime(2026, 10, 5, 18)`) để in ra `05/10/2026` ở mọi lần chạy test; (2) `showPixelConfirm` nhận `confirmLabel`/`cancelLabel` (plan 2 Task 8) nên Task 13 truyền `cancelLabel: 'HỦY'` — mặc định `'Hủy'` sẽ làm `find.text('HỦY')` không khớp.

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/widget/trash_settings_pixel_test.dart`
Expected: FAIL — test 1 không tìm thấy `PixelScreenHeader` và `ValueKey('trash-restore-7')` vì màn hình vẫn dùng `AppBar` + `PopupMenuButton`; test 5 không tìm thấy `'Phiên bản 2.2.0 • PIXEL JOURNAL'` và vẫn thấy `SwitchListTile`. Đó chính là fail dự kiến; không được nới assertion để test "xanh" giả.

- [ ] **Step 3: Viết lại `trash_screen.dart`**

`_buildThumbnail` xóa toàn bộ (Task 1 đã gom mọi ảnh về `PixelReceiptImage`); import `dart:io` và `cached_network_image` bị xóa theo.

`_restore`:

```dart
  Future<void> _restore(Expense expense) async {
    await ref.read(expenseProvider.notifier).restoreExpense(expense.id!);
    if (!mounted) return;
    setState(_reload);
    showPixelSnackBar(
      context,
      'Đã khôi phục “${expense.caption}”.',
      tone: PixelTone.success,
    );
  }
```

`_deleteForever`:

```dart
  Future<void> _deleteForever(Expense expense) async {
    final confirm = await showPixelConfirm(
      context,
      title: 'XÓA VĨNH VIỄN?',
      message: 'Khoản chi và ảnh đính kèm sẽ không thể khôi phục.',
      confirmLabel: 'XÓA VĨNH VIỄN',
      cancelLabel: 'HỦY',
    );
    if (!confirm) return;
    try {
      await ref
          .read(expenseProvider.notifier)
          .permanentlyDeleteExpense(expense);
      if (!mounted) return;
      setState(_reload);
    } catch (_) {
      if (!mounted) return;
      showPixelSnackBar(
        context,
        'Không thể xóa vĩnh viễn. Kiểm tra kết nối và thử lại.',
        tone: PixelTone.danger,
      );
    }
  }
```

Giữ nguyên **từng chữ** message lỗi và message xác nhận hiện có (`trash_screen.dart:44,68-70`).

`build`:

```dart
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final categoryMap = {
      for (final category in ref.watch(categoryProvider).categories)
        category.id: category,
    };
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: pixelAppBar(
        PixelScreenHeader(
          title: 'THÙNG RÁC',
          subtitle: 'Hoàn tác hoặc xóa hẳn khoản chi khỏi cloud',
          onBackTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<Expense>>(
        future: _deletedExpenses,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const PixelLoading(label: 'Đang tải thùng rác');
          }
          if (snapshot.hasError) {
            return PixelPanel(
              background: palette.butter,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIcon(
                        name: 'alert',
                        size: 32,
                        color: palette.butterInk,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Không tải được thùng rác. Kiểm tra kết nối.',
                          style: text.bodyMedium
                              ?.copyWith(color: palette.butterInk),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PixelButton(
                    label: 'THỬ LẠI',
                    icon: 'refresh',
                    variant: PixelButtonVariant.secondary,
                    onPressed: () => setState(_reload),
                  ),
                ],
              ),
            );
          }
          final expenses = snapshot.data ?? const <Expense>[];
          if (expenses.isEmpty) {
            return const PixelEmptyState(
              glyph: 'trash',
              title: 'Thùng rác đang trống.',
              message:
                  'Xóa khoản chi trong nhật ký để đưa vào đây trước khi xóa hẳn.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final category = categoryMap[expense.categoryId];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TrashRow(
                  expense: expense,
                  categoryName: category?.name ?? 'Khác',
                  categoryIcon: IconHelper.normalizeIconKey(
                    category?.icon ?? 'dotsThreeOutline',
                  ),
                  onRestore: () => _restore(expense),
                  onPurge: () => _deleteForever(expense),
                ),
              );
            },
          );
        },
      ),
    );
  }
```

`TrashScreen` luôn được push thành route (drawer gọi `_push(const TrashScreen())` ở `lib/screens/main_screen.dart`, Cài đặt push ở Step 4) nên `onBackTap` an toàn; vì closure tham chiếu `context` nên `appBar:` không đặt `const`; `pixelAppBar` tự thêm `padding.top` cho status bar nên header không bị che. `PixelPanel` chỉ nhận `padding`, không có `margin`.

`_TrashRow` (StatelessWidget private, cùng file):

```dart
class _TrashRow extends StatelessWidget {
  final Expense expense;
  final String categoryName;
  final String categoryIcon;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  const _TrashRow({
    required this.expense,
    required this.categoryName,
    required this.categoryIcon,
    required this.onRestore,
    required this.onPurge,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final deletedAt = expense.deletedAt ?? expense.createdAt;
    return PixelPanel(
      key: ValueKey('trash-row-${expense.id}'),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PixelReceiptImage.fromExpense(
                expense,
                width: 52,
                height: 52,
                semanticLabel: 'Ảnh khoản chi ${expense.caption}',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(expense.amount),
                        style: text.titleLarge,
                      ),
                    ),
                    Text(
                      expense.caption.isEmpty
                          ? 'Không có ghi chú'
                          : expense.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        AppIcon(
                          name: categoryIcon,
                          size: 16,
                          color: palette.accentForCategory(categoryName),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            categoryName,
                            style: text.bodySmall
                                ?.copyWith(color: palette.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Xóa ngày ${DateFormatter.formatDate(deletedAt)}',
                      style: text.bodySmall
                          ?.copyWith(color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  key: ValueKey('trash-restore-${expense.id}'),
                  label: 'KHÔI PHỤC',
                  icon: 'undo',
                  variant: PixelButtonVariant.secondary,
                  onPressed: onRestore,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelButton(
                  key: ValueKey('trash-purge-${expense.id}'),
                  label: 'XÓA VĨNH VIỄN',
                  icon: 'trash',
                  variant: PixelButtonVariant.danger,
                  onPressed: onPurge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

`DateFormatter.formatDate` chỉ in `dd/MM/yyyy` khi ngày **không phải** hôm nay/hôm qua → test 1 dùng `deletedAt = 05/10/2026` và assert `'05/10/2026'` ✓. `showPixelSnackBar(context, message, {actionLabel, onAction, tone})` — tham số thứ 2 là positional (`lib/widgets/pixel/pixel_snack_bar.dart`, plan 2 Task 8).

- [ ] **Step 4: Viết lại `settings_screen.dart`**

Xóa import `../../core/constants/app_colors.dart`. Import mới: `../../core/config/supabase_config.dart`, `../../core/theme/app_palette.dart`, `../../widgets/pixel/app_icon.dart`, `../../widgets/pixel/pixel_button.dart`, `../../widgets/pixel/pixel_chip.dart`, `../../widgets/pixel/pixel_dialog.dart`, `../../widgets/pixel/pixel_panel.dart`, `../../widgets/pixel/pixel_screen_header.dart`, `csv_export_sheet.dart` (plan 3 Task 10), cùng các import cũ (`auth_provider`, `theme_provider`, `manage_categories_screen`, `trash_screen`).

Cấu trúc `build`:

```dart
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: pixelAppBar(
        PixelScreenHeader(
          title: 'CÀI ĐẶT',
          subtitle: AppInfo.tagline,
          onBackTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _ProfilePanel(displayName: displayName, email: email),
          pixelGroupHeader('DỮ LIỆU'),
          _NavRow(
            glyph: 'download',
            label: 'Xuất CSV (sao lưu)',
            onTap: () => showCsvExportSheet(context),
          ),
          _NavRow(
            glyph: 'tag',
            label: 'Quản lý danh mục',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
            ),
          ),
          _NavRow(
            glyph: 'trash',
            label: 'Thùng rác',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TrashScreen()),
            ),
          ),
          pixelGroupHeader('GIAO DIỆN'),
          PixelPanel(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                AppIcon(
                  name: isDarkMode ? 'moon' : 'sun',
                  size: 32,
                  color: palette.inkMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Chế độ tối', style: text.titleMedium),
                ),
                PixelChip(
                  key: const ValueKey('darkModeToggle'),
                  label: isDarkMode ? 'TỐI' : 'SÁNG',
                  icon: isDarkMode ? 'moon' : 'sun',
                  selected: isDarkMode,
                  showCheck: false,
                  onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ],
            ),
          ),
          pixelGroupHeader('TÀI KHOẢN'),
          _NavRow(
            glyph: 'logout',
            label: 'Đăng xuất',
            ink: palette.danger,
            onTap: () => _confirmLogout(context, ref),
          ),
          pixelGroupHeader('VỀ APP'),
          const _AboutPanel(),
        ],
      ),
    );
```

`displayName`/`email` lấy **đúng công thức** đang dùng ở `lib/screens/main_screen.dart` (đã có sẵn trong repo):

```dart
    final user = authState.user;
    final email = user?.email;
    final name = (user?.userMetadata?['full_name'] as String?)?.trim();
    final displayName = (name == null || name.isEmpty)
        ? (email != null ? email.split('@').first : 'Bạn')
        : name;
```

`_confirmLogout`:

```dart
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final yes = await showPixelConfirm(
      context,
      title: 'ĐĂNG XUẤT?',
      message: 'Bạn cần đăng nhập lại để xem dữ liệu trên cloud.',
      confirmLabel: 'ĐĂNG XUẤT',
      cancelLabel: 'HỦY',
      danger: false,
    );
    if (!yes) return;
    await ref.read(authProvider.notifier).signOut();
  }
```

Thêm `Semantics`/`Tooltip` không cần cho `_NavRow` vì nhãn luôn là chữ. `isDarkMode` giữ nguyên định nghĩa cũ `themeMode == ThemeMode.dark` (`settings_screen.dart:16`) — **không** đổi sang `Theme.of(context).brightness`, để không đổi hành vi đã được test.

Widget private trong cùng file:

```dart
class _ProfilePanel extends StatelessWidget {
  final String displayName;
  final String? email;

  const _ProfilePanel({required this.displayName, this.email});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final connected = SupabaseConfig.isInitialized;
    return PixelPanel(
      background: palette.mint,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.mintStrong,
                  border: Border.all(color: palette.lineStrong, width: 3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : 'C',
                    style: text.displaySmall?.copyWith(color: palette.onAccent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        displayName,
                        style: text.titleLarge
                            ?.copyWith(color: palette.onAccent),
                      ),
                    ),
                    Text(
                      email ?? 'Tài khoản đám mây',
                      style: text.bodySmall
                          ?.copyWith(color: palette.onAccent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppIcon(
                name: connected ? 'cloud' : 'cloudOff',
                size: 32,
                color: palette.onAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  connected
                      ? 'Đang kết nối Supabase'
                      : 'Chưa cấu hình Supabase. Kiểm tra biến môi trường.',
                  style: text.bodySmall?.copyWith(color: palette.onAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String glyph;
  final String label;
  final VoidCallback onTap;
  final Color? ink;

  const _NavRow({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = ink ?? palette.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PixelPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            AppIcon(name: glyph, size: 32, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppIcon(name: 'chevronRight', size: 16, color: palette.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return PixelPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.mint,
                  border: Border.all(color: palette.lineStrong, width: 3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: AppIcon(
                    name: 'wallet',
                    size: 32,
                    color: palette.onAccent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppInfo.name, style: text.titleLarge),
                    Text(
                      AppInfo.aboutLabel,
                      style: text.bodySmall?.copyWith(color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mỗi khoản chi cần một ảnh. Ảnh lưu ở bucket private, chỉ bạn đọc được '
            'qua đường dẫn ký tạm.',
            style: text.bodySmall?.copyWith(color: palette.inkMuted),
          ),
        ],
      ),
    );
  }
}
```

`AppInfo.aboutLabel = 'Phiên bản $version • $tagline'` với `version = '2.2.0'`, `tagline = 'PIXEL JOURNAL'` (plan 2 Task 3, `lib/core/constants/app_info.dart`) → chuỗi test 5 assert `'Phiên bản 2.2.0 • PIXEL JOURNAL'` ✓. **Nếu plan 2 chưa đổi `AppInfo`** thì test 5 fail đúng — hoàn thành plan 2 trước, không đổi constant tại chỗ.

`PixelChip` có `onTap` và `selected`, `icon` là glyph `String` (plan 2 Task 7). `AppIcon` size **chỉ 16/32/48**.

- [ ] **Step 5: Cập nhật `test/widget/screens_test.dart`**

Bốn thay đổi tối thiểu, giữ nguyên mọi group và số test:

```dart
      expect(find.text('CÀI ĐẶT'), findsOneWidget);          // dòng 26: 'Cài đặt'
      expect(find.byKey(const ValueKey('darkModeToggle')), findsOneWidget); // dòng 30: thay find.byType(SwitchListTile)
      expect(find.text('Chế độ tối'), findsOneWidget);        // dòng 27: giữ nguyên
      expect(find.text('Quản lý danh mục'), findsOneWidget);  // dòng 28: giữ nguyên
      expect(find.text('Thùng rác'), findsOneWidget);         // dòng 29: giữ nguyên (nhãn hàng menu, không phải header)
```

và trong group `TrashScreen Widget Tests`:

```dart
      expect(find.text('THÙNG RÁC'), findsOneWidget);          // dòng 79: 'Thùng rác' -> header uppercase
      expect(find.text('Thùng rác đang trống.'), findsOneWidget); // dòng 80: giữ nguyên (spec §6)
```

`_MockThemeNotifier` trong `screens_test.dart` không override `toggleTheme` → chỉ an toàn vì test không chạm `darkModeToggle`; **không** tap nó ở test cũ.

- [ ] **Step 6: Chạy test và gate**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter test test/widget/trash_settings_pixel_test.dart && flutter test && flutter analyze`
Expected: PASS 7 test mới; toàn bộ PASS; analyze sạch.

Run: `grep -rn "CachedNetworkImage\|Image.file" lib/`
Expected: **chỉ** `lib/widgets/pixel/pixel_receipt_image.dart` (gate nghiêm, Task 9 đã hoãn file này tới đây).

Run:
```bash
grep -n "AppColors\|Icons\.\|LinearGradient\|Card(\|SwitchListTile\|PopupMenuButton" lib/screens/settings/settings_screen.dart
grep -n "AppColors\|Icons\.\|dart:io\|PopupMenuButton\|TextButton\|FilledButton" lib/screens/trash/trash_screen.dart
```
Expected: cả hai không kết quả.

Run: `flutter test test/widget/app_drawer_test.dart`
Expected: PASS — drawer thuộc plan 2 Task 9; Task 13 chỉ xác minh không hồi quy (nhãn mục điều hướng không đổi).

- [ ] **Step 7: Commit (khi được ủy quyền)**

```bash
git add lib/screens/trash/trash_screen.dart lib/screens/settings/settings_screen.dart test/widget/trash_settings_pixel_test.dart test/widget/screens_test.dart
git commit -m "feat(ui): pixel trash rows with visible actions and grouped settings"
```

---

### Task 14: Dọn code cũ, thống nhất phiên bản, tài liệu và gate kết thúc plan

Spec §3.5: "xóa component không còn dùng, không giữ shim." Spec §4.8: version `2.2.0+3`, `AppInfo` là nguồn duy nhất, cập nhật README/requirements/project-structure, "không tuyên bố đã kiểm thử trên thiết bị nếu chưa chạy thực tế".

**Files:**
- Delete: `lib/widgets/glass_card.dart`, `lib/widgets/screen_background.dart`, `lib/widgets/category_icon_badge.dart`, `lib/widgets/expense_card.dart`, `lib/widgets/priority_badge.dart`, `lib/widgets/category_chip.dart`, `lib/widgets/amount_display.dart`, `lib/core/constants/app_colors.dart`
- Delete: `test/widget/widgets_test.dart` (4 group, 8 test — toàn bộ test widget cũ đã bị thay)
- Modify: `test/unit/auth_and_supabase_test.dart` (xóa 2 group + 2 import)
- Modify: `pubspec.yaml` (`version:`), `README.md`, `docs/requirements.md`, `docs/project-structure.md`
- Create: `test/widget/legacy_cleanup_test.dart`

**Interfaces:**
- Consumes: mọi task trước (1–13) + plan 2 (`AppInfo` ở `lib/core/constants/app_info.dart`) + plan 1 (`lib/core/utils/storage_paths.dart`) + plan 3 (`amount_input_formatter.dart`, `csv_export_service.dart`).
- Produces: không API mới. `test/widget/legacy_cleanup_test.dart` là gate tự động, chạy trong `flutter test` nên các plan sau không hồi quy được nữa.
- Số kiểm được đã xác minh trước khi viết plan:
  - `grep -rn "AppColors" lib/ | wc -l` = **145** trên **15** file → tất cả đã chuyển sang `context.palette` ở Task 4–13 và plan 2.
  - `grep -rn "Icons\." lib/ | wc -l` = **96** dòng trên **17** file, phân bổ:`icon_helper` (20) và `app_section` (4) + `hamburger_button` (1) + `app_drawer` (8) thuộc plan 2 Task 5/6/9; `onboarding` (3) + `login` (7) + `register` (7) Task 4; `camera` (9) + `feed_grid` (2) + `feed_photo` (3) + `expense_form_sheet` (1) Task 7–9; `home` (12) Task 5; `statistics` (1) Task 10; `settings` (8) + `trash` (4) Task 13; `manage_categories` (4) Task 12; `expense_card` (2) xóa ở Task 14. Tổng = 96, đủ 17 file, không file nào ngoài danh sách này chứa `Icons.`.
  - Importer còn lại của 7 widget cũ tại thời điểm bắt đầu plan: `glass_card`/`screen_background` ← home(5), statistics(10), budget(11); `category_icon_badge` ← home(5); `priority_badge` ← feed_photo(9), home(5); `expense_card`/`category_chip`/`amount_display` ← chỉ `test/widget/widgets_test.dart`. Tức là sau Task 13, `lib/` không còn import nào tới 7 file đó.
  - Số test: baseline repo **trước 4 plan** là **69** (đã chạy `flutter test` khi viết plan: `+69: All tests passed!`), nhưng đầu plan 4 là **sau plan 1–3** nên mốc thật là con số đã ghi ở bước kiểm tra đầu plan (dòng 32, dự kiến 110–120). Task 14 xóa **10** test (`widgets_test.dart` 8 + `Fintech Colors Tests` 1 + `CategoryIconBadge Widget Tests` 1) và thêm **5** gate test → net **-5**. Cả plan 4: +91 −10 = **+81** so với mốc đầu plan, tức cuối plan phải thấy **mốc đầu plan + 81** test. Không hard-code: lấy số thật ở output `flutter test`, điều kiện đạt là `số cuối ≥ số đầu plan + 75`.

- [ ] **Step 1: Xóa file cũ và dọn test tham chiếu**

```bash
git rm lib/widgets/glass_card.dart lib/widgets/screen_background.dart \
       lib/widgets/category_icon_badge.dart lib/widgets/expense_card.dart \
       lib/widgets/priority_badge.dart lib/widgets/category_chip.dart \
       lib/widgets/amount_display.dart lib/core/constants/app_colors.dart \
       test/widget/widgets_test.dart
```

`git rm` chỉ an toàn khi các task trước đã được commit (lịch sử còn giữ được nội dung). Nếu chưa commit gì, dùng `rm` thường rồi `git add -A` ở Step 9: mọi file xóa đều đang nằm trong working tree nên không mất work của user.

Sửa `test/unit/auth_and_supabase_test.dart`:
- Xóa 2 dòng import `package:chi_tieu/core/constants/app_colors.dart` (dòng 4) và `package:chi_tieu/widgets/category_icon_badge.dart` (dòng 8).
- Xóa nguyên 2 group: `Fintech Colors Tests` (dòng 112-118) và `CategoryIconBadge Widget Tests` (dòng 120-131).
- Giữ nguyên 3 group còn lại (`Auth State Tests`, `Storage Path Tests`, `IconHelper Tests`) — `IconHelper Tests` đã được plan 2 Task 6 đổi assertion sang `isA<AppIcon>()`; nếu vẫn thấy `isA<Icon>()` thì plan 2 chưa xong, **dừng và hoàn tất plan 2**.

Lý do xóa chứ không giữ: spec §3.5 cấm shim; hai group trên chỉ kiểm tra hằng màu/`Icon` của hệ cũ không còn tồn tại.

- [ ] **Step 2: Viết gate test failing (chưa đổi pubspec/README)**

Tạo `test/widget/legacy_cleanup_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/constants/app_info.dart';

List<File> _dartFiles(String root) => Directory(root)
    .listSync(recursive: true, followLinks: false)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

List<String> _filesContaining(String needle, {String root = 'lib'}) => [
  for (final file in _dartFiles(root))
    if (file.readAsStringSync().contains(needle)) file.path,
];

const _legacyWidgets = [
  'lib/widgets/glass_card.dart',
  'lib/widgets/screen_background.dart',
  'lib/widgets/category_icon_badge.dart',
  'lib/widgets/expense_card.dart',
  'lib/widgets/priority_badge.dart',
  'lib/widgets/category_chip.dart',
  'lib/widgets/amount_display.dart',
  'lib/core/constants/app_colors.dart',
];

void main() {
  group('Pixel cleanup gates', () {
    test('7 widget cũ và AppColors không còn trên đĩa', () {
      expect(
        [for (final path in _legacyWidgets) if (File(path).existsSync()) path],
        isEmpty,
      );
    });

    test('lib/ không còn tham chiếu AppColors hay Icons.*', () {
      expect(_filesContaining('AppColors'), isEmpty);
      expect(_filesContaining('Icons.'), isEmpty);
    });

    test('lib/ không còn widget cũ và fl_chart', () {
      for (final needle in [
        'GlassCard',
        'ScreenBackground',
        'CategoryIconBadge',
        'ExpenseCard',
        'PriorityBadge',
        'CategoryChip',
        'AmountDisplay',
        'fl_chart',
        'google_fonts',
      ]) {
        expect(_filesContaining(needle), isEmpty, reason: needle);
      }
    });

    test('pubspec và AppInfo cùng một phiên bản', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('version: ${AppInfo.version}+${AppInfo.build}'));
      expect(AppInfo.version, '2.2.0');
      expect(AppInfo.build, '3');
      expect(AppInfo.tagline, 'PIXEL JOURNAL');
    });

    test('mọi màn hình chính có thư mục pixel và header pixel', () {
      for (final path in [
        'lib/screens/home/home_screen.dart',
        'lib/screens/statistics/statistics_screen.dart',
        'lib/screens/budget/budget_screen.dart',
        'lib/screens/categories/manage_categories_screen.dart',
        'lib/screens/trash/trash_screen.dart',
        'lib/screens/settings/settings_screen.dart',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      for (final path in [
        'lib/widgets/pixel/pixel_receipt_image.dart',
        'lib/widgets/pixel/pixel_screen_header.dart',
        'lib/widgets/pixel/pixel_expense_tile.dart',
        'lib/widgets/pixel/pixel_share_bar.dart',
        'lib/widgets/pixel/pixel_stacked_share.dart',
        'lib/widgets/pixel/pixel_bar_chart.dart',
        'lib/widgets/pixel/feed_hud.dart',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });
}
```

Run: `flutter test test/widget/legacy_cleanup_test.dart`
Expected: FAIL ở test 4 (`version: 1.0.0+1` ≠ `2.2.0+3`) sau khi đã xóa file ở Step 1; test 1-3, 5 PASS. Nếu test 2 hoặc 3 fail, **quay lại task tương ứng sửa hết** rồi mới đi tiếp — không được xóa gate test để "cho qua".

- [ ] **Step 3: Sửa `pubspec.yaml`**

Đổi dòng 4: `version: 1.0.0+1` → `version: 2.2.0+3` (khớp `AppInfo.version`/`AppInfo.build`, spec §4.8). Chạy `flutter pub get` để đồng bộ `pubspec.lock`.

`grep -n "fl_chart\|google_fonts" pubspec.yaml` → Expected: không kết quả (plan 2 Task 1 gỡ `google_fonts`, Task 10 của plan này gỡ `fl_chart`).

- [ ] **Step 4: Chạy gate đầy đủ và sửa tới khi xanh**

```bash
export PATH="$PATH:/c/flutter/bin"
flutter analyze
flutter test
```
Expected: `No issues found!` và `All tests passed!`. **Ghi lại số test thật** từ dòng `N tests passed` — dùng cho README ở Step 5.

Run: `flutter build apk --debug`
Expected: `√ Built build\app\outputs\flutter-apk\app-debug.apk`. Nếu fail, dán nguyên văn lỗi vào báo cáo và dừng; không tự hạ phiên bản package, không sửa `android/build.gradle` ngoài phạm vi.

Run (các gate grep, phải trả về rỗng):
```bash
grep -rn "AppColors" lib/ test/
grep -rn "Icons\." lib/
grep -rn "GlassCard\|ScreenBackground\|CategoryIconBadge\|ExpenseCard\|PriorityBadge\|CategoryChip\|AmountDisplay" lib/ test/
grep -rn "CachedNetworkImage\|Image.file" lib/
grep -rn "LinearGradient" lib/screens/
grep -rn "fl_chart" lib/ pubspec.yaml
grep -rn "TODO\|FIXME\|@Skip\|skip:" lib/ test/
```
Expected: 5 grep đầu chỉ cho phép kết quả nằm trong `lib/widgets/pixel/pixel_receipt_image.dart` (riêng grep ảnh); grep `LinearGradient` chỉ quét `lib/screens/` nên `lib/widgets/pixel/*.dart` không liên quan, và `lib/core/constants/app_colors.dart` (nơi chứa 8 gradient cũ) đã bị `git rm` ở Step 1 của chính task này; `lib/widgets/pixel/pixel_snack_bar.dart`/`feed_hud.dart` dùng gradient HUD theo spec §3.7 nên grep cuối chỉ quét `lib/screens/`. Hai grep còn lại phải rỗng.

- [ ] **Step 5: `docs/requirements.md` — thêm FR-28..FR-34**

Chèn 7 dòng tiếp sau FR-27 trong bảng FR:

```markdown
| FR-28 | Bộ icon pixel tự vẽ (lưới 16×16, `CustomPainter`) thay Material Icons và emoji; `IconHelper` giữ API cũ, chỉ đổi render sang `AppIcon`. | Đã có |
| FR-29 | `AppPalette` (ThemeExtension) là nguồn màu duy nhất, tương phản WCAG ở cả hai theme; bỏ gradient và glassmorphism. | Đã có |
| FR-30 | Component pixel dùng chung cho mọi màn: panel, button, chip, progress, segmented, text field, dialog/sheet/snackbar, empty/loading/stat/badge/divider, expense tile. | Đã có |
| FR-31 | Biểu đồ tự vẽ bằng khối pixel (tỉ trọng danh mục, mức độ cần thiết, theo ngày) kèm nhãn chữ và `Semantics`; đã gỡ `fl_chart`. | Đã có |
| FR-32 | Vùng chạm ≥ 48×48 dp, chữ không chỉ dựa vào màu, lỗi hiển thị dưới field, test ở text scale 1.3×. | Đã có, cần xác minh thêm trên thiết bị |
| FR-33 | Ảnh khoản chi chỉ render qua `PixelReceiptImage` với placeholder "Không tải được ảnh"; feed/lưới/thùng rác/danh mục theo ngôn ngữ Pixel. | Đã có |
| FR-34 | Phiên bản app lấy từ `AppInfo` (`2.2.0` / build `3`), khớp `pubspec.yaml`, hiển thị ở drawer và Cài đặt. | Đã có |
```

Cập nhật dòng "trạng thái" của FR-08 trong bảng (đang ghi "Đã có" với mô tả donut/bar `fl_chart`) thành: `| FR-08 | Biểu đồ pixel theo danh mục, mức độ cần thiết và theo ngày; nhận xét tổng quan. | Đã có |` Lý do: Task 10 thay biểu đồ tròn `fl_chart` bằng thanh khối pixel (spec §3.6). Chỉ đổi mô tả, giữ nguyên số dòng của bảng.

- [ ] **Step 6: `README.md`**

Bốn chỗ cần sửa (số dòng tham khảo lúc viết plan; xác minh lại bằng grep trước khi sửa):
- Dòng 5: `<h1 align="center">Chi Tiêu — Pixel Expense Journal</h1>`.
- Dòng 8: `<b>Nhật ký chi tiêu bằng ảnh, giao diện Pixel tự vẽ, ảnh hóa đơn lưu bucket private trên Supabase và hiển thị qua signed URL, bắt buộc đăng nhập.</b>`.
- Dòng 53 (mục "Giao diện"): thay "Thẻ kính mờ (glassmorphism), gradient, huy hiệu icon pastel." bằng "Panel viền vuông 2–3 px, bóng cứng lệch (3,4), bộ icon pixel 16×16 tự vẽ, font VT323 + Be Vietnam Pro bundle offline."
- Bảng công nghệ (dòng 88-89, 93): 

```markdown
| **Giao diện** | `AppPalette` (ThemeExtension), font bundle VT323 + Be Vietnam Pro | Pixel sáng/tối, không dùng google_fonts |
| **Biểu đồ** | Widget pixel tự vẽ (`PixelShareBar`, `PixelStackedShare`, `PixelBarChart`) | Không dùng `fl_chart` |
| **Kiểm thử** | `flutter_test` | <N> Unit & Widget tests |
```

`<N>` = số test thật đo được ở Step 4. Không giữ số cũ.

Thêm mục mới ở cuối README:

```markdown
## Chưa xác minh trên thiết bị

Các mục dưới đây chỉ được kiểm chứng bằng unit/widget test trong môi trường CLI, chưa chạy
trên máy Android thật:

1. Ảnh hóa đơn load từ bucket private qua signed URL (hết hạn 24h, THỬ LẠI khi lỗi).
2. Chụp ảnh bằng camera thật và lật camera trong màn nhật ký.
3. Share sheet khi xuất CSV (kèm dấu tiếng Việt và BOM UTF-8).
4. Text scale hệ thống 1.3× và 2.0× trên màn hình nhỏ.
5. Supabase free tier bị pause sau 7 ngày: keep-alive bằng GitHub Actions và cron-job.org
   chỉ hoạt động sau khi người dùng cấu hình secret và bật workflow.
```

Nếu README còn mục "Ảnh bìa/gradient" mô tả giao diện cũ, cập nhật theo §3 của spec; không chụp screenshot mới trong plan này.

- [ ] **Step 7: `docs/project-structure.md`**

Trong khối cây thư mục (dòng ~12-70):
- Thêm `lib/core/icons/` với `pixel_glyphs.dart`, `pixel_glyph_data.dart`, `pixel_glyph.dart` (tên thật theo plan 2 — `ls lib/core/icons/`).
- Thêm `lib/core/theme/app_palette.dart` và `lib/core/constants/app_info.dart`; giữ dòng `theme/app_theme.dart` nhưng đổi chú thích thành `# Sinh ThemeData từ AppPalette` (file vẫn tồn tại).
- Thêm `lib/widgets/pixel/` và liệt kê các file đang có (`ls lib/widgets/pixel/`).
- Thêm `lib/core/utils/storage_paths.dart`, `lib/core/utils/amount_input_formatter.dart`, `lib/core/utils/pixel_allocate.dart`, `lib/data/repositories/csv_export_service.dart`, `lib/screens/home/expense_filter_sheet.dart`, `lib/screens/home/dashboard_summary.dart`, `lib/screens/home/budget_progress_card.dart`, `lib/screens/statistics/statistics_charts.dart`, `lib/screens/categories/category_glyph_grid.dart`, `lib/screens/settings/csv_export_sheet.dart`.
- Xóa các dòng `glass_card.dart`, `expense_card.dart`, `category_icon_badge.dart`, `priority_badge.dart`, `category_chip.dart`, `amount_display.dart`, `screen_background.dart`, `app_colors.dart`.
- Cập nhật dòng 189 note về drawer/icon theme: giữ, bổ sung "drawer và mọi nút icon dùng `AppIcon`".

Run: `ls lib/widgets lib/core/icons lib/widgets/pixel` rồi đối chiếu từng dòng trong doc với output; không chép tên file từ bộ nhớ.

- [ ] **Step 8: Xác minh accessibility và 48dp bằng test có sẵn**

Run: `flutter test --reporter expanded | grep -i "48\|text scale\|semantics"`
Expected: thấy các test đã viết ở Task 1–13 (tile 48dp, header 48dp, textScale 1.3, semantics feed). Nếu thiếu màn nào trong danh sách dưới đây, bổ sung test cho màn đó **trước** khi đóng plan:

| Màn | Test 48dp | Test textScale 1.3 |
| --- | --- | --- |
| Onboarding/Login/Register | Task 4 | Task 4 |
| Dashboard | Task 5 | Task 5 |
| Form khoản chi | Task 7 | Task 7 |
| Feed/Camera/Grid | Task 8, 9 | Task 8 |
| Thống kê | Task 10 | Task 10 |
| Ngân sách | Task 11 | Task 11 |
| Danh mục | Task 12 | Task 12 |
| Thùng rác / Cài đặt | Task 13 | Task 13 |

- [ ] **Step 9: Chạy lại toàn bộ và commit (khi được ủy quyền)**

```bash
export PATH="$PATH:/c/flutter/bin"
flutter analyze && flutter test && flutter build apk --debug
```
Expected: analyze sạch, `All tests passed!` (số test đã ghi ở Step 4), build `√ Built`.

```bash
git add -A lib test pubspec.yaml pubspec.lock README.md docs
git commit -m "chore(ui): remove legacy theme widgets, cut app to 2.2.0+3, document pixel redesign"
```

- [ ] **Step 10: Báo cáo kết quả (bắt buộc, không được bỏ)**

Ghi vào message trả lời cho user, theo đúng sự thật:
1. Số test lúc bắt đầu plan (mốc đã ghi ở bước kiểm tra đầu plan — repo gốc là 69, sau plan 1–3 thường cao hơn) và số thật đo được lúc kết thúc, kèm 10 test legacy đã xóa.
2. Kết quả `flutter analyze` / `flutter test` / `flutter build apk --debug` (dán dòng cuối mỗi lệnh).
3. Danh sách 5 mục "Chưa xác minh trên thiết bị" từ README.
4. Việc user còn phải làm tay: chạy `supabase_setup.sql` (plan 1), cấu hình `.env` + secret GitHub Actions + cron-job.org (plan 1), bật Google provider (README hiện có), và **giữ cho dự án Supabase có hoạt động hằng ngày** để không bị pause lại.
5. Không tuyên bố "đã kiểm thử UI trên máy" nếu chưa chạy `flutter run` trên thiết bị — plan này không có bước đó.

---

## Self-review của plan (đã chạy khi viết)

- **Phủ spec**: §3.2 tokens → plan 2; §3.3 font → plan 2; §3.4 icon → plan 2 + Task 12; §3.5 kit → plan 2 + Task 1-3; §3.6 biểu đồ (bỏ donut, bỏ `fl_chart`) → Task 3 + 10; §3.7 feed/camera → Task 8-9; §3.8 chuyển động → Task 5 (`AnimatedSwitcher` 160 ms), Task 4 (120 ms), plan 2 kit; §3.9 accessibility → mọi task có test 48dp/textScale; §5.1-5.12 → Task 4-13; §6 empty/error/loading → Task 1, 5, 9, 10, 12, 13; §4.8 phiên bản & tài liệu → Task 14.
- **Không placeholder**: các đoạn `...` còn lại chỉ là chữ lược trong mô tả bằng lời, mọi bước cần code đều có code khối đầy đủ. Nếu executor gặp `...` trong code, đó là lỗi plan → báo về leader, không tự bịa tiếp.
- **Nhất quán tên**: `resolveReceiptImage`/`PixelReceiptImage.fromExpense`/`receiptPlaceholder` (Task 1) dùng ở Task 2, 7, 9, 13; `pixelGroupHeader` (Task 2) dùng ở Task 6, 12, 13; `ExpenseFilter` public (Task 6) dùng ở Task 5; `openExpenseForm` (Task 7) dùng ở Task 8-9; `StatRange`/`statRangeLabel`/`dailySeries` (Task 10); `BudgetMode` (Task 11); `AppInfo.aboutLabel` (Task 13, 14).
- **Ràng buộc đã chốt**: không thêm glyph mới, không `Icons.*`, không `AppColors`, không gradient ở `lib/screens/`, không `fl_chart`, không gọi mạng trong test, không commit khi chưa ủy quyền.
