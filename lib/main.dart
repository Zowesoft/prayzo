import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/create_note_screen.dart';
import 'screens/bible_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/colors.dart';
import 'widgets/bottom_nav_bar.dart';

void main() {
  runApp(PrayZoApp());
}

class PrayZoApp extends StatelessWidget {
  const PrayZoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrayZo',
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
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    HomeScreen(),
    BibleScreen(),
    CreateNoteScreen(),
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
