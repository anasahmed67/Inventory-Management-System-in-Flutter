import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsProvider with ChangeNotifier {
  Map<String, dynamic> _stockSummary = {
    'healthy': 0,
    'low_stock': 0,
    'out_of_stock': 0,
  };
  List<dynamic> _topProducts = [];
  bool _isLoading = false;

  Map<String, dynamic> get stockSummary => _stockSummary;
  List<dynamic> get topProducts => _topProducts;
  bool get isLoading => _isLoading;

  /// Updates internal state based on current products without making an API call.
  /// This enables real-time updates on the dashboard.
  void updateFromProducts(List<dynamic> products) {
    if (products.isEmpty) {
      _stockSummary = {
        'healthy': 0,
        'low_stock': 0,
        'out_of_stock': 0,
      };
      _topProducts = [];
      notifyListeners();
      return;
    }

    // 1. Calculate stock summary
    int healthy = 0;
    int lowStock = 0;
    int outOfStock = 0;

    for (final p in products) {
      final qty = (p['quantity'] ?? 0) as num;
      final threshold = (p['low_stock_threshold'] ?? 5) as num;

      if (qty <= 0) {
        outOfStock++;
      } else if (qty <= threshold) {
        lowStock++;
      } else {
        healthy++;
      }
    }

    _stockSummary = {
      'healthy': healthy,
      'low_stock': lowStock,
      'out_of_stock': outOfStock,
    };

    // 2. Calculate top 5 products (Qty)
    final sorted = List.from(products);
    sorted.sort((a, b) {
      final qtyA = (a['quantity'] ?? 0) as num;
      final qtyB = (b['quantity'] ?? 0) as num;
      return qtyB.compareTo(qtyA);
    });
    
    _topProducts = sorted.take(5).map((p) => {
      'name': p['name'],
      'quantity': p['quantity'],
    }).toList();

    notifyListeners();
  }

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Fetch both in parallel
      final results = await Future.wait([
        ApiService.getStockSummary(),
        ApiService.getTopProducts(),
      ]);

      _stockSummary = results[0] as Map<String, dynamic>;
      _topProducts = results[1] as List<dynamic>;
    } catch (e) {
      debugPrint('Fetch analytics error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
