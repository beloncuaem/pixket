# Pixel Foundation: Tokens, Fonts, Icons & Component Kit — Implementation Plan (Plan 2/4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng nền tảng thiết kế Pixel — font bundle offline, design token sáng/tối qua `ThemeExtension`, bộ icon pixel tự vẽ, và component kit — để các plan sau chỉ việc lắp màn hình.

**Architecture:** `AppPalette extends ThemeExtension` là nguồn màu duy nhất; `AppTheme` sinh `ThemeData` từ palette và `TextStyle` có `fontVariations` tường minh. Icon pixel là dữ liệu lưới 16×16 (`pixelGlyphs`) được vẽ bằng `CustomPainter`, truy cập qua `AppIcon`; `IconHelper` giữ API cũ nên không đổi dữ liệu danh mục. Component kit nằm trong `lib/widgets/pixel/`, không màn hình nào tự vẽ lại kiểu dáng.

**Tech Stack:** Flutter Material 3, Dart 3.13, VT323 + Be Vietnam Pro (variable), `flutter_test`, `CustomPainter`. Bỏ dependency `google_fonts`.

**Spec:** [docs/superpowers/specs/2026-11-01-chi-tieu-pixel-redesign-design.md](../specs/2026-11-01-chi-tieu-pixel-redesign-design.md) — §3.2, §3.3, §3.4, §3.5, §3.9, §4.1, §4.2.

**Depends on:** Plan 1 đã merge (repository/model ổn định để Plan 4 không xung đột).
**Blocks:** Plan 4 (redesign màn hình dùng `context.palette`, `AppIcon`, component kit).

## Global Constraints

- Trả lời và comment bằng tiếng Việt; giữ thuật ngữ kỹ thuật tiếng Anh.
- Font **bắt buộc bundle** trong `assets/fonts/`; không tải font hay icon từ mạng lúc chạy.
- Không dùng `Icon(Icons.*)` trong UI mới; mọi icon đi qua `AppIcon`.
- Không dùng màu hex thô hay `Colors.*` trong widget (trừ `Colors.transparent`, `Colors.black/white` cho overlay ảnh); mọi màu đọc từ `context.palette`.
- Tương phản chữ/nền ≥ 4.5:1, chữ lớn (≥ 24 px đậm hoặc ≥ 32 px) ≥ 3:1 ở **cả hai** theme.
- Vùng chạm ≥ 48×48 dp, khoảng cách giữa hai đích chạm ≥ 8 dp.
- Size glyph chỉ dùng bội số 16 logical px: 16, 32, 48.
- Copy UI tiếng Việt, không emoji.
- Chạy `flutter analyze` + `flutter test` sau mỗi task; `flutter build apk --debug` ở task cuối.
- `flutter` **không** có trong PATH của Git Bash trên máy phát triển này; SDK ở `/c/flutter/bin`. Mỗi lệnh chạy với `export PATH="$PATH:/c/flutter/bin"` (đã xác minh `flutter --version` → Flutter 3.47.6 / Dart 3.13.5).
- Không commit/push nếu người dùng chưa ủy quyền.
- **Shim tạm thời có chủ đích:** `AppColors` tồn tại tới Plan 4 vì 145 dòng tham chiếu trên 15 file `lib/` đang nằm rải rác. Trong plan này `AppColors` được đổi **giá trị** sang hex pixel (light) và đánh dấu `@Deprecated`; Plan 4 xóa hẳn. Không thêm tham chiếu `AppColors` mới.

---

## File Structure

| File | Responsibility |
| --- | --- |
| Create `assets/fonts/VT323-Regular.ttf`, `assets/fonts/BeVietnamPro-Variable.ttf`, `assets/fonts/OFL-VT323.txt`, `assets/fonts/OFL-BeVietnamPro.txt` | Font offline + giấy phép |
| Modify `pubspec.yaml` | Khai báo `assets/fonts/`, hai `fonts: family`, xóa `google_fonts` |
| Create `lib/core/theme/app_palette.dart` | `AppPalette extends ThemeExtension` + `context.palette` + bảng light/dark |
| Create `test/unit/app_palette_contrast_test.dart` | Test tương phản WCAG cho các cặp token |
| Create `lib/core/theme/pixel_text_theme.dart` | `TextTheme` dựng từ font bundle + `FontVariation('wght', …)` |
| Modify `lib/core/theme/app_theme.dart` | `ThemeData` light/dark mới: ColorScheme, component themes, picker/sheet/dialog |
| Modify `lib/core/constants/app_colors.dart` | Giá trị đổi sang hex pixel, `@Deprecated`, xóa gradient/hằng không dùng |
| Create `lib/core/constants/app_info.dart` | `appName`, `version`, `build`, `tagline` |
| Create `lib/core/icons/pixel_glyphs.dart` | Dữ liệu lưới 16×16 cho toàn bộ glyph |
| Create `lib/core/icons/pixel_glyph_data.dart` | Hàm parse/validate glyph (pure) |
| Create `test/unit/pixel_glyphs_test.dart` | Test 16×16, ký tự hợp lệ, phủ đủ khóa |
| Create `lib/widgets/pixel/pixel_glyph.dart` | `CustomPainter` vẽ ô vuông, `isAntiAlias: false` |
| Create `lib/widgets/pixel/app_icon.dart` | `AppIcon` + `PixelIconButton` (48 dp, semantics) |
| Modify `lib/core/utils/icon_helper.dart` | `getIconWidget` trả `AppIcon`; giữ 19 khóa + map emoji |
| Modify `lib/core/navigation/app_section.dart` | `IconData` → `String glyph` |
| Modify `lib/widgets/hamburger_button.dart`, `lib/widgets/app_drawer.dart` | Đổi icon sang `AppIcon`, bỏ gradient cứng |
| Create `lib/widgets/pixel/pixel_panel.dart`, `pixel_button.dart`, `pixel_chip.dart`, `pixel_progress.dart`, `pixel_text_field.dart`, `pixel_dialog.dart`, `pixel_sheet.dart`, `pixel_snack_bar.dart`, `pixel_empty_state.dart`, `pixel_loading.dart`, `pixel_stat_tile.dart`, `pixel_badge.dart`, `pixel_segmented.dart`, `pixel_divider.dart` | Component kit |
| Modify `test/unit/auth_and_supabase_test.dart`, `test/widget/*` | Cập nhật assert icon/màu cũ |

---

### Task 1: Bundle font và bỏ `google_fonts`

**Files:**
- Create: `assets/fonts/VT323-Regular.ttf`, `assets/fonts/BeVietnamPro-Variable.ttf`, `assets/fonts/OFL-VT323.txt`, `assets/fonts/OFL-BeVietnamPro.txt`
- Modify: `pubspec.yaml:20-40` (dependencies + flutter/assets)

**Interfaces:**
- Consumes: không.
- Produces: hai `fontFamily` dùng được trong code: `'VT323'`, `'BeVietnamPro'`.

- [ ] **Step 1: Tải font và giấy phép**

```bash
mkdir -p assets/fonts
curl -sSL -o assets/fonts/VT323-Regular.ttf \
  https://github.com/google/fonts/raw/main/ofl/vt323/VT323-Regular.ttf
curl -sSL -o assets/fonts/BeVietnamPro-Variable.ttf \
  "https://github.com/google/fonts/raw/main/ofl/bevietnampro/Variable%5Bwdth%2Cwght%5D.ttf"
curl -sSL -o assets/fonts/OFL-VT323.txt \
  https://github.com/google/fonts/raw/main/ofl/vt323/OFL.txt
curl -sSL -o assets/fonts/OFL-BeVietnamPro.txt \
  https://github.com/google/fonts/raw/main/ofl/bevietnampro/OFL.txt
ls -la assets/fonts
```
Expected: bốn tệp tồn tại, hai `.ttf` có kích thước > 20 KB. Nếu URL variable font đổi tên, mở `https://github.com/google/fonts/tree/main/ofl/bevietnampro` và lấy đúng tên tệp `Variable[wdth,wght].ttf`.

- [ ] **Step 2: Kiểm font có chứa ký tự tiếng Việt**

Run:
```bash
python - <<'PY'
from fontTools.ttLib import TTFont
for p in ["assets/fonts/VT323-Regular.ttf","assets/fonts/BeVietnamPro-Variable.ttf"]:
    f=TTFont(p); cmap=f.getBestCmap()
    need="àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ"
    print(p.split('/')[-1], "thiếu:", "".join(c for c in need if ord(c) not in cmap) or "không")
PY
```
Expected: cả hai in `thiếu: không`. Nếu máy chưa có `fontTools`, cài trong môi trường ảo (`python -m pip install --user fonttools`) hoặc bỏ qua bước này và ghi rõ "chưa kiểm cmap tự động" vào báo cáo; **không được** đoán là đạt.

- [ ] **Step 3: Khai báo trong `pubspec.yaml`**

Khối `flutter:` hiện tại chỉ có `uses-material-design: true` và `assets:` gồm đúng một
dòng `- .env`, chưa có khóa `fonts:`. Viết lại cả khối thành:

```yaml
  assets:
    - .env
    - assets/fonts/

  fonts:
    - family: VT323
      fonts:
        - asset: assets/fonts/VT323-Regular.ttf
    - family: BeVietnamPro
      fonts:
        - asset: assets/fonts/BeVietnamPro-Variable.ttf
```
YAML không cho phép hai khóa `assets:` nên `- .env` và `- assets/fonts/` phải nằm cùng một khối như trên.

- [ ] **Step 4: Xóa `google_fonts`**

Xóa dòng `  google_fonts: ^6.2.1` (giá trị thật trong `pubspec.yaml`) khỏi `dependencies`, rồi:

```bash
flutter pub get
grep -rn "google_fonts\|GoogleFonts" lib/ test/
```
Expected: `Got dependencies`; grep còn đúng 3 chỗ trong `lib/core/theme/app_theme.dart` (dòng 3, 22, 97) — Task 3 sẽ thay. Nếu còn chỗ khác, ghi lại và xử lý trong Task 3.

- [ ] **Step 5: Không commit `.ttf` vào gitignore sai chỗ**

Run: `git check-ignore -v assets/fonts/VT323-Regular.ttf || echo "not ignored"`
Expected: `not ignored`. Nếu bị ignore, sửa `.gitignore` chứ không dùng `git add -f`.

- [ ] **Step 6: Commit (khi được ủy quyền)**

```bash
git add assets/fonts pubspec.yaml pubspec.lock
git commit -m "build(assets): bundle VT323 and Be Vietnam Pro for offline pixel type"
```

---

### Task 2: `AppPalette` — token sáng/tối

**Files:**
- Create: `lib/core/theme/app_palette.dart`
- Create: `test/unit/app_palette_contrast_test.dart`

**Interfaces:**
- Consumes: không.
- Produces:
  - `class AppPalette extends ThemeExtension<AppPalette>` với các field `Color`: `canvas, surface, surfaceAlt, ink, inkMuted, inkInverse, line, lineStrong, shadow, mint, mintStrong, mintInk, butter, butterInk, peach, peachInk, sky, skyInk, rose, roseInk, onAccent, danger, dangerInk, success, warning, feedBg, feedPanel, feedInk, feedMuted`
  - `static const AppPalette light` / `static const AppPalette dark`
  - `AppPalette get context.palette` (extension trên `BuildContext`)
  - `Color accentForCategory(Object key)` — 5 accent xoay vòng, ổn định
  - `Color priorityColor(int priority)` — 0 mint, 1 sky, 2 butter, 3 rose
  - `String priorityLabel(int priority)` kế thừa `AppStrings.priorityLabels` (out-of-range trả nhãn đầu tiên, khớp `priorityColor`)

- [ ] **Step 1: Viết test tương phản failing**

Tạo `test/unit/app_palette_contrast_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_palette.dart';

// Color.r/.g/.b trả double 0.0-1.0 trên Flutter 3.47 (đã đo), nên nhân 255 trước.
double luminance(Color c) {
  double f(int channel) {
    final s = channel / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }
  return 0.2126 * f((c.r * 255).round()) +
      0.7152 * f((c.g * 255).round()) +
      0.0722 * f((c.b * 255).round());
}

/// WCAG 2.1: (L_sang + 0.05) / (L_toi + 0.05).
double contrast(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('AppPalette contrast', () {
    for (final palette in [AppPalette.light, AppPalette.dark]) {
      final name = palette == AppPalette.light ? 'light' : 'dark';

      test('$name: ink trên canvas >= 4.5', () {
        expect(contrast(palette.ink, palette.canvas), greaterThanOrEqualTo(4.5));
      });
      test('$name: inkMuted trên canvas >= 4.5', () {
        expect(contrast(palette.inkMuted, palette.canvas), greaterThanOrEqualTo(4.5));
      });
      test('$name: inkMuted trên surface >= 4.5', () {
        expect(contrast(palette.inkMuted, palette.surface), greaterThanOrEqualTo(4.5));
      });
      test('$name: onAccent trên mỗi accent >= 4.5', () {
        for (final accent in [
          palette.mint, palette.butter, palette.peach, palette.sky, palette.rose,
        ]) {
          expect(contrast(palette.onAccent, accent), greaterThanOrEqualTo(4.5));
        }
      });
      test('$name: danger trên canvas >= 4.5', () {
        expect(contrast(palette.danger, palette.canvas), greaterThanOrEqualTo(4.5));
      });
      test('$name: feedInk trên feedPanel >= 4.5', () {
        expect(contrast(palette.feedInk, palette.feedPanel), greaterThanOrEqualTo(4.5));
      });
      test('$name: feedMuted trên feedPanel >= 4.5', () {
        expect(contrast(palette.feedMuted, palette.feedPanel), greaterThanOrEqualTo(4.5));
      });
    }

    test('accentForCategory ổn định và nằm trong 5 accent', () {
      final a = AppPalette.light.accentForCategory('Ăn uống');
      final b = AppPalette.light.accentForCategory('Ăn uống');
      expect(a, b);
      final allowed = <Color>{
        AppPalette.light.mint, AppPalette.light.butter, AppPalette.light.peach,
        AppPalette.light.sky, AppPalette.light.rose,
      }.map((c) => c.toARGB32()).toSet();
      expect(allowed.contains(a.toARGB32()), isTrue);
    });

    test('priorityColor ánh xạ 0..3 đúng spec', () {
      expect(AppPalette.light.priorityColor(0), AppPalette.light.mint);
      expect(AppPalette.light.priorityColor(1), AppPalette.light.sky);
      expect(AppPalette.light.priorityColor(2), AppPalette.light.butter);
      expect(AppPalette.light.priorityColor(3), AppPalette.light.rose);
      expect(AppPalette.light.priorityColor(9), AppPalette.light.mint);
    });
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Giá trị đã tính sẵn bằng công thức WCAG 2.1 cho đúng các cặp test này, trên hex của
`AppPalette.light` và `AppPalette.dark` bên dưới: light thấp nhất **5.73** (`inkMuted` trên
`canvas`), dark thấp nhất **7.80** (`onAccent` trên `rose`); các cặp còn lại nằm trong
khoảng 6.05-17.43. Tất cả đều >= 4.5 nên **không đổi hex palette** — nếu test fail thì lỗi
nằm ở helper (`quên math.pow(..., 2.4)` hoặc dùng `la/lb` thay vì `(hi+0.05)/(lo+0.05)`),
không phải ở màu.

Run: `flutter test test/unit/app_palette_contrast_test.dart`
Expected: FAIL — URI `app_palette.dart` không tồn tại.

- [ ] **Step 3: Implement palette**

Tạo `lib/core/theme/app_palette.dart`:

```dart
import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// Token màu của giao diện Pixel. Light là mặc định, dark đảo nền mực.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkMuted,
    required this.inkInverse,
    required this.line,
    required this.lineStrong,
    required this.shadow,
    required this.mint,
    required this.mintStrong,
    required this.mintInk,
    required this.butter,
    required this.butterInk,
    required this.peach,
    required this.peachInk,
    required this.sky,
    required this.skyInk,
    required this.rose,
    required this.roseInk,
    required this.onAccent,
    required this.danger,
    required this.dangerInk,
    required this.success,
    required this.warning,
    required this.feedBg,
    required this.feedPanel,
    required this.feedInk,
    required this.feedMuted,
  });

  static const _accents = <String, Color>{
    'mint': Color(0xFF7BD8A8),
    'butter': Color(0xFFFFD86B),
    'peach': Color(0xFFFFB38A),
    'sky': Color(0xFF8ECAE6),
    'rose': Color(0xFFF28C9A),
  };

  final Color canvas, surface, surfaceAlt, ink, inkMuted, inkInverse;
  final Color line, lineStrong, shadow;
  final Color mint, mintStrong, mintInk;
  final Color butter, butterInk, peach, peachInk, sky, skyInk, rose, roseInk;
  final Color onAccent, danger, dangerInk, success, warning;
  final Color feedBg, feedPanel, feedInk, feedMuted;

  static const AppPalette light = AppPalette(
    canvas: Color(0xFFFFF6E3),
    surface: Color(0xFFFFFDF6),
    surfaceAlt: Color(0xFFFFF1D6),
    ink: Color(0xFF2B2118),
    inkMuted: Color(0xFF6E5F4E),
    inkInverse: Color(0xFFFFF6E3),
    line: Color(0xFF1B140E),
    lineStrong: Color(0xFF1B140E),
    shadow: Color(0xFF1B140E),
    mint: Color(0xFF7BD8A8),
    mintStrong: Color(0xFF2F9E6E),
    mintInk: Color(0xFF1F7A52),
    butter: Color(0xFFFFD86B),
    butterInk: Color(0xFF6E4A00),
    peach: Color(0xFFFFB38A),
    peachInk: Color(0xFF7A3108),
    sky: Color(0xFF8ECAE6),
    skyInk: Color(0xFF0F4A63),
    rose: Color(0xFFF28C9A),
    roseInk: Color(0xFF7A1B2A),
    onAccent: Color(0xFF1B140E),
    danger: Color(0xFFB3261E),
    dangerInk: Color(0xFFB3261E),
    success: Color(0xFF1F7A52),
    warning: Color(0xFF6E4A00),
    feedBg: Color(0xFF14100B),
    feedPanel: Color(0xFF1E1710),
    feedInk: Color(0xFFFFF6E3),
    feedMuted: Color(0xFFC9B79E),
  );

  static const AppPalette dark = AppPalette(
    canvas: Color(0xFF1A130D),
    surface: Color(0xFF241A12),
    surfaceAlt: Color(0xFF302318),
    ink: Color(0xFFFFF6E3),
    inkMuted: Color(0xFFC9B79E),
    inkInverse: Color(0xFF2B2118),
    line: Color(0xFF6B553F),
    lineStrong: Color(0xFFFFF6E3),
    shadow: Color(0xFF000000),
    mint: Color(0xFF7BD8A8),
    mintStrong: Color(0xFF3FBF86),
    mintInk: Color(0xFF9BE9C2),
    butter: Color(0xFFFFD86B),
    butterInk: Color(0xFFFFE7A6),
    peach: Color(0xFFFFB38A),
    peachInk: Color(0xFFFFCDB0),
    sky: Color(0xFF8ECAE6),
    skyInk: Color(0xFFBEE4F5),
    rose: Color(0xFFF28C9A),
    roseInk: Color(0xFFF7B7C0),
    onAccent: Color(0xFF1B140E),
    danger: Color(0xFFFF8A7A),
    dangerInk: Color(0xFFFF8A7A),
    success: Color(0xFF9BE9C2),
    warning: Color(0xFFFFE7A6),
    feedBg: Color(0xFF0D0A07),
    feedPanel: Color(0xFF17110B),
    feedInk: Color(0xFFFFF6E3),
    feedMuted: Color(0xFFC9B79E),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? inkMuted,
    Color? inkInverse,
    Color? line,
    Color? lineStrong,
    Color? shadow,
    Color? mint,
    Color? mintStrong,
    Color? mintInk,
    Color? butter,
    Color? butterInk,
    Color? peach,
    Color? peachInk,
    Color? sky,
    Color? skyInk,
    Color? rose,
    Color? roseInk,
    Color? onAccent,
    Color? danger,
    Color? dangerInk,
    Color? success,
    Color? warning,
    Color? feedBg,
    Color? feedPanel,
    Color? feedInk,
    Color? feedMuted,
  }) =>
      AppPalette(
        canvas: canvas ?? this.canvas,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        ink: ink ?? this.ink,
        inkMuted: inkMuted ?? this.inkMuted,
        inkInverse: inkInverse ?? this.inkInverse,
        line: line ?? this.line,
        lineStrong: lineStrong ?? this.lineStrong,
        shadow: shadow ?? this.shadow,
        mint: mint ?? this.mint,
        mintStrong: mintStrong ?? this.mintStrong,
        mintInk: mintInk ?? this.mintInk,
        butter: butter ?? this.butter,
        butterInk: butterInk ?? this.butterInk,
        peach: peach ?? this.peach,
        peachInk: peachInk ?? this.peachInk,
        sky: sky ?? this.sky,
        skyInk: skyInk ?? this.skyInk,
        rose: rose ?? this.rose,
        roseInk: roseInk ?? this.roseInk,
        onAccent: onAccent ?? this.onAccent,
        danger: danger ?? this.danger,
        dangerInk: dangerInk ?? this.dangerInk,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        feedBg: feedBg ?? this.feedBg,
        feedPanel: feedPanel ?? this.feedPanel,
        feedInk: feedInk ?? this.feedInk,
        feedMuted: feedMuted ?? this.feedMuted,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      inkInverse: mix(inkInverse, other.inkInverse),
      line: mix(line, other.line),
      lineStrong: mix(lineStrong, other.lineStrong),
      shadow: mix(shadow, other.shadow),
      mint: mix(mint, other.mint),
      mintStrong: mix(mintStrong, other.mintStrong),
      mintInk: mix(mintInk, other.mintInk),
      butter: mix(butter, other.butter),
      butterInk: mix(butterInk, other.butterInk),
      peach: mix(peach, other.peach),
      peachInk: mix(peachInk, other.peachInk),
      sky: mix(sky, other.sky),
      skyInk: mix(skyInk, other.skyInk),
      rose: mix(rose, other.rose),
      roseInk: mix(roseInk, other.roseInk),
      onAccent: mix(onAccent, other.onAccent),
      danger: mix(danger, other.danger),
      dangerInk: mix(dangerInk, other.dangerInk),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      feedBg: mix(feedBg, other.feedBg),
      feedPanel: mix(feedPanel, other.feedPanel),
      feedInk: mix(feedInk, other.feedInk),
      feedMuted: mix(feedMuted, other.feedMuted),
    );
  }

  /// Màu nhãn danh mục ổn định: cùng key luôn ra cùng accent.
  Color accentForCategory(Object key) {
    final order = ['mint', 'sky', 'butter', 'peach', 'rose'];
    final index = key.hashCode.abs() % order.length;
    return _accents[order[index]]!;
  }

  Color priorityColor(int priority) => switch (priority) {
    0 => mint,
    1 => sky,
    2 => butter,
    3 => rose,
    _ => mint,
  };

  Color priorityInk(int priority) => switch (priority) {
    0 => mintInk,
    1 => skyInk,
    2 => butterInk,
    3 => roseInk,
    _ => mintInk,
  };

  String priorityLabel(int priority) {
    // `elementAtOrNull` nằm trong dart:collection, không import ở đây
    // nên guard bằng index thường.
    if (priority < 0 || priority >= AppStrings.priorityLabels.length) {
      return AppStrings.priorityLabels.first;
    }
    return AppStrings.priorityLabels[priority];
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
```

- [ ] **Step 4: Chạy test**

Run: `flutter test test/unit/app_palette_contrast_test.dart`
Expected: PASS. Nếu cặp nào dưới 4.5:1, **chỉnh hex trong palette cho đạt** thay vì nới ngưỡng test; ghi lại hex đã đổi.

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/core/theme/app_palette.dart test/unit/app_palette_contrast_test.dart
git commit -m "feat(theme): add pixel AppPalette tokens with contrast tests"
```

---

### Task 3: TextTheme font bundle và `ThemeData` Pixel

**Files:**
- Create: `lib/core/theme/pixel_text_theme.dart`
- Modify: `lib/core/theme/app_theme.dart:1-120`
- Modify: `lib/app.dart:34-35` (`theme: AppTheme.lightTheme` → `AppTheme.light`, `darkTheme: AppTheme.darkTheme` → `AppTheme.dark`) vì plan này đổi tên getter sang `AppTheme.light`/`AppTheme.dark`; sau đó chạy `grep -rn "lightTheme\|darkTheme" lib/ test/` phải trả về rỗng.
- Modify: `lib/core/constants/app_colors.dart` (đổi giá trị sang hex pixel + `@Deprecated`)
- Create: `lib/core/constants/app_info.dart`

**Interfaces:**
- Consumes: `AppPalette` (Task 2), font families `'VT323'`, `'BeVietnamPro'` (Task 1).
- Produces:
  - `TextTheme pixelTextTheme(AppPalette palette)` trong `lib/core/theme/pixel_text_theme.dart`
  - `ThemeData AppTheme.light` / `AppTheme.dark` có `extensions: [palette]`
  - `const TextStyle displayPixel` (`VT323` 40), `headlinePixel` (28), `labelPixel` (17 uppercase), tức là các style: `displayLarge/Medium` = VT323, `titleLarge/titleMedium` = VT323, `bodyLarge/bodyMedium/labelLarge` = BeVietnamPro.
  - `AppInfo.name/version/build/tagline`

- [ ] **Step 1: Viết test failing cho font và extension**

Tạo `test/unit/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_palette.dart';
import 'package:chi_tieu/core/theme/app_theme.dart';

void main() {
  testWidgets('light theme cung cấp AppPalette và font bundle', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(captured.palette, isA<AppPalette>());
    final textTheme = Theme.of(captured).textTheme;
    expect(textTheme.displayLarge!.fontFamily, 'VT323');
    expect(textTheme.titleLarge!.fontFamily, 'VT323');
    expect(textTheme.bodyLarge!.fontFamily, 'BeVietnamPro');
    expect(
      textTheme.bodyLarge!.fontVariations,
      contains(const FontVariation('wght', 400)),
    );
    expect(
      textTheme.titleLarge!.fontVariations,
      isNull,
    ); // VT323 chỉ có một weight, không cần variation
  });

  test('dark theme dùng palette dark', () {
    final theme = AppTheme.dark;
    final palette = theme.extension<AppPalette>()!;
    expect(palette.canvas, AppPalette.dark.canvas);
    expect(theme.scaffoldBackgroundColor, AppPalette.dark.canvas);
  });

  test('không còn tham chiếu google_fonts', () {
    final source = File('lib/core/theme/app_theme.dart').readAsStringSync();
    expect(source.contains('GoogleFonts'), isFalse);
  });
}
```
Thêm `import 'dart:io';` ở đầu file test.

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/unit/app_theme_test.dart`
Expected: FAIL — `extension<AppPalette>()` trả null / fontFamily vẫn là kết quả google_fonts.

- [ ] **Step 3: Tạo `pixel_text_theme.dart`**

```dart
import 'package:flutter/material.dart';

import 'app_palette.dart';

const String pixelFontFamily = 'VT323';
const String bodyFontFamily = 'BeVietnamPro';

TextStyle _body(AppPalette palette, {
  required double size,
  required double weight,
  double height = 1.5,
  Color? color,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: size,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', weight)],
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? palette.ink,
  );
}

TextStyle _pixel(AppPalette palette, {
  required double size,
  Color? color,
  double letterSpacing = 0.6,
}) {
  return TextStyle(
    fontFamily: pixelFontFamily,
    fontSize: size,
    height: 1.05,
    letterSpacing: letterSpacing,
    color: color ?? palette.ink,
  );
}

TextTheme pixelTextTheme(AppPalette palette) {
  final label = _pixel(palette, size: 17, letterSpacing: 0.9);
  return TextTheme(
    displayLarge: _pixel(palette, size: 48),
    displayMedium: _pixel(palette, size: 40),
    displaySmall: _pixel(palette, size: 34),
    headlineMedium: _pixel(palette, size: 30),
    headlineSmall: _pixel(palette, size: 26),
    titleLarge: _pixel(palette, size: 28),
    titleMedium: _pixel(palette, size: 22),
    titleSmall: label,
    labelLarge: _body(palette, size: 15, weight: 600, height: 1.2),
    labelMedium: _body(palette, size: 13, weight: 500, height: 1.2),
    labelSmall: _body(palette, size: 12, weight: 500, height: 1.2),
    bodyLarge: _body(palette, size: 16, weight: 400),
    bodyMedium: _body(palette, size: 14, weight: 400),
    bodySmall: _body(palette, size: 13, weight: 400, color: palette.inkMuted),
  ).apply(bodyColor: palette.ink, displayColor: palette.ink);
}
```
Trong test ở Step 1, `titleLarge` **không** có `fontVariations` vì là VT323; giữ assertion đó để phát hiện nếu ai đó đổi style.

- [ ] **Step 4: Viết lại `app_theme.dart`**

```dart
import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import 'app_palette.dart';
import 'pixel_text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette palette) {
    final textTheme = pixelTextTheme(palette);
    final scheme = ColorScheme(
      brightness: palette == AppPalette.dark ? Brightness.dark : Brightness.light,
      primary: palette.mintStrong,
      onPrimary: palette.onAccent,
      secondary: palette.butter,
      onSecondary: palette.onAccent,
      error: palette.danger,
      onError: palette.surface,
      surface: palette.surface,
      onSurface: palette.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      extensions: <ThemeExtension<dynamic>>[palette],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(letterSpacing: 0.9),
        iconTheme: IconThemeData(color: palette.ink, size: 24),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: palette.lineStrong, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.line,
        thickness: 2,
        space: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: palette.lineStrong, width: 3),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: palette.line, width: 1),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.canvas),
        actionTextColor: palette.butter,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(color: palette.mintStrong, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceAlt,
        labelStyle: textTheme.labelLarge,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
        errorStyle: textTheme.bodySmall?.copyWith(color: palette.danger),
        enabledBorder: _pixelBorder(palette.line),
        focusedBorder: _pixelBorder(palette.mintStrong, width: 3),
        errorBorder: _pixelBorder(palette.danger),
        focusedErrorBorder: _pixelBorder(palette.danger, width: 3),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.mintInk,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: Colors.transparent, width: 2),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.mint,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.surfaceAlt,
          disabledForegroundColor: palette.inkMuted,
          elevation: 0,
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: palette.lineStrong, width: 2),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.mint,
          foregroundColor: palette.onAccent,
          elevation: 0,
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: palette.lineStrong, width: 2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: palette.lineStrong, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.mintStrong
              : palette.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.mint
              : palette.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.all(palette.lineStrong),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.ink,
        textColor: palette.ink,
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.mintStrong,
        linearTrackColor: palette.surfaceAlt,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.ink,
          borderRadius: BorderRadius.circular(2),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: palette.canvas),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: palette.mint,
        headerForegroundColor: palette.onAccent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: palette.surface,
        dialBackgroundColor: palette.surfaceAlt,
        helpTextStyle: textTheme.labelMedium,
      ),
    );
  }

  static OutlineInputBorder _pixelBorder(Color color, {double width = 2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
```

- [ ] **Step 5: Đổi giá trị `AppColors` sang hex pixel và đánh dấu legacy**

`lib/core/constants/app_colors.dart` — **giữ nguyên tên và cấu trúc**, chỉ đổi giá trị. Đo
file hiện tại: 37 `static const Color` + 8 `static const LinearGradient` + `getPriorityColor`,
không có constructor private. `grep -rn "AppColors" lib/ | wc -l` = **145** dòng trên **15** file,
tương ứng **29** hằng được tham chiếu thật.

16 hằng không có chỗ dùng trong `lib/` **và** `test/` (`secondary`, `primaryDark`, `accentPurple`,
`accentCyan`, `accentAmber`, `accentRose`, `budgetSafe`, `budgetWarning80`, `budgetWarning100`,
`categoryDefault`, `glassSurfaceLight`, `glassBorderLight`, `priorityEssential`, `priorityHigh`,
`priorityMedium`, `priorityLow`) → **xóa**, để lại hex fintech cũ cho code chết là nguồn lỗi về sau.

Thêm doc comment + annotation trên class (chỉ class, không từng field, để warning không lan):

```dart
/// LEGACY: chỉ cho các màn hình chưa chuyển sang `context.palette`.
/// Plan 4 Task 14 xóa toàn bộ file. Không thêm tham chiếu mới.
@Deprecated('Dùng context.palette (AppPalette) thay vì AppColors')
class AppColors {
```

Bảng giá trị mới, lấy nguyên hex từ `AppPalette.light`/`dark` đã định nghĩa ở Task 1:

| Hằng | Giá trị mới | Nguồn hex |
|---|---|---|
| `primary` | `Color(0xFF2F9E6E)` | `light.mintStrong` |
| `primaryLight` | `Color(0xFF7BD8A8)` | `light.mint` |
| `backgroundLight` | `Color(0xFFFFF6E3)` | `light.canvas` |
| `surfaceLight` | `Color(0xFFFFFDF6)` | `light.surface` |
| `surfaceLightDark` | `Color(0xFFFFF1D6)` | `light.surfaceAlt` |
| `borderLight` | `Color(0xFF1B140E)` | `light.line` (viền pixel luôn đậm) |
| `textPrimaryLight` | `Color(0xFF2B2118)` | `light.ink` |
| `textSecondaryLight` | `Color(0xFF6E5F4E)` | `light.inkMuted` |
| `backgroundDark` | `Color(0xFF1A130D)` | `dark.canvas` |
| `surfaceDark` | `Color(0xFF241A12)` | `dark.surface` |
| `surfaceDarkLight` | `Color(0xFF302318)` | `dark.surfaceAlt` |
| `borderDark` | `Color(0xFF6B553F)` | `dark.line` |
| `textPrimaryDark` | `Color(0xFFFFF6E3)` | `dark.ink` |
| `textSecondaryDark` | `Color(0xFFC9B79E)` | `dark.inkMuted` |
| `feedBackground` | `Color(0xFF14100B)` | `light.feedBg` |
| `glassSurfaceDark` | `Color(0xCC241A12)` | `dark.surface` + alpha 0xCC |
| `glassBorderDark` | `Color(0x33FFF6E3)` | `dark.ink` + alpha 0x33 |
| `priority0` | `Color(0xFF1F7A52)` | `light.mintInk` |
| `priority1` | `Color(0xFF0F4A63)` | `light.skyInk` |
| `priority2` | `Color(0xFF6E4A00)` | `light.butterInk` |
| `priority3` | `Color(0xFFB3261E)` | `light.danger` |

`priority0..3` dùng làm **màu chữ/nét/chart series** trên nền kem (`home_screen`,
`statistics_screen:357-372`, `login_screen:298`, `app_theme:53,128`) nên ánh xạ sang biến thể
*ink* đậm; `AppPalette.priorityColor(int)` vẫn trả accent nhạt theo spec — hai bảng phục vụ hai
vai trò khác nhau và không cần bằng nhau.

8 `LinearGradient` đều còn được dùng; đổi stop color theo bảng sau, giữ nguyên
`begin`/`end`:

| Hằng | Stops mới |
|---|---|
| `cardGradientDark` | `[Color(0xFF241A12), Color(0xFF1A130D)]` |
| `primaryGradient` | `[Color(0xFF7BD8A8), Color(0xFF2F9E6E)]` |
| `captureButtonGradient` | `[Color(0xFF7BD8A8), Color(0xFF2F9E6E)]` |
| `balanceCardGradient` | `[Color(0xFF241A12), Color(0xFF1A130D), Color(0xFF1F7A52)]` |
| `pageGradientDark` | `[Color(0xFF1A130D), Color(0xFF241A12), Color(0xFF14100B)]` |
| `pageGradientLight` | `[Color(0xFFFFFDF6), Color(0xFFFFF6E3), Color(0xFFFFF1D6)]` |
| `feedTopGradient` | giữ `[Color(0xB3000000), Color(0x00000000)]` (scrim alpha, không phải màu thương hiệu) |
| `feedBottomGradient` | giữ `[Color(0x00000000), Color(0x99000000), Color(0xF2000000)]` |

`getPriorityColor(int)` giữ nguyên thân (nó tham chiếu `priority0..3` đã đổi ở bảng trên).

- [ ] **Step 6: Tạo `app_info.dart`**

```dart
class AppInfo {
  AppInfo._();
  static const String name = 'Chi Tiêu';
  static const String version = '2.2.0';
  static const String build = '3';
  static const String tagline = 'PIXEL JOURNAL';
  static const String aboutLabel = 'Phiên bản $version • $tagline';
}
```
Rà soát: `grep -rn "Phiên bản 2.1\|LOCKET JOURNAL\|PHIÊN BẢN 2.1" lib/` và thay bằng `AppInfo.aboutLabel` (xuất hiện ở `app_drawer.dart` và `settings_screen.dart`).

- [ ] **Step 7: Chạy test và sửa các test cũ**

Run: `flutter test`
Expected: FAIL ở `test/unit/auth_and_supabase_test.dart` (group `Fintech Colors Tests` assert `AppColors.primary == 0xFF10B981`, `AppColors.cardGradientDark.colors.length == 2`). Sửa thành giá trị mới:

```dart
  group('Legacy Colors', () {
    test('AppColors trỏ tới hex pixel', () {
      expect(AppColors.primary, const Color(0xFF2F9E6E));
      expect(AppColors.backgroundDark, const Color(0xFF1A130D));
    });
  });
```
`cardGradientDark` vẫn còn ở `lib/core/constants/app_colors.dart:61-65` (2 stop
`0xFF1E293B`, `0xFF0F172A`) và Step 5 đổi sang `0xFF241A12`, `0xFF1A130D`, nên giữ
`expect(AppColors.cardGradientDark.colors.length, 2)` và thêm
`expect(AppColors.cardGradientDark.colors.first, const Color(0xFF241A12));`.

Run lại: `flutter test`
Expected: PASS toàn bộ + `test/unit/app_theme_test.dart` pass.

- [ ] **Step 8: Kiểm tra**

Run: `flutter analyze`
Expected: No issues found (warning `@Deprecated` dùng nội bộ là chấp nhận được; nếu analyzer phàn nàn `deprecated_member_use_from_same_package`, thêm `// ignore: deprecated_member_use_from_same_package` tại chỗ dùng cũ **và** ghi chú `// TODO(Plan 4): xóa AppColors`).

- [ ] **Step 9: Commit (khi được ủy quyền)**

```bash
git add lib/core/theme/ lib/core/constants/ test/unit/app_theme_test.dart test/unit/auth_and_supabase_test.dart
git commit -m "feat(theme): build pixel ThemeData from AppPalette with bundled fonts"
```

---

### Task 4: Dữ liệu glyph pixel + painter

**Files:**
- Create: `lib/core/icons/pixel_glyph_data.dart`
- Create: `lib/core/icons/pixel_glyphs.dart`
- Create: `lib/widgets/pixel/pixel_glyph.dart`
- Create: `test/unit/pixel_glyphs_test.dart`

**Interfaces:**
- Consumes: `AppPalette` (Task 2).
- Produces:
  - `const int pixelGlyphGrid = 16;`
  - `class PixelGlyphData` với `static const Map<String, List<String>> all`, `static List<String>? rowsOf(String name)`, `static List<String> get names`, `static const String fallbackKey = 'label'`
  - `String pixelGlyphValidationError(String name, List<String> rows)` — pure, trả `''` nếu hợp lệ
  - `class PixelGlyph extends StatelessWidget { const PixelGlyph({required String name, double size = 32, Color? color, Color? secondary, Key? key}); }`

Quy ước glyph (đưa vào doc-comment của file dữ liệu):
- 16 hàng, mỗi hàng đúng 16 ký tự, chỉ dùng `.` (trống), `#` (màu chính), `+` (màu phụ).
- Chừa viền 1 px quanh hình (hàng 0, hàng 15, cột 0, cột 15 thường là `.`) để không dính khung badge.
- Đường nét chính dày 2 ô để đọc được ở 16 px.
- `+` dùng cho bóng/chi tiết đậm (đỉnh, mắt, nút), không dùng cho khối lớn.

- [ ] **Step 1: Viết test failing**

Tạo `test/unit/pixel_glyphs_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/icons/pixel_glyph_data.dart';
import 'package:chi_tieu/core/utils/icon_helper.dart';

void main() {
  test('pixelGlyphValidationError bắt đúng lỗi', () {
    expect(pixelGlyphValidationError('a', PixelGlyphData.all['label']!), isEmpty);
    expect(
      pixelGlyphValidationError('bad', List.filled(15, '.' * 16)),
      contains('16 hàng'),
    );
    expect(
      pixelGlyphValidationError('bad', List.filled(16, '.' * 15)),
      contains('16 ký tự'),
    );
    expect(
      pixelGlyphValidationError('bad', [
        for (var i = 0; i < 15; i++) '.' * 16,
        'x' * 16,
      ]),
      contains('ký tự không hợp lệ'),
    );
  });

  test('mọi glyph hợp lệ 16x16', () {
    for (final entry in PixelGlyphData.all.entries) {
      expect(
        pixelGlyphValidationError(entry.key, entry.value),
        isEmpty,
        reason: 'glyph ${entry.key} không hợp lệ',
      );
    }
  });

  test('có glyph cho toàn bộ khóa danh mục', () {
    for (final key in IconHelper.availableIcons) {
      expect(PixelGlyphData.rowsOf(key), isNotNull, reason: 'thiếu glyph $key');
    }
  });

  test('có glyph fallback', () {
    expect(PixelGlyphData.rowsOf(PixelGlyphData.fallbackKey), isNotNull);
    expect(PixelGlyphData.rowsOf('khong_ton_tai'), isNull);
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/unit/pixel_glyphs_test.dart`
Expected: FAIL — URI `pixel_glyph_data.dart` không tồn tại.

- [ ] **Step 3: Tạo validator + container glyph**

Tạo `lib/core/icons/pixel_glyph_data.dart`:

```dart
/// Định nghĩa glyph pixel 16x16 dạng lưới ký tự: `.` trống, `#` màu chính,
/// `+` màu phụ. Vẽ bằng CustomPainter, không dùng icon hệ thống.
library;

const int pixelGlyphGrid = 16;
const Set<String> _allowedChars = {'.', '#', '+'};

/// Trả về chuỗi mô tả lỗi, rỗng nếu glyph hợp lệ.
String pixelGlyphValidationError(String name, List<String> rows) {
  if (rows.length != pixelGlyphGrid) return '$name: phải có 16 hàng';
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].length != pixelGlyphGrid) {
      return '$name: hàng $i phải có 16 ký tự';
    }
    for (final char in rows[i].split('')) {
      if (!_allowedChars.contains(char)) {
        return '$name: hàng $i có ký tự không hợp lệ';
      }
    }
  }
  return '';
}

class PixelGlyphData {
  PixelGlyphData._();

  static const String fallbackKey = 'label';

  static List<String>? rowsOf(String name) => all[name];

  static List<String> get names => all.keys.toList(growable: false);

  static const Map<String, List<String>> all = {
    'label': [
      '................',
      '.##############.',
      '.#++++++++++++#.',
      '.#+##########+#.',
      '.#++########++#.',
      '.#+++######+++#.',
      '.#+++++##+++++#.',
      '.#++++++++++++#.',
      '.##############.',
      '.#++++++++++++#.',
      '.#+##########+#.',
      '.#++########++#.',
      '.#+++######+++#.',
      '.#+++++##+++++#.',
      '.#++++++++++++#.',
      '................',
    ],
  };
}
```

- [ ] **Step 4: Chạy test, xác nhận 2/4 pass**

Run: `flutter test test/unit/pixel_glyphs_test.dart`
Expected: FAIL — test `có glyph cho toàn bộ khóa danh mục` đỏ vì mới có `label`. Đó là tín hiệu đúng: các task sau bổ sung glyph theo nhóm.

- [ ] **Step 5: Tạo painter**

Tạo `lib/widgets/pixel/pixel_glyph.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/icons/pixel_glyph_data.dart';
import '../../core/theme/app_palette.dart';

/// Vẽ một glyph pixel 16x16. Size nên là bội số 16 để sắc nét.
class PixelGlyph extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final Color? secondary;

  const PixelGlyph({
    super.key,
    required this.name,
    this.size = 32,
    this.color,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rows = PixelGlyphData.rowsOf(name) ??
        PixelGlyphData.rowsOf(PixelGlyphData.fallbackKey)!;
    final main = color ?? palette.ink;
    final sub = secondary ?? main.withValues(alpha: 0.55);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GlyphPainter(rows, main, sub)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final List<String> rows;
  final Color main;
  final Color secondary;

  _GlyphPainter(this.rows, this.main, this.secondary);

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty || size.width <= 0 || size.height <= 0) return;
    final cell = size.width / pixelGlyphGrid;
    final cellHeight = size.height / pixelGlyphGrid;
    final paint = Paint()..isAntiAlias = false;

    for (var y = 0; y < pixelGlyphGrid; y++) {
      final row = y < rows.length ? rows[y] : '.' * pixelGlyphGrid;
      for (var x = 0; x < pixelGlyphGrid; x++) {
        final char = x < row.length ? row[x] : '.';
        if (char == '.') continue;
        paint.color = char == '#' ? main : secondary;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cellHeight, cell + 0.2, cellHeight + 0.2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.main != main || old.secondary != secondary || old.rows != rows;
}
```
`+ 0.2` là dung sai chống kẻ hở giữa hai ô liền kề; không đổi thành anti-alias.

- [ ] **Step 6: Widget test painter**

Thêm vào `test/unit/pixel_glyphs_test.dart` (cần `import 'package:flutter/material.dart';` và `import 'package:chi_tieu/widgets/pixel/pixel_glyph.dart';`):

```dart
  testWidgets('PixelGlyph render không ném lỗi với glyph lạ', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: const Scaffold(body: PixelGlyph(name: 'khong_ton_tai', size: 32)),
      ),
    );
    expect(find.byType(PixelGlyph), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
```
Thêm import `package:chi_tieu/core/theme/app_palette.dart`.

- [ ] **Step 7: Chạy test**

Run: `flutter test test/unit/pixel_glyphs_test.dart`
Expected: chỉ còn đỏ đúng một test `có glyph cho toàn bộ khóa danh mục`.

- [ ] **Step 8: Commit (khi được ủy quyền)**

```bash
git add lib/core/icons/ lib/widgets/pixel/pixel_glyph.dart test/unit/pixel_glyphs_test.dart
git commit -m "feat(icons): add 16x16 pixel glyph data model and painter"
```

---

### Task 5: Glyph nhóm điều hướng + `AppIcon`

**Files:**
- Modify: `lib/core/icons/pixel_glyph_data.dart` (thêm `all` entries)
- Create: `lib/widgets/pixel/app_icon.dart`
- Modify: `test/unit/pixel_glyphs_test.dart` (thêm nhóm expect mới)

**Interfaces:**
- Consumes: `PixelGlyph` (Task 4), `AppPalette` (Task 2).
- Produces:
  - Glyph keys Task 5: `menu, close, back, chevronRight, chevronDown, plus, minus, check, edit, trash, search, filter, calendar, clock, refresh, undo, eye, eyeOff, mail, lock, logout, user, sun, moon, alert, info, settings, cloud, cloudOff, grid, share, download, sparkle`
  - `class AppIcon extends StatelessWidget { const AppIcon({required String name, double size = 32, Color? color, Color? secondary, String? semanticLabel, bool functional = false}); }`
  - `class PixelIconButton extends StatelessWidget { const PixelIconButton({Key? key, required String icon, required VoidCallback? onPressed, String? tooltip, Color? background, Color? iconColor, double iconSize = 32}); }` — vùng chạm bắt buộc 48×48, glyph `iconSize` là bội số 16.

- [ ] **Step 1: Viết test danh sách glyph nhóm này**

Thêm vào `test/unit/pixel_glyphs_test.dart`:

```dart
  const navGlyphs = [
    'menu', 'close', 'back', 'chevronRight', 'chevronDown', 'plus', 'minus',
    'check', 'edit', 'trash', 'search', 'filter', 'calendar', 'clock',
    'refresh', 'undo', 'eye', 'eyeOff', 'mail', 'lock', 'logout', 'user',
    'sun', 'moon', 'alert', 'info', 'settings', 'cloud', 'cloudOff', 'grid',
    'share', 'download', 'sparkle',
  ];

  test('có glyph cho nhóm điều hướng và UI', () {
    for (final key in navGlyphs) {
      expect(PixelGlyphData.rowsOf(key), isNotNull, reason: 'thiếu glyph $key');
      expect(
        pixelGlyphValidationError(key, PixelGlyphData.rowsOf(key)!),
        isEmpty,
      );
    }
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/unit/pixel_glyphs_test.dart -n "nhóm điều hướng"`
Expected: FAIL `thiếu glyph menu`.

- [ ] **Step 3: Vẽ glyph theo đặc tả**

Thêm vào `PixelGlyphData.all`. Mẫu đã vẽ sẵn (copy nguyên khối, chỉ thêm các key còn lại theo bảng đặc tả bên dưới):

```dart
    'menu': [
      '................',
      '................',
      '..############..',
      '..############..',
      '................',
      '..############..',
      '..############..',
      '................',
      '..############..',
      '..############..',
      '................',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
    'close': [
      '................',
      '.##..........##.',
      '.###........###.',
      '..###......###..',
      '...###....###...',
      '....###..###....',
      '.....######.....',
      '......####......',
      '.....######.....',
      '....###..###....',
      '...###....###...',
      '..###......###..',
      '.###........###.',
      '.##..........##.',
      '................',
      '................',
    ],
    'back': [
      '................',
      '................',
      '.......####.....',
      '......####......',
      '.....####.......',
      '....####........',
      '...####.........',
      '..####..........',
      '...####.........',
      '....####........',
      '.....####.......',
      '......####......',
      '.......####.....',
      '................',
      '................',
      '................',
    ],
    'check': [
      '................',
      '................',
      '.............##.',
      '............###.',
      '...........###..',
      '..........###...',
      '..##.....###....',
      '..###...###.....',
      '...###.###......',
      '....####........',
      '....####........',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
    'plus': [
      '................',
      '................',
      '......####......',
      '......####......',
      '......####......',
      '......####......',
      '################',
      '################',
      '################',
      '################',
      '......####......',
      '......####......',
      '......####......',
      '......####......',
      '................',
      '................',
    ],
```
Bảng đặc tả cho các key còn lại (mỗi glyph 16×16, nét 2 ô, chừa viền 1 ô):

| Key | Bố cục phải vẽ |
| --- | --- |
| `chevronRight` | Mũi tên `>` dày 2 ô, đỉnh cột 10, hai cánh từ hàng 4 và 11 gặp nhau ở hàng 7–8 |
| `chevronDown` | Mũi tên `v` xoay của `chevronRight`, đỉnh hàng 11 |
| `minus` | Thanh ngang `################` ở hàng 7–8 |
| `edit` | Bút chì chéo từ góc trên phải xuống góc dưới trái, thân 2 ô, đầu `+` là ngòi bút |
| `trash` | Nắp ngang hàng 3 rộng cột 3–12, thân hình thang cột 4–11 hàng 5–13, 3 vạch `+` dọc trong thân |
| `search` | Kính tròn 8×8 ở góc trên trái (cột 2–9, hàng 2–9), cán `+` chéo từ cột 10 hàng 10 xuống cột 13 hàng 13 |
| `filter` | Phễu: hàng 2 rộng cột 2–13 thu dần tới cột 7–8 hàng 8, cuống 2 ô rộng tới hàng 13 |
| `calendar` | Viền cột 2–13 hàng 4–13, gáy `#` hàng 4–5, hai chốt `+` ở cột 4 và 11 hàng 2–3, lưới 3×3 dấu `+` bên trong |
| `clock` | Vòng tròn 12 ô, hai kim `#` từ tâm lên 12 và sang 3 |
| `refresh` | Cung tròn hở góc phải dưới, mũi tên `#` ở đầu cung chỉ theo chiều kim đồng hồ |
| `undo` | Mũi tên cong sang trái, đầu mũi tên ở cột 2 hàng 7, đuôi quặt lên hàng 3 |
| `eye` | Hạnh nhãn ngang cột 2–13, đồng tử `#` 3×3 ở giữa, khóe `+` hai bên |
| `eyeOff` | `eye` cộng đường chéo `#` dày 2 ô từ cột 2 hàng 13 lên cột 13 hàng 2 |
| `mail` | Phong bì chữ nhật cột 2–13 hàng 4–12, nắp `+` chéo gặp nhau ở giữa hàng 8 |
| `lock` | Cust tròn hàng 2–6 cột 5–10, thân `#` cột 3–12 hàng 6–14, lỗ khóa `+` 2 ô ở giữa thân |
| `logout` | Khung cửa hở phải cột 2–9 hàng 3–13, mũi tên `#` từ cột 8 sang cột 14 ở hàng 8 |
| `user` | Đầu tròn 6×6 hàng 2–7 giữa, vai `#` hình thang hàng 9–14 |
| `sun` | Đĩa tròn 6×6 giữa, 8 tia `#` dài 2 ô theo 8 hướng |
| `moon` | Khuyết trăng lưỡi liềm hở phía phải, dày 3–4 ô |
| `alert` | Tam giác cảnh báo đỉnh hàng 2 cột 7–8, đáy hàng 13 cột 1–14, dấu `+` chấm than giữa |
| `info` | Vòng tròn như `clock` nhưng bên trong là `+` chấm (hàng 5) gạch `#` dọc (hàng 7–12) |
| `settings` | Bánh răng 8 răng bao vòng tròn trống tâm 4×4 |
| `cloud` | Đám mây 3 u: u to giữa, hai u nhỏ hai bên, đáy phẳng hàng 12 |
| `cloudOff` | `cloud` cộng chéo `#` góc 45° như `eyeOff` |
| `grid` | 4 ô vuông 5×5 cách nhau 1 ô trong vùng cột 2–13 hàng 2–13 |
| `share` | Ô vuông hở đỉnh trên (cột 6–9), hai ô dưới trái/phải, nối bằng hai nét chéo |
| `download` | Mũi tên xuống `#` giữa hàng 2–10, khay ngang hàng 12–13 rộng cột 3–12 |
| `sparkle` | Sao 4 cánh giữa ô 16, cánh chính dài 5 ô, thêm 2 chấm `+` nhỏ góc trên trái và dưới phải |

Yêu cầu nghiệm thu trực quan: mỗi glyph phải nhận ra được khi xem ở 32 px trên nền `AppPalette.light.surface`. Người làm mở `test/widget/` render (Task 8 có harness) để eyeball.

- [ ] **Step 4: Chạy test**

Run: `flutter test test/unit/pixel_glyphs_test.dart -n "nhóm điều hướng"`
Expected: PASS.

- [ ] **Step 5: Tạo `AppIcon` và `PixelIconButton`**

Tạo `lib/widgets/pixel/app_icon.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'pixel_glyph.dart';

/// Icon pixel có semantics. `functional: true` khi icon truyền tải hành động
/// và bắt buộc có `semanticLabel`.
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final Color? secondary;
  final String? semanticLabel;
  final bool functional;

  const AppIcon({
    super.key,
    required this.name,
    this.size = 32,
    this.color,
    this.secondary,
    this.semanticLabel,
    this.functional = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel;
    final glyph = PixelGlyph(name: name, size: size, color: color, secondary: secondary);
    if (label == null) return ExcludeSemantics(child: glyph);
    return Semantics(label: label, child: glyph);
  }
}

/// Nút icon pixel, vùng chạm tối thiểu 48x48, viền cứng, nền accent tùy chọn.
class PixelIconButton extends StatelessWidget {
  final String icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? background;
  final Color? iconColor;
  final double iconSize;

  const PixelIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.background,
    this.iconColor,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null;

    Widget button = DecoratedBox(
      decoration: BoxDecoration(
        color: enabled
            ? (background ?? palette.surface)
            : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: enabled ? palette.lineStrong : palette.line,
          width: 2,
        ),
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: AppIcon(
            name: icon,
            size: iconSize,
            color: enabled ? (iconColor ?? palette.ink) : palette.inkMuted,
            semanticLabel: tooltip,
          ),
        ),
      ),
    );

    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: button,
      ),
    );
  }
}
```

- [ ] **Step 6: Test semantics**

Thêm vào `test/unit/pixel_glyphs_test.dart`:

```dart
  testWidgets('PixelIconButton có semantics label và vùng chạm 48dp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: Scaffold(
          body: PixelIconButton(icon: 'menu', onPressed: () {}, tooltip: 'Mở menu'),
        ),
      ),
    );
    final size = tester.getSize(find.byType(PixelIconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(find.byType(PixelIconButton)).label,
      contains('Mở menu'),
    );
  });
```
Cần `SemanticsBinding.instance.debugSemanticsEnabled` — trong widget test, bọc bằng `tester.ensureSemantics()` trước và `handle.dispose()` sau; hoặc đơn giản hơn assert qua `find.byType(Semantics)` có `label`.

- [ ] **Step 7: Chạy test và commit**

```bash
flutter test test/unit/pixel_glyphs_test.dart
git add lib/core/icons/pixel_glyph_data.dart lib/widgets/pixel/app_icon.dart test/unit/pixel_glyphs_test.dart
git commit -m "feat(icons): add navigation pixel glyphs and AppIcon widgets"
```

---

### Task 6: Glyph nhóm danh mục + `IconHelper` render pixel

**Files:**
- Modify: `lib/core/icons/pixel_glyph_data.dart`
- Modify: `lib/core/utils/icon_helper.dart:1-93`
- Modify: `test/unit/pixel_glyphs_test.dart`, `test/unit/auth_and_supabase_test.dart:90-110`

**Interfaces:**
- Consumes: `AppIcon` (Task 5).
- Produces:
  - 19 glyph keys danh mục: `forkKnife, coffee, car, shoppingBag, receipt, gameController, heartbeat, graduationCap, house, airplaneTilt, gift, pawPrint, barbell, filmStrip, tShirt, deviceMobile, bank, wallet, dotsThreeOutline`
  - `Widget IconHelper.getIconWidget(String iconKey, {double size = 22, Color? color, Color? secondary})` trả `AppIcon`
  - `IconHelper.normalizeIconKey` giữ nguyên hành vi

- [ ] **Step 1: Cập nhật test**

`test/unit/auth_and_supabase_test.dart` group `IconHelper Tests` đổi assertion `isA<Icon>()` thành `isA<AppIcon>()`:

```dart
    test('Resolves modern icon keys and legacy emojis', () {
      expect(IconHelper.availableIcons.contains('forkKnife'), isTrue);
      expect(IconHelper.getIconWidget('forkKnife'), isA<AppIcon>());
      expect(IconHelper.getIconWidget('🍜'), isA<AppIcon>());
      expect(IconHelper.getIconWidget('chưa_biết'), isA<AppIcon>());
    });
```
Thêm `import 'package:chi_tieu/widgets/pixel/app_icon.dart';`.

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/unit/auth_and_supabase_test.dart`
Expected: FAIL `isA<AppIcon>` vì hiện tại trả `Icon`.

- [ ] **Step 3: Vẽ 19 glyph danh mục**

Bảng đặc tả (same 16×16 rules):

| Key | Bố cục |
| --- | --- |
| `forkKnife` |ĩa 3 răng bên trái (cột 3–5, răng hàng 2–6, cán hàng 6–13), dao bên phải lưỡi `#` cột 10–12 hàng 2–9, cán tới hàng 13 |
| `coffee` | Thân cốc cột 4–11 hàng 5–13, quai `+` cột 11–13 hàng 6–10, 2 hơi nước `+` so le hàng 2–4 |
| `car` | Thân xe `#` cột 2–13 hàng 7–11, mui `+` cột 5–10 hàng 4–6, 2 bánh tròn 3×3 hàng 11–13 tại cột 4 và 10 |
| `shoppingBag` | Quai `+` vòng cung hàng 2–5 cột 5–10, thân vuông cột 3–12 hàng 5–13 |
| `receipt` | Hình chữ nhật cột 4–12 hàng 2–14, đáy răng cưa 3 ô, 3 dòng `+` ngang trong hóa đơn |
| `gameController` | Thân ngang cột 2–13 hàng 6–11, tay cầm loe hai đầu, chữ thập `+` trái, 2 nút `#` phải |
| `heartbeat` | Trái tim 2 u đỉnh hàng 3–5, chụm xuống đỉnh hàng 13 cột 7–8, thêm 1 nhịp `+` ngang giữa |
| `graduationCap` | Mũ chéo hình thoi hàng 4–8 rộng cột 2–13, thân `+` cột 6–10 hàng 8–11, tua treo cột 12 hàng 8–13 |
| `house` | Mái tam giác đỉnh cột 7–8 hàng 2, thân cột 3–12 hàng 7–13, cửa `+` cột 7–8 hàng 9–13 |
| `airplaneTilt` | Thân chéo từ cột 3 hàng 12 lên cột 12 hàng 3, cánh `#` hai bên, đuôi `+` |
| `gift` | Nắp cột 2–13 hàng 3–5, hộp cột 3–12 hàng 5–13, dải dọc `+` cột 7–8, nơ hai vòng hàng 2 |
| `pawPrint` | 4 ngón `+` tròn hàng 2–6 trải cột 2–13, đệm chính `#` 6×5 hàng 7–13 giữa |
| `barbell` | Thanh ngang `#` hàng 7–8 cột 5–10, hai đĩa `+` cột 2–4 và 11–13 hàng 4–11 |
| `filmStrip` | Viền cột 2–13 hàng 4–12, 3 lỗ `.` vuông mỗi cạnh trên/dưới, 2 khung `+` giữa |
| `tShirt` | Cổ `+` hàng 3 cột 6–9, thân cột 4–11 hàng 4–13, hai tay áo lồi cột 2–3 và 12–13 hàng 4–7 |
| `deviceMobile` | Viền đứng cột 5–10 hàng 2–13, màn hình `.` trong, nút `+` giữa cạnh dưới, loa thẹo hàng 3 |
| `bank` | Mái tam giác hàng 2–4 cột 2–13, 3 cột `#` đứng hàng 5–11 tại cột 3, 7, 11, bệ ngang hàng 12–13 |
| `wallet` | Ví ngang cột 2–13 hàng 4–12, khóa `+` ô vuông cột 10–12 hàng 7–9, gập trên hàng 4–5 |
| `dotsThreeOutline` | 3 chấm `#` 3×3 ngang hàng 7–9 tại cột 3, 7, 11 |

- [ ] **Step 4: Chạy test glyph**

Run: `flutter test test/unit/pixel_glyphs_test.dart`
Expected: PASS cả 4 test (danh mục + điều hướng + fallback + painter). Đây là lần đầu test `có glyph cho toàn bộ khóa danh mục` xanh.

- [ ] **Step 5: Đổi `IconHelper` sang `AppIcon`**

`lib/core/utils/icon_helper.dart`:
- Xóa `import 'package:flutter/material.dart';` nếu không còn dùng `IconData`; thay bằng `import 'dart:ui' show Color;` nếu cần, và thêm `import '../../widgets/pixel/app_icon.dart';` (đường dẫn tương đối đúng từ `lib/core/utils/` là `../../widgets/pixel/app_icon.dart`).
- Xóa `_iconRegistry` kiểu `Map<String, IconData>`; thay bằng `static const Set<String> categoryIconKeys = {'forkKnife', 'coffee', 'car', 'shoppingBag', 'receipt', 'gameController', 'heartbeat', 'graduationCap', 'house', 'airplaneTilt', 'gift', 'pawPrint', 'barbell', 'filmStrip', 'tShirt', 'deviceMobile', 'bank', 'wallet', 'dotsThreeOutline'};`
- `availableIcons` → `categoryIconKeys.toList(growable: false)`.
- `normalizeIconKey`: `categoryIconKeys.contains(mappedKey) ? mappedKey : 'dotsThreeOutline'` — **giữ nguyên hành vi cũ** (`icon_helper.dart:52-55` trả `'dotsThreeOutline'`, và khóa này nằm trong 19 khóa của `categoryIconKeys`). Không dùng `PixelGlyphData.fallbackKey` ở đây: `'label'` chỉ là fallback vẽ bên trong `AppIcon`, đổi ở tầng dữ liệu sẽ làm danh mục cũ hiển thị sai nghĩa.
- `getIconWidget`:

```dart
  static Widget getIconWidget(
    String iconKey, {
    double size = 16,
    Color? color,
    Color? secondary,
  }) {
    final mappedKey = _emojiToIconName[iconKey] ?? iconKey;
    final name = PixelGlyphData.rowsOf(mappedKey) != null
        ? mappedKey
        : PixelGlyphData.fallbackKey;
    return AppIcon(
      name: name,
      size: size,
      color: color,
      secondary: secondary,
    );
  }
```
- Xóa nhánh emoji-render-Text và nhánh `Icons.label_outline_rounded`; glyph fallback xử lý cả hai.
- Đổi default `size` từ `22` (`icon_helper.dart:59`) sang `16`: lưới glyph 16×16 chỉ scaling đẹp ở bội số 16 (Plan 4 Global Constraints). 13 call site `getIconWidget` trong `lib/` đều nằm ở file Plan 4 viết lại (budget, expense_form_sheet, feed_photo, manage_categories×2, home×2, statistics, trash, category_chip, category_icon_badge, expense_card) và truyền `size` tường minh; `test/unit/auth_and_supabase_test.dart:96,99` không truyền `size` nhưng chỉ assert kiểu widget nên không ảnh hưởng. `secondary` là tham số mới, `AppIcon` dùng cho lớp màu phụ của glyph.
- Giữ nguyên `parseColor` (Plan 3/4 vẫn dùng cho `color_hex`).

- [ ] **Step 6: Chạy toàn bộ test**

Run: `flutter analyze` && `flutter test`
Expected: PASS. Nếu `test/widget/widgets_test.dart` assert `CategoryIconBadge` chứa `Icon`, đổi sang `AppIcon`.

- [ ] **Step 7: Harness xem glyph (để eyeball)**

Tạo `test/manual/pixel_gallery_manual.dart` (thư mục `test/manual/` không chạy trong `flutter test` vì file không kết thúc `_test.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:chi_tieu/core/icons/pixel_glyph_data.dart';
import 'package:chi_tieu/core/theme/app_palette.dart';
import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/widgets/pixel/app_icon.dart';

void main() {
  runApp(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppPalette.light.canvas,
        body: SafeArea(
          child: GridView.count(
            crossAxisCount: 6,
            children: [
              for (final name in PixelGlyphData.names)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [AppIcon(name: name, size: 32), Text(name)],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
```
Run: `flutter run -t test/manual/pixel_gallery_manual.dart` trên thiết bị/emulator nếu có; nếu không có, ghi rõ "chưa eyeball trực quan" vào báo cáo bàn giao và yêu cầu người dùng xem.

- [ ] **Step 8: Commit (khi được ủy quyền)**

```bash
git add lib/core/icons/pixel_glyph_data.dart lib/core/utils/icon_helper.dart test/unit/ test/manual/
git commit -m "feat(icons): add category pixel glyphs and render IconHelper through AppIcon"
```

---

### Task 7: Component kit phần 1 — Panel, Button, Chip, Progress, Divider

**Files:**
- Create: `lib/widgets/pixel/pixel_panel.dart`, `pixel_button.dart`, `pixel_chip.dart`, `pixel_progress.dart`, `pixel_divider.dart`
- Create: `test/widget/pixel_components_test.dart`

**Interfaces:**
- Consumes: `AppPalette`, `AppIcon`, `pixelTextTheme`.
- Produces:
  - `PixelPanel({required Widget child, VoidCallback? onTap, EdgeInsets padding, Color? background, Color? borderColor, double borderWidth, Offset shadowOffset, BorderRadius? radius, bool semantic})`
  - `PixelButton({Key? key, required String label, VoidCallback? onPressed, PixelButtonVariant variant = PixelButtonVariant.primary, String? icon, double? minWidth, bool expanded, bool isLoading = false})` + `enum PixelButtonVariant { primary, secondary, ghost, danger }`. Khi `isLoading == true`: nút tự vô hiệu hóa (không bắt chạm), thay glyph bên trái bằng `AppIcon(name: 'dotsThreeOutline', size: 16)` (glyph đã có từ Task 6), giữ nguyên nhãn và chiều cao 48dp.
  - `PixelChip({required String label, String? icon, bool selected = false, VoidCallback? onTap, Color? accent, bool showCheck = true})`
  - `PixelProgress({required double value, double? limit, int segments = 10, Color? fillColor, bool showLabel = false})`
  - `const PixelDivider()`

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/pixel_components_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_palette.dart';
import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/widgets/pixel/app_icon.dart';
import 'package:chi_tieu/widgets/pixel/pixel_button.dart';
import 'package:chi_tieu/widgets/pixel/pixel_chip.dart';
import 'package:chi_tieu/widgets/pixel/pixel_panel.dart';
import 'package:chi_tieu/widgets/pixel/pixel_progress.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

void main() {
  testWidgets('PixelButton vô hiệu hóa vẫn hiện nhãn và không bắt chạm', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(PixelButton(label: 'Lưu', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Lưu'));
    expect(taps, 1);
    await tester.pumpWidget(_wrap(const PixelButton(label: 'Lưu', onPressed: null)));
    await tester.tap(find.text('Lưu'), warnIfMissed: false);
    expect(tester.takeException(), isNull);
    // isLoading cũng chặn chạm và đổi glyph, giữ nhãn.
    await tester.pumpWidget(
      _wrap(PixelButton(label: 'Lưu', onPressed: () => taps++, isLoading: true)),
    );
    await tester.tap(find.text('Lưu'), warnIfMissed: false);
    expect(taps, 1);
    expect(find.byType(AppIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelButton đạt chiều cao chạm 48dp', (tester) async {
    await tester.pumpWidget(_wrap(PixelButton(label: 'Lưu', onPressed: () {})));
    final size = tester.getSize(find.byType(PixelButton));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('PixelChip chọn/ bỏ chọn đổi trạng thái', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      _wrap(StatefulBuilder(
        builder: (context, setState) => PixelChip(
          label: 'Cà phê',
          selected: selected,
          onTap: () => setState(() => selected = !selected),
        ),
      )),
    );
    await tester.tap(find.text('Cà phê'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelProgress clamp value và vẽ đúng số khối', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(
      width: 200,
      child: PixelProgress(value: 1.7, segments: 10),
    )));
    expect(find.byType(PixelProgress), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('AppPalette cung cấp extension cho mọi component', () {
    expect(AppPalette.light.ink, isNot(AppPalette.dark.ink));
  });

  testWidgets('PixelPanel render child', (tester) async {
    await tester.pumpWidget(_wrap(const PixelPanel(child: Text('nội dung'))));
    expect(find.text('nội dung'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/widget/pixel_components_test.dart`
Expected: FAIL — URI không tồn tại.

- [ ] **Step 3: Implement 5 component**

`lib/widgets/pixel/pixel_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Khung pixel: nền surface, viền cứng, bóng lệch. Mọi màn hình dùng khối này.
class PixelPanel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final Color? borderColor;
  final double borderWidth;
  final Offset shadowOffset;
  final BorderRadius? radius;

  const PixelPanel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.background,
    this.borderColor,
    this.borderWidth = 2,
    this.shadowOffset = const Offset(3, 4),
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final border = radius ?? BorderRadius.circular(4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? palette.surface,
        borderRadius: border,
        border: Border.all(
          color: borderColor ?? palette.lineStrong,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.9),
            offset: shadowOffset,
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: border,
          splashColor: palette.mint.withValues(alpha: 0.25),
          highlightColor: palette.mint.withValues(alpha: 0.15),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
```

`lib/widgets/pixel/pixel_button.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

enum PixelButtonVariant { primary, secondary, ghost, danger }

class PixelButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final PixelButtonVariant variant;
  final String? icon;
  final bool expanded;
  final double? minWidth;
  final bool isLoading;

  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PixelButtonVariant.primary,
    this.icon,
    this.expanded = false,
    this.minWidth,
    this.isLoading = false,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = widget.onPressed != null && !widget.isLoading;

    final colors = switch (widget.variant) {
      PixelButtonVariant.primary => (
        bg: enabled ? palette.mint : palette.surfaceAlt,
        fg: enabled ? palette.onAccent : palette.inkMuted,
        border: enabled ? palette.lineStrong : palette.line,
      ),
      PixelButtonVariant.secondary => (
        bg: enabled ? palette.surface : palette.surfaceAlt,
        fg: enabled ? palette.ink : palette.inkMuted,
        border: enabled ? palette.lineStrong : palette.line,
      ),
      PixelButtonVariant.ghost => (
        bg: Colors.transparent,
        fg: enabled ? palette.mintInk : palette.inkMuted,
        border: Colors.transparent,
      ),
      PixelButtonVariant.danger => (
        bg: enabled ? palette.rose : palette.surfaceAlt,
        fg: enabled ? palette.onAccent : palette.inkMuted,
        border: enabled ? palette.lineStrong : palette.line,
      ),
    };

    // isLoading thay glyph bên trái bằng glyph đang chạy, giữ nguyên nhãn.
    final glyph = widget.isLoading ? 'dotsThreeOutline' : widget.icon;

    Widget content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (glyph != null) ...[
          AppIcon(name: glyph, size: 16, color: colors.fg),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.fg,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          offset: _pressed ? const Offset(0.03, 0.05) : Offset.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.border, width: 2),
              boxShadow:
                  widget.variant == PixelButtonVariant.ghost || !enabled
                  ? null
                  : [
                    BoxShadow(
                      color: palette.shadow.withValues(alpha: 0.9),
                      offset: const Offset(2, 3),
                      blurRadius: 0,
                    ),
                  ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth:
                    widget.minWidth ??
                    (widget.variant == PixelButtonVariant.ghost ? 48 : 64),
                minHeight: 48,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```


`lib/widgets/pixel/pixel_chip.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

/// Chip chọn/badge. Luôn có nhãn chữ, không chỉ dựa vào màu.
class PixelChip extends StatelessWidget {
  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color? accent;
  final bool showCheck;

  const PixelChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.accent,
    this.showCheck = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = accent ?? palette.mint;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '$label${selected ? ', đã chọn' : ''}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: selected ? tone : palette.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? palette.lineStrong : palette.line,
              width: selected ? 3 : 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppIcon(
                  name: icon!,
                  size: 16,
                  color: selected ? palette.onAccent : palette.ink,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? palette.onAccent : palette.ink,
                ),
              ),
              if (selected && showCheck && onTap != null) ...[
                const SizedBox(width: 6),
                AppIcon(name: 'check', size: 16, color: palette.onAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/widgets/pixel/pixel_progress.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class PixelProgress extends StatelessWidget {
  final double value;
  final int segments;
  final Color? fillColor;
  final Color? emptyColor;
  final bool showLabel;

  const PixelProgress({
    super.key,
    required this.value,
    this.segments = 10,
    this.fillColor,
    this.emptyColor,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final filled = (clamped * segments).round().clamp(0, segments);

    return Semantics(
      value: '${(clamped * 100).round()}%',
      label: showLabel ? 'Tiến độ' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < segments; i++)
                Expanded(
                  child: Container(
                    height: 14,
                    margin: EdgeInsets.only(right: i == segments - 1 ? 0 : 3),
                    color: i < filled
                        ? (fillColor ?? palette.mintStrong)
                        : (emptyColor ?? palette.surfaceAlt),
                  ),
                ),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            Text(
              '${(clamped * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.end,
            ),
          ],
        ],
      ),
    );
  }
}
```

`lib/widgets/pixel/pixel_divider.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class PixelDivider extends StatelessWidget {
  final EdgeInsetsGeometry margin;
  const PixelDivider({super.key, this.margin = const EdgeInsets.symmetric(vertical: 8)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ExcludeSemantics(
        child: ColoredBox(
          color: context.palette.line,
          child: const SizedBox(height: 2, width: double.infinity),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Chạy test, sửa tới xanh**

Run: `flutter test test/widget/pixel_components_test.dart`
Expected: PASS 6 test. Lỗi hay gặp: `PixelProgress` thiếu `crossAxisAlignment: stretch` trong `SizedBox` width cố định.

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/widgets/pixel/ test/widget/pixel_components_test.dart
git commit -m "feat(widgets): add pixel panel button chip progress divider"
```

---

### Task 8: Component kit phần 2 — TextField, Dialog, Sheet, SnackBar, Empty, Loading, Stat, Badge, Segmented

**Files:**
- Create: `lib/widgets/pixel/pixel_text_field.dart`, `pixel_dialog.dart`, `pixel_sheet.dart`, `pixel_snack_bar.dart`, `pixel_empty_state.dart`, `pixel_loading.dart`, `pixel_stat_tile.dart`, `pixel_badge.dart`, `pixel_segmented.dart`
- Create: `test/widget/pixel_components_2_test.dart`

**Interfaces:**
- Consumes: `PixelPanel`, `PixelButton`, `AppIcon`, `AppPalette`, `pixelTextTheme`.
- Produces:
  - `PixelTextField` (`StatefulWidget` bọc `TextFormField`, constructor nhận `Key? key`: `label (required), hint, controller, keyboardType, inputFormatters, validator, maxLines, errorText, helperText, onChanged, onSubmitted, onTap, autofocus, textCapitalization, focusNode, suffixGlyph (String), onSuffixTap, obscureToggle (bool)`). `obscureToggle: true` render nút `ValueKey('pixel-obscure-toggle')` glyph eye/eyeOff 48dp bên phải và tự giữ state ẩn/hiện; `validator` cho phép dùng trong `Form`; `errorText` hiển thị inline + `Semantics(liveRegion: true)`. Tên tham số **không phải** `suffixIcon` / `obscureText`.
  - `Future<T?> showPixelDialog<T>({required BuildContext context, required String title, required Widget content, List<Widget> actions})`
  - `Future<R?> showPixelSheet<R>({required BuildContext context, required String title, required Widget Function(BuildContext) builder, bool fullScreen = false})` — `fullScreen: true` mở sheet cao `0.92 × màn hình` (dùng cho form khoản chi nhiều field); mặc định ôm nội dung.
  - `void showPixelSnackBar(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction, PixelTone tone = PixelTone.info})` + `enum PixelTone { info, success, warning, danger }`
  - `PixelEmptyState({required String glyph, required String title, required String message, String? actionLabel, VoidCallback? onAction})`
  - `PixelLoading({int blocks = 3, String? label})`
  - `PixelStatTile({required String label, required String value, String? glyph})`
  - `PixelBadge({required String glyph, required String label, Color? accent, Color? ink})`
  - `PixelSegmented<T>({required List<PixelSegmentItem<T>> items, required T selected, required ValueChanged<T> onChanged})` + `class PixelSegmentItem<T> { final T value; final String label; final String? glyph; }`

- [ ] **Step 1: Viết test failing**

Tạo `test/widget/pixel_components_2_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/widgets/pixel/pixel_empty_state.dart';
import 'package:chi_tieu/widgets/pixel/pixel_segmented.dart';
import 'package:chi_tieu/widgets/pixel/pixel_snack_bar.dart';
import 'package:chi_tieu/widgets/pixel/pixel_text_field.dart';
import 'package:chi_tieu/widgets/pixel/pixel_loading.dart';
import 'package:chi_tieu/widgets/pixel/pixel_badge.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

void main() {
  testWidgets('PixelTextField hiện label và lỗi dưới field', (tester) async {
    final controller = TextEditingController(text: 'abc');
    await tester.pumpWidget(_wrap(
      PixelTextField(
        label: 'Mô tả',
        controller: controller,
        errorText: 'Không được để trống',
      ),
    ));
    expect(find.text('Mô tả'), findsOneWidget);
    expect(find.text('Không được để trống'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showPixelSnackBar hiển thị action', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(_wrap(
      Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }),
    ));
    showPixelSnackBar(ctx, 'Đã xóa khoản chi',
        actionLabel: 'Hoàn tác', onAction: () {});
    await tester.pump();
    expect(find.text('Đã xóa khoản chi'), findsOneWidget);
    expect(find.text('Hoàn tác'), findsOneWidget);
  });

  testWidgets('PixelSegmented chọn đúng item', (tester) async {
    var selected = 'week';
    await tester.pumpWidget(_wrap(StatefulBuilder(
      builder: (context, setState) => PixelSegmented<String>(
        items: const [
          PixelSegmentItem(value: 'day', label: 'NGÀY'),
          PixelSegmentItem(value: 'week', label: 'TUẦN'),
          PixelSegmentItem(value: 'month', label: 'THÁNG'),
        ],
        selected: selected,
        onChanged: (v) => setState(() => selected = v),
      ),
    )));
    await tester.tap(find.text('THÁNG'));
    await tester.pump();
    expect(selected, 'month');
  });

  testWidgets('PixelEmptyState có title, message và CTA', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(PixelEmptyState(
      glyph: 'receipt',
      title: 'CHƯA CÓ KHOẢN CHI',
      message: 'Mở camera và chụp khoản chi đầu tiên.',
      actionLabel: 'Mở camera',
      onAction: () => taps++,
    )));
    await tester.tap(find.text('Mở camera'));
    expect(taps, 1);
  });

  testWidgets('PixelLoading và PixelBadge render', (tester) async {
    await tester.pumpWidget(_wrap(const Column(
      children: [
        PixelLoading(),
        PixelBadge(glyph: 'coffee', label: 'Cà phê'),
      ],
    )));
    expect(find.byType(PixelLoading), findsOneWidget);
    expect(find.text('Cà phê'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/widget/pixel_components_2_test.dart`
Expected: FAIL — URI không tồn tại.

- [ ] **Step 3: Implement**

`lib/widgets/pixel/pixel_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

class PixelTextField extends StatefulWidget {
  const PixelTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.focusNode,
    this.suffixGlyph,
    this.onSuffixTap,
    this.obscureToggle = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final String? suffixGlyph;
  final VoidCallback? onSuffixTap;
  final bool obscureToggle;

  @override
  State<PixelTextField> createState() => _PixelTextFieldState();
}

class _PixelTextFieldState extends State<PixelTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    Widget? suffix;
    if (widget.obscureToggle) {
      suffix = IconButton(
        key: const ValueKey('pixel-obscure-toggle'),
        tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
        onPressed: () => setState(() => _hidden = !_hidden),
        iconSize: 20,
        icon: AppIcon(
          name: _hidden ? 'eye' : 'eyeOff',
          size: 20,
          color: palette.inkMuted,
        ),
      );
    } else if (widget.suffixGlyph != null) {
      suffix = IconButton(
        onPressed: widget.onSuffixTap,
        iconSize: 16,
        icon: AppIcon(name: widget.suffixGlyph!, size: 16),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: text.labelLarge?.copyWith(color: palette.ink)),
        const SizedBox(height: 6),
        Semantics(
          textField: true,
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            maxLines: widget.obscureToggle ? 1 : widget.maxLines,
            obscureText: widget.obscureToggle && _hidden,
            autofocus: widget.autofocus,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            textCapitalization: widget.textCapitalization,
            style: text.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              helperText: widget.helperText,
              suffixIcon: suffix,
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ),
        // errorText của TextFormField đã hiển thị inline; live region giúp
        // screen reader đọc lại khi lỗi xuất hiện sau khi submit.
        if (widget.errorText != null)
          const Semantics(
            liveRegion: true,
            label: 'Có lỗi dữ liệu',
            child: SizedBox.shrink(),
          ),
      ],
    );
  }
}
```

`TextFormField` (không phải `TextField`) là bắt buộc: `validator` chỉ hoạt động bên trong `Form`, và plan 3 / plan 4 dựa vào `validator` cho login, register, form khoản chi, sheet lọc. `obscureToggle` là state nội nên phải là `StatefulWidget`. `onSubmitted` map vào `onFieldSubmitted`.

`lib/widgets/pixel/pixel_dialog.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'pixel_button.dart';
import 'pixel_panel.dart';

Future<T?> showPixelDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget> actions = const [],
  String? glyph,
}) {
  final palette = Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: PixelPanel(
        background: palette.surface,
        borderWidth: 3,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(dialogContext)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(letterSpacing: 0.9),
            ),
            const SizedBox(height: 12),
            Flexible(child: content),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final action in actions)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: action,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Dialog xác nhận hai nút dùng chung cho xóa/hủy.
Future<bool> showPixelConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xóa',
  String cancelLabel = 'Hủy',
  bool danger = true,
}) async {
  final result = await showPixelDialog<bool>(
    context: context,
    title: title,
    content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    actions: [
      PixelButton(
        label: cancelLabel,
        variant: PixelButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(false),
      ),
      PixelButton(
        label: confirmLabel,
        variant: danger ? PixelButtonVariant.danger : PixelButtonVariant.primary,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ],
  );
  return result ?? false;
}
```

`lib/widgets/pixel/pixel_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'pixel_panel.dart';

Future<R?> showPixelSheet<R>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext) builder,
  bool fullScreen = false,
}) {
  final palette = Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surface,
    shape: const RoundedRectangleBorder(),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * (fullScreen ? 0.95 : 0.8),
          ),
          child: PixelPanel(
            background: palette.surface,
            borderWidth: 0,
            shadowOffset: Offset.zero,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(letterSpacing: 0.9),
                ),
                const SizedBox(height: 12),
                Flexible(child: SingleChildScrollView(child: builder(sheetContext))),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
```

`lib/widgets/pixel/pixel_snack_bar.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

enum PixelTone { info, success, warning, danger }

void showPixelSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  PixelTone tone = PixelTone.info,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  final palette = Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
  final border = switch (tone) {
    PixelTone.info => palette.mint,
    PixelTone.success => palette.mint,
    PixelTone.warning => palette.butter,
    PixelTone.danger => palette.rose,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: action != null || onAction != null
            ? const Duration(seconds: 5)
            : duration,
        backgroundColor: palette.ink,
        margin: const EdgeInsets.all(12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(color: border, width: 2),
        ),
        content: Text(message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: palette.canvas)),
        action: action ??
            (actionLabel != null && onAction != null
                ? SnackBarAction(
                    label: actionLabel,
                    textColor: palette.butter,
                    onPressed: onAction,
                  )
                : null),
      ),
    );
}
```

`lib/widgets/pixel/pixel_empty_state.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';
import 'pixel_button.dart';
import 'pixel_panel.dart';

class PixelEmptyState extends StatelessWidget {
  final String glyph;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PixelEmptyState({
    super.key,
    required this.glyph,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: PixelPanel(
          background: palette.surface,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(name: glyph, size: 48, color: palette.mintInk),
              const SizedBox(height: 12),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: palette.inkMuted),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                PixelButton(label: actionLabel!, onPressed: onAction, icon: 'plus'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/widgets/pixel/pixel_loading.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Nhấp nháy theo bậc (không shimmer mượt): 3 khối đổi độ sáng mỗi 160ms.
class PixelLoading extends StatefulWidget {
  final int blocks;
  final String? label;

  const PixelLoading({super.key, this.blocks = 3, this.label});

  @override
  State<PixelLoading> createState() => _PixelLoadingState();
}

class _PixelLoadingState extends State<PixelLoading> {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedBuilder(
      animation: _controller,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.blocks; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: SizedBox(width: 12, height: 12, child: _Frame(i: i)),
            ),
        ],
      ),
      builder: (context, child) {
        final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        final step = disabled ? 0 : (_controller.value * 4).floor() % 4;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Stepped(step: step, blocks: widget.blocks, child: child!),
            if (widget.label != null) ...[
              const SizedBox(height: 8),
              Text(widget.label!, style: Theme.of(context).textTheme.labelMedium),
            ],
          ],
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  final int i;
  const _Frame({required this.i});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Stepped extends StatelessWidget {
  final int step;
  final int blocks;
  final Widget child;
  const _Stepped({required this.step, required this.blocks, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 12,
              height: 12,
              color: ((i + step) % blocks == 0)
                  ? palette.mintStrong
                  : palette.surfaceAlt,
            ),
          ),
      ],
    );
  }
}
```
Bản gọn hơn được phép: bỏ `_Frame` và `child:` của `AnimatedBuilder`, chỉ giữ `_Stepped`. Yêu cầu: không dùng opacity mượt, không `Curves.easeInOut` cho chu kỳ.

`lib/widgets/pixel/pixel_stat_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';
import 'pixel_panel.dart';

class PixelStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? glyph;

  const PixelStatTile({
    super.key,
    required this.label,
    required this.value,
    this.glyph,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return PixelPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (glyph != null) ...[
                AppIcon(name: glyph!, size: 16, color: palette.mintInk),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}
```

`lib/widgets/pixel/pixel_badge.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

class PixelBadge extends StatelessWidget {
  final String glyph;
  final String label;
  final Color? accent;
  final Color? ink;
  final double iconSize;

  const PixelBadge({
    super.key,
    required this.glyph,
    required this.label,
    this.accent,
    this.ink,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = accent ?? palette.mint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: tone,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: palette.lineStrong, width: 2),
          ),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: AppIcon(name: glyph, size: iconSize, color: palette.onAccent),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: ink ?? palette.ink,
        )),
      ],
    );
  }
}
```

`lib/widgets/pixel/pixel_segmented.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

class PixelSegmentItem<T> {
  final T value;
  final String label;
  final String? glyph;
  const PixelSegmentItem({required this.value, required this.label, this.glyph});
}

class PixelSegmented<T> extends StatelessWidget {
  final List<PixelSegmentItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  const PixelSegmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Semantics(
              selected: item.value == selected,
              button: true,
              label: item.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(item.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.value == selected ? palette.mint : palette.surface,
                    border: Border.all(color: palette.lineStrong, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.glyph != null) ...[
                        AppIcon(
                          name: item.glyph!,
                          size: 16,
                          color: item.value == selected
                              ? palette.onAccent
                              : palette.ink,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          item.label.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: item.value == selected
                                    ? palette.onAccent
                                    : palette.ink,
                              ),
                        ),
                      ),
                    ],
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

- [ ] **Step 4: Chạy test, sửa tới xanh**

Run: `flutter test test/widget/pixel_components_2_test.dart`
Expected: PASS 5 test. Lỗi thường gặp: `PixelLoading` cần `MaterialApp` ở gốc (test đã có); `showPixelSnackBar` cần `ScaffoldMessenger` — `MaterialApp` tự cung cấp.

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add lib/widgets/pixel/ test/widget/pixel_components_2_test.dart
git commit -m "feat(widgets): add pixel text field dialog sheet snack bar empty loading badge segmented"
```

---

### Task 9: Swap icon trong shell (hamburger, drawer, AppSection)

**Files:**
- Modify: `lib/core/navigation/app_section.dart:1-12`
- Modify: `lib/widgets/hamburger_button.dart`
- Modify: `lib/widgets/app_drawer.dart` (icon + bỏ gradient cứng)
- Modify: `test/widget/app_drawer_test.dart`

**Interfaces:**
- Consumes: `AppIcon`, `context.palette`, glyph keys Task 5.
- Produces:
  - `enum AppSection { feed('Nhật ký ảnh', 'camera'), dashboard('Tổng quan', 'house'), statistics('Thống kê', 'chart'), budget('Ngân sách', 'wallet') }` với `final String glyph;`
  - `HamburgerButton` — **giữ nguyên chữ ký hiện có** (`lib/widgets/hamburger_button.dart:7`: `const HamburgerButton({super.key, required this.onTap, this.light = false})`, tham số tên là `onTap` chứ không phải `onPressed`), chỉ đổi `Icon(Icons.menu_rounded, size: 24)` (dòng 25-29) → `AppIcon(name: 'menu', size: 32)` và màu nền/viền theo `light`: `light == true` dùng `palette.feedBg.withValues(alpha: 0.5)` / viền `palette.feedInk.withValues(alpha: 0.3)` (HUD camera), `light == false` dùng `palette.surface` / `palette.line`. Vẫn `IconButton` + `tooltip: 'Mở menu'`.

- [ ] **Step 1: Thêm glyph `camera`, `chart`, `chart` cần cho section**

Kiểm tra: `grep -n "'camera'\|'chart'\|'tag'" lib/core/icons/pixel_glyph_data.dart`
Expected: thiếu → thêm vào `PixelGlyphData.all` theo đặc tả:

| Key | Bố cục |
| --- | --- |
| `camera` | Thân máy `#` cột 2–13 hàng 5–13, bẩy giữa hàng 3–4 cột 6–9, ống kính tròn `+` 5×5 tâm cột 8 hàng 9 |
| `chart` | Trục `#` dọc cột 3 hàng 2–13 và ngang hàng 13; 3 cột `+`/`#` cao thấp khác nhau tại cột 6, 9, 12 |
| `tag` | Nhãn chéo: khối `#` cột 4–13 hàng 2–11 xoay 45° kiểu bậc thang, lỗ tròn `.` 2×2 ở góc trên trái |

Chạy: `flutter test test/unit/pixel_glyphs_test.dart` → PASS.

- [ ] **Step 2: Sửa `AppSection`**

```dart
enum AppSection {
  feed('Nhật ký ảnh', 'camera'),
  dashboard('Tổng quan', 'house'),
  statistics('Thống kê', 'chart'),
  budget('Ngân sách', 'wallet');

  final String label;
  final String glyph;

  const AppSection(this.label, this.glyph);
}
```
Xóa `import 'package:flutter/material.dart';` nếu không còn dùng `IconData` (kiểm tra nơi khác dùng `AppSection.icon`).
Run: `grep -rn "\.icon" lib/ | grep -i section`
Expected: không còn chỗ nào dùng `section.icon` làm `IconData`; nếu có, thay bằng `section.glyph` + `AppIcon`.

- [ ] **Step 3: Sửa `HamburgerButton`**

Giữ nguyên `IconButton` (đã tự có semantics button + vùng chạm 48×48 theo constraint Material), chỉ thay `icon: Icon(Icons.menu_rounded, size: 24, ...)` bằng `icon: AppIcon(name: 'menu', size: 32, color: light ? palette.feedInk : null)` và thay `Colors.black.withValues(alpha: 0.28)` / `Colors.white.withValues(alpha: 0.22)` / `Theme.of(context).colorScheme…` bằng palette như bullet trên. `tooltip: 'Mở menu'` giữ nguyên — không cần bọc `Semantics` thủ công. Xóa `Icons.menu_rounded`.

- [ ] **Step 4: Bỏ gradient cứng của drawer, đổi icon**

`lib/widgets/app_drawer.dart`:
- Xóa `LinearGradient([#0B0F19, #111C2E, #07231D])`; nền dùng `context.palette.surface`, viền phải 3 px `palette.lineStrong`.
- Mỗi mục chuyển `Icon(...)` → `AppIcon(name: <glyph>)`: `camera`, `house`, `chart`, `wallet`, `tag`, `trash`, `settings`.
- Mục đang chọn: nền `palette.mint`, chữ `palette.onAccent`, gạch trái 4 px `palette.lineStrong`.
- Item khác vẫn `InkWell`/`ListTile` cao ≥ 48, `Semantics(selected:)`.
- Footer: `AppInfo.aboutLabel` + trạng thái cloud dùng `AppIcon(name: SupabaseConfig.isInitialized ? 'cloud' : 'cloudOff')`.
- Header hồ sơ: ô avatar `DecoratedBox` nền `palette.mint` với chữ cái đầu của email (`AppIcon` không có chữ → dùng `Text` VT323), email `bodySmall` màu `palette.inkMuted`.
- Công tắc sáng/tối: `Switch` (theme đã lo phần màu) + nhãn "Giao diện tối".

- [ ] **Step 5: Cập nhật widget test drawer**

`test/widget/app_drawer_test.dart`: các assertion `find.byIcon(Icons.…)` đổi sang `find.byType(AppIcon)` kèm `that: findsWidgets`, hoặc assert nhãn `find.text('Tổng quan')`. Giữ nguyên nội dung test điều hướng. Thêm test:

```dart
  testWidgets('Drawer không còn gradient tối cố định', (tester) async {
    // build MainScreen/Drawer như các test hiện có, rồi:
    final decorated = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    final box = decorated.decoration as BoxDecoration;
    expect(box.gradient, isNull);
  });
```

`AppDrawer` trả `Drawer` chứ không phải `NavigationDrawer` (`lib/widgets/app_drawer.dart:39`) — dùng `find.byType(Drawer)`. Nếu `DecoratedBox` đầu tiên không phải nền drawer, tìm bằng `find.descendant(of: find.byType(Drawer), matching: find.byType(Drawer))` không ổn định → thay assertion bằng cách quét toàn bộ:

```dart
    for (final d in tester.widgetList<DecoratedBox>(
      find.descendant(of: find.byType(Drawer), matching: find.byType(DecoratedBox)),
    )) {
      final dec = d.decoration;
      if (dec is BoxDecoration) expect(dec.gradient, isNull);
    }
```

- [ ] **Step 6: Chạy bộ**

Run: `flutter analyze` && `flutter test`
Expected: PASS.

- [ ] **Step 7: Commit (khi được ủy quyền)**

```bash
git add lib/core/navigation/app_section.dart lib/widgets/hamburger_button.dart lib/widgets/app_drawer.dart lib/core/icons/pixel_glyph_data.dart test/widget/app_drawer_test.dart
git commit -m "feat(shell): switch drawer and section icons to pixel glyphs"
```

---

### Task 10: Build xanh và khóa nền tảng

**Files:**
- Modify: `docs/project-structure.md` (mục `lib/core/icons`, `lib/widgets/pixel`, `assets/fonts`)

**Interfaces:**
- Consumes: Task 1-9.
- Produces: nền tảng ổn định cho Plan 3 và Plan 4.

- [ ] **Step 1: Chạy bộ kiểm chứng**

```bash
flutter analyze
flutter test
flutter build apk --debug
```
Expected: analyze `No issues found`; test pass; build ra `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 2: Kiểm tra không còn tải font từ mạng**

```bash
grep -rn "google_fonts\|GoogleFonts" lib/ pubspec.yaml
```
Expected: không kết quả.

- [ ] **Step 3: Kiểm tra không còn icon hệ thống trong shell**

```bash
grep -rn "Icons\." lib/widgets/app_drawer.dart lib/widgets/hamburger_button.dart lib/core/navigation/app_section.dart
```
Expected: không kết quả.

- [ ] **Step 4: Ghi trạng thái eyeball**

Nếu chưa chạy được trên thiết bị/emulator, ghi rõ trong báo cáo: "Component kit và glyph mới chỉ được xác minh bằng widget test, chưa xem trực quan."

- [ ] **Step 5: Commit (khi được ủy quyền)**

```bash
git add docs/project-structure.md
git commit -m "docs: record pixel foundation structure"
```

## Chốt chặn cuối plan

- [ ] 51+ glyph hợp lệ 16×16, phủ đủ 19 khóa danh mục + nhóm điều hướng + `camera/chart/tag`.
- [ ] `AppPalette.light`/`dark` đạt tương phản theo test.
- [ ] Font bundle offline, không `google_fonts`.
- [ ] `PixelTextField` hiện label + lỗi + live region.
- [ ] `AppIcon`/`PixelIconButton` semantics có nhãn.
- [ ] Màn hình cũ vẫn chạy (Plan 2 chưa đổi layout) — xác nhận bằng `flutter test` + eyeball nếu có thiết bị.
