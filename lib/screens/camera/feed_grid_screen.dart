import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/pixel_empty_state.dart';
import '../../widgets/pixel/pixel_receipt_image.dart';

/// Lưới ảnh nhật ký: chạm một ô để quay lại đúng trang ảnh đó.
class FeedGridScreen extends StatelessWidget {
  final List<Expense> expenses;
  final Map<int, Category> categoriesById;

  const FeedGridScreen({
    super.key,
    required this.expenses,
    this.categoriesById = const {},
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: palette.feedBg,
      appBar: AppBar(
        backgroundColor: palette.feedBg,
        foregroundColor: palette.feedInk,
        leading: PixelIconButton(
          icon: 'close',
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
          background: palette.feedPanel,
          borderColor: palette.feedInk,
          iconColor: palette.feedInk,
        ),
        title: Text(
          '${expenses.length} ảnh',
          style: text.titleMedium?.copyWith(color: palette.feedInk),
        ),
      ),
      body: expenses.isEmpty
          ? const PixelEmptyState(
              glyph: 'filmStrip',
              title: 'Chưa có khoản chi nào',
              message: 'Mở camera và chụp khoản chi đầu tiên.',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return _GridTile(
                  expense: expense,
                  categoryName: categoriesById[expense.categoryId]?.name,
                  onTap: () => Navigator.of(context).pop(index),
                );
              },
            ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final Expense expense;
  final String? categoryName;
  final VoidCallback onTap;

  const _GridTile({
    required this.expense,
    required this.onTap,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final label =
        'Ảnh khoản chi ${expense.caption.isEmpty ? expense.amount.toInt() : expense.caption}';

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PixelReceiptImage.fromExpense(expense, semanticLabel: label),
              if (categoryName != null)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: ColoredBox(
                    color: palette.feedPanel.withValues(alpha: 0.85),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        categoryName!,
                        style: text.labelSmall?.copyWith(
                          color: palette.feedInk,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
