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
}