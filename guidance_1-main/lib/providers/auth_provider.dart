import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  bool _isLoggedIn = false;

  Map<String, dynamic>? get userData => _userData;
  String? get userId => _userData?['id']?.toString();
  String? get userRole => _userData?['role'];
  bool get isLoggedIn => _isLoggedIn;

  void login(Map<String, dynamic> userData) {
    _userData = userData;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _userData = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
