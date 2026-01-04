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
    this.timestamp,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      author: data['author'] ?? 'Anonymous',
      role: data['role'] ?? 'Member',
      content: data['content'] ?? '',
      avatar: data['avatar'] ?? '?',
      color: data['color'] ?? 0xFF9E9E9E,
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
