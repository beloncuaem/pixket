import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense.dart';
import 'app_icon.dart';
import 'pixel_receipt_image.dart';

/// Một dòng khoản chi theo ngôn ngữ pixel, tùy chọn vuốt để xóa mềm.
class PixelExpenseTile extends StatelessWidget {
  const PixelExpenseTile({
    super.key,
    required this.expense,
    required this.categoryName,
    this.categoryIconKey = 'tag',
    this.onTap,
    this.onDismiss,
    this.showTime = true,
  });

  final Expense expense;
  final String categoryName;
  final String categoryIconKey;
  final ValueChanged<Expense>? onTap;
  final ValueChanged<Expense>? onDismiss;
  final bool showTime;

  static const double rowHeight = 72;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final accent = palette.accentForCategory(categoryName);
    final priorityInk = palette.priorityColor(expense.priority);

    final row = InkWell(
      onTap: onTap == null ? null : () => onTap!(expense),
      child: Container(
        height: rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(bottom: BorderSide(color: palette.line, width: 1)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: expense.imagePath == null
                  ? _CategoryBadge(
                      iconKey: categoryIconKey,
                      accent: accent,
                      palette: palette,
                    )
                  : PixelReceiptImage.fromExpense(
                      expense,
                      width: 52,
                      height: 52,
                      radius: 8,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.caption.isEmpty ? '—' : expense.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.format(expense.amount),
                    style: text.titleMedium?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 8, height: 8, color: priorityInk),
                    const SizedBox(width: 4),
                    Text(
                      showTime
                          ? DateFormatter.formatTime(expense.createdAt)
                          : expense.priorityLabel,
                      style: text.labelSmall?.copyWith(color: palette.inkMuted),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onDismiss == null) return row;

    return Dismissible(
      key: ValueKey('expense-row-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        key: ValueKey('delete-bg-${expense.id}'),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: palette.danger,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Xóa',
              style: text.labelLarge?.copyWith(color: palette.onAccent),
            ),
            const SizedBox(width: 8),
            AppIcon(name: 'trash', size: 32, color: palette.onAccent),
          ],
        ),
      ),
      onDismissed: (_) => onDismiss!(expense),
      child: row,
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.iconKey,
    required this.accent,
    required this.palette,
  });

  final String iconKey;
  final Color accent;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent,
        border: Border.all(color: palette.lineStrong, width: 2),
      ),
      child: Center(
        child: AppIcon(name: iconKey, size: 32, color: palette.onAccent),
      ),
    );
  }
}
