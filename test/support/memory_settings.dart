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
