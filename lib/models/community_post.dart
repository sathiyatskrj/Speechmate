class CommunityPost {
  final String id;
  final String author;
  final String role;
  final String content;
  final String avatar;
  final int color;
  final int likes;
  final int comments;
  final bool isVerified;
  final List<dynamic> likedBy;
  final DateTime? timestamp;

  CommunityPost({
    required this.id,
    required this.author,
    required this.role,
    required this.content,
    required this.avatar,
    required this.color,
    required this.likes,
    required this.comments,
    required this.isVerified,
    this.likedBy = const [],
    this.timestamp,
  });

  /// Create from a Map (local JSON or Firestore)
  factory CommunityPost.fromMap(Map<String, dynamic> data, {String? docId}) {
    return CommunityPost(
      id: docId ?? data['id'] ?? '',
      author: data['author'] ?? 'Anonymous',
      role: data['role'] ?? 'Member',
      content: data['content'] ?? '',
      avatar: data['avatar'] ?? '?',
      color: data['color'] ?? 0xFF9E9E9E,
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      likedBy: data['likedBy'] ?? [],
      timestamp: data['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
          : null,
    );
  }
}
