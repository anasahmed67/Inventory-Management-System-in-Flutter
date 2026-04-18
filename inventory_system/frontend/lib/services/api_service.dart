// API Service
/// 
/// This singleton class acts as the bridge between the Flutter frontend and the Dart backend.
/// It encapsulates all HTTP requests (GET, POST, PUT, DELETE) and handles JSON serialization,
/// basic error handling, and authorization headers.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Add this for kIsWeb

class ApiService {
  /// Local IP address of the backend server.
  /// Update this if the server's local IP changes (e.g., in office or home networks).
  static const String _serverIp = '192.168.100.10';

  /// Base API URL resolution.
  /// Dynamically selects the localhost URL based on the platform.
  /// (e.g., 10.0.2.2 is required for Android emulators to reach the host machine).
  static String get baseUrl {
    // For physical Android devices, use the local IP of the host machine
    // For Android emulators, 10.0.2.2 is usually used
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_serverIp:8080/api';
    }
    return 'http://127.0.0.1:8080/api';
  }

  /// Generates the standard HTTP headers for requests.
  /// 
  /// Optionally attaches the 'X-User-Role' header if a [role] is provided, 
  /// which the backend uses for access control (e.g., admin-only routes).
  static Map<String, String> _headers(String? role) {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (role != null) {
      headers['X-User-Role'] = role;
    }
    return headers;
  }

  /// Centralized response handler.
  /// 
  /// Parses the JSON body for successful responses (status 200-299).
  /// Extracts the 'error' message from the backend if it exists and throws an 
  /// exception for unsuccessful responses.
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {};
      }
    } else {
      String errorMessage = 'Unknown error';
      try {
        final decoded = jsonDecode(response.body);
        errorMessage = decoded['error'] ?? 'Unknown error';
      } catch (e) {
        errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Server returned status ${response.statusCode}';
      }
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  /// Authenticates a user by sending email and password to the server.
  /// Returns user info and token on success.
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: _headers(null),
    );
    return _processResponse(response);
  }

  /// Fetches a specific product using its unique barcode or SKU.
  static Future<Map<String, dynamic>> getProductByBarcode(
    String barcode,
  ) async {
    // Encode the barcode to handle special characters (common in QR codes)
    final encodedCode = Uri.encodeComponent(barcode);
    final response = await http.get(
      Uri.parse('$baseUrl/products/barcode/$encodedCode'),
      headers: _headers(null),
    );
    return _processResponse(response);
  }

  /// Retrieves the entire inventory of products.
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _headers(null),
    );
    return _processResponse(response);
  }

  /// Submits a newly created product payload to the backend.
  /// Only accessible if the active user role is 'admin'.
  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> product,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      body: jsonEncode(product),
      headers: _headers(role),
    );
    return _processResponse(response);
  }

  /// Updates an existing product using its [id].
  /// Requires 'admin' role.
  static Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, dynamic> product,
    String role,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      body: jsonEncode(product),
      headers: _headers(role),
    );
    return _processResponse(response);
  }

  /// Deletes a product from the database permanently.
  /// Requires 'admin' role.
  static Future<Map<String, dynamic>> deleteProduct(int id, String role) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: _headers(role),
    );
    return _processResponse(response);
  }

  /// Updates stock quantities (Add/Deduct/Adjust).
  /// Also logs the reason and the user performing the change in the transactions log.
  static Future<Map<String, dynamic>> adjustStock({
    required int productId,
    required int quantityChange,
    required int userId,
    required String reason,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stock/adjust'),
      body: jsonEncode({
        'product_id': productId,
        'quantity_change': quantityChange,
        'user_id': userId,
        'reason': reason,
      }),
      headers: _headers(role),
    );
    return _processResponse(response);
  }

  /// Fetches products whose quantity has reached or fallen below their threshold.
  static Future<List<dynamic>> getLowStock() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/low-stock'),
      headers: _headers(null),
    );
    return _processResponse(response);
  }

  /// Fetches the complete history of stock insertions, adjustments, and updates.
  static Future<List<dynamic>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: _headers(null),
    );
    return _processResponse(response);
  }

  /// Calculates the total monetary value of all stock items currently held.
  static Future<Map<String, dynamic>> getStockValue() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/stock-value'),
      headers: _headers(null),
    );
    return _processResponse(response);
  }

  /// Returns a summarized count of products categorized by stock health 
  /// (healthy, low_stock, out_of_stock).
  static Future<Map<String, dynamic>> getStockSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/stock-summary'),
      headers: _headers(null),
    );
    return _processResponse(response);
  }

  /// Fetches the top 5 products ranked by quantity on hand.
  static Future<List<dynamic>> getTopProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/top-products'),
      headers: _headers(null),
    );
    return _processResponse(response);
  }
}
