import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../models/friendship.dart';

class ProfileRepository {
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

  Future<FriendProfile> getProfile() async {
    final client = _client();
    final uid = client.auth.currentUser!.id;
    final row = await client
        .from('friend_profiles')
        .select('id, nickname, avatar_url')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return FriendProfile(id: uid);
    return FriendProfile.fromMap(row);
  }

  Future<void> updateNickname(String nickname) async {
    final client = _client();
    await client
        .from('profiles')
        .update({'nickname': nickname.trim()})
        .eq('id', client.auth.currentUser!.id);
  }

  Future<String> uploadAvatar(Uint8List bytes) async {
    final client = _client();
    final uid = client.auth.currentUser!.id;
    final path = '$uid/avatar.jpg';
    await client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    await client
        .from('profiles')
        .update({'avatar_url': path})
        .eq('id', uid);
    return path;
  }

  String? avatarPublicUrl(String path) {
    final client = SupabaseConfig.client;
    if (client == null) return null;
    return client.storage.from('avatars').getPublicUrl(path);
  }
}