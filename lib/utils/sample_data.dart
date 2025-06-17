import '../models/prayer.dart';
import '../models/user.dart';
import '../models/bible_verse.dart';
import '../models/prayer_event.dart';

class SampleData {
  static List<Prayer> prayers = [
    Prayer(
      id: '1',
      title: 'Morning Prayer Service',
      author: 'Pastor Sarah Johnson',
      authorRole: 'Pastor & Prayer Leader',
      content: 'Father, endue every winner with the zeal of the Lord that will engrace us for continuity in our kingdom advancement endeavour all through the remaining days of the year and beyond.',
      scriptureReferences: ['Psalms 23:1-6', 'John 3:16', 'Matthew 6:9-13', 'Romans 8:28'],
      tags: ['Morning', 'Gratitude', 'Peace'],
      likes: 2400,
      comments: 156,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      isLive: true,
      authorAvatar: 'assets/avatars/sarah.png',
    ),
    Prayer(
      id: '2',
      title: 'Evening Gratitude',
      author: 'Sarah Johnson',
      authorRole: 'Pastor & Prayer Leader',
      content: 'Heavenly Father, as I begin this new day, I come before you with a heart full of gratitude...',
      scriptureReferences: ['Psalms 118:24'],
      tags: ['Gratitude', 'Morning', 'Peace'],
      likes: 45,
      comments: 12,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      authorAvatar: 'assets/avatars/sarah.png',
    ),
    Prayer(
      id: '3',
      title: 'Healing Prayer for Community',
      author: 'Unity Church',
      authorRole: 'Community Church',
      content: 'Lord, we lift up our community to you today. We pray for healing, both physical and spiritual...',
      scriptureReferences: ['James 5:14-15'],
      tags: ['Healing', 'Community', 'Unity'],
      likes: 89,
      comments: 23,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      authorAvatar: 'assets/avatars/unity.png',
    ),
  ];

  static List<BibleVerse> bibleVerses = [
    BibleVerse(
      text: 'I can do all things through Christ who strengthens me.',
      book: 'Philippians',
      chapter: 4,
      verse: 13,
    ),
    BibleVerse(
      text: 'For God so loved the world...',
      book: 'John',
      chapter: 3,
      verse: 16,
    ),
    BibleVerse(
      text: 'And we know that in all things...',
      book: 'Romans',
      chapter: 8,
      verse: 28,
    ),
    BibleVerse(
      text: 'For I know the plans I have for you...',
      book: 'Jeremiah',
      chapter: 29,
      verse: 11,
    ),
  ];

  static List<PrayerEvent> upcomingEvents = [
    PrayerEvent(
      id: '1',
      title: 'Evening Meditation',
      dateTime: DateTime.now().add(Duration(hours: 5)),
      participantsCount: 45,
      description: 'Join us for a peaceful evening meditation',
    ),
    PrayerEvent(
      id: '2',
      title: 'Group Prayer Session',
      dateTime: DateTime.now().add(Duration(days: 1, hours: 9)),
      participantsCount: 128,
      description: 'Community prayer session',
    ),
    PrayerEvent(
      id: '3',
      title: 'Healing Prayer Circle',
      dateTime: DateTime.now().add(Duration(days: 2, hours: 18, minutes: 30)),
      participantsCount: 67,
      description: 'Focused healing prayers',
    ),
    PrayerEvent(
      id: '4',
      title: 'Youth Prayer Meeting',
      dateTime: DateTime.now().add(Duration(days: 4, hours: 20)),
      participantsCount: 89,
      description: 'Prayer meeting for youth',
    ),
  ];

  static User currentUser = User(
    id: '1',
    name: 'Sarah Johnson',
    role: 'Pastor & Prayer Leader',
    bio: 'Blessed to serve God\'s people through prayer and teaching. Let\'s grow in faith together! 🙏',
    avatar: 'assets/avatars/sarah.png',
    prayersCount: 45,
    teachingsCount: 23,
    followersCount: 1247,
    isVerified: true,
  );

  static List<Prayer> userActivity = [
    Prayer(
      id: '4',
      title: 'Evening Gratitude',
      author: 'Sarah Johnson',
      authorRole: 'Pastor & Prayer Leader',
      content: 'Thank you Lord for this beautiful day...',
      scriptureReferences: ['Psalms 118:24'],
      tags: ['Gratitude'],
      likes: 34,
      comments: 8,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      authorAvatar: 'assets/avatars/sarah.png',
    ),
    Prayer(
      id: '5',
      title: 'Walking in Faith',
      author: 'Sarah Johnson',
      authorRole: 'Pastor & Prayer Leader',
      content: 'Lord, help us to walk by faith and not by sight...',
      scriptureReferences: ['2 Corinthians 5:7'],
      tags: ['Faith', 'Trust'],
      likes: 67,
      comments: 15,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      authorAvatar: 'assets/avatars/sarah.png',
    ),
    Prayer(
      id: '6',
      title: 'Healing for Nations',
      author: 'Sarah Johnson',
      authorRole: 'Pastor & Prayer Leader',
      content: 'We pray for healing and peace across all nations...',
      scriptureReferences: ['2 Chronicles 7:14'],
      tags: ['Healing', 'Nations', 'Peace'],
      likes: 89,
      comments: 23,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      authorAvatar: 'assets/avatars/sarah.png',
    ),
  ];

  static List<BibleVerse> psalms23 = [
    BibleVerse(
      text: 'The Lord is my shepherd; I shall not want.',
      book: 'Psalms',
      chapter: 23,
      verse: 1,
    ),
    BibleVerse(
      text: 'He makes me lie down in green pastures. He leads me beside still waters.',
      book: 'Psalms',
      chapter: 23,
      verse: 2,
    ),
    BibleVerse(
      text: 'He restores my soul. He leads me in paths of righteousness for his name\'s sake.',
      book: 'Psalms',
      chapter: 23,
      verse: 3,
    ),
    BibleVerse(
      text: 'Even though I walk through the valley of the shadow of death, I will fear no evil, for you are with me; your rod and your staff, they comfort me.',
      book: 'Psalms',
      chapter: 23,
      verse: 4,
    ),
    BibleVerse(
      text: 'You prepare a table before me in the presence of my enemies; you anoint my head with oil; my cup overflows.',
      book: 'Psalms',
      chapter: 23,
      verse: 5,
    ),
    BibleVerse(
      text: 'Surely goodness and mercy shall follow me all the days of my life, and I shall dwell in the house of the Lord forever.',
      book: 'Psalms',
      chapter: 23,
      verse: 6,
    ),
  ];

  static List<BibleVerse> bookmarkedVerses = [
    BibleVerse(
      text: 'For God so loved the world...',
      book: 'John',
      chapter: 3,
      verse: 16,
    ),
    BibleVerse(
      text: 'And we know that in all things...',
      book: 'Romans',
      chapter: 8,
      verse: 28,
    ),
    BibleVerse(
      text: 'For I know the plans I have for you...',
      book: 'Jeremiah',
      chapter: 29,
      verse: 11,
    ),
  ];
}