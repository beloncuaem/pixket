import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/friendship.dart';
import '../../providers/friend_provider.dart';
import 'friends_feed_screen.dart';

class FriendsManageScreen extends ConsumerStatefulWidget {
  const FriendsManageScreen({super.key});

  @override
  ConsumerState<FriendsManageScreen> createState() => _FriendsManageScreenState();
}

class _FriendsManageScreenState extends ConsumerState<FriendsManageScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(friendRepositoryProvider).sendRequest(email);
      _emailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lời mời.')),
        );
      }
      ref.invalidate(pendingRequestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider);
    final pending = ref.watch(pendingRequestsProvider);

    return Scaffold(
      backgroundColor: context.palette.canvas,
      appBar: AppBar(
        title: const Text('Bạn bè'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email bạn bè',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Mời'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Lời mời đến', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          pending.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Lỗi: $e'),
            data: (list) {
              if (list.isEmpty) return const Text('Không có lời mời nào.');
              return Column(
                children: list.map((item) {
                  final id = item['id'] as int;
                  final prof = item['profile'] as FriendProfile?;
                  final name = prof?.displayName ?? 'Người dùng';
                  return ListTile(
                    title: Text(name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Text('✓'),
                          onPressed: () async {
                            await ref.read(friendRepositoryProvider).accept(id);
                            ref.invalidate(pendingRequestsProvider);
                            ref.invalidate(friendsProvider);
                          },
                        ),
                        IconButton(
                          icon: const Text('×'),
                          onPressed: () async {
                            await ref.read(friendRepositoryProvider).decline(id);
                            ref.invalidate(pendingRequestsProvider);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Danh sách bạn bè', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          friends.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Lỗi: $e'),
            data: (list) {
              if (list.isEmpty) return const Text('Chưa có bạn bè nào.');
              return Column(
                children: list.map((f) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          f.avatarUrl != null ? NetworkImage(f.avatarUrl!) : null,
                      child: f.avatarUrl == null
                          ? Text(f.displayName.characters.first.toUpperCase())
                          : null,
                    ),
                    title: Text(f.displayName),
                    trailing: IconButton(
                      icon: const Text('×'),
                      onPressed: () async {
                        await ref.read(friendRepositoryProvider).remove(f.id);
                        ref.invalidate(friendsProvider);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FriendsFeedScreen()),
            ),
            icon: const Text('🖼'),
            label: const Text('Xem ảnh bạn bè'),
          ),
        ],
      ),
    );
  }
}