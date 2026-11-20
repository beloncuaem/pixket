import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/friendship.dart';

class FriendRepository {
  SupabaseClient _client() {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Chưa kết nối được Supabase. Vui lòng kiểm tra mạng.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('Vui lòng đăng nhập để tiếp tục.');
    }
    return client;
  }

  Future<void> sendRequest(String email) async {
    final client = _client();
    final rows = await client.rpc('find_user_by_email', params: {'p_email': email});
    final list = (rows as List?) ?? const [];
    if (list.isEmpty) {
      throw StateError('Không tìm thấy người dùng với email này.');
    }
    final targetId = list.first['id'] as String;
    await client.from('friendships').insert({
      'requester_id': client.auth.currentUser!.id,
      'addressee_id': targetId,
      'status': 'pending',
    });
  }

  Future<List<FriendProfile>> listFriends() async {
    final client = _client();
    final uid = client.auth.currentUser!.id;
    final rows = await client
        .from('friendships')
        .select('requester_id, addressee_id')
        .eq('status', 'accepted')
        .or('requester_id.eq.$uid,addressee_id.eq.$uid');

    final ids = <String>{};
    for (final r in (rows as List)) {
      final req = r['requester_id'] as String;
      final add = r['addressee_id'] as String;
      ids.add(req == uid ? add : req);
    }
    if (ids.isEmpty) return const [];
    final profiles = await client
        .from('friend_profiles')
        .select('id, nickname, avatar_url')
        .inFilter('id', ids.toList());
    return (profiles as List)
        .map((m) => FriendProfile.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listPendingIncoming() async {
    final client = _client();
    final uid = client.auth.currentUser!.id;
    final rows = await client
        .from('friendships')
        .select('id, requester_id, created_at')
        .eq('addressee_id', uid)
        .eq('status', 'pending');

    final ids = (rows as List)
        .map((r) => r['requester_id'] as String)
        .toSet()
        .toList();
    final profileMap = <String, FriendProfile>{};
    if (ids.isNotEmpty) {
      final profs = await client
          .from('friend_profiles')
          .select('id, nickname, avatar_url')
          .inFilter('id', ids);
      for (final p in (profs as List)) {
        final fp = FriendProfile.fromMap(p as Map<String, dynamic>);
        profileMap[fp.id] = fp;
      }
    }
    return (rows as List).map((r) {
      return <String, dynamic>{
        'id': r['id'] as int,
        'profile': profileMap[r['requester_id'] as String],
      };
    }).toList();
  }

  Future<void> accept(int id) async {
    await _client().from('friendships').update({'status': 'accepted'}).eq('id', id);
  }

  Future<void> decline(int id) async {
    await _client().from('friendships').update({'status': 'declined'}).eq('id', id);
  }

  Future<void> remove(String friendId) async {
    final client = _client();
    final uid = client.auth.currentUser!.id;
    await client
        .from('friendships')
        .delete()
        .or('and(requester_id.eq.$uid,addressee_id.eq.$friendId),and(addressee_id.eq.$uid,requester_id.eq.$friendId)');
  }
}