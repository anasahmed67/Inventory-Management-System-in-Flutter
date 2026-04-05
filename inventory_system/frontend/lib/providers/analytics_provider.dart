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
