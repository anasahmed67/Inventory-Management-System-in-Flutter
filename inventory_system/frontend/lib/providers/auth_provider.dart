/// Authentication Provider
/// 
/// Manages the logged-in user's state, including their JWT token, role (admin/user), 
/// and user ID. This provider is crucial for Role-Based Access Control (RBAC) in the UI.
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

  /// Submits credentials to the backend and updates the user's session state on success.
  /// Returns `true` if authentication passes, `false` otherwise.
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

  /// Clears the current user's session data and notifies the UI to redirect to the login screen.
  void logout() {
    _token = null;
    _role = null;
    _userId = null;
    notifyListeners();
  }
}
