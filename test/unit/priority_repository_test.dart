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
  Future<List<Map<String, dynamic>>> readAll() async =>
      throw StateError('Chưa kết nối được Supabase. Vui lòng kiểm tra mạng.');
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
