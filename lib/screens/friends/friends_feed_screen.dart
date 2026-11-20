import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/pixel/pixel_receipt_image.dart';

class FriendsFeedScreen extends ConsumerWidget {
  const FriendsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(friendsFeedProvider);
    final friends = ref.watch(friendsProvider).valueOrNull ?? const [];
    final profileMap = {for (final f in friends) f.id: f};
    final categories = ref.watch(categoryProvider).categories;
    final catMap = {for (final c in categories) c.id: c.name};

    return Scaffold(
      backgroundColor: context.palette.canvas,
      appBar: AppBar(
        title: const Text('Ảnh bạn bè'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Không tải được: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có ảnh bạn bè nào.'));
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final e = items[index];
              final author = profileMap[e.authorId];
              return _FeedPage(
                expense: e,
                authorName: author?.displayName ?? 'Bạn bè',
                avatarUrl: author?.avatarUrl,
                categoryName: catMap[e.categoryId] ?? 'Khác',
              );
            },
          );
        },
      ),
    );
  }
}

class _FeedPage extends StatelessWidget {
  final Expense expense;
  final String authorName;
  final String? avatarUrl;
  final String categoryName;

  const _FeedPage({
    required this.expense,
    required this.authorName,
    required this.avatarUrl,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final avatarPublicUrl = avatarUrl == null
        ? null
        : SupabaseConfig.client?.storage.from('avatars').getPublicUrl(avatarUrl!);
    return Column(
      children: [
        Expanded(
          child: PixelReceiptImage.fromExpense(
            expense,
            fit: BoxFit.cover,
            radius: 0,
          ),
        ),
        Container(
          width: double.infinity,
          color: palette.surface,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: avatarPublicUrl != null
                        ? NetworkImage(avatarPublicUrl)
                        : null,
                    child: avatarPublicUrl == null
                        ? Text(authorName.characters.first.toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(categoryName, style: TextStyle(color: palette.inkMuted)),
                ],
              ),
              const SizedBox(height: 6),
              Text(expense.caption),
              const SizedBox(height: 4),
              Text(
                '${CurrencyFormatter.format(expense.amount)} • ${expense.priorityLabel} • '
                '${expense.createdAt.day}/${expense.createdAt.month}/${expense.createdAt.year}',
                style: TextStyle(color: palette.inkMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}