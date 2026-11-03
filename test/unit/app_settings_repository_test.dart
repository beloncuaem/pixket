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
