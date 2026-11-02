# Pixket — Brand pixel camera + palette Nyan Cat + hiệu ứng vũ trụ (Spec)

- **Ngày:** 2026-11-02
- **Trạng thái:** Chờ người dùng duyệt (board thiết kế v4 đã duyệt 11/11 quyết định)
- **Phạm vi:** Lớp brand + design token + 6 hiệu ứng + IA điều hướng. Không đổi nghiệp vụ, không đổi schema.
- **Tham chiếu:** spec nền `2026-11-01-pixket-pixel-redesign-design.md`; board duyệt
  `pixket-redesign-v1.html` (bản v4 — artifact của phiên duyệt, **không nằm trong repo**;
  mọi quyết định của nó đã được chép lại ở mục 14 nên tài liệu này vẫn tự đủ);
  `docs/brand/pixket_icon_1024.png` (icon hiện tại, sẽ bị thay ở giai đoạn 1).

## 1. Bối cảnh

App đã chuyển sang ngôn ngữ Pixel (v2.2.0+3) nhưng brand còn yếu: mark đang là vòng tròn
aperture trừu tượng, palette 5 accent tự chọn không có bản sắc, nền tối là màu nâu mực
chứ không phải "vũ trụ", và biểu đồ tô màu theo danh mục nên nhìn ngẫu nhiên.

Người dùng đưa hai ảnh tham chiếu (màn chụp máy ảnh pixel + Nyan Cat) và yêu cầu: logo
đọc ra máy ảnh, màu theo dải Nyan Cat, thêm hiệu ứng. Sau 4 vòng duyệt trên board, các
quyết định đã chốt ở mục 14.

## 2. Mục tiêu

1. Mark pixel **đọc ra máy ảnh** (thân máy + ống kính), dùng chung một định nghĩa lưới cho
   in-app và icon launcher.
2. Palette Nyan Cat hai theme: **light kem** (giấy sạch, không sao) và **dark vũ trụ**
   (nền xanh đêm + sao), đạt WCAG 2.1 theo số đo thật.
3. Biểu đồ/tier chi tiêu tô theo **mức chi** (xanh dương → xanh lá → vàng → đỏ), không theo
   danh mục; vẫn thoả "không chỉ bằng màu".
4. Sáu hiệu ứng pixel bậc rời, mỗi cái có khoá Settings và tôn trọng `disableAnimations`.
5. Điều hướng thành tab bar đáy (4 section chính), drawer giữ cho action phụ.

### Trong phạm vi

`lib/core/theme/`, `lib/widgets/pixel/` (thêm 6 file), `lib/screens/main_screen.dart`,
`camera_screen.dart`, `home_screen.dart`, `statistics/`, `budget_screen.dart`,
`settings_screen.dart`, `lib/data/repositories/app_settings_repository.dart`,
`lib/providers/app_settings_provider.dart`, mipmaps Android, README +
`docs/project-structure.md`, test unit/widget mới.

### Ngoài phạm vi

- Phương án A của chuyển cảnh chụp (6 vòng iris + đĩa) — đã chọn B, A không được code.
- Icon iOS/web/windows (CI chỉ build APK); cập nhật chúng là việc riêng nếu sau này cần.
- Đổi tên app, đổi `AppInfo.tagline`, đổi schema DB/Supabase, thêm dependency mới.
- Golden test / so ảnh; máy chưa có thiết bị để đo cảm giác chuyển động thật.

## 3. Brand: mark, wordmark, icon launcher

**Mark chính (phương án A đã duyệt).** Lưới 24×24 cho brand, 16×16 cho glyph nhỏ, vẽ bằng
`CustomPaint` với `isAntiAlias: false` theo đúng cách `pixel_glyph.dart` đang làm. Grid **không
phải bảng ký tự viết tay** mà sinh bằng hàm dựng thuần — thuật toán này chính là thứ đã tạo ra
hình bạn đang duyệt trên board, nên nó tái hiện được cả hai cỡ và bản mono/tối giản:

```dart
// lib/widgets/pixel/pixel_logo.dart
class PixelLogo extends StatelessWidget {
  const PixelLogo({super.key, this.size = 24, this.mono = false, this.simple = false});
  final double size;    // 24 brand, 16 glyph; không phải bội số 8 -> làm tròn xuống
  final bool mono;      // chỉ ink, cho launcher / drawer / favicon
  final bool simple;    // bỏ gờ nhả chụp + ô ngắm, chỉ thân + ống kính
}

/// Trả về n chuỗi, mỗi chuỗi n ký tự: '.' trống, 'k' ink, 'b' surface, 'p' surfaceAlt,
/// 'f' flash vàng, 'g' highlight, 'h' pupil, '1'..'6' sáu cung iris.
List<String> buildLogoGrid(int n, {bool mono = false, bool simple = false});
```

Các bước dựng (tỷ lệ tính theo `n`, làm tròn nguyên, giống hệt board):

1. Thân máy: chữ nhật x ∈ [12%, 88%], y ∈ [33%, 75%]; mọi ô thuộc mask mà có hàng xóm
   ngoài mask → `k` (viền), còn lại `b`.
2. Gờ nhả chụp: x ∈ [76%, 88%], cao 8% nằm ngay trên thân → `f`.
3. Ô ngắm: x ∈ [12%+2, 12%+2+17%] trên thân, cao 8% → `h`.
4. Iris: tâm `(cx, cy + 1%)`, bán kính `R = 26%·n`; vành trong `rho > R-1` → `k`;
   chia 6 cung 60° lệch swirl 15° → số thứ tự accent `1..6`; lỗ đồng tử
   `rho < 34%·R / cos(loc)` → `h` (đa giác 6 cạnh, không phải tròn).
5. Highlight 2×2 tại `(cx − 52%R, cy − 62%R)` trên cung màu → `g`.
6. `mono` → mọi cung màu thành `k`; `simple` → bỏ bước 2 và 3.

Màu tô theo ký tự lấy từ palette, không hardcode: `1..6` → `accents[i-1]`, `h`/`k` → `ink`,
`b`/`p` → `surface`/`surfaceAlt`, `f` → `butter`, `g` → `star` (dark) / `surface` (light).

**Mark phụ (phương án B, polaroid).** Chỉ dùng cho empty-state và khung hướng dẫn màn chụp,
kích thước 16, không xuất hiện ở header.

**Wordmark.** `PIXKET` bằng VT323 + **dải cầu vồng 6 ô làm gạch chân** (`RainbowRule`,
`height: 5`). Không tô màu từng chữ (gạch cầu vồng rẻ hơn và giữ chữ đọc được).

**Launcher icon.** Nguồn vẽ = `buildLogoGrid(24, mono: true)` trên nền `#0E2A4F`, viền
`#DCEBFF`. Sinh PNG bằng test có điều khiển môi trường, không thêm dependency:

```dart
// test/tool/launcher_icons_test.dart  (chỉ chạy khi PIXKET_GEN_ICONS=1)
// RepaintBoundary -> toImage(1024) -> downscale nearest-neighbour
// Ghi android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png
```

Mặc định test ở chế độ `skip` để `flutter test` trong CI không ghi đè file.

## 4. Design token: `AppPalette`

Giữ **tên field hiện có** để không đụng hàng trăm điểm gọi; chỉ đổi **giá trị**, thêm
`violet`/`violetInk` và các token mới. Đây là quyết định thiết kế chủ ý: đặt tên theo
`mint/sky/butter/rose` hơi lệch với "cầu vồng", nhưng đổi tên sẽ là refactor không cần
thiết bị nào yêu cầu.

| Field | Light (kem) | Dark (vũ trụ) | Ghi chú |
|---|---|---|---|
| `canvas` | `#FFF6E3` (giữ) | `#0E2A4F` (đổi từ `#1A130D`) | nền vũ trụ |
| `surface` | `#FFFDF6` | `#16396A` | panel |
| `surfaceAlt` | `#FFF1D6` | `#1D4A82` | panel phụ |
| `ink` / `inkMuted` | `#2B2118` / `#6E5F4E` | `#F2F8FF` / `#A8C3E8` | |
| `line` / `lineStrong` / `shadow` | `#1B140E` | `#4E76A8` / `#DCEBFF` / `#06121F` | |
| `rose` = a1 đỏ | `#FF5C5C` | `#FF6B6B` | |
| `peach` = a2 cam | `#FFA53D` | `#FFB347` | |
| `butter` = a3 vàng | `#FFE45C` | `#FFE873` | |
| `mint` = a4 lục | `#57D98A` | `#6BE58A` | |
| `sky` = a5 dương | `#57AEFF` | `#6FB7FF` | |
| `violet` = a6 tím (**mới**) | `#B983FF` | `#C99BFF` | |
| `roseInk`…`violetInk` (bản deep d1..d6) | `#C0273B` `#9C4A06` `#8A6A00` `#146B3C` `#0F4C8F` `#57309E` | **giữ các tint đang có** (`#F7B7C0 #FFCDB0 #FFE7A6 #9BE9C2 #BEE4F5`) + `violetInk` mới `#E0C4FF` | dùng cho thanh mảnh, legend, chữ |
| `star` (**mới**) | `#FFE45C` (khai báo cho đủ field; theme light không vẽ sao và không dùng token này) | `#FFFFFF` | nền sao chỉ có ở dark |
| `feedBg` / `feedPanel` | `#06121F` / `#0E2A4F` | `#06121F` / `#0E2A4F` | khung chụp đồng nhất hai theme |

Ba thay đổi API bắt buộc:

1. **Bỏ static map `_accents`** (`app_palette.dart:40-46`). Nó trùng giá trị với field và
   khiến light/dark dùng chung một màu accent — bug sẵn có. Thay bằng danh sách của instance:

```dart
List<Color> get accents => [rose, peach, butter, mint, sky, violet];
List<Color> get accentInks => [roseInk, peachInk, butterInk, mintInk, skyInk, violetInk];
Color accentForCategory(Object key) =>
    accents[(key.hashCode & 0x7FFFFFFF) % accents.length];
```

2. **Ramp mức chi** (mục 7) là method của palette để ngưỡng tập trung một chỗ:

```dart
/// t = giá trị / mốc tham chiếu. Bậc: [0,.25) [.25,.5) [.5,.75) [.75,∞)
int spendBand(double t) => t < 0.25 ? 0 : t < 0.5 ? 1 : t < 0.75 ? 2 : 3;
Color rampFill(double t) => [sky, mint, butter, rose][spendBand(t)];
Color rampInk(double t) => [skyInk, mintInk, butterInk, roseInk][spendBand(t)];
String rampLabel(double t) => const ['Thấp', 'Vừa', 'Cao', 'Vượt mức'][spendBand(t)];
```

3. **`copyWith`/`lerp`** phải thêm đủ 3 field mới (`violet`, `violetInk`, `star`), nếu
   thiếu thì `lerp` giữa hai theme sẽ quăng `NoSuchMethodError` lúc animate theme.

`priorityColor/priorityInk` (4 mức ưu tiên) chuyển sang dùng `accentAt(i)`/`accentInkAt(i)`
trên `accents` để không hardcode màu lần nữa.

## 5. Nền sao vũ trụ (`PixelStarField`)

- **Chỉ theme dark.** Light kem không sao (đã chốt mục 7): chấm trắng trên giấy ra bụi,
  chấm tối ra vết bẩn.
- **Chỉ dấu chấm**, bỏ hình dấu cộng: 62% ô 2 px opacity .55, 38% ô 4 px opacity .8;
  ~6% số ô nhuốm `#FFE45C`. Mật độ sinh 1 ô / 3.600 px².
- Vị trí theo seed cố định (`Random(20261102)`, LCG như board) → không nhảy khi `setState`;
  chỉ sinh lại khi `Size` đổi.
- Một ô bị bỏ nếu tâm của nó rơi vào keep-out rect nở thêm 4 px.
- Layer: `CustomPaint` + `RepaintBoundary` + `IgnorePointer`, là con đầu tiên của `Stack`
  trong scaffold pixel; panel có nền đặc nên sao sau lưng tự bị che, không cần tính.
- Nhấp nháy: ~12% số ô, `steps(2)`, 1,4 s, delay ngẫu nhiên theo seed.

**Keep-out là cơ chế nào.** Trong board, keep-out đo từ DOM. Trong Flutter, dùng registry
tối giản (~60 dòng) và **opt-in tại các chỗ chữ nằm trực tiếp trên canvas**:

```dart
// lib/widgets/pixel/pixel_star_field.dart
class KeepOutRegistry extends ChangeNotifier {
  void report(Object id, Rect? rect);   // rect == null → gỡ
  List<Rect> get rects;                   // chỉ notify khi tập rect thật sự đổi
}
class PixelStarSafe extends StatefulWidget { ... } // đo paint bounds sau layout, báo lên registry
```

`PixelStarSafe` được bọc quanh: tiêu đề `PixelScreenHeader`, `pixelGroupHeader(...)`,
HUD trên `feed_hud.dart`, dòng hint của khung chụp, và `PixelStatTile` không nằm trong
panel. Tổng cộng 6 điểm gọi — không làm cố gắng che mọi `Text` trong app.

Tắt: `MediaQuery.disableAnimations` → sao tĩnh; Settings "Nền sao" → không vẽ layer.

## 6. Vệt cầu vồng dưới header (`RainbowRule`)

`SizedBox(height: 5)` + `CustomPaint` vẽ 6 `drawRect` màu `accents`, chạy ngang trong
1,6 s với `steps(14)`. Đặt dưới `PixelScreenHeader` (mọi màn section), trên splash, và
**trên cả nền sao** vì header không có panel mờ. `disableAnimations` hoặc Settings tắt →
dải tĩnh. Một `AnimationController` dùng chung, không rebuild toàn màn.

## 7. Biểu đồ và progress tô theo mức chi

`t = giá trị / mốc tham chiếu`; **mốc tham chiếu mặc định = theo kỳ đang xem** (đã chốt
mục 9), riêng progress ngân sách luôn dùng hạn mức. Bậc màu: dương → lá → vàng → đỏ
(a5, a4, a3, a1); bản deep cho thanh mảnh/legend/chữ.

Widget đổi (giữ nguyên public API, chỉ đổi nguồn màu và thêm tham số tuỳ chọn):

| File | Thay đổi |
|---|---|
| `pixel_bar_chart.dart` | `barColor` thay bằng `rampFill(t)` theo từng cột; thêm `double? reference` |
| `pixel_stacked_share.dart` | block dùng `rampFill(t)` của *từng nhóm*, `colors` vẫn nhận override cho caller cũ |
| `pixel_share_bar.dart` | thôi tự gọi `accentForCategory`; thêm `useSpendRamp` (mặc định true) |
| `pixel_progress.dart` | `fillColor` = `rampFill(value)`; quá hạn mức → `rose` + nhãn "Vượt mức" |
| `statistics_charts.dart` | truyền `reference` = max của kỳ đang xem |
| `budget_progress_card.dart`, `budget_screen.dart` | `reference` = hạn mức kỳ đó |

**Không chỉ dựa vào màu:** mọi block/legend giữ nhãn số (`valueTexts`) và `rampLabel(t)`;
`danger #B3261E` / `warning #FFA53D` vẫn dành riêng cho lỗi hệ thống và cảnh báo hạn mức,
không lẫn với đỏ của bậc chi tiêu.

## 8. Chuyển cảnh sau khi bấm chụp — `RainbowSweep` (phương án B đã chọn)

```dart
// lib/widgets/pixel/rainbow_sweep.dart
class RainbowSweep {
  static Future<void> play(BuildContext context, {required VoidCallback onCovered});
}
```

- Một `Overlay` entry chứa `CustomPaint` vẽ dải 6 ô, hình bình hành `skewX(-12°)`,
  rộng 170% khung (đủ để phần lệch skew vẫn che kín 4 góc — đã nghiệm trên mockup),
  cao 148%.
- 8 bậc theo danh sách vị trí `[-150, -95, -40, 0, 0, 40, 95, 150] %`, 82 ms/bậc, tổng
  660 ms. **Bậc 4–5 che kín 100% trong 165 ms** → `onCovered` chạy ở đầu bậc 4, nên nội
  dung đổi mà mắt không thấy giật.
- `disableAnimations` → 2 bậc, ~220 ms, vẫn gọi `onCovered` đúng một lần.
- Điểm nối: `camera_screen.dart:_takePicture` (dòng ~140) — sau khi có `imagePath`, chạy
  `RainbowSweep.play(context, onCovered: () => _openExpenseForm(imagePath: imagePath))`.
  `onCovered` phải guard bằng cờ để không mở sheet hai lần.
- Không dùng `Gradient` cho dải: 6 `drawRect` màu phẳng, đúng chất pixel.

## 9. Confetti khi lưu và mosaic khi chuyển section

- `PixelConfetti.burst(context)` (file mới): **một** `CustomPaint` + `RepaintBoundary` vẽ
  24 ô 4×4 px bay lên rồi rơi theo bậc nguyên, 480 ms, `IgnorePointer`. Gọi sau khi lưu
  khoản chi thành công (form sheet và màn thêm thủ công). Không tạo 24 widget riêng lẻ.
- `MosaicWipe` (file mới): lưới 8×14 ô phủ `surface`/`canvas`, lật theo thứ tự seeded
  260 ms, chạy khi `_selectSection` đổi `AppSection`; thay cho `AnimatedSwitcher` 160 ms
  ở `main_screen.dart:93`. `disableAnimations` → cắt 2 bước. Settings mặc định **tắt** để
  thử dần (khớp mock Settings trên board).

## 10. Điều hướng: tab bar đáy

`PixelTabBar` 4 mục (CHỤP · SỔ · BIỂU · NGÂN) gắn vào `Scaffold.bottomNavigationBar`.
Icon lấy từ registry glyph **đã có** (`lib/core/icons/pixel_glyph_data.dart`, 44 key) qua
`AppIcon`: `camera`, `receipt`, `chart`, `wallet` — không phải vẽ glyph mới. Mục đang chọn
nền `butter` + ink `onAccent`; mỗi mục vẫn có `Semantics(selected: true)` vì màu không đủ.
`AppDrawer` giữ nguyên cho DANH MỤC · THÙNG RÁC · CÀI ĐẶT · theme · logout, nên
`onMenuTap` ở 4 screen không phải xoá. `AppSection` không đổi. Safe area: `padding:
MediaQuery.paddingOf(context).bottom` tô cùng nền tab bar.

## 11. Khoá Settings

`app_settings` (SQLite, giá trị kiểu `String`) thêm 6 key, lưu `'true'/'false'` như cách
`onboarding_complete` đang làm:

| Key | Mặc định | Tác dụng |
|---|---|---|
| `fx_stars` | true | nền sao dark |
| `fx_rainbow_rule` | true | dải dưới header |
| `fx_capture_sweep` | true | RainbowSweep sau chụp |
| `fx_confetti` | true | confetti khi lưu |
| `fx_mosaic` | **false** | mosaic khi chuyển section |
| `chart_spend_ramp` | true | biểu đồ tô theo mức chi |

Cần thêm `AppSettingsRepository.getBool(key, {fallback})` / `setBool` và một
`effectsProvider` (`EffectSettings` bất biến + notifier) để widget đọc bằng
`ref.watch(effectsProvider).stars`. Nhóm UI mới trong `settings_screen.dart` dùng
`pixelGroupHeader('GIAO DIỆN & HIỆU ỨNG')` theo đúng khuôn `_ThemeRow` hiện có.

## 12. Tương phản (số đo thật, WCAG 2.1 relative luminance)

Đã đo từng cặp bằng đúng hàm `luminance`/`contrast` trong
`test/unit/app_palette_contrast_test.dart` (không ước lượng):

| Cặp | Số đo | Kết luận |
|---|---|---|
| bright a1..a6 trên dark canvas `#0E2A4F` | 5,17 · 8,06 · 11,65 · 9,02 · 6,76 · 6,57 | đạt 3:1 (block) và 4,5:1 |
| bright a1..a6 trên light canvas `#FFF6E3` | 2,82 · 1,83 · 1,18 · 1,67 · 2,19 · 2,52 | **không đạt** → bắt buộc viền ink |
| `onAccent #1B140E` trên 6 accent light | 6,02 · 9,28 · 14,31 · 10,15 · 7,72 · 6,72 | đạt |
| `onAccent #1B140E` trên 6 accent dark | 6,56 · 10,23 · 14,78 · 11,45 · 8,58 · 8,34 | đạt (onAccent giữ `#1B140E` ở cả hai theme) |
| deep d1..d6 trên light canvas | 5,44 · 5,76 · 4,72 · 6,11 · 7,97 · 8,42 | đạt, dùng cho thanh mảnh/legend/chữ |
| bright làm **chữ nhỏ** trên dark surface `#16396A` | rose **4,14** · peach 6,45 · butter 9,33 · mint 7,22 · sky 5,41 · violet 5,26 | riêng `rose #FF6B6B` trượt 4,5 → chữ màu đỏ trên panel đêm phải dùng `roseInk #F7B7C0` (6,83) |
| tint `*Ink` dark trên dark surface | 6,83 · 8,00 · 9,43 · 8,11 · 8,54 · 7,39 | đạt, không cần đổi tint dark hiện có |
| viền ink `#1B140E` trên light canvas | 16,95 | đạt 3:1 cho đường phi-text |
| dark `ink` / `inkMuted` | canvas 13,43 / 7,95 · surface 10,75 / 6,37 · surfaceAlt 8,35 / 4,94 | đạt; `inkMuted` trên `surfaceAlt` sát ngưỡng → ưu tiên `ink` cho chữ nhỏ ở panel phụ |
| light `ink` / `inkMuted` | canvas 14,66 / 5,73 · surface 15,47 / 6,05 · surfaceAlt 14,10 / 5,51 | đạt |
| `danger` | `#B3261E` trên kem 6,08 · `#FF8A7A` trên nền đêm 6,27 / 5,02 (surface) | đạt |
| `star #FFFFFF` trên dark canvas | 14,36 | đạt 3:1; sao là trang trí, không phải token chữ |

Ba quy tắc cứng rút ra từ bảng trên:

1. Block bao giờ cũng có **viền ink 2 px** (`#1B140E` trên kem = 16,95:1) để tách khỏi nền.
2. Thanh mảnh < 8 px, legend và **chữ màu** → dùng bản `*Ink` (deep trên kem, tint trên đêm),
   không dùng bao giờ dùng bright làm chữ nhỏ — ngoại lệ trượt duy nhất là `rose` trên đêm.
3. Giá trị luôn in kèm số (`1.216.000 ₫`, `78%`) và `rampLabel` (`Thấp`/`Vừa`/`Cao`/
   `Vượt mức`), màu không mang nghĩa một mình (WCAG 1.4.1).

## 13. Test

- Mở rộng `test/unit/app_palette_contrast_test.dart`: bảng số ở mục 12, và assert
  `accents.length == 6`, light/dark không còn dùng chung `_accents`.
- `test/unit/spend_ramp_test.dart`: ngưỡng 0 / 0,249 / 0,25 / 0,5 / 0,75 / 1 / 1,4 cho đúng
  bậc; `rampLabel` có chuỗi tiếng Việt; `t` âm → bậc 0.
- `test/widget/pixel_star_field_test.dart`: cùng seed ra cùng vị trí; mọi ô được sinh đều
  **không** giao keep-out rect đã báo cáo; `disableAnimations` → không có `AnimationController` chạy.
- `test/widget/rainbow_sweep_test.dart`: `onCovered` chạy đúng 1 lần và rơi vào bậc 4–5;
  overlay bị gỡ sau 740 ms; `disableAnimations` vẫn hoàn tất.
- `test/widget/pixel_logo_test.dart`: lưới 24 và 16 cùng số hàng/cột như khai báo; `mono`
  chỉ dùng ink; `size` lẻ làm tròn xuống bội số 8.
- `test/widget/pixel_tab_bar_test.dart`: 4 mục, đổi tab gọi `_selectSection` một lần,
  drawer vẫn mở được bằng nút menu.
- `test/widget/settings_effects_test.dart`: 6 key đọc/ghi đúng qua repository thật.
- `legacy_cleanup_test.dart` vẫn phải xanh (không thêm `Icons.`, không xoá file trong
  danh sách gate). Khi bump 2.3.0+4 ở giai đoạn 4 thì **sửa luôn gate version** ở dòng 71-77.

## 14. Các quyết định đã chốt

| # | Quyết định |
|---|---|
| 1 | Logo chính = phương án A (thân máy + ống kính), lưới 24 brand / 16 glyph |
| 2 | Polaroid (B) làm mark phụ cho màn chụp + empty state |
| 3 | Wordmark: gạch cầu vồng, không tô từng chữ |
| 4 | Thêm tab bar đáy, giữ drawer cho action phụ |
| 5 | Dark = xanh vũ trụ, Light = kem + deep accent |
| 6 | Chạy đủ 4 giai đoạn |
| 7 | Nền sao chỉ theme tối |
| 8 | Ramp light: bright + viền ink 2 px, deep cho thanh mảnh/legend/chữ |
| 9 | Mốc tham chiếu biểu đồ = theo kỳ đang xem; progress ngân sách = hạn mức |
| 10 | **Chuyển cảnh sau chụp = B (cầu vồng quét ngang)** |
| 11 | **Bậc 3 của dải mức chi = vàng `#FFE45C`** |

## 15. Kế hoạch 4 giai đoạn

| G | Nội dung | File chính |
|---|---|---|
| 1 | Token + logo + ramp API | `app_palette.dart`, `app_theme.dart`, `pixel_logo.dart`, `test/tool/launcher_icons_test.dart`, mipmaps |
| 2 | Nền sao + vệt cầu vồng + khoá Settings | `pixel_star_field.dart`, `rainbow_rule.dart`, `pixel_screen_header.dart`, `app_settings_repository.dart`, `app_settings_provider.dart`, `settings_screen.dart` |
| 3 | Tab bar đáy + mark trên header | `pixel_tab_bar.dart`, `main_screen.dart`, `app.dart`, 4 screen |
| 4 | Biểu đồ theo mức chi + RainbowSweep + confetti + mosaic + bump 2.3.0+4 + docs | 6 widget chart/progress, `statistics_charts.dart`, `budget_*`, `camera_screen.dart`, `rainbow_sweep.dart`, `pixel_confetti.dart`, `mosaic_wipe.dart`, `README.md`, `docs/project-structure.md` |

Mỗi giai đoạn kết thúc bằng `flutter analyze` sạch + `flutter test` xanh rồi mới sang G kế.

## 16. Rủi ro và điều chưa kiểm chứng được

- **Chưa có thiết bị.** App chỉ build APK qua GitHub Actions, Supabase free tier đang tạm
  dừng, nên rung/chuyển động mới chỉ được xác minh bằng mockup + số đo khung hình; cảm
  giác thật cần bạn cài APK thử sau G2 và G4.
- **Keep-out có thể thiếu điểm.** Danh sách 6 điểm `PixelStarSafe` là liệt kê thủ công; nếu
  còn chỗ nào chữ nằm trên canvas mà chưa bọc, sao sẽ ló sau chữ — sửa bằng cách thêm một
  điểm bọc, không đổi cơ chế.
- **Đỏ của bậc chi tiêu gần `danger`.** Khác nhau ở ngữ cảnh và nhãn, nhưng nếu bạn thấy
  lẫn thì bậc 4 đổi sang cam `#FFA53D` chỉ là một dòng trong `rampFill`.
- **Thay `AnimatedSwitcher` bằng mosaic** chạm transition toàn app; nếu nó gây khó chịu thì
  khoá `fx_mosaic` mặc định false đã là van an toàn sẵn có.
- **Bump version** bắt buộc sửa gate test cũ, nếu quên thì CI đỏ ở job `quality`.
