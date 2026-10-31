import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/icon_helper.dart';
import '../core/utils/storage_paths.dart';
import '../data/models/category.dart';
import '../data/models/expense.dart';
import 'category_icon_badge.dart';
import 'priority_badge.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final Category category;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Category Icon Badge
              CategoryIconBadge(iconKey: category.icon, size: 44, iconSize: 22),
              const SizedBox(width: 12),

              // Title and Category / Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconHelper.getIconWidget(
                          category.icon,
                          size: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriorityBadge(priority: expense.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expense.dateTime.hour.toString().padLeft(2, '0')}:${expense.dateTime.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Thumbnail (if available)
              if (expense.imagePath != null &&
                  expense.imagePath!.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _showImagePreview(context, expense),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: _buildThumbnailImage(expense),
                    ),
                  ),
                ),
              ],

              // Amount
              Text(
                CurrencyFormatter.format(expense.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(Expense expense) {
    final url = expense.displayImageUrl;
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        cacheKey: storagePathOf(expense.imagePath),
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) =>
            const Center(child: Icon(Icons.receipt_long_rounded, size: 18)),
      );
    }

    // Chỉ ảnh chưa kịp lên Cloud mới còn là đường dẫn tệp cục bộ.
    final path = expense.imagePath;
    if (path != null && storagePathOf(path) == null) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return const Center(child: Icon(Icons.image_rounded, size: 18));
  }

  void _showImagePreview(BuildContext context, Expense expense) {
    final url = expense.displayImageUrl;
    final path = expense.imagePath;
    final Widget preview;
    if (url != null) {
      preview = CachedNetworkImage(
        imageUrl: url,
        cacheKey: storagePathOf(path),
        fit: BoxFit.contain,
      );
    } else if (path != null && storagePathOf(path) == null) {
      preview = Image.file(File(path), fit: BoxFit.contain);
    } else {
      preview = const Icon(Icons.image_rounded, color: Colors.white);
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(color: Colors.black, child: preview),
          ),
        ),
      ),
    );
  }
}
