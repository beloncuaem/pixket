import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/expense.dart';
import '../data/models/friendship.dart';
import '../data/repositories/friend_repository.dart';
import '../data/repositories/profile_repository.dart';
import 'expense_provider.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final friendsProvider = FutureProvider<List<FriendProfile>>((ref) {
  return ref.read(friendRepositoryProvider).listFriends();
});

final pendingRequestsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(friendRepositoryProvider).listPendingIncoming();
});

final profileProvider = FutureProvider<FriendProfile>((ref) {
  return ref.read(profileRepositoryProvider).getProfile();
});

final friendsFeedProvider = FutureProvider<List<Expense>>((ref) async {
  final friends = await ref.watch(friendsProvider.future);
  final ids = friends.map((f) => f.id).toList();
  if (ids.isEmpty) return const [];
  return ref.read(expenseRepositoryProvider).getExpensesForUsers(ids, limit: 50);
});