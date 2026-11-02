import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixket/data/repositories/expense_repository.dart';
import 'package:pixket/data/repositories/category_repository.dart';
import 'package:intl/intl.dart';

class StatisticsState {
  final Map<int, double> categoryTotals;
  final Map<int, double> priorityTotals;
  final Map<String, double> dailyTotals;
  final double totalAmount;
  final List<String> insights;
  final bool isLoading;

  StatisticsState({
    this.categoryTotals = const {},
    this.priorityTotals = const {},
    this.dailyTotals = const {},
    this.totalAmount = 0.0,
    this.insights = const [],
    this.isLoading = false,
  });

  double get totalSpending => totalAmount;
  Map<int, double> get spendingByCategory => categoryTotals;
  Map<int, double> get spendingByPriority => priorityTotals;

  StatisticsState copyWith({
    Map<int, double>? categoryTotals,
    Map<int, double>? priorityTotals,
    Map<String, double>? dailyTotals,
    double? totalAmount,
    List<String>? insights,
    bool? isLoading,
  }) {
    return StatisticsState(
      categoryTotals: categoryTotals ?? this.categoryTotals,
      priorityTotals: priorityTotals ?? this.priorityTotals,
      dailyTotals: dailyTotals ?? this.dailyTotals,
      totalAmount: totalAmount ?? this.totalAmount,
      insights: insights ?? this.insights,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  StatisticsNotifier()
    : _expenseRepository = ExpenseRepository(),
      _categoryRepository = CategoryRepository(),
      super(StatisticsState());

  DateTime? _lastFrom;
  DateTime? _lastTo;

  Future<void> loadStatistics(DateTime from, DateTime to) async {
    _lastFrom = from;
    _lastTo = to;
    state = state.copyWith(isLoading: true);
    try {
      final expenses = await _expenseRepository.getExpenses(from: from, to: to);

      Map<int, double> categoryTotals = {};
      Map<int, double> priorityTotals = {};
      Map<String, double> dailyTotals = {};
      double totalAmount = 0.0;

      for (var expense in expenses) {
        totalAmount += expense.amount;

        categoryTotals[expense.categoryId] =
            (categoryTotals[expense.categoryId] ?? 0.0) + expense.amount;

        priorityTotals[expense.priority] =
            (priorityTotals[expense.priority] ?? 0.0) + expense.amount;

        final dateStr = DateFormat('yyyy-MM-dd').format(expense.createdAt);
        dailyTotals[dateStr] = (dailyTotals[dateStr] ?? 0.0) + expense.amount;
      }

      state = state.copyWith(
        categoryTotals: categoryTotals,
        priorityTotals: priorityTotals,
        dailyTotals: dailyTotals,
        totalAmount: totalAmount,
        isLoading: false,
      );

      await generateInsights(from, to);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshStatistics() async {
    final now = DateTime.now();
    final from = _lastFrom ?? DateTime(now.year, now.month, 1);
    final to =
        _lastTo ?? DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    await loadStatistics(from, to);
  }

  Future<void> generateInsights(DateTime from, DateTime to) async {
    List<String> insights = [];
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    insights.add('Tổng chi tiêu: ${formatter.format(state.totalAmount)}');

    final days = to.difference(from).inDays + 1;
    if (days > 0) {
      final avg = state.totalAmount / days;
      insights.add('Trung bình mỗi ngày: ${formatter.format(avg)}');
    }

    if (state.categoryTotals.isNotEmpty) {
      int? topCategoryId;
      double maxAmount = 0.0;

      state.categoryTotals.forEach((id, amount) {
        if (amount > maxAmount) {
          maxAmount = amount;
          topCategoryId = id;
        }
      });

      if (topCategoryId != null) {
        try {
          final categories = await _categoryRepository.getAll();
          final topCat = categories.firstWhere((c) => c.id == topCategoryId);
          final percent = (maxAmount / state.totalAmount * 100).toStringAsFixed(
            1,
          );
          insights.add('Danh mục chi nhiều nhất: ${topCat.name} ($percent%)');
        } catch (e) {
          // ignore
        }
      }
    }

    // Priority 3 assumes "Chưa cần thiết"
    final notNecessaryAmount = state.priorityTotals[3] ?? 0.0;
    if (state.totalAmount > 0 && notNecessaryAmount > 0) {
      final percent = (notNecessaryAmount / state.totalAmount * 100)
          .toStringAsFixed(1);
      insights.add('$percent% chi tiêu là Chưa cần thiết');
    }

    state = state.copyWith(insights: insights);
  }
}

final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
      return StatisticsNotifier();
    });
