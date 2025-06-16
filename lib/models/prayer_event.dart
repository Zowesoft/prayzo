class PrayerEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final int participantsCount;
  final String description;

  PrayerEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.participantsCount,
    required this.description,
  });
}