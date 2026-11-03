import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/square_image.dart';
import '../core/utils/storage_paths.dart';
import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/supabase_storage_service.dart';
import 'budget_provider.dart';
import 'statistics_provider.dart';

class ExpenseState {
  final List<Expense> expenses;
  final double todayTotal;
  final double weekTotal;
  final double monthTotal;
  final bool isLoading;
  final String? errorMessage;

  const ExpenseState({
    this.expenses = const [],
    this.todayTotal = 0,
    this.weekTotal = 0,
    this.monthTotal = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  ExpenseState copyWith({
    List<Expense>? expenses,
    double? todayTotal,
    double? weekTotal,
    double? monthTotal,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      todayTotal: todayTotal ?? this.todayTotal,
      weekTotal: weekTotal ?? this.weekTotal,
      monthTotal: monthTotal ?? this.monthTotal,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  ExpenseNotifier(this._ref) : super(const ExpenseState()) {
    refreshDashboard();
  }

  final Ref _ref;
  final ExpenseRepository _repository = ExpenseRepository();

  Future<void> loadExpenses({
    DateTime? from,
    DateTime? to,
    String? search,
    int? categoryId,
    int? priority,
    double? minAmount,
    double? maxAmount,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final expenses = await _repository.getExpenses(
        from: from,
        to: to,
        search: search,
        categoryId: categoryId,
        priority: priority,
        minAmount: minAmount,
        maxAmount: maxAmount,
      );
      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách khoản chi.',
      );
    }
  }

  Future<void> refreshDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    try {
      final results = await Future.wait<dynamic>([
        _repository.getExpenses(),
        _repository.getTotalAmount(from: startOfToday, to: endOfToday),
        _repository.getTotalAmount(from: startOfWeek, to: endOfToday),
        _repository.getTotalAmount(from: startOfMonth, to: endOfToday),
      ]);
      state = state.copyWith(
        expenses: results[0] as List<Expense>,
        todayTotal: results[1] as double,
        weekTotal: results[2] as double,
        monthTotal: results[3] as double,
        isLoading: false,
      );
      unawaited(_migrateLegacySquares(results[0] as List<Expense>));
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải dữ liệu chi tiêu.',
      );
    }
  }

  /// Migration lazy cho ảnh tỉ lệ full còn sót trong DB. Chạy sau khi feed đã
  /// vẽ, cắt vài ảnh mỗi lần, và chỉ xoá object cũ khi state đã trỏ sang ảnh
  /// mới — nếu không ảnh đang hiển thị sẽ mất nguồn giữa chừng.
  Future<void> _migrateLegacySquares(List<Expense> rows) async {
    final signedByPath = <String, String>{};
    for (final row in rows) {
      final path = storagePathOf(row.imagePath);
      final url = row.displayImageUrl;
      if (path == null || url == null || isSquareImagePath(path)) continue;
      signedByPath[path] = url;
    }
    if (signedByPath.isEmpty) return;

    final repointed = await _repository.migrateLegacyImages(signedByPath);
    if (repointed.isEmpty || !mounted) return;

    state = state.copyWith(expenses: await _repository.getExpenses());
    await _repository.deleteLegacyImages(repointed);
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.insertExpense(expense);
    await refreshDashboard();
    await _ref
        .read(budgetProvider.notifier)
        .refreshCurrentMonthAfterExpenseChange();
    await _ref.read(statisticsProvider.notifier).refreshStatistics();
  }

  Future<void> updateExpense(Expense expense) async {
    await _repository.updateExpense(expense);
    await refreshDashboard();
    await _ref
        .read(budgetProvider.notifier)
        .refreshCurrentMonthAfterExpenseChange();
    await _ref.read(statisticsProvider.notifier).refreshStatistics();
  }

  Future<void> moveToTrash(int id) async {
    await _repository.moveToTrash(id);
    await refreshDashboard();
    await _ref
        .read(budgetProvider.notifier)
        .refreshCurrentMonthAfterExpenseChange();
    await _ref.read(statisticsProvider.notifier).refreshStatistics();
  }

  Future<void> restoreExpense(int id) async {
    await _repository.restoreExpense(id);
    await refreshDashboard();
    await _ref
        .read(budgetProvider.notifier)
        .refreshCurrentMonthAfterExpenseChange();
    await _ref.read(statisticsProvider.notifier).refreshStatistics();
  }

  Future<List<Expense>> getDeletedExpenses() =>
      _repository.getDeletedExpenses();

  Future<void> permanentlyDeleteExpense(Expense expense) async {
    if (expense.id == null) return;

    final storedPath = storagePathOf(expense.imagePath);
    if (storedPath != null) {
      await SupabaseStorageService().deleteByPath(storedPath);
      final url = expense.displayImageUrl;
      if (url != null) {
        await CachedNetworkImage.evictFromCache(url, cacheKey: storedPath);
      }
    } else {
      final local = expense.imagePath;
      if (local != null) {
        final file = File(local);
        if (await file.exists()) await file.delete();
      }
    }

    // Ảnh phải xóa xong trước để không còn object mồ côi.
    await _repository.permanentlyDeleteExpense(expense.id!);
  }

  Future<double> getTodayTotal() async {
    final now = DateTime.now();
    return _repository.getTotalAmount(
      from: DateTime(now.year, now.month, now.day),
      to: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>(
  (ref) => ExpenseNotifier(ref),
);
