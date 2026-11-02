import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/category.dart';

class CategoryRepository {
  SupabaseClient _requireClient() {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Chưa kết nối được Supabase. Vui lòng kiểm tra mạng.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('Vui lòng đăng nhập để tiếp tục.');
    }
    return client;
  }

  Category _fromRow(Map<String, dynamic> row) {
    return Category(
      id: row['id'] as int?,
      name: row['name'] as String,
      icon: (row['icon'] as String?) ?? 'dotsThreeOutline',
      isDefault: (row['is_default'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse((row['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Future<List<Category>> getAll() async {
    final client = _requireClient();
    final data = await client
        .from('categories')
        .select()
        .order('is_default', ascending: false)
        .order('name');

    return (data as List)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<Category>> getCategories() async {
    return getAll();
  }

  Future<Category?> getById(int id) async {
    final client = _requireClient();
    final data = await client
        .from('categories')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : _fromRow(data);
  }

  Future<int> insert(Category category) async {
    final client = _requireClient();
    final row = await client
        .from('categories')
        .insert({
          'user_id': client.auth.currentUser!.id,
          'name': category.name,
          'icon': category.icon,
          'color_hex': '#10B981',
          'is_default': false,
        })
        .select()
        .single();
    return row['id'] as int;
  }

  Future<int> insertCategory(Category category) async {
    return insert(category);
  }

  Future<int> update(Category category) async {
    final client = _requireClient();
    final id = category.id;
    if (id == null) {
      throw StateError('Không tìm thấy danh mục cần cập nhật.');
    }
    await client
        .from('categories')
        .update({'name': category.name, 'icon': category.icon})
        .eq('id', id);
    return 1;
  }

  Future<Category?> getOtherCategory() async {
    final all = await getAll();
    try {
      return all.firstWhere((c) => c.name.toLowerCase() == 'khác');
    } catch (_) {
      return all.isNotEmpty ? all.first : null;
    }
  }

  Future<int> deleteAndMoveExpensesToOther(int id) async {
    final client = _requireClient();
    final other = await getOtherCategory();
    if (other == null || other.id == null) {
      throw StateError('Không tìm thấy danh mục Khác để chuyển khoản chi.');
    }
    if (other.id == id) {
      throw StateError('Không thể xóa danh mục Khác.');
    }

    await client
        .from('expenses')
        .update({'category_id': other.id})
        .eq('category_id', id);
    await client.from('categories').delete().eq('id', id);
    return 1;
  }

  Future<int> deleteCategory(int id) async {
    return deleteAndMoveExpensesToOther(id);
  }
}
