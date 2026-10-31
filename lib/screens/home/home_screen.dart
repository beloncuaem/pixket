import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/amount_input_formatter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/storage_paths.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/priority_level.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/priority_provider.dart';
import '../../widgets/category_icon_badge.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/hamburger_button.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/screen_background.dart';
import '../camera/expense_form_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;

  const HomeScreen({super.key, this.onMenuTap});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  _ExpenseFilter _filter = const _ExpenseFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _searchController.clear();
    setState(() => _filter = const _ExpenseFilter());
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

  Future<void> _loadFilteredExpenses() {
    final range = _filter.dateRange;
    return ref
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

  Future<void> _showFilters() async {
    final selected = await showModalBottomSheet<_ExpenseFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        initial: _filter,
        categories: ref.read(categoryProvider).categories,
        priorities: ref.read(priorityProvider).levels,
      ),
    );
    if (selected == null) return;
    _searchController.text = selected.search;
    setState(() => _filter = selected);
    await _loadFilteredExpenses();
  }

  void _showImageDialog(Expense expense) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Xem ảnh',
      barrierColor: Colors.black.withValues(alpha: 0.94),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => _PhotoPreviewDialog(expense: expense),
    );
  }

  void _showEditSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormSheet(expense: expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final categories = ref.watch(categoryProvider).categories;
    final priorities = ref.watch(priorityProvider).levels;
    final budgetState = ref.watch(budgetProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userEmail = authState.user?.email;
    final displayName =
        authState.user?.userMetadata?['full_name'] as String? ??
        (userEmail != null ? userEmail.split('@').first : 'Bạn');

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: HamburgerButton(onTap: widget.onMenuTap),
        ),
        leadingWidth: 64,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, $displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: authState.user != null
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        authState.user != null
                            ? 'Cloud Sync'
                            : 'Đang kết nối...',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ScreenBackground(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Neo-Bank Balance & Summary Card
              _SummaryCards(
                today: expenseState.todayTotal,
                week: expenseState.weekTotal,
                month: expenseState.monthTotal,
              ),
              const SizedBox(height: 14),

              // Budget Progress Card
              _BudgetProgressCard(budgetState: budgetState),
              const SizedBox(height: 18),

              // Search & Filter Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _applySearch(),
                      decoration: InputDecoration(
                        hintText: 'Tìm ghi chú, danh mục...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: IconButton(
                          tooltip: 'Tìm kiếm',
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          onPressed: _applySearch,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Lọc giao dịch',
                    onPressed: _showFilters,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Badge(
                      isLabelVisible: _filter.isActive,
                      label: const Text(''),
                      child: const Icon(Icons.tune_rounded, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filter.isActive ? 'Kết quả lọc' : 'Giao dịch gần đây',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (_filter.isActive)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _filter = const _ExpenseFilter());
                        _loadFilteredExpenses();
                      },
                      child: const Text(
                        'Xóa lọc',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              if (expenseState.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  expenseState.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              if (expenseState.isLoading && expenseState.expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (expenseState.expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.surfaceDarkLight
                                : AppColors.surfaceLightDark,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 36,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có khoản chi phù hợp.\nHãy chụp hoặc chọn một ảnh để bắt đầu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._buildGroupedExpenses(
                  context,
                  expenseState.expenses,
                  categories,
                  priorities,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedExpenses(
    BuildContext context,
    List<Expense> expenses,
    List<Category> categories,
    List<PriorityLevel> priorities,
  ) {
    final categoryMap = {
      for (final category in categories) category.id: category,
    };
    final priorityMap = {
      for (final priority in priorities) priority.id: priority,
    };
    final groups = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final date = DateUtils.dateOnly(expense.createdAt);
      groups.putIfAbsent(date, () => []).add(expense);
    }

    final result = <Widget>[];
    for (final entry in groups.entries) {
      result.add(
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            DateFormatter.formatDate(entry.key),
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      );
      for (final expense in entry.value) {
        result.add(
          _ExpenseTile(
            expense: expense,
            category: categoryMap[expense.categoryId],
            priority: priorityMap[expense.priority],
            onTap: () => _showEditSheet(expense),
            onImageTap: expense.imagePath == null
                ? null
                : () => _showImageDialog(expense),
            onMoveToTrash: () async {
              if (expense.id == null) return;
              await ref.read(expenseProvider.notifier).moveToTrash(expense.id!);
              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Đã chuyển khoản chi vào thùng rác.'),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Hoàn tác',
                    onPressed: () => ref
                        .read(expenseProvider.notifier)
                        .restoreExpense(expense.id!),
                  ),
                ),
              );
            },
          ),
        );
      }
    }
    return result;
  }
}

class _PhotoPreviewDialog extends StatelessWidget {
  final Expense expense;

  const _PhotoPreviewDialog({required this.expense});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(child: _buildImage()),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 12,
            right: 16,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final url = expense.displayImageUrl;
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        cacheKey: storagePathOf(expense.imagePath),
        fit: BoxFit.contain,
        width: double.infinity,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.broken_image_rounded,
          color: Colors.white38,
          size: 64,
        ),
      );
    }

    // Chỉ ảnh chưa kịp lên Cloud mới còn là đường dẫn tệp cục bộ.
    final path = expense.imagePath;
    if (path != null && storagePathOf(path) == null) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain, width: double.infinity);
      }
    }
    return const Icon(
      Icons.broken_image_rounded,
      color: Colors.white38,
      size: 64,
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final double today;
  final double week;
  final double month;

  const _SummaryCards({
    required this.today,
    required this.week,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.balanceCardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primaryLight,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tổng chi tháng này',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'VND',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(month),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hôm nay',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormatter.format(today),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tuần này',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          CurrencyFormatter.format(week),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final BudgetState budgetState;
  const _BudgetProgressCard({required this.budgetState});

  @override
  Widget build(BuildContext context) {
    final total = budgetState.totalBudgetAmount;
    if (total <= 0) return const SizedBox.shrink();
    final progress = budgetState.budgetUsagePercent.clamp(0, 1).toDouble();
    final isOver = budgetState.budgetUsagePercent >= 1;
    final overAmount = budgetState.totalSpent - total;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.track_changes_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ngân sách tháng',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isOver ? AppColors.priority3 : AppColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(budgetState.budgetUsagePercent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: isOver ? AppColors.priority3 : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? AppColors.surfaceDarkLight
                  : AppColors.surfaceLightDark,
              color: isOver ? AppColors.priority3 : AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã chi: ${CurrencyFormatter.format(budgetState.totalSpent)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                'Hạn mức: ${CurrencyFormatter.format(total)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            overAmount > 0
                ? 'Quá ngân sách: ${CurrencyFormatter.format(overAmount)}'
                : 'Còn lại: ${CurrencyFormatter.format(-overAmount)}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: overAmount > 0 ? AppColors.priority3 : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final Category? category;
  final PriorityLevel? priority;
  final VoidCallback onTap;
  final VoidCallback? onImageTap;
  final Future<void> Function() onMoveToTrash;

  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.priority,
    required this.onTap,
    required this.onImageTap,
    required this.onMoveToTrash,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onMoveToTrash(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.priority3,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: GestureDetector(
            onTap: onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _buildLeadingWidget(context),
              ),
            ),
          ),
          title: Text(
            expense.caption.isEmpty ? 'Không có ghi chú' : expense.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  avatar: IconHelper.getIconWidget(
                    category?.icon ?? 'dotsThreeOutline',
                    size: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    category?.name ?? 'Khác',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (priority != null) PriorityBadge(priority: expense.priority),
                Text(
                  DateFormatter.formatTime(expense.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          trailing: Text(
            CurrencyFormatter.format(expense.amount),
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget(BuildContext context) {
    final url = expense.displayImageUrl;
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        cacheKey: storagePathOf(expense.imagePath),
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => CategoryIconBadge(
          iconKey: category?.icon ?? 'dotsThreeOutline',
          size: 48,
        ),
      );
    }

    final img = expense.imagePath;
    if (img != null && img.isNotEmpty && storagePathOf(img) == null) {
      final file = File(img);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return CategoryIconBadge(
      iconKey: category?.icon ?? 'dotsThreeOutline',
      size: 48,
      iconSize: 24,
    );
  }
}

class _ExpenseFilter {
  final String search;
  final DateTimeRange? dateRange;
  final int? categoryId;
  final int? priorityId;
  final double? minAmount;
  final double? maxAmount;

  const _ExpenseFilter({
    this.search = '',
    this.dateRange,
    this.categoryId,
    this.priorityId,
    this.minAmount,
    this.maxAmount,
  });

  bool get isActive =>
      search.isNotEmpty ||
      dateRange != null ||
      categoryId != null ||
      priorityId != null ||
      minAmount != null ||
      maxAmount != null;

  _ExpenseFilter copyWith({
    String? search,
    DateTimeRange? dateRange,
    int? categoryId,
    int? priorityId,
    double? minAmount,
    double? maxAmount,
    bool clearDateRange = false,
    bool clearCategory = false,
    bool clearPriority = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) => _ExpenseFilter(
    search: search ?? this.search,
    dateRange: clearDateRange ? null : dateRange ?? this.dateRange,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    priorityId: clearPriority ? null : priorityId ?? this.priorityId,
    minAmount: clearMinAmount ? null : minAmount ?? this.minAmount,
    maxAmount: clearMaxAmount ? null : maxAmount ?? this.maxAmount,
  );
}

class _FilterSheet extends StatefulWidget {
  final _ExpenseFilter initial;
  final List<Category> categories;
  final List<PriorityLevel> priorities;

  const _FilterSheet({
    required this.initial,
    required this.categories,
    required this.priorities,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTimeRange? _dateRange;
  late int? _categoryId;
  late int? _priorityId;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initial.dateRange;
    _categoryId = widget.initial.categoryId;
    _priorityId = widget.initial.priorityId;
    _minController = TextEditingController(
      text: CurrencyFormatter.toEditableText(widget.initial.minAmount ?? 0),
    );
    _maxController = TextEditingController(
      text: CurrencyFormatter.toEditableText(widget.initial.maxAmount ?? 0),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (result != null) setState(() => _dateRange = result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lọc giao dịch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(
                    _dateRange == null
                        ? 'Chọn khoảng thời gian'
                        : '${DateFormatter.formatDate(_dateRange!.start)} – ${DateFormatter.formatDate(_dateRange!.end)}',
                  ),
                ),
                if (_dateRange != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _dateRange = null),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Bỏ lọc thời gian'),
                  ),
                const SizedBox(height: 12),
                Text('Danh mục', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    ...widget.categories.map(
                      (category) => ChoiceChip(
                        avatar: IconHelper.getIconWidget(
                          category.icon,
                          size: 15,
                        ),
                        label: Text(category.name),
                        selected: _categoryId == category.id,
                        onSelected: (selected) => setState(
                          () => _categoryId = selected ? category.id : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Mức độ cần thiết',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _priorityId == null,
                      onSelected: (_) => setState(() => _priorityId = null),
                    ),
                    ...widget.priorities.map(
                      (priority) => ChoiceChip(
                        label: Text(priority.name),
                        selected: _priorityId == priority.id,
                        onSelected: (selected) => setState(
                          () => _priorityId = selected ? priority.id : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [
                          ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Từ số tiền',
                          suffixText: '₫',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [
                          ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Đến số tiền',
                          suffixText: '₫',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, const _ExpenseFilter()),
                      child: const Text('Xóa bộ lọc'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _ExpenseFilter(
                          search: widget.initial.search,
                          dateRange: _dateRange,
                          categoryId: _categoryId,
                          priorityId: _priorityId,
                          minAmount: CurrencyFormatter.parseInput(
                            _minController.text,
                          ),
                          maxAmount: CurrencyFormatter.parseInput(
                            _maxController.text,
                          ),
                        ),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
