import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/storage_paths.dart';
import '../../data/models/expense.dart';

class FeedGridScreen extends StatelessWidget {
  final List<Expense> photos;

  const FeedGridScreen({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.feedBackground,
      appBar: AppBar(
        backgroundColor: AppColors.feedBackground,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Đóng',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhật ký ảnh',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '${photos.length} khoảnh khắc',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: photos.isEmpty
          ? const Center(
              child: Text(
                'Chưa có khoảnh khắc nào.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final expense = photos[index];
                return _GridTile(
                  expense: expense,
                  onTap: () => Navigator.of(context).pop(index),
                );
              },
            ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const _GridTile({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: expense.caption.isEmpty ? 'Ảnh khoản chi' : expense.caption,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(expense),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 54,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xB3000000)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 7,
                right: 7,
                bottom: 6,
                child: Text(
                  CurrencyFormatter.format(expense.amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          color: AppColors.surfaceDark,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white38,
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _errorTile(),
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
          errorBuilder: (_, __, ___) => _errorTile(),
        );
      }
    }
    return _errorTile();
  }

  Widget _errorTile() {
    return const ColoredBox(
      color: AppColors.surfaceDark,
      child: Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 28),
      ),
    );
  }
}
