import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/priority_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_empty_state.dart';
import '../../widgets/pixel/pixel_expense_tile.dart';
import '../../widgets/pixel/pixel_loading.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_screen_header.dart';
import '../../widgets/pixel/pixel_snack_bar.dart';
import '../../widgets/pixel/pixel_star_field.dart';
import '../../widgets/pixel/pixel_text_field.dart';
import '../camera/expense_form_sheet.dart';
import 'budget_progress_card.dart';
import 'dashboard_summary.dart';
import 'expense_filter_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onOpenBudget;
  final VoidCallback? onOpenFeed;

  const HomeScreen({
    super.key,
    this.onMenuTap,
    this.onOpenBudget,
    this.onOpenFeed,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  ExpenseFilter _filter = const ExpenseFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _searchController.clear();
    setState(() => _filter = const ExpenseFilter());
    await ref.read(expenseProvider.notifier).refreshDashboard();
    await ref
        .read(budgetProvider.notifier)
        .refreshCurrentMonthAfterExpenseChange();
  }

  Future<void> _applySearch() async {
    _filter = _filter.copyWith(search: _searchController.text.trim());
    setState(() {});
    await _loadFilteredExpenses();
  }

  Future<void> _loadFilteredExpenses() async {
    final range = _filter.dateRange;
    await ref
        .read(expenseProvider.notifier)
        .loadExpenses(
          from: range?.start,
          to: range == null
              ? null
              : DateTime(
                  range.end.year,
                  range.end.month,
                  range.end.day,
                  23,
                  59,
                  59,
                  999,
                ),
          search: _filter.search,
          categoryId: _filter.categoryId,
          priority: _filter.priorityId,
          minAmount: _filter.minAmount,
          maxAmount: _filter.maxAmount,
        );
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _filter = const ExpenseFilter());
    _loadFilteredExpenses();
  }

  Future<void> _showFilters() async {
    final selected = await openExpenseFilterSheet(
      context,
      initial: _filter,
      categories: ref.read(categoryProvider).categories,
      priorities: ref.read(priorityProvider).levels,
    );
    if (selected == null || !mounted) return;
    _searchController.text = selected.search;
    setState(() => _filter = selected);
    await _loadFilteredExpenses();
  }

  Future<void> _showEditSheet(Expense expense) =>
      openExpenseForm(context, expense: expense);

  Future<void> _moveToTrash(Expense expense) async {
    final id = expense.id;
    if (id == null) return;
    await ref.read(expenseProvider.notifier).moveToTrash(id);
    if (!mounted) return;
    showPixelSnackBar(
      context,
      'Đã chuyển khoản chi vào thùng rác.',
      actionLabel: 'Hoàn tác',
      onAction: () => ref.read(expenseProvider.notifier).restoreExpense(id),
      tone: PixelTone.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final expenseState = ref.watch(expenseProvider);
    final categories = ref.watch(categoryProvider).categories;
    final budgetState = ref.watch(budgetProvider);
    final user = ref.watch(authProvider).user;
    final email = user?.email;
    final fullName = (user?.userMetadata?['full_name'] as String?)?.trim();
    final displayName = (fullName == null || fullName.isEmpty)
        ? (email != null ? email.split('@').first : 'Bạn')
        : fullName;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: PixelScreenHeader(
              title: 'TỔNG QUAN',
              subtitle:
                  'Chào $displayName • ${DateFormatter.formatDate(DateTime.now())}',
              onMenuTap: widget.onMenuTap,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  DashboardSummary(
                    month: expenseState.monthTotal,
                    today: expenseState.todayTotal,
                    week: expenseState.weekTotal,
                    expenseCount: expenseState.expenses.length,
                  ),
                  const SizedBox(height: 14),
                  BudgetProgressCard(
                    spent: budgetState.totalSpent,
                    budget: budgetState.totalBudgetAmount,
                    onTap: widget.onOpenBudget,
                  ),
                  const SizedBox(height: 14),
                  _buildSearchRow(palette),
                  const SizedBox(height: 14),
                  PixelStarSafe(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _filter.isActive
                                ? 'Kết quả lọc'
                                : 'Giao dịch gần đây',
                            style: text.titleMedium?.copyWith(
                              color: palette.ink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_filter.isActive)
                          PixelButton(
                            label: 'Xóa lọc',
                            variant: PixelButtonVariant.ghost,
                            onPressed: _resetFilters,
                            icon: 'undo',
                          ),
                      ],
                    ),
                  ),
                  if (expenseState.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    PixelPanel(
                      background: palette.rose,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          AppIcon(
                            name: 'alert',
                            size: 32,
                            color: palette.roseInk,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              expenseState.errorMessage!,
                              style: text.bodyMedium?.copyWith(
                                color: palette.roseInk,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PixelButton(
                            label: 'THỬ LẠI',
                            onPressed: _refresh,
                            icon: 'refresh',
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (expenseState.isLoading && expenseState.expenses.isEmpty)
                    const PixelStarSafe(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: PixelLoading(blocks: 3, label: 'Đang tải…'),
                      ),
                    )
                  else if (expenseState.expenses.isEmpty)
                    PixelStarSafe(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: PixelEmptyState(
                          glyph: 'receipt',
                          title: _filter.isActive
                              ? 'Không tìm thấy khoản chi'
                              : 'Chưa có khoản chi nào',
                          message: _filter.isActive
                              ? 'Thử bỏ bớt bộ lọc.'
                              : 'Mở camera và chụp khoản chi đầu tiên.',
                          actionLabel: _filter.isActive
                              ? 'XÓA BỘ LỌC'
                              : 'MỞ CAMERA',
                          onAction: _filter.isActive
                              ? _resetFilters
                              : widget.onOpenFeed,
                        ),
                      ),
                    )
                  else
                    ..._buildGroupedExpenses(expenseState.expenses, categories),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(AppPalette palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: PixelTextField(
            key: const Key('dashboardSearch'),
            label: 'Tìm kiếm',
            hint: 'Tìm ghi chú, danh mục...',
            controller: _searchController,
            suffixGlyph: 'search',
            onSuffixTap: _applySearch,
            onSubmitted: (_) => _applySearch(),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            PixelIconButton(
              icon: 'filter',
              tooltip: 'Lọc giao dịch',
              onPressed: _showFilters,
            ),
            if (_filter.isActive)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: palette.butter,
                    border: Border.all(color: palette.lineStrong, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildGroupedExpenses(
    List<Expense> expenses,
    List<Category> categories,
  ) {
    final categoryMap = {
      for (final category in categories) category.id: category,
    };
    final groups = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final date = DateUtils.dateOnly(expense.createdAt);
      groups.putIfAbsent(date, () => []).add(expense);
    }

    final result = <Widget>[];
    for (final entry in groups.entries) {
      result.add(pixelGroupHeader(DateFormatter.formatDate(entry.key)));
      for (final expense in entry.value) {
        final category = categoryMap[expense.categoryId];
        result.add(
          PixelExpenseTile(
            expense: expense,
            categoryName: category?.name ?? 'Khác',
            categoryIconKey: category?.icon ?? 'tag',
            onTap: (_) => _showEditSheet(expense),
            onDismiss: (_) => _moveToTrash(expense),
          ),
        );
      }
    }
    return result;
  }
}
