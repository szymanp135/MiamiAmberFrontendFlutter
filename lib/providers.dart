import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isThemeDark') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isThemeDark', isDark);
    notifyListeners();
  }
}

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await ApiService().getToken();
    if (token != null) {
      _token = token;
      _isLoggedIn = true;
      notifyListeners();
    }
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

enum SortingType {
  byNewest,
  byOldest,
  byMostRated,
  byLeastRated;

  static SortingType fromString(String s) => switch (s) {
    "byNewest" => byNewest,
    "byOldest" => byOldest,
    "byMostRated" => byMostRated,
    "byLeastRated" => byLeastRated,
    _ => byNewest
  };
}

String SortingTypeToString(SortingType arg) => arg.toString().split(".").last;

class SettingsProvider with ChangeNotifier {
  SortingType _sortingType = SortingType.byNewest;

  SortingType get sortingType => _sortingType;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('sortingType') ?? SortingTypeToString(SortingType.byNewest);
    _sortingType = SortingType.fromString(type);
    notifyListeners();
  }

  Future<void> setSortOrder(SortingType sorting) async {
    _sortingType = sorting;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortingType', SortingTypeToString(sorting));
    notifyListeners();
  }
}
