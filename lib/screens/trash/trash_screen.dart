import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

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
    setState(_reload);
  }

  Future<void> _deleteForever(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa vĩnh viễn?'),
        content: const Text(
          'Khoản chi và ảnh đính kèm sẽ không thể khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(expenseProvider.notifier)
          .permanentlyDeleteExpense(expense);
      if (mounted) setState(_reload);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể xóa vĩnh viễn. Kiểm tra kết nối và thử lại.',
          ),
        ),
      );
    }
  }

  Widget _buildThumbnail(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const ColoredBox(
        color: Colors.black12,
        child: Icon(Icons.broken_image_outlined),
      );
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(
          color: Colors.black12,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => const ColoredBox(
          color: Colors.black12,
          child: Icon(Icons.broken_image_outlined),
        ),
      );
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return const ColoredBox(
      color: Colors.black12,
      child: Icon(Icons.broken_image_outlined),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryMap = {
      for (final category in ref.watch(categoryProvider).categories)
        category.id: category,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Thùng rác')),
      body: FutureBuilder<List<Expense>>(
        future: _deletedExpenses,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final expenses = snapshot.data ?? const <Expense>[];
          if (expenses.isEmpty) {
            return const Center(child: Text('Thùng rác đang trống.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final category = categoryMap[expense.categoryId];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 56,
                      width: 56,
                      child: _buildThumbnail(expense.imagePath),
                    ),
                  ),
                  title: Text(
                    expense.caption.isEmpty
                        ? 'Không có ghi chú'
                        : expense.caption,
                  ),
                  subtitle: Row(
                    children: [
                      IconHelper.getIconWidget(
                        category?.icon ?? 'dotsThreeOutline',
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          category?.name ?? 'Khác',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Thao tác',
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'restore') _restore(expense);
                      if (value == 'delete') _deleteForever(expense);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'restore', child: Text('Khôi phục')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa vĩnh viễn'),
                      ),
                    ],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(CurrencyFormatter.format(expense.amount)),
                        const SizedBox(height: 2),
                        const Icon(Icons.more_vert_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
