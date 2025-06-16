class User {
  final String id;
  final String name;
  final String role;
  final String bio;
  final String avatar;
  final int prayersCount;
  final int teachingsCount;
  final int followersCount;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.bio,
    required this.avatar,
    required this.prayersCount,
    required this.teachingsCount,
    required this.followersCount,
    this.isVerified = false,
  });
}