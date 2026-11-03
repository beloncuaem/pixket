import 'package:flutter/material.dart';

class PriorityLevel {
  final int id;
  final String name;
  final int colorValue;
  final int sortOrder;

  const PriorityLevel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.sortOrder,
  });

  Color get color => Color(colorValue);

  PriorityLevel copyWith({String? name, int? colorValue, int? sortOrder}) {
    return PriorityLevel(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color_value': colorValue,
    'sort_order': sortOrder,
  };

  factory PriorityLevel.fromMap(Map<String, dynamic> map) => PriorityLevel(
    id: map['id'] as int,
    name: map['name'] as String,
    colorValue: map['color_value'] as int,
    sortOrder: map['sort_order'] as int,
  );

  /// Row từ bảng Supabase `priority_levels`. `level_key` mới là giá trị mà
  /// `expenses.priority` trỏ tới, còn `id` của bảng chỉ là identity nội bộ.
  factory PriorityLevel.fromSupabaseRow(Map<String, dynamic> row) =>
      PriorityLevel(
        id: (row['level_key'] as num).toInt(),
        name: row['name'] as String,
        colorValue: (row['color_value'] as num).toInt(),
        sortOrder: (row['sort_order'] as num).toInt(),
      );
}
