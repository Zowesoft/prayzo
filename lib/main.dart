import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:prayoo/providers/auth_provider.dart';
import 'package:prayoo/providers/connection_provider.dart';
import 'package:prayoo/providers/session_provider.dart';
import 'package:prayoo/screens/home_page.dart';
import 'package:prayoo/screens/session_page.dart';
import 'package:provider/provider.dart';
import 'screens/notes_screen.dart';
import 'screens/bible_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/prayer_view_page.dart';
import 'utils/colors.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'config/env.dart';
import 'screens/notifications_screen.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'screens/organization_page.dart';
import 'services/local_notifications.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
  await NotificationService.initialize();
  // Initialize local notifications plugin early to avoid MissingPluginException
  await LocalNotifications.initialize();
  runApp(PrayooApp());
}

class PrayooApp extends StatelessWidget {
  const PrayooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SessionProvider()),
          ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
          ],
          theme: ThemeData(
            primaryColor: AppColors.primaryBlue,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              brightness: Brightness.light,
            ),
            fontFamily: 'Roboto',
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: AppColors.primaryBlue),
            ),
          ),
          home: MainScreen(),
          routes: {
            '/home': (context) => HomePage(),
            '/session': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments as PrayerSession;
              return SessionPage(session: args);
            },
            '/profile': (context) => ProfileScreen(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/prayer': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return PrayerViewPage(prayer: args);
            },
            '/notifications': (context) => const NotificationsScreen(),
          },
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '');
            if (uri.pathSegments.length == 2 &&
                uri.pathSegments.first == 'organizations') {
              final orgId = uri.pathSegments[1];
              return MaterialPageRoute(
                builder: (_) => OrganizationPage(orgId: orgId),
                settings: settings,
              );
            }
            return null;
          },
          debugShowCheckedModeBanner: false,
        ));
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    HomePage(),
    BibleScreen(),
    NotesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
