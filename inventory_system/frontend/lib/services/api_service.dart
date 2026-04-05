import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Add this for kIsWeb

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for others (Web, Desktop, iOS Simulator)
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
       return 'http://10.0.2.2:8080/api';
    }
    return 'http://127.0.0.1:8080/api';
  }

  // Helper for generating headers
  static Map<String, String> _headers(String? role) {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (role != null) {
      headers['X-User-Role'] = role;
    }
    return headers;
  }

  // Helper for handling responses
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
      throw Exception('API Error (${response.statusCode}): $error');
    }
  }

  // Auth: Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({'email': email, 'password': password}),
      headers: _headers(null),
    );
    return _processResponse(response);
  }

  // Products: Get by Barcode
  static Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    final response = await http.get(Uri.parse('$baseUrl/products/barcode/$barcode'), headers: _headers(null));
    return _processResponse(response);
  }

  // Products: Get All
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'), headers: _headers(null));
    return _processResponse(response);
  }

  // Products: Create
  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      body: jsonEncode(product),
      headers: _headers(role),
    );
    return _processResponse(response);
  }

  // Products: Update
  static Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> product, String role) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      body: jsonEncode(product),
      headers: _headers(role),
    );
    return _processResponse(response);
  }

  // Products: Delete
  static Future<Map<String, dynamic>> deleteProduct(int id, String role) async {
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'), headers: _headers(role));
    return _processResponse(response);
  }

  // Stock: Adjust
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

  // Products: Get Low Stock
  static Future<List<dynamic>> getLowStock() async {
    final response = await http.get(Uri.parse('$baseUrl/products/low-stock'), headers: _headers(null));
    return _processResponse(response);
  }

  // Transactions: Get All
  static Future<List<dynamic>> getTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions'), headers: _headers(null));
    return _processResponse(response);
  }

  // Reports: Stock Value
  static Future<Map<String, dynamic>> getStockValue() async {
    final response = await http.get(Uri.parse('$baseUrl/reports/stock-value'), headers: _headers(null));
    return _processResponse(response);
  }
}
