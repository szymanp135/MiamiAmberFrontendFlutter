import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() { _checkLoginStatus(); }

  Future<void> _checkLoginStatus() async {
    final token = await ApiService().getToken();
    if (token != null) { _token = token; _isLoggedIn = true; notifyListeners(); }
  }

  Future<void> login(String username, String password) async {
    final data = await ApiService().login(username, password);
    _token = data['token'];
    await ApiService().saveToken(_token!);
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService().removeToken();
    _token = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}

class SettingsProvider with ChangeNotifier {
  bool _sortNewestFirst = true; // Domyślnie najnowsze na górze

  bool get sortNewestFirst => _sortNewestFirst;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sortNewestFirst = prefs.getBool('sortNewestFirst') ?? true;
    notifyListeners();
  }

  Future<void> setSortOrder(bool newestFirst) async {
    _sortNewestFirst = newestFirst;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sortNewestFirst', newestFirst);
    notifyListeners();
  }
}