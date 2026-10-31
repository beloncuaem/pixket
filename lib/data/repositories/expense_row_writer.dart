import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Gom mọi thao tác ghi bảng expenses để repository test được rollback.
abstract class ExpenseRowWriter {
  String currentUserId();
  Future<int> insert(Map<String, dynamic> values);
  Future<void> update(int id, Map<String, dynamic> values);
}

class SupabaseExpenseRowWriter implements ExpenseRowWriter {
  SupabaseClient _client() {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Chưa kết nối được Supabase. Vui lòng kiểm tra mạng.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('Vui lòng đăng nhập để tiếp tục.');
    }
    return client;
  }

  @override
  String currentUserId() => _client().auth.currentUser!.id;

  @override
  Future<int> insert(Map<String, dynamic> values) async {
    final row = await _client()
        .from('expenses')
        .insert(values)
        .select()
        .single();
    return row['id'] as int;
  }

  @override
  Future<void> update(int id, Map<String, dynamic> values) =>
      _client().from('expenses').update(values).eq('id', id);
}
