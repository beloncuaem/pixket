import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/utils/storage_paths.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/priority_level.dart';
import '../../widgets/priority_badge.dart';

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
    final caption = expense.caption.trim();

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(expense),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 170,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.feedTopGradient),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 340,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.feedBottomGradient),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _GlassPill(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconHelper.getIconWidget(
                                category?.icon ?? 'dotsThreeOutline',
                                size: 14,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category?.name ?? 'Khác',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (priority != null)
                          PriorityBadge(priority: expense.priority),
                        const Spacer(),
                        Text(
                          '${DateFormatter.formatDate(expense.createdAt)} • ${DateFormatter.formatTime(expense.createdAt)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      caption.isEmpty ? 'Một khoảnh khắc chi tiêu' : caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 14,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(expense.amount),
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _FeedActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Chỉnh sửa',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 10),
                  _FeedActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Xóa',
                    onTap: onDelete,
                    danger: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage(Expense expense) {
    final url = expense.displayImageUrl;
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        cacheKey: storagePathOf(expense.imagePath),
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(
          color: AppColors.feedBackground,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),
        ),
        errorWidget: (_, __, ___) => _errorPlaceholder(),
      );
    }

    // Chỉ ảnh chưa kịp lên Cloud mới còn là đường dẫn tệp cục bộ.
    final path = expense.imagePath;
    if (path != null && storagePathOf(path) == null) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _errorPlaceholder(),
        );
      }
    }
    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.pageGradientDark),
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.white24,
          size: 64,
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

class _FeedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _FeedActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF9AA8) : Colors.white;
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
