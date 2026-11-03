import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Gom việc đọc bảng priority_levels để repository test được bằng reader giả.
/// Mẫu lấy từ ExpenseRowWriter.
abstract class PriorityRowReader {
  Future<List<Map<String, dynamic>>> readAll();
}

class SupabasePriorityRowReader implements PriorityRowReader {
  SupabaseClient _client() {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Chưa kết nối được Supabase. Vui lòng kiểm tra mạng.');
    }
    // Bảng không có user_id nhưng policy chỉ mở cho role authenticated,
    // nên chưa đăng nhập thì đọc cũng trả về rỗng — báo rõ cho người dùng.
    if (client.auth.currentUser == null) {
      throw StateError('Vui lòng đăng nhập để tiếp tục.');
    }
    return client;
  }

  @override
  Future<List<Map<String, dynamic>>> readAll() async {
    final rows = await _client()
        .from('priority_levels')
        .select()
        .order('sort_order', ascending: true);
    return (rows as List).map((row) => row as Map<String, dynamic>).toList();
  }
}
