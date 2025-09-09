class Prayer {
  final String id;
  final String title;
  final String author;
  final String authorRole;
  final String content;
  final List<String> scriptureReferences;
  final List<String> tags;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final String? videoUrl;
  final bool isLive;
  final String authorAvatar;

  Prayer({
    required this.id,
    required this.title,
    required this.author,
    required this.authorRole,
    required this.content,
    required this.scriptureReferences,
    required this.tags,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.videoUrl,
    this.isLive = false,
    required this.authorAvatar,
  });

  factory Prayer.fromFirestore(String id, Map<String, dynamic> data) {
    return Prayer(
      id: id,
      title: data['title']?.toString() ?? '',
      author: data['authorName']?.toString() ?? '',
      authorRole: data['authorRole']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      scriptureReferences: (data['scriptures'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      likes: (data['likesCount'] is int) ? data['likesCount'] as int : 0,
      comments: (data['commentsCount'] is int) ? data['commentsCount'] as int : 0,
      createdAt: data['createdAt'] != null && data['createdAt'].millisecondsSinceEpoch != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'].millisecondsSinceEpoch)
          : DateTime.now(),
      videoUrl: data['videoUrl']?.toString(),
      isLive: data['isLive'] ?? false,
      authorAvatar: data['authorPhotoUrl']?.toString() ?? '',
    );
  }
}