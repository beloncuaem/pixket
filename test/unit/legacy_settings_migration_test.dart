import 'package:flutter/foundation.dart';
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

  // debugDefaultTargetPlatformOverride là global: không reset thì nền tảng giả
  // của test này rò rỉ sang test khác.
  tearDown(() => debugDefaultTargetPlatformOverride = null);

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
    expect(preferences.getBool(LegacySettingsMigration.flagKey), isTrue);
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

  test('desktop bỏ qua hẳn: không đọc DB cũ, không set cờ', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var reads = 0;
    Future<Map<String, String>> countingReader() async {
      reads++;
      return _fullLegacyDb();
    }

    await LegacySettingsMigration(readLegacySettings: countingReader).run();

    expect(reads, 0);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(LegacySettingsMigration.flagKey), isNull);
  });

  test('Android vẫn migrate: guard mới không chặn nền tảng thật', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await LegacySettingsMigration(readLegacySettings: _fullLegacyDb).run();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('onboarding_complete'), 'true');
    expect(preferences.getString('theme_mode'), 'dark');
    expect(preferences.getString('chart_spend_ramp'), 'false');
    expect(preferences.getBool(LegacySettingsMigration.flagKey), isTrue);
  });
}
