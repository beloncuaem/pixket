import 'package:pixket/data/repositories/app_settings_repository.dart';

/// Repository trong bộ nhớ cho test: chạy đúng code getBool/setString thật
/// mà không chạm SharedPreferences, để test kiểm soát được giá trị ban đầu.
class MemorySettingsRepository extends AppSettingsRepository {
  final Map<String, String> store = {};

  @override
  Future<String?> getString(String key) async => store[key];

  @override
  Future<void> setString(String key, String value) async => store[key] = value;
}
