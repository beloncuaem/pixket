import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/save_to_gallery.dart';
import '../../core/utils/square_image.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/priority_level.dart';
import '../../widgets/pixel/app_icon.dart';
import '../../widgets/pixel/feed_hud.dart';
import '../../widgets/pixel/pixel_badge.dart';
import '../../widgets/pixel/pixel_receipt_image.dart';
import '../../widgets/pixel/pixel_star_field.dart';

/// Một trang ảnh trong nhật ký: ảnh vuông ở trên, panel thông tin đặc ở dưới,
/// không thành phần nào đè hay làm mờ ảnh.
class FeedPhotoPage extends StatelessWidget {
  final Expense expense;
  final Category? category;
  final PriorityLevel? priority;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Vị trí hiện tại trong feed, chỉ để hiển thị "3/12"; null là ẩn.
  final int? photoIndex;
  final int? photoCount;

  const FeedPhotoPage({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    this.category,
    this.priority,
    this.photoIndex,
    this.photoCount,
  });

  Future<void> _saveToGallery(BuildContext context) async {
    // Bắt messenger trước khi chờ: BuildContext sau await không còn hợp lệ.
    final messenger = ScaffoldMessenger.of(context);
    final error = await saveReceiptToGallery(
      signedUrl: expense.displayImageUrl,
      localPath: expense.imagePath,
      name: 'pixket_${expense.id ?? DateTime.now().millisecondsSinceEpoch}',
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã lưu ảnh vào thư viện.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final categoryName = category?.name ?? 'Khác';
    final priorityName = priority?.name ?? expense.priorityLabel;
    // Ảnh legacy chưa cắt mà ép cover sẽ mất hai bên, nên chỉ vuông mới cover.
    final fit = isSquareImagePath(expense.imagePath)
        ? BoxFit.cover
        : BoxFit.contain;
    final topInset = MediaQuery.of(context).padding.top;

    return ColoredBox(
      color: palette.feedBg,
      child: Column(
        children: [
          SizedBox(height: topInset + feedHudBarHeight),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PixelReceiptImage.fromExpense(
                    expense,
                    fit: fit,
                    radius: 4,
                    semanticLabel:
                        'Ảnh khoản chi ${expense.caption.isEmpty ? expense.amount.toInt() : expense.caption}',
                  ),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.feedPanel,
              border: Border(top: BorderSide(color: palette.mint, width: 2)),
            ),
            child: Stack(
              children: [
                // Panel nền tối nên có sao; IgnorePointer giữ nút bấm hoạt động.
                const Positioned.fill(child: PixelStarField()),
                SafeArea(
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
                              key: const ValueKey('feed-download'),
                              icon: 'download',
                              tooltip: 'Tải ảnh về máy',
                              onPressed: () => _saveToGallery(context),
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
                            if (photoIndex != null && photoCount != null) ...[
                              const Spacer(),
                              Text(
                                '$photoIndex/$photoCount',
                                style: text.bodySmall?.copyWith(
                                  color: palette.feedMuted,
                                ),
                              ),
                            ],
                          ],
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
