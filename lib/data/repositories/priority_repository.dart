import '../models/priority_level.dart';
import 'priority_row_reader.dart';

/// Mức độ cần thiết là dữ liệu hệ thống cố định (4 dòng seed trong
/// supabase_setup.sql), client chỉ đọc. Các method ghi từng có ở đây
/// (insert/update/deleteAndMoveExpenses/nextId) không màn hình nào gọi và đã bị
/// gỡ; thêm lại khi thực sự có UI quản lý mức độ.
class PriorityRepository {
  PriorityRepository({PriorityRowReader? reader})
    : _reader = reader ?? SupabasePriorityRowReader();

  final PriorityRowReader _reader;

  Future<List<PriorityLevel>> getAll() async {
    final rows = await _reader.readAll();
    return rows.map(PriorityLevel.fromSupabaseRow).toList();
  }
}
