/// Product Provider
/// 
/// Manages the state of the entire product inventory. Caches the product list 
/// locally to minimize API calls and provides filtered lists (like low stock).
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<dynamic> _products = [];
  bool _isLoading = false;

  List<dynamic> get products => _products;
  bool get isLoading => _isLoading;

  /// Dynamically filters the cached products to return only those that 
  /// are at or below their designated low stock threshold (defaults to 5).
  List<dynamic> get lowStockProducts => _products.where((p) {
    final threshold = p['low_stock_threshold'] ?? 5; // Fallback to 5 if threshold is undefined
    return (p['quantity'] ?? 0) <= threshold;
  }).toList();

  /// Refreshes the product inventory from the backend.
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

  /// Updates the quantity of a product directly (e.g., from a quick-action button in the UI).
  /// Automatically re-fetches the product list after a successful update to sync the UI.
  Future<void> quickAdjustStock({
    required int productId,
    required int quantityChange, // Positive for adding stock, Negative for deducting
    required int userId,
    required String role,
    String reason = "Quick Adjustment",
  }) async {
    try {
      await ApiService.adjustStock(
        productId: productId,
        quantityChange: quantityChange,
        userId: userId,
        reason: reason,
        role: role,
      );
      await fetchProducts(); // Refresh list to see new quantity
    } catch (e) {
      debugPrint('Quick adjust stock error: $e');
      rethrow;
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
