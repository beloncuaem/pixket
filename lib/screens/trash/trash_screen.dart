import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_button.dart';
import '../../widgets/pixel/pixel_dialog.dart';
import '../../widgets/pixel/pixel_empty_state.dart';
import '../../widgets/pixel/pixel_loading.dart';
import '../../widgets/pixel/pixel_panel.dart';
import '../../widgets/pixel/pixel_receipt_image.dart';
import '../../widgets/pixel/pixel_screen_header.dart';
import '../../widgets/pixel/pixel_snack_bar.dart';
import '../../widgets/pixel/pixel_star_field.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  late Future<List<Expense>> _deletedExpenses;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _deletedExpenses = ref.read(expenseProvider.notifier).getDeletedExpenses();
  }

  Future<void> _restore(Expense expense) async {
    await ref.read(expenseProvider.notifier).restoreExpense(expense.id!);
    if (!mounted) return;
    setState(_reload);
    showPixelSnackBar(
      context,
      'Đã khôi phục “${expense.caption}”.',
      tone: PixelTone.success,
    );
  }

  Future<void> _deleteForever(Expense expense) async {
    final confirm = await showPixelConfirm(
      context,
      title: 'XÓA VĨNH VIỄN?',
      message: 'Khoản chi và ảnh đính kèm sẽ không thể khôi phục.',
      confirmLabel: 'XÓA VĨNH VIỄN',
      cancelLabel: 'HỦY',
    );
    if (!confirm) return;
    try {
      await ref
          .read(expenseProvider.notifier)
          .permanentlyDeleteExpense(expense);
      if (!mounted) return;
      setState(_reload);
    } catch (_) {
      if (!mounted) return;
      showPixelSnackBar(
        context,
        'Không thể xóa vĩnh viễn. Kiểm tra kết nối và thử lại.',
        tone: PixelTone.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final categoryMap = {
      for (final category in ref.watch(categoryProvider).categories)
        category.id: category,
    };

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: PixelStarField()),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: PixelScreenHeader(
                  title: 'THÙNG RÁC',
                  subtitle: 'Hoàn tác hoặc xóa hẳn khoản chi khỏi cloud',
                  onBackTap: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Expense>>(
                  future: _deletedExpenses,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: PixelLoading(label: 'Đang tải thùng rác…'),
                      );
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          PixelPanel(
                            background: palette.butter,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AppIcon(
                                      name: 'alert',
                                      size: 32,
                                      color: palette.butterInk,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Không tải được thùng rác. Kiểm tra kết nối.',
                                        style: text.bodyMedium?.copyWith(
                                          color: palette.butterInk,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                PixelButton(
                                  label: 'THỬ LẠI',
                                  icon: 'refresh',
                                  variant: PixelButtonVariant.secondary,
                                  onPressed: () => setState(_reload),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    final expenses = snapshot.data ?? const <Expense>[];
                    if (expenses.isEmpty) {
                      return const PixelEmptyState(
                        glyph: 'trash',
                        title: 'Thùng rác đang trống',
                        message: 'Xóa khoản chi trong nhật ký để đưa vào đây trước khi xóa hẳn.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final category = categoryMap[expense.categoryId];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TrashRow(
                            expense: expense,
                            categoryName: category?.name ?? 'Khác',
                            categoryIcon: IconHelper.normalizeIconKey(
                              category?.icon ?? 'dotsThreeOutline',
                            ),
                            onRestore: () => _restore(expense),
                            onPurge: () => _deleteForever(expense),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrashRow extends StatelessWidget {
  final Expense expense;
  final String categoryName;
  final String categoryIcon;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  const _TrashRow({
    required this.expense,
    required this.categoryName,
    required this.categoryIcon,
    required this.onRestore,
    required this.onPurge,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final deletedAt = expense.deletedAt ?? expense.createdAt;

    return PixelPanel(
      key: ValueKey('trash-row-${expense.id}'),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelReceiptImage.fromExpense(
                expense,
                width: 52,
                height: 52,
                semanticLabel: 'Ảnh khoản chi ${expense.caption}',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(expense.amount),
                        style: text.titleLarge,
                      ),
                    ),
                    Text(
                      expense.caption.isEmpty
                          ? 'Không có ghi chú'
                          : expense.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        AppIcon(
                          name: categoryIcon,
                          size: 16,
                          color: palette.accentForCategory(categoryName),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            categoryName,
                            style: text.bodySmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Xóa ngày ${DateFormatter.formatDate(deletedAt)}',
                      style: text.bodySmall?.copyWith(color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Xếp chồng thay vì đặt cạnh nhau: nhãn tiếng Việt dài không vừa nửa
          // bề rộng của màn 360dp và sẽ bị cắt bớt.
          PixelButton(
            key: ValueKey('trash-restore-${expense.id}'),
            label: 'KHÔI PHỤC',
            icon: 'undo',
            variant: PixelButtonVariant.secondary,
            expanded: true,
            onPressed: onRestore,
          ),
          const SizedBox(height: 8),
          PixelButton(
            key: ValueKey('trash-purge-${expense.id}'),
            label: 'XÓA VĨNH VIỄN',
            icon: 'trash',
            variant: PixelButtonVariant.danger,
            expanded: true,
            onPressed: onPurge,
          ),
        ],
      ),
    );
  }
}
