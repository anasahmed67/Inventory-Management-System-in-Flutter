import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  int? _userId;

  String? get token => _token;
  String? get role => _role;
  int? get userId => _userId;
  bool get isLoggedIn => _token != null;

  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);
      
      _token = response['token'];
      _role = response['user']['role'];
      _userId = response['user']['id'];
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  void logout() {
    _token = null;
    _role = null;
    _userId = null;
    notifyListeners();
  }
}
