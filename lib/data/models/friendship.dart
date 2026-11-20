class FriendProfile {
  final String id;
  final String? nickname;
  final String? avatarUrl;

  const FriendProfile({required this.id, this.nickname, this.avatarUrl});

  factory FriendProfile.fromMap(Map<String, dynamic> map) => FriendProfile(
        id: map['id'] as String,
        nickname: map['nickname'] as String?,
        avatarUrl: map['avatar_url'] as String?,
      );

  String get displayName {
    final n = nickname?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Bạn';
  }
}

class Friendship {
  final int id;
  final String requesterId;
  final String addresseeId;
  final String status;
  final DateTime createdAt;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
  });

  factory Friendship.fromMap(Map<String, dynamic> map) => Friendship(
        id: map['id'] as int,
        requesterId: map['requester_id'] as String,
        addresseeId: map['addressee_id'] as String,
        status: map['status'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}