import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class AppSettingsRepository {
  Future<String?> getString(String key) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setString(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
    final db = await DatabaseHelper.instance.database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }
}
