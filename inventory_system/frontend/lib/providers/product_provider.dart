import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<dynamic> _products = [];
  bool _isLoading = false;

  List<dynamic> get products => _products;
  bool get isLoading => _isLoading;

  List<dynamic> get lowStockProducts => _products.where((p) {
    final threshold = p['low_stock_threshold'] ?? 5;
    return (p['quantity'] ?? 0) <= threshold;
  }).toList();

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await ApiService.getProducts();
    } catch (e) {
      debugPrint('Fetch products error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Map<String, dynamic> product, String role) async {
    try {
      await ApiService.createProduct(product, role);
      await fetchProducts();
    } catch (e) {
      debugPrint('Add product error: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(int id, Map<String, dynamic> product, String role) async {
    try {
      await ApiService.updateProduct(id, product, role);
      await fetchProducts();
    } catch (e) {
      debugPrint('Update product error: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(int id, String role) async {
    try {
      await ApiService.deleteProduct(id, role);
      await fetchProducts();
    } catch (e) {
      debugPrint('Delete product error: $e');
      rethrow;
    }
  }
}
