# Pixket Brand — Kế hoạch thực thi Giai đoạn 2–4

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn tất phần còn lại của spec brand pixel: nền sao vũ trụ + khoá Settings (G2), tab bar đáy + mark trên header (G3), biểu đồ theo mức chi + 3 chuyển cảnh + bump version + docs (G4).

**Architecture:** Mọi hiệu ứng là widget `CustomPaint` bậc rời đặt trong `Overlay`/`Stack`, đọc bật/tắt qua một `effectsProvider` Riverpod duy nhất backed bởi bảng `app_settings` SQLite sẵn có. Nền sao đặt MỘT lần trong `Stack` của `MainScreen`; ba Scaffold section chuyển sang nền trong suốt để sao ló ra giữa các panel đục.

**Tech Stack:** Flutter 3.47 / Dart 3.13, Riverpod 2.6, sqflite, `flutter_test` (không thêm dependency mới).

**Spec:** `docs/superpowers/specs/2026-11-02-pixket-nyan-pixel-brand-design.md` — kế hoạch này luận chứng từ spec; đọc cả hai trước khi làm.

## Global Constraints

- Không thêm dependency mới; không đổi schema DB/Supabase; không đổi tên app hay `AppInfo.tagline`.
- Không dùng `Icons.` của Material, không `Gradient` cho dải cầu vồng (6 `drawRect` màu phẳng), mọi pixel paint với `isAntiAlias: false`.
- Chữ màu nhỏ luôn dùng bản `*Ink`; block bright bắt buộc viền ink 2 px; giá trị luôn in kèm số và `rampLabel` (WCAG 1.4.1).
- Mọi hiệu ứng tôn trọng `MediaQuery.disableAnimations` (bậc giảm, vẫn hoàn tất và vẫn gọi callback đúng một lần) và khoá Settings tương ứng.
- `flutter` không nằm trong PATH của Git Bash: mọi lệnh chạy sau `export PATH="$PATH:/c/flutter/bin"`.
- **Không commit/push trừ khi người dùng yêu cầu rõ ràng lúc thực thi.** Mỗi task kết thúc bằng `flutter analyze` sạch + `flutter test` xanh; bước "Commit" trong template được thay bằng bước kiểm tra này.
- `test/widget/legacy_cleanup_test.dart` phải luôn xanh; ở Task 16 mới được sửa gate version (dòng 71–77).

## Ghi chú phạm vi

**Mark phụ polaroid (phương án B): ĐÃ QUYẾT — bỏ qua, không thực thi trong kế hoạch
này** (người dùng chốt ngày 2026-11-02). Spec §3 (dòng 83–84) và bảng quyết định #2
(dòng 322) có nêu polaroid làm mark phụ cho empty-state và khung hướng dẫn màn chụp,
kích thước 16, không xuất hiện ở header — nhưng bảng giai đoạn §15 không giao nó cho
G2/G3/G4, và `buildLogoGrid` hiện chỉ dựng thân máy + ống kính nên không có sẵn lưới
polaroid. `PixelEmptyState` và khung hướng dẫn `camera_screen.dart` giữ nguyên. Nếu sau
này muốn làm: thêm một task sau Task 8 dựng `PixelPolaroidMark` (size 16) rồi gắn vào
hai chỗ đó — đừng hỏi lại, cứ coi đây là phạm vi đã chốt trừ khi người dùng đổi ý.

---

## Giai đoạn 2 — Nền sao + RainbowRule + khoá Settings

### Task 1: `getBool/setBool` + `EffectSettings` + `effectsProvider`

**Files:**
- Modify: `lib/data/repositories/app_settings_repository.dart`
- Modify: `lib/providers/app_settings_provider.dart`
- Create: `test/support/memory_settings.dart` (fake repository dùng chung cho mọi test từ Task 1 trở đi)
- Test: `test/unit/effects_settings_test.dart` (mới)

**Interfaces:**
- Produces: `AppSettingsRepository.getBool(String key, {required bool fallback}) -> Future<bool>`, `setBool(String key, bool value) -> Future<void>`; class `EffectSettings` với 6 field bool `stars, rainbowRule, captureSweep, confetti, mosaic, chartSpendRamp`; `EffectSettingsNotifier extends StateNotifier<EffectSettings>` với `Future<void> set(String key, bool value)`; `final effectsProvider = StateNotifierProvider<EffectSettingsNotifier, EffectSettings>`; class test `MemorySettingsRepository` với field `Map<String, String> store`.

- [x] **Step 1: Viết test thất bại**

Repo không có `sqflite_common_ffi` và `DatabaseHelper` không chạy được trong
`flutter test` (MissingPluginException), nên test subclass `AppSettingsRepository`
bằng một map trong bộ nhớ: vẫn chạy đúng code `getBool/setBool` thật mà không thêm
dev-dependency. File này nằm ở `test/support/` để Task 2–16 dùng lại, không nhân
bản fake trong từng test.

`test/support/memory_settings.dart`:

```dart
import 'package:pixket/data/repositories/app_settings_repository.dart';

/// Repository trong bộ nhớ cho test: chạy đúng code getBool/setString thật
/// mà không chạm sqflite (DatabaseHelper không chạy được trong flutter_test).
class MemorySettingsRepository extends AppSettingsRepository {
  final Map<String, String> store = {};

  @override
  Future<String?> getString(String key) async => store[key];

  @override
  Future<void> setString(String key, String value) async =>
      store[key] = value;
}
```

`test/unit/effects_settings_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/data/repositories/app_settings_repository.dart';
import 'package:pixket/providers/app_settings_provider.dart';

import '../support/memory_settings.dart';

/// Repository luôn ném: kiểm chứng nhánh fallback của `_load`/`set`.
class _BrokenSettings extends AppSettingsRepository {
  @override
  Future<String?> getString(String key) async => throw StateError('db hỏng');

  @override
  Future<void> setString(String key, String value) async =>
      throw StateError('db hỏng');
}

void main() {
  test('getBool/setBool round-trip và fallback', () async {
    final repo = MemorySettingsRepository();
    expect(await repo.getBool('k', fallback: true), isTrue);
    await repo.setBool('k', false);
    expect(await repo.getBool('k', fallback: true), isFalse);
    await repo.setBool('k', true);
    expect(await repo.getBool('k', fallback: false), isTrue);
  });

  test('6 key hiệu ứng đọc/ghi đúng qua repository', () async {
    final repo = MemorySettingsRepository();
    final notifier = EffectSettingsNotifier(repository: repo);
    await notifier.loadComplete;

    // Mặc định spec §11: chỉ mosaic tắt.
    expect(notifier.state.stars, isTrue);
    expect(notifier.state.rainbowRule, isTrue);
    expect(notifier.state.captureSweep, isTrue);
    expect(notifier.state.confetti, isTrue);
    expect(notifier.state.mosaic, isFalse);
    expect(notifier.state.chartSpendRamp, isTrue);

    await notifier.set('fx_stars', false);
    expect(notifier.state.stars, isFalse);
    expect(repo.store['fx_stars'], 'false');

    final again = EffectSettingsNotifier(repository: repo);
    await again.loadComplete;
    expect(again.state.stars, isFalse, reason: 'giá trị phải bền qua phiên');
  });

  test('repository lỗi thì về mặc định và không ném', () async {
    final notifier = EffectSettingsNotifier(repository: _BrokenSettings());
    await notifier.loadComplete;
    expect(notifier.state.stars, isTrue);
    expect(notifier.state.mosaic, isFalse);

    await notifier.set('fx_stars', false);
    expect(notifier.state.stars, isFalse, reason: 'UI vẫn đổi dù ghi hỏng');
    // Không cần assert "không có lỗi unhandled": nếu _load/set để lọt Future
    // lỗi thì flutter_test tự làm đỏ test này.
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/unit/effects_settings_test.dart`
Expected: FAIL — `EffectSettingsNotifier` chưa tồn tại.

- [x] **Step 3: Hiện thực tối thiểu**

Thêm vào `app_settings_repository.dart`:

```dart
  Future<bool> getBool(String key, {required bool fallback}) async {
    final saved = await getString(key);
    if (saved == 'true') return true;
    if (saved == 'false') return false;
    return fallback;
  }

  Future<void> setBool(String key, bool value) =>
      setString(key, value ? 'true' : 'false');
```

Thêm vào `app_settings_provider.dart`:

```dart
class EffectSettings {
  final bool stars, rainbowRule, captureSweep, confetti, mosaic, chartSpendRamp;

  const EffectSettings({
    this.stars = true,
    this.rainbowRule = true,
    this.captureSweep = true,
    this.confetti = true,
    this.mosaic = false,
    this.chartSpendRamp = true,
  });

  EffectSettings copyWith({
    bool? stars,
    bool? rainbowRule,
    bool? captureSweep,
    bool? confetti,
    bool? mosaic,
    bool? chartSpendRamp,
  }) => EffectSettings(
    stars: stars ?? this.stars,
    rainbowRule: rainbowRule ?? this.rainbowRule,
    captureSweep: captureSweep ?? this.captureSweep,
    confetti: confetti ?? this.confetti,
    mosaic: mosaic ?? this.mosaic,
    chartSpendRamp: chartSpendRamp ?? this.chartSpendRamp,
  );
}

class EffectSettingsNotifier extends StateNotifier<EffectSettings> {
  EffectSettingsNotifier({AppSettingsRepository? repository})
    : _repository = repository ?? AppSettingsRepository(),
      super(const EffectSettings()) {
    _load().then((loaded) {
      if (mounted) state = loaded;
      _loadCompleter.complete();
    });
  }

  final AppSettingsRepository _repository;
  final Completer<void> _loadCompleter = Completer<void>();
  Future<void> get loadComplete => _loadCompleter.future;

  static const _keys = (
    stars: 'fx_stars',
    rainbowRule: 'fx_rainbow_rule',
    captureSweep: 'fx_capture_sweep',
    confetti: 'fx_confetti',
    mosaic: 'fx_mosaic',
    chartSpendRamp: 'chart_spend_ramp',
  );

  Future<EffectSettings> _load() async {
    // Không catch ở đây thì mọi test widget pump màn có PixelScreenHeader
    // (→ RainbowRule → effectsProvider) sẽ dính MissingPluginException của
    // sqflite; trên máy thật thì DB lỗi cũng chỉ nên về mặc định, không crash.
    try {
      final s = await _repository.getBool(_keys.stars, fallback: true);
      final r = await _repository.getBool(_keys.rainbowRule, fallback: true);
      final c = await _repository.getBool(_keys.captureSweep, fallback: true);
      final f = await _repository.getBool(_keys.confetti, fallback: true);
      final m = await _repository.getBool(_keys.mosaic, fallback: false);
      final g = await _repository.getBool(_keys.chartSpendRamp, fallback: true);
      return EffectSettings(
        stars: s,
        rainbowRule: r,
        captureSweep: c,
        confetti: f,
        mosaic: m,
        chartSpendRamp: g,
      );
    } catch (error) {
      debugPrint('Không đọc được khoá hiệu ứng, dùng mặc định: $error');
      return const EffectSettings();
    }
  }

  Future<void> set(String key, bool value) async {
    try {
      await _repository.setBool(key, value);
    } catch (error) {
      // Vẫn đổi state: khoá là cosmetic, UI phải phản hồi dù ghi DB hỏng.
      debugPrint('Không lưu được khoá hiệu ứng $key: $error');
    }
    final s = state;
    state = s.copyWith(
      stars: key == _keys.stars ? value : null,
      rainbowRule: key == _keys.rainbowRule ? value : null,
      captureSweep: key == _keys.captureSweep ? value : null,
      confetti: key == _keys.confetti ? value : null,
      mosaic: key == _keys.mosaic ? value : null,
      chartSpendRamp: key == _keys.chartSpendRamp ? value : null,
    );
  }
}

final effectsProvider =
    StateNotifierProvider<EffectSettingsNotifier, EffectSettings>(
      (ref) => EffectSettingsNotifier(),
    );
```

Cần `import 'dart:async';` (Completer) và `import 'package:flutter/foundation.dart';`
(debugPrint) ở đầu `app_settings_provider.dart`.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/unit/effects_settings_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 2: Nhóm "GIAO DIỆN & HIỆU ỨNG" trong Settings

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`
- Test: `test/widget/settings_effects_test.dart` (mới)

**Interfaces:**
- Consumes: `effectsProvider`, `EffectSettingsNotifier.set`, `MemorySettingsRepository` từ Task 1; `pixelGroupHeader`, `PixelChip`, `PixelPanel`, `AppIcon` sẵn có.

Không phải sửa `test/widget/trash_settings_pixel_test.dart` hay
`test/widget/screens_test.dart`: hai test này pump `SettingsScreen` mà không
override `effectsProvider`, nhưng `_load()` của Task 1 đã catch lỗi sqflite và
về mặc định, nên 6 hàng mới hiện với trạng thái mặc định và các assertion cũ
(4 nhóm nhãn, `darkModeToggle`) vẫn đúng.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/providers/auth_provider.dart';
import 'package:pixket/providers/theme_provider.dart';
import 'package:pixket/screens/settings/settings_screen.dart';

import '../support/memory_settings.dart';

// Cùng khuôn fake với test/widget/trash_settings_pixel_test.dart: SettingsScreen
// watch authProvider + themeProvider, cả hai đều chạm DB nếu để thật.
// effectsProvider cũng phải override: notifier thật gọi AppSettingsRepository
// (sqflite) ngay trong constructor → MissingPluginException khi test.
class _FakeAuth extends StateNotifier<AppAuthState> implements AuthNotifier {
  _FakeAuth() : super(const AppAuthState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTheme extends StateNotifier<ThemeMode> implements ThemeNotifier {
  _FakeTheme() : super(ThemeMode.light);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Text _chipLabel(WidgetTester tester, String key) =>
    tester.widgetList<Text>(find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(Text),
    )).single;

void main() {
  testWidgets('6 khoá hiệu ứng đọc/ghi qua provider', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuth()),
        themeProvider.overrideWith((ref) => _FakeTheme()),
        effectsProvider.overrideWith(
          () => EffectSettingsNotifier(repository: MemorySettingsRepository()),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('GIAO DIỆN & HIỆU ỨNG'), findsOneWidget);
    for (final label in [
      'Nền sao (chế độ tối)',
      'Vệt cầu vồng dưới header',
      'Cầu vồng quét khi chụp',
      'Pháo giấy khi lưu',
      'Lật mosaic khi đổi mục',
      'Biểu đồ tô theo mức chi',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'thiếu khoá $label');
    }

    // mosaic mặc định TẮT, năm khoá còn lại BẬT.
    expect(_chipLabel(tester, 'fx_mosaic').data, 'TẮT');
    expect(_chipLabel(tester, 'fx_stars').data, 'BẬT');

    await tester.tap(find.byKey(const ValueKey('fx_mosaic')));
    await tester.pumpAndSettle();
    expect(_chipLabel(tester, 'fx_mosaic').data, 'BẬT');
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/settings_effects_test.dart`
Expected: FAIL — chưa có nhóm UI.

- [x] **Step 3: Hiện thực**

Trong `settings_screen.dart`, chèn vào `Column` của `SingleChildScrollView` ngay sau `_ThemeRow(isDarkMode: isDarkMode),`:

```dart
                  pixelGroupHeader('GIAO DIỆN & HIỆU ỨNG'),
                  const _EffectRow(
                    settingKey: 'fx_stars',
                    glyph: 'sparkle',
                    label: 'Nền sao (chế độ tối)',
                    hint: 'Chấm sao nhấp nháy trên nền đêm',
                  ),
                  const _EffectRow(
                    settingKey: 'fx_rainbow_rule',
                    glyph: 'grid',
                    label: 'Vệt cầu vồng dưới header',
                    hint: 'Dải 6 màu chạy ngang đầu màn hình',
                  ),
                  const _EffectRow(
                    settingKey: 'fx_capture_sweep',
                    glyph: 'camera',
                    label: 'Cầu vồng quét khi chụp',
                    hint: 'Chuyển cảnh sau khi bấm chụp',
                  ),
                  const _EffectRow(
                    settingKey: 'fx_confetti',
                    glyph: 'gift',
                    label: 'Pháo giấy khi lưu',
                    hint: '24 ô bay lên khi lưu khoản chi',
                  ),
                  const _EffectRow(
                    settingKey: 'fx_mosaic',
                    glyph: 'grid',
                    label: 'Lật mosaic khi đổi mục',
                    hint: 'Lưới ô lật khi chuyển tab',
                  ),
                  const _EffectRow(
                    settingKey: 'chart_spend_ramp',
                    glyph: 'chart',
                    label: 'Biểu đồ tô theo mức chi',
                    hint: 'Tắt để tô theo danh mục như cũ',
                  ),
```

và thêm class cuối file, theo đúng khuôn `_ThemeRow`:

```dart
class _EffectRow extends ConsumerWidget {
  final String settingKey;
  final String glyph;
  final String label;
  final String hint;

  const _EffectRow({
    required this.settingKey,
    required this.glyph,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final effects = ref.watch(effectsProvider);
    final on = switch (settingKey) {
      'fx_stars' => effects.stars,
      'fx_rainbow_rule' => effects.rainbowRule,
      'fx_capture_sweep' => effects.captureSweep,
      'fx_confetti' => effects.confetti,
      'fx_mosaic' => effects.mosaic,
      _ => effects.chartSpendRamp,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PixelPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            AppIcon(name: glyph, size: 32, color: palette.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    hint,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ),
            ),
            PixelChip(
              key: ValueKey(settingKey),
              label: on ? 'BẬT' : 'TẮT',
              icon: on ? 'check' : 'close',
              selected: on,
              showCheck: false,
              onTap: () =>
                  ref.read(effectsProvider.notifier).set(settingKey, !on),
            ),
          ],
        ),
      ),
    );
  }
}
```

Lưu ý: chỉ `PixelChip` mang `ValueKey(settingKey)`, `_EffectRow` không nhận key —
nếu cả hai cùng key thì `find.byKey` trả 2 widget và test `_chipLabel` vỡ. Chữ ký
`PixelChip` (`label/icon/selected/showCheck/onTap`, đã dùng ở `_ThemeRow`) xem tại
`lib/widgets/pixel/pixel_chip.dart`; chip chỉ có đúng một `Text` nên `.single` an toàn.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/settings_effects_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 3: `pixel_star_field.dart` — registry keep-out + nền sao

**Files:**
- Create: `lib/widgets/pixel/pixel_star_field.dart`
- Test: `test/widget/pixel_star_field_test.dart` (mới)

**Interfaces:**
- Consumes: `effectsProvider` (Task 1), `MemorySettingsRepository` (Task 1), token `star`/`ink` của `AppPalette`.
- Produces: `KeepOutRegistry` (`report(Object id, Rect? rect)`, `List<Rect> rects`), `keepOutRegistryProvider`, `PixelStarSafe({required Widget child, Object? id})`, `PixelStarField()`, `List<PixelStar> buildStarField(Size size)`, `bool starKeptOut(Offset center, Iterable<Rect> rects)`.

- [x] **Step 1: Viết test thất bại**

`test/widget/pixel_star_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/pixel_star_field.dart';

import '../support/memory_settings.dart';

Widget _host({bool dark = true, bool disableAnimations = false}) =>
    ProviderScope(
      overrides: [
        effectsProvider.overrideWith(
          () => EffectSettingsNotifier(repository: MemorySettingsRepository()),
        ),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        // Builder + copyWith: `MediaQueryData(...)` dựng mới sẽ thay toàn bộ
        // MediaQuery (size/brightness/padding về mặc định). Chỉ sửa một cờ thì
        // dùng copyWith trên MediaQuery kế thừa.
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: disableAnimations,
            ),
            child: const Scaffold(
              body: SizedBox.expand(child: PixelStarField()),
            ),
          ),
        ),
      ),
    );

Finder _paint() => find.descendant(
  of: find.byType(PixelStarField),
  matching: find.byType(CustomPaint),
);

void main() {
  test('cùng seed ra cùng vị trí sao', () {
    const size = Size(360, 640);
    final a = buildStarField(size);
    final b = buildStarField(size);
    expect(a, isNotEmpty);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].x, b[i].x);
      expect(a[i].y, b[i].y);
      expect(a[i].cell, b[i].cell);
    }
  });

  test('mật độ 1 ô / 3600 px2', () {
    expect(
      buildStarField(const Size(360, 640)).length,
      (360 * 640 / 3600).round(),
    );
  });

  test('keep-out nở thêm 4 px', () {
    const rect = Rect.fromLTWH(10, 10, 20, 20);
    expect(starKeptOut(const Offset(31, 20), [rect]), isTrue);
    expect(starKeptOut(const Offset(35, 20), [rect]), isFalse);
  });

  testWidgets('theme light không vẽ sao', (tester) async {
    await tester.pumpWidget(_host(dark: false));
    await tester.pump();
    expect(_paint(), findsNothing);
  });

  testWidgets('disableAnimations thì không còn controller chạy', (tester) async {
    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pump();
    expect(_paint(), findsOneWidget, reason: 'sao vẫn vẽ, chỉ ngưng nhấp nháy');
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('dark vẽ sao và nhấp nháy', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();
    expect(_paint(), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isTrue);
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/pixel_star_field_test.dart`
Expected: FAIL — file widget chưa tồn tại.

- [x] **Step 3: Hiện thực**

`lib/widgets/pixel/pixel_star_field.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/app_settings_provider.dart';

/// Registry keep-out tối giản: widget chữ nằm trực tiếp trên canvas báo rect
/// paint (toạ độ global, đã nở 4 px) để nền sao bỏ các ô rơi vào đó.
class KeepOutRegistry extends ChangeNotifier {
  final Map<Object, Rect> _byId = {};

  List<Rect> get rects => _byId.values.toList(growable: false);

  void report(Object id, Rect? rect) {
    if (rect == null) {
      if (_byId.remove(id) != null) notifyListeners();
      return;
    }
    if (_byId[id] == rect) return;
    _byId[id] = rect;
    notifyListeners();
  }
}

final keepOutRegistryProvider = Provider<KeepOutRegistry>((ref) {
  final registry = KeepOutRegistry();
  ref.onDispose(registry.dispose);
  return registry;
});

class PixelStar {
  const PixelStar({
    required this.x,
    required this.y,
    required this.cell,
    required this.tinted,
    required this.twinkle,
    required this.delay,
  });

  final double x, y, delay;
  final double cell; // 2 hoặc 4 px
  final bool tinted, twinkle;

  double get opacity => cell == 2 ? 0.55 : 0.8;
}

/// Sinh sao thuần: seed cố định nên không nhảy khi setState; chỉ gọi lại khi
/// Size đổi. Mật độ 1 ô / 3600 px2; 62% ô 2 px, 38% ô 4 px; 6% nhuốm màu star;
/// 12% nhấp nháy.
List<PixelStar> buildStarField(Size size) {
  final random = math.Random(20261102);
  final count = (size.width * size.height / 3600).round();
  return [
    for (var i = 0; i < count; i++)
      PixelStar(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        cell: random.nextDouble() < 0.62 ? 2 : 4,
        tinted: random.nextDouble() < 0.06,
        twinkle: random.nextDouble() < 0.12,
        delay: random.nextDouble(),
      ),
  ];
}

bool starKeptOut(Offset center, Iterable<Rect> rects) =>
    rects.any((rect) => rect.contains(center));

/// Bọc một widget chữ nằm trực tiếp trên canvas để nền sao tránh rect của nó.
class PixelStarSafe extends ConsumerStatefulWidget {
  const PixelStarSafe({super.key, required this.child, this.id});

  final Widget child;
  final Object? id;

  @override
  ConsumerState<PixelStarSafe> createState() => _PixelStarSafeState();
}

class _PixelStarSafeState extends ConsumerState<PixelStarSafe> {
  late final Object _id = widget.id ?? this;

  @override
  void dispose() {
    ref.read(keepOutRegistryProvider).report(_id, null);
    super.dispose();
  }

  void _report() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;
      final topLeft = box.localToGlobal(Offset.zero);
      ref.read(keepOutRegistryProvider).report(
        _id,
        Rect.fromLTWH(
          topLeft.dx,
          topLeft.dy,
          box.size.width,
          box.size.height,
        ).inflate(4),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _report();
    return widget.child;
  }
}

/// Nền sao vũ trụ: chỉ theme dark và chỉ khi khoá `fx_stars` bật.
class PixelStarField extends ConsumerStatefulWidget {
  const PixelStarField({super.key});

  @override
  ConsumerState<PixelStarField> createState() => _PixelStarFieldState();
}

class _PixelStarFieldState extends ConsumerState<PixelStarField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  Size? _cachedSize;
  List<PixelStar> _stars = const [];

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = ref.watch(effectsProvider).stars;
    if (!isDark || !enabled) return const SizedBox.shrink();

    final still = MediaQuery.of(context).disableAnimations;
    if (still) {
      _twinkle.stop(canceled: false);
    } else if (!_twinkle.isAnimating) {
      _twinkle.repeat();
    }

    final registry = ref.watch(keepOutRegistryProvider);
    final box = context.findRenderObject() as RenderBox?;

    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            if (_cachedSize != size) {
              _cachedSize = size;
              _stars = buildStarField(size);
            }
            return ListenableBuilder(
              listenable: registry,
              builder: (context, _) => CustomPaint(
                painter: _StarPainter(
                  _stars,
                  registry,
                  context.palette,
                  box,
                  _twinkle,
                  still,
                ),
                repaint: still ? null : _twinkle,
                size: size,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(
    this.stars,
    this.registry,
    this.palette,
    this.box,
    this.twinkle,
    this.still,
  );

  final List<PixelStar> stars;
  final KeepOutRegistry registry;
  final AppPalette palette;
  final RenderBox? box;
  final Animation<double> twinkle;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = box?.attached == true
        ? box!.localToGlobal(Offset.zero)
        : Offset.zero;
    final keepOut = [for (final rect in registry.rects) rect.shift(-origin)];
    final paint = Paint()..isAntiAlias = false;

    for (final star in stars) {
      final center = Offset(star.x + star.cell / 2, star.y + star.cell / 2);
      if (starKeptOut(center, keepOut)) continue;
      var opacity = star.opacity;
      if (!still && star.twinkle) {
        // steps(2): nửa chu kỳ sáng, nửa chu kỳ mờ; delay riêng theo seed.
        if (((twinkle.value + star.delay) * 2).floor() % 2 == 1) {
          opacity *= 0.35;
        }
      }
      paint.color = (star.tinted ? palette.star : palette.ink).withValues(
        alpha: opacity,
      );
      canvas.drawRect(Rect.fromLTWH(star.x, star.y, star.cell, star.cell), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.stars != stars ||
      old.still != still ||
      old.twinkle.value != twinkle.value;
}
```

Ghi chú: sao trắng dùng `palette.ink` của dark (`#F2F8FF`) thay vì hardcode `#FFFFFF`; riêng 6% nhuốm `palette.star`. Spec §12 đo `star #FFFFFF` trên canvas đạt 14,36 — `#F2F8FF` sáng tương đương và giữ được tính token.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/pixel_star_field_test.dart`
Expected: PASS (6 test).

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 4: `rainbow_rule.dart` — vệt cầu vồng dưới header

**Files:**
- Create: `lib/widgets/pixel/rainbow_rule.dart`
- Test: `test/widget/rainbow_rule_test.dart` (mới)

**Interfaces:**
- Consumes: `effectsProvider.rainbowRule`, `palette.accents`.
- Produces: `RainbowRule({double height = 5})`.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/rainbow_rule.dart';

import '../support/memory_settings.dart';

Widget _host({bool disableAnimations = false}) => ProviderScope(
  overrides: [
    effectsProvider.overrideWith(
      () => EffectSettingsNotifier(repository: MemorySettingsRepository()),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.dark,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
        ),
        child: const Scaffold(body: RainbowRule()),
      ),
    ),
  ),
);

void main() {
  testWidgets('cao đúng 5 px, chạy MỘT lượt 1,6 s rồi tĩnh', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();
    expect(tester.getSize(find.byType(RainbowRule)).height, 5);
    expect(tester.binding.hasScheduledFrame, isTrue);

    // Nếu dải loop vô hạn thì pumpAndSettle timeout ở đây — đó là lỗi, không
    // phải lý do để đổi sang tester.pump() cố định.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('disableAnimations thì dải tĩnh ngay', (tester) async {
    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/rainbow_rule_test.dart`
Expected: FAIL — widget chưa tồn tại.

- [x] **Step 3: Hiện thực**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/app_settings_provider.dart';

/// Gạch chân cầu vồng 6 ô trượt ngang 14 bậc rời trong 1,6 s; tĩnh khi tắt.
class RainbowRule extends ConsumerStatefulWidget {
  const RainbowRule({super.key, this.height = 5});

  final double height;

  @override
  ConsumerState<RainbowRule> createState() => _RainbowRuleState();
}

class _RainbowRuleState extends ConsumerState<RainbowRule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool _ran = false;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate =
        ref.watch(effectsProvider).rainbowRule &&
        !MediaQuery.of(context).disableAnimations;
    // Chạy MỘT lượt rồi nghỉ (spec §6: "chạy ngang trong 1,6 s"). Loop vô hạn
    // dưới mọi PixelScreenHeader sẽ làm `pumpAndSettle` của ~8 test cũ timeout
    // và tốn pin trên máy thật; bậc 14 kết thúc ở đúng vị trí dải tĩnh.
    if (animate && !_ran) {
      _ran = true;
      _slide.forward(from: 0);
    } else if (!animate && _slide.isAnimating) {
      _slide.stop(canceled: false);
    }

    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: _RainbowPainter(context.palette.accents, _slide, animate),
        repaint: animate ? _slide : null,
        size: Size.infinite,
      ),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  _RainbowPainter(this.accents, this.slide, this.animate);

  final List<Color> accents;
  final Animation<double> slide;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || accents.isEmpty) return;
    // Vẽ dải gấp đôi chiều rộng để phần trượt quấn vòng không để hở mép.
    final step = animate ? (slide.value * 14).floor() % 14 : 0;
    final shift = -(step / 14) * size.width;
    final band = size.width / accents.length;
    final paint = Paint()..isAntiAlias = false;
    for (var pass = 0; pass < 2; pass++) {
      for (var i = 0; i < accents.length; i++) {
        paint.color = accents[i];
        canvas.drawRect(
          Rect.fromLTWH(
            shift + pass * size.width + i * band,
            0,
            band + 0.2,
            size.height,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainbowPainter old) =>
      old.animate != animate || old.slide.value != slide.value;
}
```

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/rainbow_rule_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 5: Đấu nối — Stack sao ở MainScreen, Scaffold trong suốt, keep-out, RainbowRule dưới header

**Files:**
- Modify: `lib/widgets/pixel/pixel_screen_header.dart:32-70` (build trả về Column gồm Container hiện tại + `RainbowRule`)
- Modify: `lib/screens/main_screen.dart:77-99` (Scaffold thêm nền canvas; body thành Stack)
- Modify: `lib/screens/home/home_screen.dart:144`, `lib/screens/statistics/statistics_screen.dart:109`, `lib/screens/budget/budget_screen.dart:160` (nền trong suốt)
- Modify: `lib/screens/home/home_screen.dart:180-201, 234-257` (bọc `PixelStarSafe`)
- Modify: `lib/screens/onboarding/onboarding_screen.dart`, `lib/screens/auth/login_screen.dart` (RainbowRule dưới khối tiêu đề splash)
- Test: `test/widget/main_star_field_test.dart` (mới)

**Interfaces:**
- Consumes: `PixelStarField`, `PixelStarSafe`, `RainbowRule`, `keepOutRegistryProvider`.

Lý do Scaffold section phải trong suốt: cả ba đang đặt `backgroundColor: palette.canvas` đục nên sẽ che kín lớp sao đặt sau ở MainScreen. Camera giữ `feedBg` đục (tường ảnh — sao không xuất hiện, đúng ý spec).

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/pixel_screen_header.dart';
import 'package:pixket/widgets/pixel/rainbow_rule.dart';

import '../support/memory_settings.dart';

void main() {
  testWidgets('header luôn kèm RainbowRule', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        effectsProvider.overrideWith(
          () => EffectSettingsNotifier(repository: MemorySettingsRepository()),
        ),
      ],
      child: const MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: PixelScreenHeader(title: 'THỬ')),
      ),
    ));
    await tester.pump();
    expect(find.byType(RainbowRule), findsOneWidget);
  });
}
```

Test MainScreen đầy đủ (sao hiện ở dark, biến mất ở light và khi tắt `fx_stars`) cần 7 provider fake; dựng `test/support/fakes.dart` ở Task 6 rồi quay lại bổ sung trong cùng file này.

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/main_star_field_test.dart`
Expected: FAIL — header chưa chứa RainbowRule.

- [x] **Step 3: Hiện thực**

`pixel_screen_header.dart`: thêm import `rainbow_rule.dart`; `build` trả về

```dart
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        headerContainer, // Container hiện tại, giữ nguyên mọi tham số
        const RainbowRule(),
      ],
    );
```

`main_screen.dart`: thêm `final palette = context.palette;` trong build; Scaffold nhận `backgroundColor: palette.canvas`; body hiện tại bọc thành

```dart
      body: Stack(
        children: [
          const Positioned.fill(child: PixelStarField()),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildSection(_section),
          ),
        ],
      ),
```

và import `../widgets/pixel/pixel_star_field.dart`.

Ba Scaffold section: `backgroundColor: palette.canvas` → `backgroundColor: Colors.transparent`.

`home_screen.dart`: bọc Row tiêu đề (`'Kết quả lọc' / 'Giao dịch gần đây'`, dòng 180–201) và nhánh `PixelLoading`/`PixelEmptyState` (dòng 234–257) mỗi thứ bằng `PixelStarSafe(child: ...)`; import widget mới.

`onboarding_screen.dart` / `login_screen.dart`: chèn `const RainbowRule()` ngay dưới khối tiêu đề đầu màn hình.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/main_star_field_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục + chốt G2**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh. Test ở mức MainScreen (sao hiện khi dark, biến mất khi light
và khi tắt `fx_stars`) **không** viết ở đây: MainScreen cần fake 8 provider, mà bộ
fake đó chỉ được dựng ở Task 6. Ba assertion này được chốt trong
`test/widget/main_tab_bar_test.dart` của Task 7 — người thực thi Task 5 chỉ cần
ghi chú giới hạn "sao ở mức màn hình kiểm chứng tại Task 7" khi báo cáo.

---

## Giai đoạn 3 — Tab bar đáy + mark trên header

### Task 6: `test/support/fakes.dart` + `pixel_tab_bar.dart`

**Files:**
- Create: `test/support/fakes.dart`
- Create: `lib/widgets/pixel/pixel_tab_bar.dart`
- Test: `test/widget/pixel_tab_bar_test.dart` (mới)

**Interfaces:**
- Consumes: `AppSection` (`lib/core/navigation/app_section.dart`), `AppIcon` với glyph đã có `camera/receipt/chart/wallet`.
- Produces: `PixelTabBar({required AppSection selected, required ValueChanged<AppSection> onSelect})`; `test/support/fakes.dart` chứa `FakeAuthNotifier`, `FakeThemeNotifier`, `FakeExpenseNotifier`, `FakeCategoryNotifier`, `FakePriorityNotifier`, `FakeBudgetNotifier`, `FakeStatisticsNotifier` và hàm `List<Override> mainScreenOverrides()`.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/navigation/app_section.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_tab_bar.dart';

void main() {
  testWidgets('4 mục, đổi tab gọi onSelect đúng một lần', (tester) async {
    final taps = <AppSection>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        bottomNavigationBar: PixelTabBar(
          selected: AppSection.feed,
          onSelect: taps.add,
        ),
      ),
    ));

    for (final label in ['CHỤP', 'SỔ', 'BIỂU', 'NGÂN']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('BIỂU'));
    await tester.pump();
    expect(taps, [AppSection.statistics]);

    // Chạm lại mục đang chọn không phát callback.
    await tester.tap(find.text('CHỤP'));
    await tester.pump();
    expect(taps, [AppSection.statistics, AppSection.feed]);
    await tester.tap(find.text('CHỤP'));
    await tester.pump();
    expect(taps.length, 2, reason: 'mục đang chọn không gọi lại');
  });

  testWidgets('mục chọn có Semantics selected', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        bottomNavigationBar: PixelTabBar(
          selected: AppSection.budget,
          onSelect: (_) {},
        ),
      ),
    ));
    // Đọc thẳng widget Semantics: `tester.getSemantics` cần bật semantics handle,
    // còn `find.ancestor(..., byType(Semantics))` dính nhiều lớp Semantics lồng nhau
    // nên mỗi tab mang một ValueKey riêng để finder trả đúng một widget.
    // Palette lấy theo khuôn test/widget/feed_hud_test.dart:115.
    final palette = AppTheme.dark.extension<AppPalette>()!;
    Semantics semOf(String label) =>
        tester.widget<Semantics>(find.byKey(ValueKey('tab-$label')));
    Color bgOf(String label) => tester
        .widget<ColoredBox>(
          find.descendant(
            of: find.byKey(ValueKey('tab-$label')),
            matching: find.byType(ColoredBox),
          ),
        )
        .color;

    expect(bgOf('NGÂN'), palette.butter);
    expect(bgOf('CHỤP'), palette.surface);
    expect(semOf('NGÂN').properties.selected, isTrue);
    expect(semOf('CHỤP').properties.selected, isFalse);
    expect(semOf('NGÂN').properties.button, isTrue);
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/pixel_tab_bar_test.dart`
Expected: FAIL — widget chưa tồn tại.

- [x] **Step 3: Hiện thực**

`lib/widgets/pixel/pixel_tab_bar.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/navigation/app_section.dart';
import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

/// Tab bar đáy 4 mục; màu không đủ mang nghĩa nên mỗi mục giữ Semantics selected.
class PixelTabBar extends StatelessWidget {
  const PixelTabBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelect;

  static const _items = <AppSection, (String, String)>{
    AppSection.feed: ('CHỤP', 'camera'),
    AppSection.dashboard: ('SỔ', 'receipt'),
    AppSection.statistics: ('BIỂU', 'chart'),
    AppSection.budget: ('NGÂN', 'wallet'),
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      color: palette.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.lineStrong, width: 3)),
          ),
          child: Row(
            children: [
              for (final entry in _items.entries)
                Expanded(
                  child: _TabItem(
                    label: entry.value.$1,
                    glyph: entry.value.$2,
                    isSelected: entry.key == selected,
                    palette: palette,
                    labelStyle: text.labelLarge,
                    onTap: () {
                      if (entry.key != selected) onSelect(entry.key);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.glyph,
    required this.isSelected,
    required this.palette,
    required this.labelStyle,
    required this.onTap,
  });

  final String label;
  final String glyph;
  final bool isSelected;
  final AppPalette palette;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? palette.butter : palette.surface;
    final fg = isSelected ? palette.onAccent : palette.inkMuted;

    return Semantics(
      key: ValueKey('tab-$label'),
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(name: glyph, size: 24, color: fg),
                const SizedBox(height: 2),
                Text(label, style: labelStyle?.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

`test/support/fakes.dart` — viết nguyên văn file này (không "chép theo khuôn"):
mọi notifier thật đều chạm sqflite/Supabase ngay trong constructor, nên test nào
dựng `MainScreen` phải override đủ 7 provider dưới. Khuôn `implements X` +
`noSuchMethod` lấy từ `test/widget/trash_settings_pixel_test.dart`; `BudgetState`
bắt buộc `month`, `StatisticsState` không phải `const`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pixket/providers/auth_provider.dart';
import 'package:pixket/providers/budget_provider.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/providers/expense_provider.dart';
import 'package:pixket/providers/priority_provider.dart';
import 'package:pixket/providers/statistics_provider.dart';
import 'package:pixket/providers/theme_provider.dart';

class FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  FakeAuthNotifier()
    : super(const AppAuthState(status: AuthStatus.authenticated));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeThemeNotifier extends StateNotifier<ThemeMode>
    implements ThemeNotifier {
  FakeThemeNotifier() : super(ThemeMode.dark);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  FakeExpenseNotifier() : super(const ExpenseState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  FakeCategoryNotifier() : super(const CategoryState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePriorityNotifier extends StateNotifier<PriorityState>
    implements PriorityNotifier {
  FakePriorityNotifier() : super(const PriorityState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBudgetNotifier extends StateNotifier<BudgetState>
    implements BudgetNotifier {
  FakeBudgetNotifier() : super(const BudgetState(month: '2026-11'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStatisticsNotifier extends StateNotifier<StatisticsState>
    implements StatisticsNotifier {
  FakeStatisticsNotifier() : super(StatisticsState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Override đủ cho test nào dựng MainScreen hoặc một trong 4 section.
List<Override> mainScreenOverrides() => [
  authProvider.overrideWith((ref) => FakeAuthNotifier()),
  themeProvider.overrideWith((ref) => FakeThemeNotifier()),
  expenseProvider.overrideWith((ref) => FakeExpenseNotifier()),
  categoryProvider.overrideWith((ref) => FakeCategoryNotifier()),
  priorityProvider.overrideWith((ref) => FakePriorityNotifier()),
  budgetProvider.overrideWith((ref) => FakeBudgetNotifier()),
  statisticsProvider.overrideWith((ref) => FakeStatisticsNotifier()),
];
```

`MainScreen` không watch `appSettingsProvider` (chỉ `app.dart` gate onboarding),
nên không cần fake cho nó ở Task 7.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/pixel_tab_bar_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 7: Gắn tab bar vào MainScreen, giữ drawer

**Files:**
- Modify: `lib/screens/main_screen.dart:77-99`
- Test: `test/widget/main_tab_bar_test.dart` (mới, dùng `test/support/fakes.dart`)

**Interfaces:**
- Consumes: `PixelTabBar`, `_selectSection` sẵn có của MainScreen.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/screens/main_screen.dart';
import 'package:pixket/widgets/pixel/pixel_star_field.dart';
import 'package:pixket/widgets/pixel/pixel_tab_bar.dart';

import '../support/fakes.dart';
import '../support/memory_settings.dart';

Finder _starPaint() => find.descendant(
  of: find.byType(PixelStarField),
  matching: find.byType(CustomPaint),
);

/// MainScreen có RainbowRule (repeat 1,6 s) và nền sao (repeat 1,4 s) nên phải
/// tắt animation, nếu không `pumpAndSettle` không bao giờ dừng.
Widget _host({ThemeData? theme, MemorySettingsRepository? repo}) =>
    ProviderScope(
      overrides: [
        ...mainScreenOverrides(),
        effectsProvider.overrideWith(
          () => EffectSettingsNotifier(
            repository: repo ?? MemorySettingsRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.dark,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const MainScreen(),
          ),
        ),
      ),
    );

void main() {
  testWidgets('tab bar đổi section một lần và drawer vẫn mở', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.byType(PixelTabBar), findsOneWidget);

    await tester.tap(find.text('BIỂU'));
    await tester.pumpAndSettle();
    expect(find.text('THEO DANH MỤC'), findsOneWidget);

    // Drawer vẫn mở được bằng nút menu trên HUD của section chụp.
    await tester.tap(find.text('SỔ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mở menu'));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsOneWidget);
  });

  testWidgets('nền sao vẽ khi dark và bật fx_stars', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(_starPaint(), findsOneWidget);
  });

  testWidgets('nền sao tắt khi fx_stars = false', (tester) async {
    final repo = MemorySettingsRepository()..store['fx_stars'] = 'false';
    await tester.pumpWidget(_host(repo: repo));
    await tester.pumpAndSettle();
    expect(_starPaint(), findsNothing);
  });

  testWidgets('nền sao không vẽ ở theme sáng', (tester) async {
    await tester.pumpWidget(_host(theme: AppTheme.light));
    await tester.pumpAndSettle();
    expect(_starPaint(), findsNothing);
  });
}
```

Nếu `pumpAndSettle` báo timeout thì còn một controller repeat chưa tôn trọng
`disableAnimations` — sửa widget đó (không lặp khi tắt) chứ không đổi sang
`tester.pump()` cố định để che lỗi.

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/main_tab_bar_test.dart`
Expected: FAIL — MainScreen chưa có tab bar.

- [x] **Step 3: Hiện thực**

Trong `main_screen.dart`, thêm vào Scaffold:

```dart
      bottomNavigationBar: PixelTabBar(
        selected: _section,
        onSelect: _selectSection,
      ),
```

import `../widgets/pixel/pixel_tab_bar.dart`. Drawer và `onMenuTap` của 4 screen giữ nguyên.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/main_tab_bar_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh. Lưu ý `screens_test.dart` cũ có thể assert số lượng widget trong MainScreen — nếu đỏ, sửa assertion theo hiện trạng mới chứ không bỏ test.

### Task 8: Mark trên header + drawer

**Files:**
- Modify: `lib/widgets/pixel/pixel_screen_header.dart` (thêm slot logo)
- Modify: `lib/widgets/app_drawer.dart` (logo mono ở đầu drawer)
- Modify: `test/widget/app_drawer_test.dart:130-141` (thêm 1 assertion vào test đã mở sẵn drawer)
- Test: `test/widget/pixel_logo_placement_test.dart` (mới)

**Interfaces:**
- Consumes: `PixelLogo` (Giai đoạn 1).

Quyết định chỗ đặt (spec không chốt ô cụ thể): header cấp section (`onBackTap == null`) hiện `PixelLogo(size: 24)` giữa nút menu và cột tiêu đề; màn push (có nút back) không hiện để không chật hàng; drawer hiện bản `mono` cỡ 32 cạnh tên người dùng.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_logo.dart';
import 'package:pixket/widgets/pixel/pixel_screen_header.dart';

void main() {
  testWidgets('header cấp section có mark, header push thì không', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: PixelScreenHeader(title: 'A', onMenuTap: _noop)),
    ));
    expect(find.byType(PixelLogo), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: PixelScreenHeader(title: 'B', onBackTap: _noop)),
    ));
    expect(find.byType(PixelLogo), findsNothing);
  });
}

void _noop() {}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/pixel_logo_placement_test.dart`
Expected: FAIL.

- [x] **Step 3: Hiện thực**

`pixel_screen_header.dart`: trong Row, giữa `leading` và `SizedBox(width: 8)` thêm

```dart
          if (onBackTap == null) ...[
            const PixelLogo(size: 24),
            const SizedBox(width: 8),
          ],
```

import `pixel_logo.dart`.

`app_drawer.dart`: ở hàng đầu chứa avatar/tên người dùng, thêm `PixelLogo(size: 32, mono: true)` trước khối tên. `PixelLogo` là StatelessWidget thuần (không watch provider) nên `app_drawer_test.dart` — vốn pump drawer không có `ProviderScope` — vẫn chạy được.

Chốt drawer bằng 2 dòng thêm vào test `'Hiển thị hồ sơ cloud và nút đăng xuất'`
của `test/widget/app_drawer_test.dart` (test này đã mở drawer sẵn, khỏi dựng
harness mới), kèm import `package:pixket/widgets/pixel/pixel_logo.dart`:

```dart
      expect(find.byType(PixelLogo), findsOneWidget);
      expect(tester.widget<PixelLogo>(find.byType(PixelLogo)).mono, isTrue);
```

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/pixel_logo_placement_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục + chốt G3**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

---

## Giai đoạn 4 — Biểu đồ theo mức chi + 3 chuyển cảnh + bump version + docs

### Task 9: `PixelProgress` tô theo mức chi + nhãn "Vượt mức"

**Files:**
- Modify: `lib/widgets/pixel/pixel_progress.dart`
- Test: `test/widget/pixel_progress_ramp_test.dart` (mới)

**Interfaces:**
- Consumes: `palette.rampFill`, `palette.rose`.
- Produces: tham số mới `bool spendRamp = true` trên `PixelProgress`; `fillColor` truyền vào vẫn thắng tuyệt đối.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_progress.dart';

Color _cellColor(WidgetTester tester, int index) =>
    (tester.widgetList<Container>(find.descendant(
      of: find.byType(PixelProgress),
      matching: find.byType(Container),
    ))[index]).color!;

void main() {
  testWidgets('tô theo bậc mức chi', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: PixelProgress(value: 0.3, segments: 4)),
    ));
    expect(_cellColor(tester, 0), AppPalette.light.rampFill(0.3));
  });

  testWidgets('quá hạn mức chuyển rose và nhãn Vượt mức', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PixelProgress(value: 1.2, segments: 4, showLabel: true),
      ),
    ));
    expect(_cellColor(tester, 0), AppPalette.light.rose);
    expect(find.text('Vượt mức'), findsOneWidget);
    expect(find.text('120%'), findsNothing);
  });

  testWidgets('spendRamp false giữ màu cũ và fillColor vẫn thắng', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PixelProgress(
          value: 0.3,
          segments: 4,
          spendRamp: false,
          fillColor: Color(0xFF123456),
        ),
      ),
    ));
    expect(_cellColor(tester, 0), const Color(0xFF123456));
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/pixel_progress_ramp_test.dart`
Expected: FAIL.

- [x] **Step 3: Hiện thực**

Trong `pixel_progress.dart` thêm field `final bool spendRamp;` (mặc định `true`) và đổi phần tính màu/nhãn:

```dart
    final over = value > 1;
    final fill = fillColor ??
        (spendRamp
            ? (over ? palette.rose : palette.rampFill(clamped))
            : palette.mintStrong);
    final label = spendRamp && over
        ? palette.rampLabel(value)
        : '${(clamped * 100).round()}%';
```

dùng `fill` cho ô đã tô và `label` cho cả `Semantics.value` lẫn `Text` khi `showLabel`.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/pixel_progress_ramp_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh (`budget_pixel_test.dart` cũ có thể assert màu mintStrong — sửa assertion sang `rampFill` nếu đỏ).

### Task 10: `PixelBarChart` nhận `reference` và tô từng cột theo ramp

**Files:**
- Modify: `lib/widgets/pixel/pixel_bar_chart.dart`
- Test: `test/widget/pixel_bar_chart_ramp_test.dart` (mới)

**Interfaces:**
- Consumes: `palette.rampFill`, `palette.rampLabel`.
- Produces: tham số mới `double? reference`; tooltip kèm `rampLabel`.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_bar_chart.dart';

void main() {
  final dates = [DateTime(2026, 11, 1), DateTime(2026, 11, 2)];

  testWidgets('mỗi cột tô theo bậc của value/reference', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PixelBarChart(
          dates: dates,
          values: const [10, 90],
          valueTexts: const ['10₫', '90₫'],
          reference: 100,
        ),
      ),
    ));
    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color != null)
        .map((c) => c.color)
        .toList();
    expect(containers, contains(AppPalette.light.rampFill(0.1)));
    expect(containers, contains(AppPalette.light.rampFill(0.9)));
  });

  testWidgets('tooltip kèm nhãn bậc mức chi', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PixelBarChart(
          dates: dates,
          values: const [90],
          valueTexts: const ['90₫'],
          reference: 100,
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('bar-0')));
    await tester.pump();
    expect(find.textContaining('Vượt mức'), findsOneWidget);
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/pixel_bar_chart_ramp_test.dart`
Expected: FAIL.

- [x] **Step 3: Hiện thực**

Giữ `barColor` làm màu fallback khi không có `reference` (spec §7 chỉ đổi nguồn
màu, không phá caller cũ; trong repo hiện chưa ai truyền `barColor`).

Trong `PixelBarChart`: thêm `this.reference,` vào constructor và
`final double? reference;` vào danh sách field.

Trong `_PixelBarChartState`, thêm hai helper và đổi chỗ tô màu + tooltip:

```dart
  double? _t(double value) {
    final ref = widget.reference;
    return ref == null || ref <= 0 ? null : value / ref;
  }

  Color _barColor(Color fallback, double value) {
    final t = _t(value);
    return t == null ? fallback : context.palette.rampFill(t);
  }
```

Trong `build`, ngay sau `final maxValue = ...`, tính chuỗi tooltip (phải nằm trong
guard index, không thì `_selected` vượt biên sẽ ném):

```dart
    String? tooltip;
    if (_selected != null && _selected! < texts.length) {
      final t = _t(values[_selected!]);
      tooltip =
          '${DateFormatter.formatDate(dates[_selected!])} • ${texts[_selected!]}'
          '${t == null ? '' : ' • ${palette.rampLabel(t)}'}';
    }
```

Đổi khối tooltip (dòng 71–84) thành `if (tooltip != null) Container(... child: Text(tooltip, style: ...))` — giữ nguyên `key: const ValueKey('bar-tooltip')`, margin, padding và decoration.

Đổi đối số màu trong vòng `for` vẽ cột (dòng 94–103): `barColor` → `_barColor(barColor, values[i])`. Chữ ký `_buildBar` giữ nguyên.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/pixel_bar_chart_ramp_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 11: `PixelShareBar` / `PixelStackedShare` theo ramp, giữ override cũ

**Files:**
- Modify: `lib/widgets/pixel/pixel_share_bar.dart`
- Modify: `lib/widgets/pixel/pixel_stacked_share.dart`
- Test: `test/widget/pixel_share_ramp_test.dart` (mới)

**Interfaces:**
- Consumes: `palette.rampFill`, `palette.rampLabel`, `palette.accentForCategory`.
- Produces: `PixelShareBar({bool useSpendRamp = true, double? reference})`; `PixelStackedShare({double? reference, List<Color> colors = const []})`.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_share_bar.dart';
import 'package:pixket/widgets/pixel/pixel_stacked_share.dart';

void main() {
  testWidgets('share bar dùng ramp khi có reference, accent khi tắt', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PixelShareBar(
          label: 'Ăn uống',
          glyph: 'coffee',
          value: 80,
          total: 100,
          valueText: '80₫',
          reference: 100,
        ),
      ),
    ));
    expect(
      find.byWidgetPredicate(
        (w) => w is Container && w.color == AppPalette.light.rampFill(0.8),
      ),
      findsWidgets,
    );
    expect(find.textContaining('Vượt mức'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PixelShareBar(
          label: 'Ăn uống',
          glyph: 'coffee',
          value: 80,
          total: 100,
          valueText: '80₫',
          useSpendRamp: false,
        ),
      ),
    ));
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.color == AppPalette.light.accentForCategory('Ăn uống'),
      ),
      findsWidgets,
    );
  });

  testWidgets('stacked share tô từng nhóm theo ramp', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PixelStackedShare(
          labels: ['A', 'B'],
          glyphs: ['tag', 'tag'],
          values: [20, 90],
          valueTexts: ['20₫', '90₫'],
          reference: 100,
        ),
      ),
    ));
    expect(
      find.byWidgetPredicate(
        (w) => w is Container && w.color == AppPalette.light.rampFill(0.9),
      ),
      findsWidgets,
    );
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/pixel_share_ramp_test.dart`
Expected: FAIL.

- [x] **Step 3: Hiện thực**

`pixel_share_bar.dart`: thêm `useSpendRamp`, `reference`; thay dòng 30:

```dart
    final t = useSpendRamp && reference != null && reference! > 0
        ? value / reference!
        : null;
    final accent = t == null
        ? palette.accentForCategory(label)
        : palette.rampFill(t);
```

và thêm một `Text(palette.rampLabel(t))` cỡ `labelSmall` màu `palette.rampInk(t)` dưới `sharePercent(...)` khi `t != null` (nhãn chữ bắt buộc theo WCAG 1.4.1).

`pixel_stacked_share.dart`: đổi `required this.colors` thành `this.colors = const []`, thêm `double? reference`; màu hiệu dụng của nhóm i:

```dart
    Color colorOf(int i) {
      final t = reference != null && reference! > 0 && i < values.length
          ? values[i] / reference!
          : null;
      if (t != null) return palette.rampFill(t);
      return i < colors.length ? colors[i] : palette.surfaceAlt;
    }
```

dùng `colorOf(i)` cho cả ô trong thanh và ô vuông legend; legend thêm `rampLabel(t)` cạnh `%` khi `t != null`.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/pixel_share_ramp_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 12: Truyền `reference` từ màn thống kê/ngân sách + tôn trọng khoá `chart_spend_ramp`

**Files:**
- Modify: `lib/screens/statistics/statistics_charts.dart:93-143`
- Modify: `lib/screens/budget/budget_screen.dart:273-276, 395-399`
- Modify: `lib/screens/home/budget_progress_card.dart:72-76`
- Modify: `test/widget/budget_pixel_test.dart:104` (assertion `fillColor` cũ)
- Test: `test/widget/statistics_ramp_toggle_test.dart` (mới)

**Interfaces:**
- Consumes: `effectsProvider.chartSpendRamp`.

Mốc tham chiếu (spec chốt #9): biểu đồ = max của kỳ đang xem; progress ngân sách = hạn mức (đã là tỉ lệ trên hạn mức nên chỉ cần bật ramp).

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/pixel_share_bar.dart';

import '../support/memory_settings.dart';

/// Widget probe: đọc khoá y như `statistics_charts.dart` rồi truyền xuống
/// `PixelShareBar`, để test khoá mà không phải fake cả statisticsProvider.
class RampProbe extends ConsumerWidget {
  const RampProbe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(effectsProvider).chartSpendRamp;
    return PixelShareBar(
      label: 'Ăn uống',
      glyph: 'coffee',
      value: 80,
      total: 100,
      valueText: '80.000₫',
      useSpendRamp: on,
      reference: on ? 100 : null,
    );
  }
}

Widget _host(MemorySettingsRepository repo) => ProviderScope(
  overrides: [
    effectsProvider.overrideWith(() => EffectSettingsNotifier(repository: repo)),
  ],
  child: const MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: RampProbe()),
  ),
);

void main() {
  testWidgets('khoá bật thì tô ramp và in nhãn chữ', (tester) async {
    await tester.pumpWidget(_host(MemorySettingsRepository()));
    await tester.pump();
    // t = 80/100 → bậc 3 → rose + nhãn 'Vượt mức' (màu không mang nghĩa một mình).
    expect(
      find.byWidgetPredicate(
        (w) => w is Container && w.color == AppPalette.light.rampFill(0.8),
      ),
      findsWidgets,
    );
    expect(find.text('Vượt mức'), findsOneWidget);
  });

  testWidgets('khoá chart_spend_ramp tắt thì về accent danh mục', (tester) async {
    final repo = MemorySettingsRepository()..store['chart_spend_ramp'] = 'false';
    await tester.pumpWidget(_host(repo));
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.color == AppPalette.light.accentForCategory('Ăn uống'),
      ),
      findsWidgets,
    );
    expect(find.text('Vượt mức'), findsNothing);
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/statistics_ramp_toggle_test.dart`
Expected: FAIL.

- [x] **Step 3: Hiện thực**

`statistics_charts.dart`: thêm `final effects = ref.watch(effectsProvider);` và

```dart
    final catMax = catEntries.isEmpty
        ? 0.0
        : catEntries.first.value;
    final priorityMax = priorityValues.fold<double>(0, (a, b) => b > a ? b : a);
    final dayMax = series.values.fold<double>(0, (a, b) => b > a ? b : a);
    final on = effects.chartSpendRamp;
```

truyền `useSpendRamp: on, reference: on ? catMax : null` cho mọi `PixelShareBar`; `reference: on ? priorityMax : null` cho `PixelStackedShare` (giữ `colors` cũ làm fallback); `reference: on ? dayMax : null` cho `PixelBarChart`. Import `app_settings_provider.dart`.

`budget_screen.dart` (2 chỗ `PixelProgress`, cả hai đều nằm trong method của `_BudgetScreenState` nên đã có sẵn `ref`) và `budget_progress_card.dart`: bỏ `fillColor` hardcode, truyền `spendRamp: ref.watch(effectsProvider).chartSpendRamp`. `BudgetProgressCard` đang là `StatelessWidget` → chuyển thành `ConsumerWidget` nhưng **giữ constructor `const`**, nếu không `dashboard_pixel_test.dart:140` (`const BudgetProgressCard(...)`) sẽ không biên dịch. Nhãn "QUÁ NGÂN SÁCH" của card giữ nguyên (ngữ cảnh hạn mức, không phải bậc chi tiêu).

`test/widget/budget_pixel_test.dart:104` đang assert `expect(progress.fillColor, isNotNull)` — bỏ `fillColor` là test này đỏ, đổi thành:

```dart
    expect(progress.spendRamp, isTrue);
```

(`test/widget/dashboard_pixel_test.dart` chỉ assert `progress.value` nên không phải sửa; `harness` của nó đã có `ProviderScope`.)

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/statistics_ramp_toggle_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 13: `rainbow_sweep.dart` — chuyển cảnh sau chụp

**Files:**
- Create: `lib/widgets/pixel/rainbow_sweep.dart`
- Test: `test/widget/rainbow_sweep_test.dart` (mới)

**Interfaces:**
- Consumes: `effectsProvider.captureSweep`, `palette.accents`.
- Produces: `RainbowSweep.play(BuildContext context, {required VoidCallback onCovered}) -> Future<void>`.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/rainbow_sweep.dart';

import '../support/memory_settings.dart';

void main() {
  Widget host(VoidCallback onCovered) => ProviderScope(
    overrides: [
      effectsProvider.overrideWith(
        () => EffectSettingsNotifier(repository: MemorySettingsRepository()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => RainbowSweep.play(context, onCovered: onCovered),
            child: const Text('PLAY'),
          ),
        ),
      ),
    ),
  );

  testWidgets('onCovered chạy một lần ở bậc 4-5, overlay gỡ sau 740 ms', (tester) async {
    var covered = 0;
    await tester.pumpWidget(host(() => covered++));
    await tester.tap(find.text('PLAY'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 200));
    expect(covered, 0, reason: 'chưa tới bậc che kín');
    await tester.pump(const Duration(milliseconds: 100));
    expect(covered, 1, reason: 'bậc 4 bắt đầu ở 246 ms');
    expect(find.byKey(const ValueKey('rainbow-sweep')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(covered, 1, reason: 'không gọi lần hai');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('rainbow-sweep')), findsNothing);
  });

  testWidgets('khoá tắt thì không vẽ nhưng vẫn gọi onCovered một lần', (tester) async {
    final repo = MemorySettingsRepository()..store['fx_capture_sweep'] = 'false';
    var covered = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        effectsProvider.overrideWith(() => EffectSettingsNotifier(repository: repo)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => RainbowSweep.play(context, onCovered: () => covered++),
              child: const Text('PLAY'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('PLAY'));
    await tester.pump();
    expect(covered, 1);
    expect(find.byKey(const ValueKey('rainbow-sweep')), findsNothing);
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/rainbow_sweep_test.dart`
Expected: FAIL.

- [x] **Step 3: Hiện thực**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/app_settings_provider.dart';

/// Vị trí tâm dải theo % chiều rộng, 8 bậc × 82 ms; bậc 4-5 (giá trị 0) che kín.
const _positions = [-150.0, -95, -40, 0, 0, 40, 95, 150];

class RainbowSweep {
  RainbowSweep._();

  static Future<void> play(
    BuildContext context, {
    required VoidCallback onCovered,
  }) {
    final enabled =
        ProviderScope.containerOf(context).read(effectsProvider).captureSweep;
    if (!enabled) {
      onCovered();
      return Future<void>.value();
    }
    final still = MediaQuery.of(context).disableAnimations;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    var covered = false;
    entry = OverlayEntry(
      builder: (_) => _SweepOverlay(
        still: still,
        onCovered: () {
          if (covered) return;
          covered = true;
          onCovered();
        },
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    return Future<void>.value();
  }
}

class _SweepOverlay extends StatefulWidget {
  const _SweepOverlay({
    required this.still,
    required this.onCovered,
    required this.onDone,
  });

  final bool still;
  final VoidCallback onCovered;
  final VoidCallback onDone;

  @override
  State<_SweepOverlay> createState() => _SweepOverlayState();
}

class _SweepOverlayState extends State<_SweepOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.still ? 220 : 660),
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run.addListener(_tick);
    _run.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onDone();
      }
    });
    _run.forward();
  }

  void _tick() {
    final steps = widget.still ? 2 : _positions.length;
    final step = (_run.value * steps).floor().clamp(0, steps - 1);
    // still: bậc 0 đã che kín; động: bậc 3 (đầu cửa sổ 165 ms che kín).
    if (step >= (widget.still ? 0 : 3)) widget.onCovered();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey('rainbow-sweep'),
          painter: _SweepPainter(
            context.palette.accents,
            widget.still ? const [0, 150] : _positions,
            _run,
          ),
          repaint: _run,
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.accents, this.positions, this.run);

  final List<Color> accents;
  final List<double> positions;
  final Animation<double> run;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || accents.isEmpty) return;
    final step = (run.value * positions.length)
        .floor()
        .clamp(0, positions.length - 1);
    final bandWidth = size.width * 1.7;
    final x0 = (positions[step] / 100) * size.width - bandWidth * 0.35;
    final column = bandWidth / accents.length;
    final paint = Paint()..isAntiAlias = false;

    canvas.save();
    // skewX(-12°): x' = x + y·tan(-12°).
    canvas.transform(
      (Matrix4.identity()..setEntry(0, 1, math.tan(-12 * math.pi / 180)))
          .storage,
    );
    for (var i = 0; i < accents.length; i++) {
      paint.color = accents[i];
      canvas.drawRect(
        Rect.fromLTWH(x0 + i * column, -size.height * 0.24, column + 0.2, size.height * 1.48),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SweepPainter old) => old.run.value != run.value;
}
```

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/rainbow_sweep_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 14: Nối sweep vào điểm chụp + `pixel_confetti.dart` khi lưu

**Files:**
- Modify: `lib/screens/camera/camera_screen.dart:150-152`
- Create: `lib/widgets/pixel/pixel_confetti.dart`
- Modify: `lib/screens/camera/expense_form_sheet.dart:135-141` (điểm lưu thành công trong `_saveExpense`)
- Test: `test/widget/pixel_confetti_test.dart` (mới)

**Interfaces:**
- Consumes: `effectsProvider.confetti`, `palette.accents`.
- Produces: `PixelConfetti.burst(BuildContext context)`.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/widgets/pixel/pixel_confetti.dart';

import '../support/memory_settings.dart';

void main() {
  testWidgets('burst vẽ một overlay rồi tự gỡ sau 480 ms', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        effectsProvider.overrideWith(
          () => EffectSettingsNotifier(repository: MemorySettingsRepository()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PixelConfetti.burst(context),
              child: const Text('BURST'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('BURST'));
    await tester.pump();
    expect(find.byKey(const ValueKey('pixel-confetti')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('pixel-confetti')), findsNothing);
  });

  testWidgets('khoá tắt thì không vẽ', (tester) async {
    final repo = MemorySettingsRepository()..store['fx_confetti'] = 'false';
    await tester.pumpWidget(ProviderScope(
      overrides: [
        effectsProvider.overrideWith(() => EffectSettingsNotifier(repository: repo)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PixelConfetti.burst(context),
              child: const Text('BURST'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('BURST'));
    await tester.pump();
    expect(find.byKey(const ValueKey('pixel-confetti')), findsNothing);
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/pixel_confetti_test.dart`
Expected: FAIL.

- [x] **Step 3: Hiện thực**

`pixel_confetti.dart`: một `OverlayEntry` chứa **một** `CustomPaint` + `RepaintBoundary` + `IgnorePointer` (key `ValueKey('pixel-confetti')`), `AnimationController` 480 ms, 24 ô 4×4 sinh từ `math.Random(20261102)`: mỗi ô có `x` ngẫu nhiên ngang màn, bay lên 6 bậc nguyên rồi rơi 10 bậc, màu `accents[i % 6]`; vị trí tính theo `step = (run.value * 8).floor()` để chuyển động bậc rời; `onDone` gỡ entry khi controller completed. Đọc khoá bằng `ProviderScope.containerOf(context).read(effectsProvider).confetti`, tắt thì return ngay. Overlay phải lấy `Overlay.of(context, rootOverlay: true)`: điểm nổ nằm trong bottom sheet sắp `pop`, entry gắn vào overlay của sheet sẽ bị gỡ theo route.

`camera_screen.dart` dòng 150–152, thay `await _openExpenseForm(imagePath: picture.path);` bằng:

```dart
      await RainbowSweep.play(
        context,
        onCovered: () {
          if (mounted) _openExpenseForm(imagePath: picture.path);
        },
      );
```

import `rainbow_sweep.dart`. Cờ chống mở sheet hai lần nằm sẵn trong `RainbowSweep.play`. Chỉ nối vào đường chụp (`_takePicture`); đường chọn ảnh thư viện `_pickFromGallery:170` giữ nguyên vì spec §10 đặt sweep ở "sau khi chụp".

Điểm nổ confetti — **không có "màn thêm thủ công" riêng**: `openExpenseForm`
(`expense_form_sheet.dart:309`) là lối vào duy nhất (chụp `camera_screen.dart:152`,
thư viện `:170`, sửa từ sổ `home_screen.dart:113`) và `addExpense` chỉ được gọi
một lần ở `expense_form_sheet.dart:124`. Vậy chèn vào `_saveExpense` của
`expense_form_sheet.dart`, giữa `if (!mounted) return;` (dòng 135) và
`Navigator.of(context).pop();` (dòng 141):

```dart
      if (!mounted) return;
      PixelConfetti.burst(context);
```

Nổ cho cả thêm mới lẫn chỉnh sửa (spec §11: "`fx_confetti` — confetti khi lưu").
Import `../../widgets/pixel/pixel_confetti.dart`.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/pixel_confetti_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 15: `mosaic_wipe.dart` thay `AnimatedSwitcher` ở MainScreen

**Files:**
- Create: `lib/widgets/pixel/mosaic_wipe.dart`
- Modify: `lib/screens/main_screen.dart:93-98`
- Test: `test/widget/mosaic_wipe_test.dart` (mới)

**Interfaces:**
- Consumes: `effectsProvider.mosaic` (đọc ở MainScreen để bật/tắt).
- Produces: `MosaicWipe({required Object transitionKey, required Widget child, required bool enabled})`.

- [x] **Step 1: Viết test thất bại**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/mosaic_wipe.dart';

void main() {
  testWidgets('đổi key thì lật lưới rồi mới thay con', (tester) async {
    Widget host(Object key) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: MosaicWipe(
          transitionKey: key,
          enabled: true,
          child: Center(child: Text('key-$key')),
        ),
      ),
    );

    await tester.pumpWidget(host('a'));
    expect(find.text('key-a'), findsOneWidget);

    await tester.pumpWidget(host('b'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byKey(const ValueKey('mosaic-wipe')), findsOneWidget);
    expect(find.text('key-a'), findsOneWidget, reason: 'chưa tới điểm đổi');

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('key-b'), findsOneWidget, reason: 'đổi ở giữa lượt lật');

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('mosaic-wipe')), findsNothing);
  });

  testWidgets('enabled false đổi ngay, không lưới', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: MosaicWipe(
          transitionKey: 'a',
          enabled: false,
          child: Center(child: Text('key-a')),
        ),
      ),
    ));
    await tester.pumpWidget(const MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: MosaicWipe(
          transitionKey: 'b',
          enabled: false,
          child: Center(child: Text('key-b')),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('key-b'), findsOneWidget);
    expect(find.byKey(const ValueKey('mosaic-wipe')), findsNothing);
  });
}
```

- [x] **Step 2: Chạy test, xác nhận thất bại**

Run: `flutter test test/widget/mosaic_wipe_test.dart`
Expected: FAIL.

- [x] **Step 3: Hiện thực**

`mosaic_wipe.dart`: `StatefulWidget` giữ `_shown = widget.child`; `didUpdateWidget` khi `transitionKey` đổi và `enabled`: khởi động `AnimationController` 260 ms, listener ở `value >= 0.5` thì `setState(() => _shown = widget.child)` một lần, `completed` thì dừng và ẩn lưới; khi không `enabled`: `_shown = widget.child` ngay. Lớp lưới là `Stack[child: _shown, nếu đang chạy: IgnorePointer(CustomPaint(key: ValueKey('mosaic-wipe'), painter: _MosaicPainter(run)))]`. Painter: lưới 8 hàng × 14 cột; thứ tự lật từ `math.Random(20261102)`; nửa đầu các ô bật lên theo thứ tự (che nội dung cũ), nửa sau tắt dần theo cùng thứ tự (lộ nội dung mới); ô vẽ màu `surface` nếu `(x + y) % 2 == 0` ngược lại `canvas`, `isAntiAlias: false`.

`main_screen.dart`: thay khối `AnimatedSwitcher(...)` trong Stack bằng

```dart
          MosaicWipe(
            transitionKey: _section,
            enabled: ref.watch(effectsProvider).mosaic &&
                !MediaQuery.of(context).disableAnimations,
            child: _buildSection(_section),
          ),
```

import `mosaic_wipe.dart` và `app_settings_provider.dart`; bỏ import/tham số AnimatedSwitcher cũ.

- [x] **Step 4: Chạy test, xác nhận xanh**

Run: `flutter test test/widget/mosaic_wipe_test.dart`
Expected: PASS.

- [x] **Step 5: Kiểm tra toàn cục**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh.

### Task 16: Bump 2.3.0+4, sửa gate test, cập nhật docs

**Files:**
- Modify: `lib/core/constants/app_info.dart:7-8` (version `2.3.0`, build `4`)
- Modify: `pubspec.yaml:4` (`version: 2.3.0+4`)
- Modify: `test/widget/legacy_cleanup_test.dart:74-75` (gate version/build mới)
- Modify: `test/widget/trash_settings_pixel_test.dart:205` (chuỗi about hardcode)
- Modify: `README.md:127`, `docs/project-structure.md:17`, `docs/requirements.md:57` (số phiên bản) + liệt kê 6 widget mới và 6 khoá hiệu ứng

- [x] **Step 1: Bump version + sửa gate trong cùng một lượt**

Gate ở `legacy_cleanup_test.dart:71-77` vừa đối chiếu `pubspec.yaml` với
`AppInfo.version`/`AppInfo.build`, vừa hardcode hai literal — sửa một bên sẽ đỏ, nên
sửa cả hai rồi mới chạy test:

- `lib/core/constants/app_info.dart:7-8` → `version = '2.3.0'`, `build = '4'`
- `pubspec.yaml` → `version: 2.3.0+4`
- `test/widget/legacy_cleanup_test.dart:74-75` → `expect(AppInfo.version, '2.3.0');`
  và `expect(AppInfo.build, '4');`
- `test/widget/trash_settings_pixel_test.dart:205` đang hardcode chuỗi about →
  `expect(find.text('Phiên bản 2.3.0 • PIXEL JOURNAL'), findsOneWidget);`
- Giữ nguyên `AppInfo.tagline = 'PIXEL JOURNAL'` và assertion dòng 76 (Global
  Constraints cấm đổi tagline).

- [x] **Step 2: Cập nhật docs**

- `README.md:127` và `docs/project-structure.md:17`: đổi `2.2.0+3` / `version 2.2.0, build 3`
  thành `2.3.0+4` / `version 2.3.0, build 4`.
- `docs/requirements.md:57` (FR-34): đổi `(`2.2.0` / build `3`)` thành
  `(`2.3.0` / build `4`)`.
- `README.md` và `docs/project-structure.md`: thêm vào danh sách widget pixel 6 file mới
  `pixel_star_field.dart`, `rainbow_rule.dart`, `pixel_tab_bar.dart`, `rainbow_sweep.dart`,
  `pixel_confetti.dart`, `mosaic_wipe.dart` (`pixel_logo.dart` đã có từ Giai đoạn 1), và
  bảng 6 khoá Settings với mặc định: `fx_stars` (true, chỉ dark), `fx_rainbow_rule` (true),
  `fx_capture_sweep` (true), `fx_confetti` (true), `fx_mosaic` (false), `chart_spend_ramp` (true).

- [x] **Step 3: Kiểm tra toàn cục + chốt G4**

Run: `export PATH="$PATH:/c/flutter/bin" && flutter analyze && flutter test`
Expected: sạch + xanh toàn bộ, kể cả `legacy_cleanup_test.dart` và
`trash_settings_pixel_test.dart`.

- [x] **Step 4: Báo cáo**

Liệt kê lệch spec (nếu phát sinh khi thực thi), giới hạn chưa kiểm chứng (cảm giác chuyển động trên thiết bị thật — spec §16), và nhắc người dùng cài APK thử sau G2 và G4.
