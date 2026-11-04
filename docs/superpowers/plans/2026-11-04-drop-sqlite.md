# Bỏ SQLite (Plan 1/3 của PWA) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gỡ hoàn toàn tầng SQLite local của Pixket — chuyển 3 key cài đặt sang `shared_preferences` và 4 mức độ cần thiết sang một bảng hệ thống read-only trên Supabase — để mở đường cho `flutter build web` ở Plan 2.

**Architecture:** `AppSettingsRepository` giữ nguyên chữ ký 5 method nhưng đổi ruột từ `sqflite` sang `shared_preferences`, nên provider và test double hiện có không phải sửa. `priority_levels` thành bảng hệ thống (`level_key` 0..3, không `user_id`) seed bằng SQL, đọc qua một seam `PriorityRowReader` tiêm được — đúng mẫu `ExpenseRowWriter` sẵn có. Một migration one-shot đọc DB SQLite cũ rồi ghi sang `shared_preferences`, chạy trước khi `database_helper.dart` bị xóa.

**Tech Stack:** Flutter 3.47.6, Dart SDK ^3.13.5, `shared_preferences` ^2.5.6 (đã có sẵn), `supabase_flutter` ^2.8.3, `sqflite` ^2.4.2 (giữ lại chỉ cho migration), Riverpod, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-04-pwa-design.md` — plan này hiện thực hóa mục 4.4, 6.1, 6.2, 6.3, 12.2, 12.3, 12.4. Đọc cả spec trước khi làm.

## Global Constraints

- App version hiện tại `2.6.0+8` (`pubspec.yaml:4` và `lib/core/constants/app_info.dart:7-8`). Plan này **không** tăng version.
- **Bản Android và Windows không được đổi hành vi.** Sau plan này, người dùng mở app vẫn thấy đúng theme đã chọn, không bị đưa lại vào màn onboarding, và thấy đúng 4 mức độ cần thiết với đúng màu cũ.
- `AppSettingsRepository` phải giữ **nguyên chữ ký** 5 method: `Future<String?> getString(String key)`, `Future<void> setString(String key, String value)`, `Future<bool> getBool(String key, {required bool fallback})`, `Future<void> setBool(String key, bool value)`, `Future<void> remove(String key)`. Lý do: `test/support/memory_settings.dart` (`MemorySettingsRepository extends AppSettingsRepository`) và `test/unit/effects_settings_test.dart` (`_BrokenSettings extends AppSettingsRepository`) đang override 2 method đầu.
- `getBool` phải giữ **đúng ngữ nghĩa cũ**: chỉ trả `true` khi chuỗi lưu là `'true'`, chỉ trả `false` khi là `'false'`, mọi trường hợp khác (kể cả key chưa tồn tại) trả `fallback`. Không đổi sang `SharedPreferences.getBool` — sẽ làm hỏng migration vì DB cũ lưu dạng chuỗi.
- Không thêm dependency mới. `shared_preferences` ^2.5.6 đã có trong `pubspec.yaml`.
- **Không nâng** `flutter_local_notifications` khỏi 18.0.1 trong plan này.
- 4 màu mức độ cần thiết phải giữ đúng: `0xFF43A047`, `0xFF1E88E5`, `0xFFFB8C00`, `0xFFE53935` (thập phân: `4282622023`, `4280191205`, `4294675456`, `4293212469`). Nguồn: `lib/data/database/database_helper.dart:183-186`.
- Không nới constraint `expenses_priority_range CHECK (priority BETWEEN 0 AND 3)` (`supabase_setup.sql:129-130`).
- `supabase_setup.sql` phải giữ tính **idempotent** — chạy lại nhiều lần an toàn, như header file đó đã cam kết (dòng 2).
- Comment và message trong code viết bằng tiếng Việt, theo convention sẵn có của repo.
- **Commit:** mỗi task có bước commit, nhưng quy tắc của chủ repo là **không commit khi chưa được yêu cầu rõ ràng**. Trước bước commit đầu tiên, hỏi chủ repo một lần: "Plan này có 5 bước commit, cho phép tôi commit sau mỗi task chứ?" Nếu được phép thì commit theo plan; nếu không thì bỏ qua toàn bộ bước commit và báo lại vào cuối.
- **Baseline test tại HEAD `8b71a45`: `All tests passed!` — 374 pass / 7 skip / 0 fail.** Mọi bước chạy `flutter test` trong plan này đối chiếu với con số đó. Nếu xuất hiện fail mới thì đó là lỗi của plan, không phải lỗi có sẵn — dừng lại và báo.
- Baseline đang in cảnh báo `Không đọc được khoá biểu đồ, dùng mặc định: Bad state: databaseFactory not initialized` từ `EffectSettingsNotifier._load()` (`app_settings_provider.dart:85`). Đó là bằng chứng sqflite không chạy được trong `flutter_test`. **Sau Task 1 các cảnh báo này phải biến mất**; nếu vẫn còn thì `AppSettingsRepository` chưa thực sự rời sqflite.
- **Noise được chấp nhận sau Task 2.** `flutter test` sẽ in 2 dòng `Không migrate được cài đặt từ SQLite cũ: Bad state: ...` — do hai test error-path của `legacy_settings_migration_test.dart` cố tình kích hoạt nhánh `catch` trong `LegacySettingsMigration.run()`. Đây **không phải** lỗi và không được "sửa" bằng cách bỏ `debugPrint`: catch mà im lặng mới là defect. Tiêu chí pristine của plan này là cụ thể: dòng `databaseFactory not initialized` phải bằng 0. Hai dòng migration là output đúng của test đúng.
- **Phạm vi stage.** Plan này viết trên HEAD `8b71a45` (đợt WIP pixel/budget đã được chủ repo commit, working tree sạch). Vẫn **không stage bằng `git add -A` hay `git add .`** — chỉ stage đúng những file plan này tạo/sửa, liệt kê từng đường dẫn, và chạy `git status` trước mỗi commit để xác nhận không có file lạ lọt vào. Các file untracked không thuộc plan này: `.graphifyignore`, cùng spec và plan trong `docs/superpowers/`.

## File Structure

**Tạo mới:**

| File | Trách nhiệm |
|---|---|
| `lib/data/database/legacy_settings_migration.dart` | Đọc 3 key `app_settings` từ `pixket.db` cũ (nếu có) → ghi sang `shared_preferences`, một lần duy nhất. File **duy nhất** được import `sqflite` sau khi plan này xong. |
| `lib/data/repositories/priority_row_reader.dart` | Seam đọc bảng `priority_levels`: interface `PriorityRowReader` + implementation `SupabasePriorityRowReader`. Theo mẫu `expense_row_writer.dart`. |
| `test/unit/app_settings_repository_test.dart` | Ngữ nghĩa 5 method của `AppSettingsRepository` trên `shared_preferences`. |
| `test/unit/legacy_settings_migration_test.dart` | Migration bỏ qua khi đã chạy, không ghi đè key có sẵn, không set cờ khi ném lỗi. |
| `test/unit/priority_repository_test.dart` | `PriorityLevel.fromSupabaseRow` + `PriorityRepository.getAll()` qua reader giả. |

**Sửa:**

| File | Sửa gì |
|---|---|
| `lib/data/repositories/app_settings_repository.dart` | Đổi ruột từ `sqflite` sang `shared_preferences`. Giữ chữ ký. |
| `lib/data/models/priority_level.dart` | Thêm factory `fromSupabaseRow`. Giữ `fromMap`/`toMap`. |
| `lib/data/repositories/priority_repository.dart` | Viết lại: chỉ còn `getAll()`, nhận `PriorityRowReader` tiêm được. Xóa `insert`/`update`/`deleteAndMoveExpenses`/`nextId`. || `lib/providers/priority_provider.dart` | Xóa `addLevel`/`updateLevel`/`deleteLevel`. Giữ `loadLevels`. |
| `lib/main.dart:19` | Thay `await DatabaseHelper.instance.database;` bằng `await LegacySettingsMigration().run();`. |
| `supabase_setup.sql` | Thêm section 5.1 (bảng + seed), policy SELECT ở section 6, query kiểm tra ở section 9. |
| `pubspec.yaml` | Gỡ `path_provider`. **Giữ** `sqflite`. |
| `docs/project-structure.md` | Cập nhật mô tả `database_helper.dart` và `priority_repository.dart`. |

**Xóa:**

| File | Lý do |
|---|---|
| `lib/data/database/database_helper.dart` | Không còn ai dùng sau Task 1, 2, 4. Migration tự mở DB bằng `sqflite` trực tiếp nên không cần nó. |

---

### Task 1: `AppSettingsRepository` sang `shared_preferences`

**Files:**
- Modify: `lib/data/repositories/app_settings_repository.dart` (toàn bộ file, 40 dòng)
- Test: `test/unit/app_settings_repository_test.dart` (tạo mới)

**Interfaces:**
- Consumes: `SharedPreferences.getInstance()`, `getString`, `setString`, `remove` từ `package:shared_preferences/shared_preferences.dart`.
- Produces: `class AppSettingsRepository` với đúng 5 method giữ nguyên chữ ký như Global Constraints. `AppSettingsNotifier` (`app_settings_provider.dart:29`), `EffectSettingsNotifier` (:59), `ThemeNotifier` (`theme_provider.dart:11`) đều gọi 5 method này và **không phải sửa**.

- [ ] **Step 1: Viết test thất bại**

Tạo `test/unit/app_settings_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pixket/data/repositories/app_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('getString / setString', () {
    test('trả null khi key chưa từng ghi', () async {
      expect(await AppSettingsRepository().getString('theme_mode'), isNull);
    });

    test('đọc lại đúng giá trị đã ghi', () async {
      final repository = AppSettingsRepository();
      await repository.setString('theme_mode', 'dark');

      expect(await repository.getString('theme_mode'), 'dark');
    });

    test('ghi đè giá trị cũ chứ không nhân đôi', () async {
      final repository = AppSettingsRepository();
      await repository.setString('onboarding_complete', 'true');
      await repository.setString('onboarding_complete', 'false');

      expect(await repository.getString('onboarding_complete'), 'false');
    });
  });

  group('getBool', () {
    test('trả fallback khi key chưa tồn tại', () async {
      expect(
        await AppSettingsRepository().getBool(
          'chart_spend_ramp',
          fallback: true,
        ),
        isTrue,
      );
    });

    test('trả fallback khi giá trị không phải true/false', () async {
      final repository = AppSettingsRepository();
      await repository.setString('chart_spend_ramp', 'yes');

      expect(
        await repository.getBool('chart_spend_ramp', fallback: true),
        isTrue,
      );
    });

    test('đọc lại true sau setBool(true)', () async {
      final repository = AppSettingsRepository();
      await repository.setBool('chart_spend_ramp', true);

      expect(
        await repository.getBool('chart_spend_ramp', fallback: false),
        isTrue,
      );
    });

    test('đọc lại false sau setBool(false)', () async {
      final repository = AppSettingsRepository();
      await repository.setBool('chart_spend_ramp', false);

      expect(
        await repository.getBool('chart_spend_ramp', fallback: true),
        isFalse,
      );
    });

    test('lưu dạng chuỗi true/false, không phải bool của prefs', () async {
      final repository = AppSettingsRepository();
      await repository.setBool('chart_spend_ramp', true);

      // Migration từ SQLite cũ lưu dạng chuỗi; nếu đổi sang setBool của
      // SharedPreferences thì getString sẽ trả null và migration hỏng.
      expect(await repository.getString('chart_spend_ramp'), 'true');
    });
  });

  group('remove', () {
    test('xóa hẳn key', () async {
      final repository = AppSettingsRepository();
      await repository.setString('theme_mode', 'light');
      await repository.remove('theme_mode');

      expect(await repository.getString('theme_mode'), isNull);
    });

    test('không ném khi key chưa tồn tại', () async {
      await expectLater(
        AppSettingsRepository().remove('chua_tung_co'),
        completes,
      );
    });
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận FAIL**

Run: `flutter test test/unit/app_settings_repository_test.dart`
Expected: FAIL. Implementation hiện tại gọi `DatabaseHelper.instance.database` → `sqflite` ném `MissingPluginException` trong `flutter_test` (đây chính là lý do `test/support/memory_settings.dart` phải tồn tại).

- [ ] **Step 3: Viết implementation**

Thay **toàn bộ** nội dung `lib/data/repositories/app_settings_repository.dart` bằng:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Cài đặt cấp thiết bị, đọc được cả khi chưa đăng nhập (cờ onboarding,
/// theme, khoá hiệu ứng). Từng nằm trong SQLite; chuyển sang
/// shared_preferences vì sqflite không chạy được trên web.
///
/// Giá trị bool vẫn lưu dạng chuỗi 'true'/'false' để giữ đúng ngữ nghĩa cũ
/// và để migration từ DB SQLite cũ chỉ là chép chuỗi nguyên trạng.
class AppSettingsRepository {
  Future<String?> getString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  Future<bool> getBool(String key, {required bool fallback}) async {
    final saved = await getString(key);
    if (saved == 'true') return true;
    if (saved == 'false') return false;
    return fallback;
  }

  Future<void> setBool(String key, bool value) =>
      setString(key, value ? 'true' : 'false');

  Future<void> remove(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
```

- [ ] **Step 4: Chạy test, xác nhận PASS**

Run: `flutter test test/unit/app_settings_repository_test.dart`
Expected: PASS, 10 test.

- [ ] **Step 5: Chạy test phụ thuộc để xác nhận không hồi quy**

Run: `flutter test test/unit/effects_settings_test.dart test/widget/settings_effects_test.dart`
Expected: PASS. Hai file này dùng `MemorySettingsRepository` và `_BrokenSettings` (đều `extends AppSettingsRepository` và override `getString`/`setString`) — chữ ký không đổi nên vẫn biên dịch và pass.

- [ ] **Step 6: Xác nhận analyze sạch**

Run: `flutter analyze lib/data/repositories/app_settings_repository.dart test/unit/app_settings_repository_test.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/data/repositories/app_settings_repository.dart test/unit/app_settings_repository_test.dart
git commit -m "refactor(data): lưu cài đặt thiết bị bằng shared_preferences thay SQLite"
```

---

### Task 2: Migration one-shot từ SQLite cũ

**Files:**
- Create: `lib/data/database/legacy_settings_migration.dart`
- Create: `test/unit/legacy_settings_migration_test.dart`
- Modify: `lib/main.dart:9,19`

**Interfaces:**
- Consumes: `SharedPreferences` (từ Task 1), `sqflite` (`getDatabasesPath`, `databaseExists`, `openDatabase`), `path.join`.
- Produces:
  - `typedef LegacySettingsReader = Future<Map<String, String>> Function();`
  - `class LegacySettingsMigration` với constructor `LegacySettingsMigration({LegacySettingsReader? readLegacySettings})` và method `Future<void> run()`.
  - `static const String LegacySettingsMigration.flagKey = 'legacy_sqlite_migrated';`
  - `static const List<String> LegacySettingsMigration.settingKeys = ['onboarding_complete', 'theme_mode', 'chart_spend_ramp'];`
- Task 5 dựa vào: `legacy_settings_migration.dart` là file **duy nhất** còn import `sqflite`.

- [ ] **Step 1: Viết test thất bại**

Tạo `test/unit/legacy_settings_migration_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pixket/data/database/legacy_settings_migration.dart';

/// DB cũ đầy đủ cả 3 key, như máy người dùng đã xài app một thời gian.
Future<Map<String, String>> _fullLegacyDb() async => const {
  'onboarding_complete': 'true',
  'theme_mode': 'dark',
  'chart_spend_ramp': 'false',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('chép cả 3 key từ DB cũ sang shared_preferences', () async {
    await LegacySettingsMigration(readLegacySettings: _fullLegacyDb).run();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('onboarding_complete'), 'true');
    expect(preferences.getString('theme_mode'), 'dark');
    expect(preferences.getString('chart_spend_ramp'), 'false');
  });

  test('set cờ đã migrate sau khi chạy thành công', () async {
    await LegacySettingsMigration(readLegacySettings: _fullLegacyDb).run();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(LegacySettingsMigration.flagKey),
      isTrue,
    );
  });

  test('không đọc DB cũ lần hai khi cờ đã set', () async {
    var reads = 0;
    Future<Map<String, String>> countingReader() async {
      reads++;
      return _fullLegacyDb();
    }

    SharedPreferences.setMockInitialValues({
      LegacySettingsMigration.flagKey: true,
    });
    await LegacySettingsMigration(readLegacySettings: countingReader).run();

    expect(reads, 0);
  });

  test('không ghi đè key người dùng đã đổi sau migration', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});

    await LegacySettingsMigration(readLegacySettings: _fullLegacyDb).run();

    final preferences = await SharedPreferences.getInstance();
    // theme_mode đã có giá trị mới hơn nên phải giữ 'light', không đè bằng 'dark'.
    expect(preferences.getString('theme_mode'), 'light');
    // Hai key còn lại chưa có thì vẫn được chép.
    expect(preferences.getString('onboarding_complete'), 'true');
    expect(preferences.getString('chart_spend_ramp'), 'false');
  });

  test('không set cờ khi đọc DB cũ ném lỗi, để lần sau thử lại', () async {
    Future<Map<String, String>> brokenReader() async =>
        throw StateError('database is locked');

    await LegacySettingsMigration(readLegacySettings: brokenReader).run();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(LegacySettingsMigration.flagKey), isNull);
  });

  test('không ném ra ngoài khi DB cũ hỏng — app vẫn phải khởi động', () async {
    Future<Map<String, String>> brokenReader() async =>
        throw StateError('no such table: app_settings');

    await expectLater(
      LegacySettingsMigration(readLegacySettings: brokenReader).run(),
      completes,
    );
  });

  test('DB cũ rỗng vẫn set cờ để không đọc lại mãi', () async {
    Future<Map<String, String>> emptyReader() async => const {};

    await LegacySettingsMigration(readLegacySettings: emptyReader).run();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(LegacySettingsMigration.flagKey), isTrue);
  });

  test('đọc DB cũ đúng một lần cho cả 3 key', () async {
    var reads = 0;
    Future<Map<String, String>> countingReader() async {
      reads++;
      return _fullLegacyDb();
    }

    await LegacySettingsMigration(readLegacySettings: countingReader).run();

    expect(reads, 1);
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận FAIL**

Run: `flutter test test/unit/legacy_settings_migration_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:pixket/data/database/legacy_settings_migration.dart'`.

- [ ] **Step 3: Viết implementation**

Tạo `lib/data/database/legacy_settings_migration.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Đọc các khoá cài đặt từ DB SQLite cũ. Tách thành typedef để test tiêm
/// reader giả mà không cần plugin sqflite (không chạy được trong flutter_test).
typedef LegacySettingsReader = Future<Map<String, String>> Function();

/// Chép một lần các khoá cài đặt từ `pixket.db` (tầng SQLite đã bỏ) sang
/// `shared_preferences`. Cài mới không có DB cũ nên bỏ qua ngay; máy đã migrate
/// rồi cũng bỏ qua nhờ [flagKey].
///
/// Không bao giờ ném ra ngoài: migration hỏng thì thà để app khởi động với giá
/// trị mặc định còn hơn chặn người dùng ở màn hình trắng.
class LegacySettingsMigration {
  LegacySettingsMigration({LegacySettingsReader? readLegacySettings})
    : _readLegacySettings = readLegacySettings ?? _readFromSqlite;

  static const String flagKey = 'legacy_sqlite_migrated';

  static const List<String> settingKeys = [
    'onboarding_complete',
    'theme_mode',
    'chart_spend_ramp',
  ];

  static const String _databaseFileName = 'pixket.db';

  final LegacySettingsReader _readLegacySettings;

  Future<void> run() async {
    if (kIsWeb) return;

    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(flagKey) ?? false) return;

    try {
      final legacy = await _readLegacySettings();
      for (final key in settingKeys) {
        final value = legacy[key];
        if (value == null) continue;
        // Không ghi đè: người dùng có thể đã đổi cài đặt sau khi bản mới chạy,
        // và migration có thể được thử lại ở lần khởi động sau.
        if (preferences.getString(key) != null) continue;
        await preferences.setString(key, value);
      }
      await preferences.setBool(flagKey, true);
    } catch (error) {
      // Không set cờ: lần khởi động sau thử lại.
      debugPrint('Không migrate được cài đặt từ SQLite cũ: $error');
    }
  }
}

Future<Map<String, String>> _readFromSqlite() async {
  final path = p.join(
    await getDatabasesPath(),
    LegacySettingsMigration._databaseFileName,
  );
  // databaseExists chứ không phải openDatabase: cài mới mà mở DB sẽ tạo ra một
  // pixket.db rỗng vô nghĩa ngay trước khi tầng SQLite bị gỡ hẳn.
  if (!await databaseExists(path)) return const {};

  final database = await openDatabase(path, readOnly: true);
  try {
    final rows = await database.query('app_settings');
    return {
      for (final row in rows)
        row['key'] as String: row['value'] as String,
    };
  } finally {
    await database.close();
  }
}
```

- [ ] **Step 4: Chạy test, xác nhận PASS**

Run: `flutter test test/unit/legacy_settings_migration_test.dart`
Expected: PASS, 8 test.

- [ ] **Step 5: Nối vào `main.dart`**

Sửa `lib/main.dart`. Thay import ở dòng 9:

```dart
import 'data/database/legacy_settings_migration.dart';
```

(thay cho `import 'data/database/database_helper.dart';`)

Và thay dòng 19 `await DatabaseHelper.instance.database;` bằng:

```dart
  await LegacySettingsMigration().run();
```

`main()` hoàn chỉnh sau khi sửa:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPrint ủy quyền cho print nên vẫn ghi logcat ở bản release. Tắt nó
  // trong release để stack trace và chi tiết lỗi backend không rơi ra log máy.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await LegacySettingsMigration().run();
  await SupabaseConfig.initialize();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: PixketApp()));
}
```

Migration phải chạy **trước** `runApp` vì `ThemeNotifier` và `AppSettingsNotifier` đọc các key này ngay trong constructor của chúng.

- [ ] **Step 6: Xác nhận analyze sạch**

Run: `flutter analyze lib/main.dart lib/data/database/legacy_settings_migration.dart`
Expected: `No issues found!`

- [ ] **Step 7: Xác nhận không còn ai import `database_helper.dart` ngoài file sắp xóa**

Run: `grep -rn "database_helper" lib test`
Expected: đúng **một** dòng — import trong `lib/data/repositories/priority_repository.dart` (sẽ dọn ở Task 4). Lưu ý `database_helper.dart` **không tự chứa tên file của chính nó** (nó khai báo `class DatabaseHelper`), nên không xuất hiện trong kết quả grep này; xác nhận nó vẫn còn bằng `ls lib/data/database/database_helper.dart`. Nếu grep ra thêm file thứ hai thì dừng lại và báo — nghĩa là có chỗ dùng SQLite chưa được khảo sát.

- [ ] **Step 8: Chạy toàn bộ test**

Run: `flutter test`
Expected: `All tests passed!`. Baseline là 374 pass / 7 skip / 0 fail; sau Task 1 và Task 2 số pass phải là **392** (thêm 10 test ở Task 1 và 8 test ở Task 2), 0 fail. Nếu có bất kỳ test nào fail thì dừng lại, ghi tên test vào report, không sang Task 3.

Xác nhận thêm: cảnh báo `Bad state: databaseFactory not initialized` phải **không còn** xuất hiện trong output (xem Global Constraints).

- [ ] **Step 9: Commit**

```bash
git add lib/data/database/legacy_settings_migration.dart test/unit/legacy_settings_migration_test.dart lib/main.dart
git commit -m "feat(data): migration một lần cài đặt từ SQLite sang shared_preferences"
```

---

### Task 3: Bảng `priority_levels` hệ thống trên Supabase

**Files:**
- Modify: `supabase_setup.sql` — thêm section 5.1, policy ở section 6, query ở section 9

**Interfaces:**
- Consumes: không có (SQL thuần).
- Produces: bảng `public.priority_levels` với các cột `id BIGINT identity`, `level_key INT NOT NULL UNIQUE`, `name TEXT NOT NULL`, `color_value BIGINT NOT NULL`, `sort_order INT NOT NULL`; RLS bật; policy SELECT cho role `authenticated`; 4 dòng seed. Task 4 đọc bảng này qua `select().order('sort_order')`.

**Lưu ý:** task này **không có test tự động** — repo không có harness chạy Postgres. Kiểm chứng bằng cách chạy SQL trong Supabase Dashboard và đọc query ở section 9. Cần chủ repo có quyền vào Dashboard.

- [ ] **Step 1: Thêm section 5.1 vào `supabase_setup.sql`**

Chèn **ngay trước** dòng `-- 6. ROW LEVEL SECURITY` (hiện ở dòng 202):

```sql
-- 5.1 BẢNG PRIORITY_LEVELS (dữ liệu hệ thống, client chỉ đọc)
-- 4 mức độ cần thiết từng nằm trong SQLite local. Không có user_id vì không
-- màn hình nào cho phép người dùng thêm/sửa mức; mọi user thấy cùng 4 dòng.
-- level_key là giá trị mà cột expenses.priority trỏ tới, nên phải khớp
-- constraint expenses_priority_range CHECK (priority BETWEEN 0 AND 3).
CREATE TABLE IF NOT EXISTS public.priority_levels (
    id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    level_key   INT NOT NULL UNIQUE,
    name        TEXT NOT NULL,
    color_value BIGINT NOT NULL,
    sort_order  INT NOT NULL
);

-- Màu viết bằng cast hex để đối chiếu được với 0xFF43A047 / 0xFF1E88E5 /
-- 0xFFFB8C00 / 0xFFE53935 trong code cũ, tránh chép sai số thập phân.
INSERT INTO public.priority_levels (level_key, name, color_value, sort_order)
VALUES
    (0, 'Thiết yếu', ('xFF43A047')::bit(32)::bigint, 0),
    (1, 'Rất cần',   ('xFF1E88E5')::bit(32)::bigint, 1),
    (2, 'Cần vừa',   ('xFFFB8C00')::bit(32)::bigint, 2),
    (3, 'Chưa cần',  ('xFFE53935')::bit(32)::bigint, 3)
ON CONFLICT (level_key) DO NOTHING;
```

- [ ] **Step 2: Thêm RLS và policy**

Trong section 6, thêm một dòng vào cuối khối `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` (ngay sau dòng `ALTER TABLE public.budget_alerts ENABLE ROW LEVEL SECURITY;`):

```sql
ALTER TABLE public.priority_levels ENABLE ROW LEVEL SECURITY;
```

Và thêm policy vào cuối khối policy của section 6 (ngay sau policy `"Users can manage own alerts"`):

```sql
-- Bảng hệ thống, không có user_id: client chỉ đọc, không bao giờ ghi.
DROP POLICY IF EXISTS "Anyone authenticated can view priority levels" ON public.priority_levels;
CREATE POLICY "Anyone authenticated can view priority levels" ON public.priority_levels
    FOR SELECT TO authenticated USING (true);
```

Chỉ một policy SELECT. Không thêm INSERT/UPDATE/DELETE vì client không ghi — bảng được seed bằng SQL chạy với quyền cao hơn RLS.

- [ ] **Step 3: Thêm query kiểm tra vào section 9**

Nối vào cuối file `supabase_setup.sql`, sau query `receipt_policies`:

```sql
-- priority_levels phải có đúng 4 dòng hệ thống và màu khớp code cũ
SELECT 'priority_levels_rows' AS check_name, count(*)::text AS expected_four
FROM public.priority_levels;

SELECT 'priority_levels_colors' AS check_name,
       string_agg(level_key || ':' || color_value, ',' ORDER BY sort_order)
           AS expected_colors
FROM public.priority_levels;
-- Kỳ vọng: 0:4282622023,1:4280191205,2:4294675456,3:4293212469
```

Đồng thời sửa comment header của section 9 (dòng 303) để nêu đủ kỳ vọng:

```sql
-- 9. KIỂM TRA SAU KHI CHẠY (kỳ vọng: bucket_public = false, receipt_policies = 4,
--    priority_levels_rows = 4, priority_levels_colors khớp 4 mã màu)
```

- [ ] **Step 4: Kiểm chứng idempotent bằng cách đọc lại file**

Run: `grep -n "priority_levels" supabase_setup.sql`
Expected: thấy `CREATE TABLE IF NOT EXISTS`, `ON CONFLICT (level_key) DO NOTHING`, `DROP POLICY IF EXISTS`, `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`. Cả bốn đều an toàn khi chạy lại. Nếu thiếu `IF NOT EXISTS` hoặc `ON CONFLICT` thì sửa trước khi sang bước sau.

- [ ] **Step 5: Chạy SQL trong Supabase Dashboard (cần chủ repo)**

Dừng lại và đưa cho chủ repo: mở Supabase Dashboard → SQL Editor → dán toàn bộ `supabase_setup.sql` → RUN. File này idempotent nên chạy lại toàn bộ là an toàn và đúng hướng dẫn ở header dòng 3.

Yêu cầu chủ repo báo lại kết quả 2 query mới:
- `priority_levels_rows` phải là `4`
- `priority_levels_colors` phải là `0:4282622023,1:4280191205,2:4294675456,3:4293212469`

Không sang Task 4 cho tới khi hai giá trị này đúng — Task 4 sẽ đọc bảng này.

- [ ] **Step 6: Commit**

```bash
git add supabase_setup.sql
git commit -m "feat(db): thêm bảng priority_levels hệ thống read-only cho bản web"
```

---

### Task 4: `PriorityRepository` đọc Supabase, xóa code chết

**Files:**
- Create: `lib/data/repositories/priority_row_reader.dart`
- Modify: `lib/data/models/priority_level.dart` (thêm factory, ~10 dòng)
- Modify: `lib/data/repositories/priority_repository.dart` (viết lại, từ 49 dòng còn ~20)
- Modify: `lib/providers/priority_provider.dart` (xóa 3 method)
- Test: `test/unit/priority_repository_test.dart` (tạo mới)

**Interfaces:**
- Consumes: bảng `public.priority_levels` từ Task 3; `SupabaseConfig.client` (`lib/core/config/supabase_config.dart`); mẫu `_client()` trong `lib/data/repositories/expense_row_writer.dart:16-26`.
- Produces:
  - `abstract class PriorityRowReader { Future<List<Map<String, dynamic>>> readAll(); }`
  - `class SupabasePriorityRowReader implements PriorityRowReader`
  - `PriorityLevel.fromSupabaseRow(Map<String, dynamic> row)` → `PriorityLevel`
  - `PriorityRepository({PriorityRowReader? reader})` với `Future<List<PriorityLevel>> getAll()`
  - `PriorityNotifier` chỉ còn `loadLevels()`; `priorityProvider` không đổi.

- [ ] **Step 1: Viết test thất bại**

Tạo `test/unit/priority_repository_test.dart`:

```dart
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/data/models/priority_level.dart';
import 'package:pixket/data/repositories/priority_repository.dart';
import 'package:pixket/data/repositories/priority_row_reader.dart';

class _FakeReader implements PriorityRowReader {
  _FakeReader(this.rows);

  final List<Map<String, dynamic>> rows;
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> readAll() async {
    calls++;
    return rows;
  }
}

class _ThrowingReader implements PriorityRowReader {
  @override
  Future<List<Map<String, dynamic>>> readAll() async => throw StateError(
    'Chưa kết nối được Supabase. Vui lòng kiểm tra mạng.',
  );
}

/// Đúng 4 dòng mà section 5.1 của supabase_setup.sql seed.
const List<Map<String, dynamic>> _seededRows = [
  {
    'id': 1,
    'level_key': 0,
    'name': 'Thiết yếu',
    'color_value': 4282622023,
    'sort_order': 0,
  },
  {
    'id': 2,
    'level_key': 1,
    'name': 'Rất cần',
    'color_value': 4280191205,
    'sort_order': 1,
  },
  {
    'id': 3,
    'level_key': 2,
    'name': 'Cần vừa',
    'color_value': 4294675456,
    'sort_order': 2,
  },
  {
    'id': 4,
    'level_key': 3,
    'name': 'Chưa cần',
    'color_value': 4293212469,
    'sort_order': 3,
  },
];

void main() {
  group('PriorityLevel.fromSupabaseRow', () {
    test('ánh xạ level_key thành id, bỏ qua cột id của bảng', () {
      final level = PriorityLevel.fromSupabaseRow(_seededRows[2]);

      // id của PriorityLevel là thứ expenses.priority trỏ tới, tức level_key
      // (2), KHÔNG phải identity của bảng (3).
      expect(level.id, 2);
      expect(level.name, 'Cần vừa');
      expect(level.sortOrder, 2);
    });

    test('giữ đúng 4 mã màu của bản SQLite cũ', () {
      final levels = _seededRows.map(PriorityLevel.fromSupabaseRow).toList();

      expect(levels[0].color, const Color(0xFF43A047));
      expect(levels[1].color, const Color(0xFF1E88E5));
      expect(levels[2].color, const Color(0xFFFB8C00));
      expect(levels[3].color, const Color(0xFFE53935));
    });

    test('đọc được color_value khi Postgres trả về số thực', () {
      final level = PriorityLevel.fromSupabaseRow(const {
        'level_key': 1,
        'name': 'Rất cần',
        'color_value': 4280191205.0,
        'sort_order': 1.0,
      });

      expect(level.colorValue, 0xFF1E88E5);
      expect(level.sortOrder, 1);
    });
  });

  group('PriorityRepository.getAll', () {
    test('trả 4 mức đúng thứ tự sort_order', () async {
      final repository = PriorityRepository(reader: _FakeReader(_seededRows));

      final levels = await repository.getAll();

      expect(levels.map((level) => level.id), [0, 1, 2, 3]);
      expect(levels.map((level) => level.name), [
        'Thiết yếu',
        'Rất cần',
        'Cần vừa',
        'Chưa cần',
      ]);
    });

    test('danh sách rỗng trả về rỗng, không ném', () async {
      final repository = PriorityRepository(reader: _FakeReader(const []));

      expect(await repository.getAll(), isEmpty);
    });

    test('lan truyền StateError khi Supabase chưa kết nối', () async {
      final repository = PriorityRepository(reader: _ThrowingReader());

      await expectLater(repository.getAll(), throwsStateError);
    });

    test('gọi reader đúng một lần', () async {
      final reader = _FakeReader(_seededRows);
      await PriorityRepository(reader: reader).getAll();

      expect(reader.calls, 1);
    });
  });

  group('toMap / fromMap cũ vẫn chạy', () {
    test('fromMap đọc lại đúng map mà toMap sinh ra', () {
      const level = PriorityLevel(
        id: 2,
        name: 'Cần vừa',
        colorValue: 0xFFFB8C00,
        sortOrder: 2,
      );

      expect(PriorityLevel.fromMap(level.toMap()).id, 2);
      expect(PriorityLevel.fromMap(level.toMap()).colorValue, 0xFFFB8C00);
    });
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận FAIL**

Run: `flutter test test/unit/priority_repository_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:pixket/data/repositories/priority_row_reader.dart'`.

- [ ] **Step 3: Tạo `priority_row_reader.dart`**

Tạo `lib/data/repositories/priority_row_reader.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Gom việc đọc bảng priority_levels để repository test được bằng reader giả.
/// Mẫu lấy từ ExpenseRowWriter.
abstract class PriorityRowReader {
  Future<List<Map<String, dynamic>>> readAll();
}

class SupabasePriorityRowReader implements PriorityRowReader {
  SupabaseClient _client() {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Chưa kết nối được Supabase. Vui lòng kiểm tra mạng.');
    }
    // Bảng không có user_id nhưng policy chỉ mở cho role authenticated,
    // nên chưa đăng nhập thì đọc cũng trả về rỗng — báo rõ cho người dùng.
    if (client.auth.currentUser == null) {
      throw StateError('Vui lòng đăng nhập để tiếp tục.');
    }
    return client;
  }

  @override
  Future<List<Map<String, dynamic>>> readAll() async {
    final rows = await _client()
        .from('priority_levels')
        .select()
        .order('sort_order', ascending: true);
    return (rows as List).map((row) => row as Map<String, dynamic>).toList();
  }
}
```

- [ ] **Step 4: Thêm `fromSupabaseRow` vào model**

Trong `lib/data/models/priority_level.dart`, thêm factory này **ngay sau** factory `fromMap` hiện có (giữ nguyên `fromMap`/`toMap` vì `test/unit/models_test.dart` có thể đang dùng):

```dart
  /// Row từ bảng Supabase `priority_levels`. `level_key` mới là giá trị mà
  /// `expenses.priority` trỏ tới, còn `id` của bảng chỉ là identity nội bộ.
  factory PriorityLevel.fromSupabaseRow(Map<String, dynamic> row) =>
      PriorityLevel(
        id: (row['level_key'] as num).toInt(),
        name: row['name'] as String,
        colorValue: (row['color_value'] as num).toInt(),
        sortOrder: (row['sort_order'] as num).toInt(),
      );
```

Cast qua `num` rồi `.toInt()` vì PostgREST có thể trả `bigint`/`numeric` dưới dạng số thực.

- [ ] **Step 5: Viết lại `priority_repository.dart`**

Thay **toàn bộ** nội dung `lib/data/repositories/priority_repository.dart` bằng:

```dart
import '../models/priority_level.dart';
import 'priority_row_reader.dart';

/// Mức độ cần thiết là dữ liệu hệ thống cố định (4 dòng seed trong
/// supabase_setup.sql), client chỉ đọc. Các method ghi từng có ở đây
/// (insert/update/deleteAndMoveExpenses/nextId) không màn hình nào gọi và đã bị
/// gỡ; thêm lại khi thực sự có UI quản lý mức độ.
class PriorityRepository {
  PriorityRepository({PriorityRowReader? reader})
    : _reader = reader ?? SupabasePriorityRowReader();

  final PriorityRowReader _reader;

  Future<List<PriorityLevel>> getAll() async {
    final rows = await _reader.readAll();
    return rows.map(PriorityLevel.fromSupabaseRow).toList();
  }
}
```

- [ ] **Step 6: Xóa 3 method chết khỏi provider**

Trong `lib/providers/priority_provider.dart`, **xóa** ba method `addLevel` (dòng 32-38), `updateLevel` (dòng 40-43), `deleteLevel` (dòng 45-50). Giữ nguyên `PriorityState`, `loadLevels()`, constructor và `priorityProvider`.

File sau khi sửa:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/priority_level.dart';
import '../data/repositories/priority_repository.dart';

class PriorityState {
  final List<PriorityLevel> levels;
  final bool isLoading;

  const PriorityState({this.levels = const [], this.isLoading = false});

  PriorityState copyWith({List<PriorityLevel>? levels, bool? isLoading}) =>
      PriorityState(
        levels: levels ?? this.levels,
        isLoading: isLoading ?? this.isLoading,
      );
}

class PriorityNotifier extends StateNotifier<PriorityState> {
  PriorityNotifier() : super(const PriorityState()) {
    loadLevels();
  }

  final PriorityRepository _repository = PriorityRepository();

  Future<void> loadLevels() async {
    state = state.copyWith(isLoading: true);
    try {
      final levels = await _repository.getAll();
      state = state.copyWith(levels: levels, isLoading: false);
    } catch (error) {
      // Supabase chưa kết nối hoặc chưa đăng nhập: giữ danh sách rỗng để UI
      // hiện placeholder thay vì để lỗi lan lên làm sập màn hình.
      state = state.copyWith(isLoading: false);
    }
  }
}

final priorityProvider = StateNotifierProvider<PriorityNotifier, PriorityState>(
  (ref) => PriorityNotifier(),
);
```

Khác biệt có chủ đích so với bản cũ: `loadLevels` bọc `try/catch`. Bản cũ gọi `_repository.getAll()` trên SQLite local nên không bao giờ ném; bản mới gọi Supabase nên **sẽ** ném `StateError` khi mất mạng hoặc chưa đăng nhập. Không catch thì constructor của notifier ném và sập cả màn hình.

- [ ] **Step 7: Chạy test mới, xác nhận PASS**

Run: `flutter test test/unit/priority_repository_test.dart`
Expected: PASS, 8 test.

- [ ] **Step 8: Chạy test đụng `priorityProvider`, xác nhận không hồi quy**

Run: `flutter test test/widget/dashboard_pixel_test.dart test/widget/expense_form_pixel_test.dart test/widget/feed_hud_test.dart test/tool/demo_screenshots_test.dart`
Expected: PASS. Bốn file này override `priorityProvider` bằng `FakePriorityNotifier` (`test/support/fakes.dart:52-56`, dùng `noSuchMethod`) nên việc bớt 3 method không làm vỡ chúng.

Nếu `demo_screenshots_test.dart` skip vì thiếu `PIXKET_GEN_SHOTS=1` thì đó là hành vi đúng, không phải lỗi.

- [ ] **Step 9: Analyze sạch**

Run: `flutter analyze lib/data/models/priority_level.dart lib/data/repositories/priority_repository.dart lib/data/repositories/priority_row_reader.dart lib/providers/priority_provider.dart`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add lib/data/models/priority_level.dart lib/data/repositories/priority_repository.dart lib/data/repositories/priority_row_reader.dart lib/providers/priority_provider.dart test/unit/priority_repository_test.dart
git commit -m "refactor(data): đọc mức độ cần thiết từ Supabase, gỡ method không ai gọi"
```

---

### Task 5: Xóa `database_helper.dart` và `path_provider`, cập nhật docs

**Files:**
- Delete: `lib/data/database/database_helper.dart`
- Modify: `pubspec.yaml` (gỡ `path_provider`)
- Modify: `docs/project-structure.md`

**Interfaces:**
- Consumes: kết quả Task 1, 2, 4 — sau ba task đó không còn ai dùng `DatabaseHelper`.
- Produces: `grep -rn "DatabaseHelper" lib` trả về rỗng; `grep -rln "package:sqflite" lib` chỉ trả về đúng `lib/data/database/legacy_settings_migration.dart`.

- [ ] **Step 1: Xác nhận không còn ai dùng `DatabaseHelper`**

Run: `grep -rn "DatabaseHelper" lib test`
Expected: chỉ còn `lib/data/database/database_helper.dart` (chính nó) và comment ở `test/support/memory_settings.dart:4`. Nếu còn file nào khác trong `lib/` thì **dừng lại** — Task 1/2/4 chưa dọn hết.

- [ ] **Step 2: Cập nhật comment lỗi thời trong test support**

Trong `test/support/memory_settings.dart`, dòng 3-4 đang viết "mà không chạm sqflite (DatabaseHelper không chạy được trong flutter_test)". Sau khi bỏ SQLite, lý do đó không còn đúng. Thay doc comment bằng:

```dart
/// Repository trong bộ nhớ cho test: chạy đúng code getBool/setString thật
/// mà không chạm SharedPreferences, để test kiểm soát được giá trị ban đầu.
```

- [ ] **Step 3: Xóa file**

```bash
git rm lib/data/database/database_helper.dart
```

- [ ] **Step 4: Xác nhận `path_provider` thực sự không được dùng**

Run: `grep -rn "path_provider\|getApplicationDocumentsDirectory\|getApplicationSupportDirectory\|getTemporaryDirectory" lib test`
Expected: **rỗng**. (`getDatabasesPath()` trong migration là của `sqflite`, không phải `path_provider`.)

Nếu ra kết quả nào thì dừng lại và báo — nghĩa là có chỗ dùng `path_provider` chưa được khảo sát, không được gỡ.

- [ ] **Step 5: Gỡ `path_provider` khỏi `pubspec.yaml`**

Xóa dòng `  path_provider: ^2.1.5` khỏi khối `dependencies`. **Giữ nguyên** `  sqflite: ^2.4.2` và `  path: ^1.9.1` — `sqflite` cần cho migration, `path` cần cho `p.join` trong migration.

Sau đó chạy: `flutter pub get`
Expected: resolve thành công, không báo thiếu package.

- [ ] **Step 6: Xác nhận không package nào cần `path_provider` làm peer**

Run: `flutter pub deps | grep -i path_provider`
Expected: nếu còn xuất hiện thì đó là **transitive dependency** của package khác (ví dụ `flutter_cache_manager`) — khi đó việc gỡ khỏi `pubspec.yaml` vẫn đúng vì ta không dùng trực tiếp, nhưng ghi nhận lại để Plan 2 xử lý `flutter_cache_manager`.

- [ ] **Step 7: Analyze + toàn bộ test**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `All tests passed!`, 0 fail. Số pass phải là **400** (374 baseline + 10 ở Task 1 + 8 ở Task 2 + 8 ở Task 4), 7 skip. Nếu thiếu hoặc thừa test so với con số này thì kiểm tra lại xem có file test nào bị bỏ sót không.

- [ ] **Step 8: Cập nhật `docs/project-structure.md`**

Trong cây thư mục của docs, sửa hai dòng mô tả đã lỗi thời:

- Dòng `│   ├── database/database_helper.dart    # SQLite: onboarding + mức độ cần thiết` → **xóa** dòng này (file không còn).
- Dòng `│   │       ├── app_settings_repository.dart # onboarding (SQLite)` → đổi thành
  `│   │       ├── app_settings_repository.dart # onboarding + theme + effect (shared_preferences)`
- Dòng `│   │       ├── priority_repository.dart     # mức độ cần thiết (SQLite)` → đổi thành
  `│   │       ├── priority_repository.dart     # mức độ cần thiết (Supabase, read-only)`
- Thêm vào cùng cấp với `app_settings_repository.dart`:
  `│   │       ├── priority_row_reader.dart     # Seam đọc priority_levels, tiêm được cho test`
- Trong mục mô tả `main.dart` (dòng 13: `│   ├── main.dart                        # Entry point: dotenv, Supabase, SQLite, ProviderScope`) → đổi thành
  `│   ├── main.dart                        # Entry point: dotenv, migration SQLite cũ, Supabase, ProviderScope`
- **Dòng 303** (ngoài cây thư mục, trong phần quy ước): `4. Nếu đổi cấu trúc bảng, cập nhật cả \`database_helper.dart\`, \`supabase_setup.sql\` và model \`toMap/fromMap\`.` → đổi thành
  ``4. Nếu đổi cấu trúc bảng, cập nhật `supabase_setup.sql` và model `toMap/fromMap`.``

Số dòng lấy từ `grep -n "database_helper\|app_settings_repository\|priority_repository\|main.dart  *#" docs/project-structure.md` — nếu lệch thì dò theo nội dung chứ không theo số dòng.

Nếu file docs còn chỗ nào khác nhắc "SQLite" cho hai bảng này thì sửa luôn cho nhất quán:

Run: `grep -n "SQLite\|sqflite" docs/project-structure.md`

- [ ] **Step 9: Xác nhận ranh giới sqflite đúng như thiết kế**

Run: `grep -rln "package:sqflite" lib`
Expected: đúng **một** dòng `lib/data/database/legacy_settings_migration.dart`. Nếu ra thêm file nào thì Task 1/2/4 đã bỏ sót.

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml pubspec.lock test/support/memory_settings.dart docs/project-structure.md
git commit -m "refactor: gỡ tầng SQLite local và dependency path_provider"
```

Việc xóa `database_helper.dart` đã được stage từ `git rm` ở Step 3, nên chỉ cần thêm bốn file còn lại. Chạy `git status` trước khi commit: phải thấy `deleted: lib/data/database/database_helper.dart` **và** bốn file modified, không có file lạ nào (`.graphifyignore`, spec, plan đều **không** thuộc commit này).

---

## Kiểm chứng cuối plan

Sau Task 5, chạy lần lượt và đối chiếu:

| Lệnh | Kỳ vọng |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` | `All tests passed!` — 400 pass / 7 skip / 0 fail, và không còn dòng `databaseFactory not initialized` |
| `grep -rn "DatabaseHelper" lib` | rỗng |
| `grep -rln "package:sqflite" lib` | đúng 1 file: `legacy_settings_migration.dart` |
| `grep -rn "path_provider" pubspec.yaml` | rỗng |
| `flutter build apk --debug` | build thành công — xác nhận bản Android không vỡ |

**Kiểm thử thủ công bắt buộc trên thiết bị Android thật** (không thể thay bằng `flutter test`):

1. Cài bản APK **cũ** (trước plan này), mở app, đổi theme sang dark, đi hết onboarding, tắt một hiệu ứng biểu đồ.
2. Cài đè bản APK **mới** lên, mở app.
3. Xác nhận: **không** bị đưa lại vào màn onboarding, theme vẫn là dark, hiệu ứng biểu đồ vẫn tắt.
4. Vào một khoản chi, xác nhận 4 mức độ cần thiết hiện ra với **đúng màu cũ** (xanh lá / xanh dương / cam / đỏ).
5. Cài **fresh** (gỡ app rồi cài lại), xác nhận vào màn onboarding bình thường và không crash.

Bước 1-3 là toàn bộ lý do tồn tại của Task 2. Nếu skip thì migration coi như chưa được kiểm chứng.

## Việc còn lại sau plan này

- **Plan 2** (`2026-11-04-web-platform-boundary.md`): 5 interface conditional import, `squareBytes` IO/Web, upload theo bytes, bỏ `cached_network_image`/`flutter_cache_manager` khỏi code chung, boundary test → `flutter build web --release` compile sạch.
- **Plan 3** (`2026-11-04-pwa-shell-and-deploy.md`): manifest đúng brand, icon sinh từ `PixelLogo`, `index.html`, `deploy-web.yml`, Supabase redirect URL, Lighthouse.
- **Release kế tiếp sau Plan 1:** gỡ `sqflite` khỏi `pubspec.yaml` và xóa `legacy_settings_migration.dart`, khi mọi user đã chạy migration.
