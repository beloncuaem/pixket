import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/amount_input_formatter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/category.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_empty_state.dart';
import '../../widgets/pixel/pixel_loading.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_progress.dart';
import '../../widgets/pixel/pixel_screen_header.dart';
import '../../widgets/pixel/pixel_segmented.dart';
import '../../widgets/pixel/pixel_snack_bar.dart';
import '../../widgets/pixel/pixel_text_field.dart';

enum BudgetMode { total, byCategory }

class BudgetScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;

  const BudgetScreen({super.key, this.onMenuTap});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  BudgetMode _mode = BudgetMode.total;
  bool _isSavingBudget = false;
  int _monthOffset = 0;
  final _totalBudgetController = TextEditingController();
  final Map<int, TextEditingController> _categoryControllers = {};

  DateTime get _monthDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset);
  }

  /// Định dạng `yyyy-MM` mà BudgetRepository và BudgetNotifier dùng.
  String get _queryMonth => DateFormat('yyyy-MM').format(_monthDate);

  /// Định dạng `MM/yyyy` chỉ dùng để hiển thị.
  String get _monthLabel => DateFormat('MM/yyyy').format(_monthDate);

  @override
  void initState() {
    super.initState();
    Future.microtask(_seedControllers);
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int id, double seed) =>
      _categoryControllers.putIfAbsent(
        id,
        () =>
            TextEditingController(text: CurrencyFormatter.toEditableText(seed)),
      );

  /// Nạp lại ô nhập từ dữ liệu đang hiển thị (đầu phiên và sau mỗi lần đổi tháng).
  void _seedControllers() {
    final budgetState = ref.read(budgetProvider);
    _totalBudgetController.text = CurrencyFormatter.toEditableText(
      budgetState.totalBudget?.amount ?? 0,
    );
    for (final category in ref.read(categoryProvider).categories) {
      final id = category.id;
      if (id == null) continue;
      _controllerFor(
        id,
        budgetState.categoryBudgets[id] ?? 0,
      ).text = CurrencyFormatter.toEditableText(
        budgetState.categoryBudgets[id] ?? 0,
      );
    }
  }

  void _previousMonth() {
    setState(() => _monthOffset -= 1);
    ref.read(budgetProvider.notifier).loadBudgets(_queryMonth);
  }

  void _nextMonth() {
    if (_monthOffset >= 0) return;
    setState(() => _monthOffset += 1);
    ref.read(budgetProvider.notifier).loadBudgets(_queryMonth);
  }

  Future<void> _saveBudget() async {
    if (_isSavingBudget) return;
    setState(() => _isSavingBudget = true);
    try {
      if (_mode == BudgetMode.total) {
        final total =
            CurrencyFormatter.parseInput(_totalBudgetController.text) ?? 0.0;
        await ref
            .read(budgetProvider.notifier)
            .setTotalBudget(month: _queryMonth, amount: total);
      } else {
        final Map<int, double> catBudgets = {};
        _categoryControllers.forEach((id, controller) {
          final val = CurrencyFormatter.parseInput(controller.text);
          if (val != null && val > 0) {
            catBudgets[id] = val;
          }
        });
        await ref
            .read(budgetProvider.notifier)
            .setCategoryBudgets(
              month: _queryMonth,
              categoryBudgets: catBudgets,
            );
      }

      if (mounted) {
        showPixelSnackBar(
          context,
          'Đã lưu ngân sách!',
          tone: PixelTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is BudgetValidationException
            ? e.message
            : 'Lỗi khi lưu ngân sách';
        showPixelSnackBar(context, message, tone: PixelTone.danger);
      }
    } finally {
      if (mounted) setState(() => _isSavingBudget = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BudgetState>(budgetProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) _seedControllers();
    });

    final budgetState = ref.watch(budgetProvider);
    final categoryState = ref.watch(categoryProvider);
    final isLoading = budgetState.isLoading && budgetState.totalBudget == null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: PixelScreenHeader(
              title: 'NGÂN SÁCH',
              subtitle: 'tháng $_monthLabel',
              onMenuTap: widget.onMenuTap,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelIconButton(
                    icon: 'back',
                    tooltip: 'Tháng trước',
                    onPressed: _previousMonth,
                  ),
                  PixelIconButton(
                    icon: 'chevronRight',
                    tooltip: 'Tháng sau',
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            // Một scroll view duy nhất: khi bàn phím mở, viewInsets thu hẹp
            // khung và nội dung cuộn được thay vì tràn.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PixelSegmented<BudgetMode>(
                    items: const [
                      PixelSegmentItem(value: BudgetMode.total, label: 'Tổng'),
                      PixelSegmentItem(
                        value: BudgetMode.byCategory,
                        label: 'Theo danh mục',
                      ),
                    ],
                    selected: _mode,
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 12),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: PixelLoading(label: 'Đang tải ngân sách…'),
                      ),
                    )
                  else if (_mode == BudgetMode.total)
                    _buildTotalBudgetView(budgetState)
                  else
                    _buildCategoryBudgetView(
                      categoryState.categories,
                      budgetState,
                    ),
                  const SizedBox(height: 4),
                  PixelButton(
                    key: const Key('saveBudgetButton'),
                    label: 'LƯU NGÂN SÁCH',
                    icon: 'check',
                    expanded: true,
                    isLoading: _isSavingBudget,
                    onPressed: _isSavingBudget ? null : _saveBudget,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBudgetView(BudgetState budgetState) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final totals = budgetTotals(budgetState);
    final rawPercent = totals.budget > 0 ? totals.spent / totals.budget : 0.0;
    final remaining = totals.budget - totals.spent;
    final isOver = remaining < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('NGÂN SÁCH TỔNG', style: text.labelLarge),
              const SizedBox(height: 10),
              PixelTextField(
                key: const Key('totalBudgetField'),
                label: 'Số tiền (VND)',
                hint: '5.000.000',
                controller: _totalBudgetController,
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.none,
                inputFormatters: const [ThousandsSeparatorInputFormatter()],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (totals.budget > 0)
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PixelProgress(
                  value: rawPercent,
                  spendRamp: ref.watch(effectsProvider).chartSpendRamp,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Đã chi: ${CurrencyFormatter.format(totals.spent)}',
                        style: text.bodyMedium?.copyWith(color: palette.ink),
                      ),
                    ),
                    Text(
                      '${(rawPercent * 100).toStringAsFixed(1)}%',
                      style: text.bodyMedium?.copyWith(color: palette.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isOver
                      ? 'QUÁ NGÂN SÁCH: ${CurrencyFormatter.format(-remaining)}'
                      : 'Còn lại: ${CurrencyFormatter.format(remaining)}',
                  style: text.titleSmall?.copyWith(
                    color: isOver ? palette.danger : palette.success,
                  ),
                ),
              ],
            ),
          )
        else
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(name: 'wallet', size: 20, color: palette.inkMuted),
                    const SizedBox(width: 8),
                    Text('Chưa đặt ngân sách', style: text.titleSmall),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Nhập số tiền rồi bấm LƯU NGÂN SÁCH.',
                  style: text.bodySmall?.copyWith(color: palette.inkMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryBudgetView(
    List<Category> categories,
    BudgetState budgetState,
  ) {
    if (categories.isEmpty) {
      return const PixelEmptyState(
        glyph: 'tag',
        title: 'Chưa có danh mục',
        message: 'Thêm danh mục để chia ngân sách theo từng nhóm.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in categories)
          if (category.id != null) _buildCategoryRow(category, budgetState),
      ],
    );
  }

  Widget _buildCategoryRow(Category category, BudgetState budgetState) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final id = category.id!;
    final controller = _controllerFor(id, budgetState.categoryBudgets[id] ?? 0);
    final budget = budgetState.categoryBudgets[id] ?? 0.0;
    final spent = budgetState.categorySpent[id] ?? 0.0;
    final rawPercent = budget > 0 ? spent / budget : 0.0;
    final remaining = budget - spent;
    final isOver = remaining < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PixelPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIcon(
                  name: IconHelper.normalizeIconKey(category.icon),
                  size: 20,
                  color: palette.accentForCategory(category.name),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(color: palette.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PixelTextField(
              key: ValueKey('categoryBudget-$id'),
              label: 'Số tiền (VND)',
              controller: controller,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              inputFormatters: const [ThousandsSeparatorInputFormatter()],
            ),
            const SizedBox(height: 10),
            if (budget > 0) ...[
              PixelProgress(
                value: rawPercent,
                segments: 12,
                spendRamp: ref.watch(effectsProvider).chartSpendRamp,
              ),
              const SizedBox(height: 6),
              Text(
                'Đã chi ${CurrencyFormatter.format(spent)} • '
                '${(rawPercent * 100).toStringAsFixed(0)}%',
                style: text.bodySmall?.copyWith(color: palette.inkMuted),
              ),
              const SizedBox(height: 4),
              Text(
                isOver
                    ? 'QUÁ NGÂN SÁCH: ${CurrencyFormatter.format(-remaining)}'
                    : 'Còn lại: ${CurrencyFormatter.format(remaining)}',
                style: text.labelLarge?.copyWith(
                  color: isOver ? palette.danger : palette.success,
                ),
              ),
            ] else
              Text(
                'Đã chi ${CurrencyFormatter.format(spent)}',
                style: text.bodySmall?.copyWith(color: palette.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tổng chi và ngân sách đã đặt của tháng đang xem; budget = 0 khi chưa đặt.
({double spent, double budget}) budgetTotals(BudgetState state) =>
    (spent: state.totalSpent, budget: state.totalBudget?.amount ?? 0);
