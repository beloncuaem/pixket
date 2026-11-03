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
