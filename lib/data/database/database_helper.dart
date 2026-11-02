import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _databaseVersion = 5;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pixket.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT,
        caption TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        priority INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL,
        category_id INTEGER,
        amount REAL NOT NULL,
        UNIQUE(month, category_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE priority_levels (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_alerts (
        month TEXT NOT NULL,
        threshold INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (month, threshold)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_expenses_active_created_at ON expenses(deleted_at, created_at DESC)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_total_budget_month ON budgets(month) WHERE category_id IS NULL',
    );

    // Insert default categories
    final now = DateTime.now().toIso8601String();
    final defaults = [
      {'name': 'Ăn uống', 'icon': '🍜'},
      {'name': 'Nhà ở', 'icon': '🏠'},
      {'name': 'Đi lại', 'icon': '🚗'},
      {'name': 'Sinh hoạt', 'icon': '🛒'},
      {'name': 'Học tập', 'icon': '📚'},
      {'name': 'Giải trí', 'icon': '🎮'},
      {'name': 'Mua sắm', 'icon': '👕'},
      {'name': 'Sức khỏe', 'icon': '💊'},
      {'name': 'Khác', 'icon': '🎁'},
    ];

    for (var cat in defaults) {
      await db.insert('categories', {
        'name': cat['name'],
        'icon': cat['icon'],
        'is_default': 1,
        'created_at': now,
      });
    }

    await _insertDefaultPriorityLevels(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE expenses ADD COLUMN deleted_at TEXT');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_active_created_at ON expenses(deleted_at, created_at DESC)',
      );
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS priority_levels (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          sort_order INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await _insertDefaultPriorityLevels(db);
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_alerts (
          month TEXT NOT NULL,
          threshold INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          PRIMARY KEY (month, threshold)
        )
      ''');
    }

    if (oldVersion < 5) {
      final duplicateMonths = await db.rawQuery('''
        SELECT month, MAX(id) AS keep_id
        FROM budgets
        WHERE category_id IS NULL
        GROUP BY month
        HAVING COUNT(*) > 1
      ''');
      for (final row in duplicateMonths) {
        await db.delete(
          'budgets',
          where: 'month = ? AND category_id IS NULL AND id != ?',
          whereArgs: [row['month'], row['keep_id']],
        );
      }
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_total_budget_month ON budgets(month) WHERE category_id IS NULL',
      );
    }
  }

  Future<void> _insertDefaultPriorityLevels(Database db) async {
    const defaults = [
      {'id': 0, 'name': 'Thiết yếu', 'color': 0xFF43A047, 'order': 0},
      {'id': 1, 'name': 'Rất cần', 'color': 0xFF1E88E5, 'order': 1},
      {'id': 2, 'name': 'Cần vừa', 'color': 0xFFFB8C00, 'order': 2},
      {'id': 3, 'name': 'Chưa cần', 'color': 0xFFE53935, 'order': 3},
    ];

    for (final level in defaults) {
      await db.insert('priority_levels', {
        'id': level['id'],
        'name': level['name'],
        'color_value': level['color'],
        'sort_order': level['order'],
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
