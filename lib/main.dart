import 'package:flutter/material.dart';
import 'package:miami_amber_flutter_frontend/page_create.dart';
import 'package:miami_amber_flutter_frontend/page_home.dart';
import 'package:miami_amber_flutter_frontend/page_profile.dart';
import 'package:miami_amber_flutter_frontend/page_settings.dart';
import 'package:miami_amber_flutter_frontend/page_user.dart';
import 'package:miami_amber_flutter_frontend/providers.dart';
import 'package:provider/provider.dart';

import 'constants.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MiamiAmberApp(),
    ),
  );
}

// --- Główna Aplikacja ---
class MiamiAmberApp extends StatelessWidget {
  const MiamiAmberApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Miami Amber',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      // JASNY
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: kLightBgColor,
        colorScheme: ColorScheme.fromSeed(seedColor: kMiamiAmberColor, brightness: Brightness.light, primary: kMiamiAmberColor),
        appBarTheme: const AppBarTheme(backgroundColor: kMiamiAmberColor, foregroundColor: Colors.white, centerTitle: true),
        // Naprawa kolorów Tabs w jasnym motywie
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white
      ),
      ),
      // CIEMNY
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kDarkBgColor,
        colorScheme: ColorScheme.fromSeed(seedColor: kMiamiAmberColor, brightness: Brightness.dark, primary: kMiamiAmberColor),
        appBarTheme: const AppBarTheme(backgroundColor: kMiamiAmberColor, foregroundColor: Colors.black, centerTitle: true),
        // Naprawa kolorów Tabs w ciemnym motywie (Issue 3)
        tabBarTheme: const TabBarThemeData(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black
        ),
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CreatePostScreen(),
    const UserSearchScreen(),
    //const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Sprawdzamy szerokość ekranu
    final double width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 600; // Standardowy próg dla telefonów
    final bool isWideScreen = width > 900;  // Próg dla rozszerzonego menu

    if (isSmallScreen) {
      // --- WIDOK NA TELEFON (Pasek na dole) ---
      return Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) => setState(() => _currentIndex = index),
          indicatorColor: kMiamiAmberColor,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Create'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Users'),
            //NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      );
    } else {
      // --- WIDOK NA KOMPUTER (Pasek z boku) ---
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) => setState(() => _currentIndex = index),
              extended: isWideScreen, // Rozwiń tekst tylko na szerokich oknach
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              indicatorColor: kMiamiAmberColor,
              selectedIconTheme: const IconThemeData(color: Colors.black),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: Text('Create')),
                NavigationRailDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search_rounded), label: Text('Users')),
                //NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      );
    }
  }
}
