import 'package:flutter/material.dart';
import 'package:miami_amber_frontend/api/api_service.dart';

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
