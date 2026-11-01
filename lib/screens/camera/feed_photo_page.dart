import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/priority_level.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/feed_hud.dart';
import '../../widgets/pixel/pixel_badge.dart';
import '../../widgets/pixel/pixel_receipt_image.dart';

/// Một trang ảnh trong nhật ký: ảnh full-bleed + panel thông tin bên dưới.
class FeedPhotoPage extends StatelessWidget {
  final Expense expense;
  final Category? category;
  final PriorityLevel? priority;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FeedPhotoPage({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    this.category,
    this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final categoryName = category?.name ?? 'Khác';
    final priorityName = priority?.name ?? expense.priorityLabel;

    return Stack(
      fit: StackFit.expand,
      children: [
        PixelReceiptImage.fromExpense(
          expense,
          fit: BoxFit.cover,
          radius: 4,
          semanticLabel:
              'Ảnh khoản chi ${expense.caption.isEmpty ? expense.amount.toInt() : expense.caption}',
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 160,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: hudTopGradient(palette)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.feedPanel.withValues(alpha: 0.92),
              border: Border(top: BorderSide(color: palette.mint, width: 2)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FeedCaptionPanel(
                      expense: expense,
                      categoryName: categoryName,
                      categoryGlyph: IconHelper.normalizeIconKey(
                        category?.icon ?? 'tag',
                      ),
                      priorityName: priorityName,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        PixelIconButton(
                          key: const ValueKey('feed-edit'),
                          icon: 'edit',
                          tooltip: 'Chỉnh sửa khoản chi',
                          onPressed: onEdit,
                          background: palette.feedPanel,
                          borderColor: palette.feedInk,
                          iconColor: palette.feedInk,
                        ),
                        const SizedBox(width: 8),
                        PixelIconButton(
                          key: const ValueKey('feed-delete'),
                          icon: 'trash',
                          tooltip: 'Chuyển vào thùng rác',
                          onPressed: onDelete,
                          background: palette.feedPanel,
                          borderColor: palette.feedInk,
                          iconColor: palette.feedInk,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Panel thông tin khoản chi phía dưới ảnh.
class FeedCaptionPanel extends StatelessWidget {
  final Expense expense;
  final String categoryName;
  final String priorityName;
  final String categoryGlyph;

  const FeedCaptionPanel({
    super.key,
    required this.expense,
    required this.categoryName,
    required this.priorityName,
    this.categoryGlyph = 'tag',
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final caption = expense.caption.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: PixelBadge(
                glyph: categoryGlyph,
                label: categoryName,
                accent: palette.accentForCategory(categoryName),
                ink: palette.feedInk,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: PixelBadge(
                glyph: 'sparkle',
                label: priorityName,
                accent: palette.priorityColor(expense.priority),
                ink: palette.feedInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            CurrencyFormatter.format(expense.amount),
            style: text.displaySmall?.copyWith(
              color: palette.feedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption.isEmpty ? 'Một khoảnh khắc chi tiêu' : caption,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium?.copyWith(color: palette.feedInk),
        ),
        const SizedBox(height: 4),
        Text(
          '${DateFormatter.formatDate(expense.createdAt)} • ${DateFormatter.formatTime(expense.createdAt)}',
          style: text.bodySmall?.copyWith(color: palette.feedMuted),
        ),
      ],
    );
  }
}
