import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/square_image.dart';
import '../../core/utils/storage_paths.dart';
import '../models/expense.dart';
import 'expense_image_mapping.dart';
import 'expense_row_writer.dart';
import 'supabase_storage_service.dart';

class ExpenseRepository {
  ExpenseRepository({
    SupabaseStorageService? storageService,
    ExpenseRowWriter? writer,
    http.Client? httpClient,
  }) : _storage = storageService ?? SupabaseStorageService(),
       _writer = writer ?? SupabaseExpenseRowWriter(),
       _http = httpClient ?? http.Client();

  final SupabaseStorageService _storage;
  final ExpenseRowWriter _writer;
  final http.Client _http;

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

  Expense _fromRow(Map<String, dynamic> row) {
    return Expense(
      id: row['id'] as int?,
      imagePath: row['image_url'] as String?,
      caption: (row['caption'] as String?) ?? '',
      amount: (row['amount'] as num).toDouble(),
      categoryId: (row['category_id'] as int?) ?? 0,
      priority: (row['priority'] as int?) ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      deletedAt: row['deleted_at'] != null
          ? DateTime.tryParse(row['deleted_at'] as String)
          : null,
    );
  }

  Future<({String? path, bool uploaded})> _resolveImage(String? source) async {
    final value = source?.trim();
    if (value == null || value.isEmpty) return (path: null, uploaded: false);

    final stored = storagePathOf(value);
    if (stored != null) return (path: stored, uploaded: false);

    if (await File(value).exists()) {
      // Chốt chặn cuối cho tỉ lệ vuông: mọi đường ghi ảnh đều đi qua đây, kể cả
      // khi UI gửi lên một tệp chưa cắt.
      final squared = await writeSquareCopy(File(value));
      return (
        path: await _storage.uploadReceiptImage(squared.path),
        uploaded: true,
      );
    }

    throw StateError('Không tìm thấy ảnh để tải lên Cloud.');
  }

  /// Ghi khoản chi. Nếu DB lỗi thì dọn ảnh vừa upload (best-effort).
  @visibleForTesting
  Future<int> saveExpense({
    required int? expenseId,
    required String? imageSource,
    required Map<String, dynamic> values,
  }) async {
    final image = await _resolveImage(imageSource);
    final payload = <String, dynamic>{
      ...values,
      if (image.path != null) 'image_url': image.path,
    };

    try {
      if (expenseId == null) return await _writer.insert(payload);
      await _writer.update(expenseId, payload);
      return expenseId;
    } catch (_) {
      if (image.uploaded && image.path != null) {
        try {
          await _storage.deleteByPath(image.path!);
        } catch (_) {
          // Ảnh mồ côi sẽ bị policy owner-only chặn; không làm mất lỗi chính.
        }
      }
      rethrow;
    }
  }

  Future<int> insertExpense(Expense expense) => saveExpense(
    expenseId: null,
    imageSource: expense.imagePath,
    values: {
      'user_id': _writer.currentUserId(),
      'caption': expense.caption,
      'amount': expense.amount,
      'category_id': expense.categoryId,
      'priority': expense.priority,
      'image_url': expense.imagePath,
      'created_at': expense.createdAt.toIso8601String(),
      'deleted_at': expense.deletedAt?.toIso8601String(),
    },
  );

  Future<int> updateExpense(Expense expense) {
    final id = expense.id;
    if (id == null) {
      throw StateError('Không tìm thấy khoản chi cần cập nhật.');
    }
    return saveExpense(
      expenseId: id,
      imageSource: expense.imagePath,
      values: {
        'caption': expense.caption,
        'amount': expense.amount,
        'category_id': expense.categoryId,
        'priority': expense.priority,
        'image_url': expense.imagePath,
        'created_at': expense.createdAt.toIso8601String(),
        'deleted_at': expense.deletedAt?.toIso8601String(),
      },
    );
  }

  /// Gán signed URL cho danh sách; lỗi ký chỉ làm ảnh trống, không mất dữ liệu.
  Future<List<Expense>> decorateWithSignedUrls(List<Expense> rows) async {
    final paths = storagePathsOf(rows);
    if (paths.isEmpty) return rows;
    try {
      final signed = await _storage.signPathsInBatches(paths);
      return attachSignedUrls(rows, signed);
    } catch (error) {
      debugPrint('Ký URL ảnh thất bại: $error');
      return rows;
    }
  }

  static const int legacyMigrationLimit = 5;
  final Set<String> _migrationAttempted = {};

  /// Cắt lại tối đa [legacyMigrationLimit] ảnh tỉ lệ full mỗi lần nạp feed, và
  /// repoint các dòng đang trỏ tới chúng. Không xoá object ở đây: caller phải
  /// nạp lại state trước khi gọi [deleteLegacyImages], nếu không ảnh đang hiển
  /// thị sẽ mất nguồn.
  /// Trả về danh sách path cũ đã repoint thành công.
  Future<List<String>> migrateLegacyImages(
    Map<String, String> signedUrls,
  ) async {
    final pending = signedUrls.keys
        .where((path) => !isSquareImagePath(path))
        .where((path) => _migrationAttempted.add(path))
        .take(legacyMigrationLimit)
        .toList();

    final repointed = <String>[];
    for (final path in pending) {
      try {
        final response = await _http.get(Uri.parse(signedUrls[path]!));
        if (response.statusCode != 200) continue;
        final squared = cropToSquareBytes(response.bodyBytes);
        if (squared == null) continue;
        final newPath = await _storage.uploadSquareBytes(
          squared,
          legacyPath: path,
        );
        await _writer.repointImage(path, newPath);
        repointed.add(path);
      } catch (error) {
        debugPrint('Bỏ qua migration ảnh $path: $error');
      }
    }
    return repointed;
  }

  Future<void> deleteLegacyImages(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _storage.deletePaths(paths);
    } catch (error) {
      debugPrint('Dọn ảnh legacy thất bại: $error');
    }
  }

  Future<List<Expense>> getExpenses({
    DateTime? from,
    DateTime? to,
    String? search,
    int? categoryId,
    int? priority,
    double? minAmount,
    double? maxAmount,
    int? limit,
    int? offset,
  }) async {
    final client = _requireClient();
    var query = client.from('expenses').select().isFilter('deleted_at', null);

    if (from != null) {
      query = query.gte('created_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('created_at', to.toIso8601String());
    }
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('caption', '%${search.trim()}%');
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (priority != null) {
      query = query.eq('priority', priority);
    }
    if (minAmount != null) {
      query = query.gte('amount', minAmount);
    }
    if (maxAmount != null) {
      query = query.lte('amount', maxAmount);
    }

    var sorted = query.order('created_at', ascending: false);
    if (limit != null) sorted = sorted.limit(limit);
    if (offset != null) {
      sorted = sorted.range(offset, offset + (limit ?? 1) - 1);
    }

    final data = await sorted;
    final rows = (data as List)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
    return decorateWithSignedUrls(rows);
  }

  Future<List<Expense>> getExpensesByCategory(
    int categoryId, {
    DateTime? from,
    DateTime? to,
  }) {
    return getExpenses(from: from, to: to, categoryId: categoryId);
  }

  Future<List<Expense>> getExpensesToday() async {
    final now = DateTime.now();
    return getExpenses(
      from: DateTime(now.year, now.month, now.day),
      to: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  Future<double> getTotalByDateRange(DateTime from, DateTime to) async {
    final expenses = await getExpenses(from: from, to: to);
    return expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  Future<double> getTotalAmount({
    required DateTime from,
    required DateTime to,
  }) {
    return getTotalByDateRange(from, to);
  }

  Future<double> getTotalByCategoryAndDateRange(
    int categoryId,
    DateTime from,
    DateTime to,
  ) async {
    final expenses = await getExpenses(
      categoryId: categoryId,
      from: from,
      to: to,
    );
    return expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  Future<double> getTotalByPriorityAndDateRange(
    int priority,
    DateTime from,
    DateTime to,
  ) async {
    final expenses = await getExpenses(priority: priority, from: from, to: to);
    return expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  Future<int> moveToTrash(int id) async {
    final client = _requireClient();
    await client
        .from('expenses')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
    return 1;
  }

  Future<int> restoreExpense(int id) async {
    final client = _requireClient();
    await client.from('expenses').update({'deleted_at': null}).eq('id', id);
    return 1;
  }

  Future<int> permanentlyDeleteExpense(int id) async {
    final client = _requireClient();
    await client.from('expenses').delete().eq('id', id);
    return 1;
  }

  Future<List<Expense>> getDeletedExpenses() async {
    final client = _requireClient();
    final data = await client
        .from('expenses')
        .select()
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);

    final rows = (data as List)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
    return decorateWithSignedUrls(rows);
  }

  Future<Expense?> getExpenseById(int id, {bool includeDeleted = false}) async {
    final client = _requireClient();
    var query = client.from('expenses').select().eq('id', id);
    if (!includeDeleted) {
      query = query.isFilter('deleted_at', null);
    }
    final data = await query.maybeSingle();
    if (data == null) return null;
    final decorated = await decorateWithSignedUrls([_fromRow(data)]);
    return decorated.isEmpty ? null : decorated.single;
  }

  Future<Map<String, double>> getDailyTotals(DateTime from, DateTime to) async {
    final expenses = await getExpenses(from: from, to: to);
    final map = <String, double>{};
    for (final exp in expenses) {
      final key =
          '${exp.createdAt.year}-${exp.createdAt.month.toString().padLeft(2, '0')}-${exp.createdAt.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0.0) + exp.amount;
    }
    return map;
  }
}
