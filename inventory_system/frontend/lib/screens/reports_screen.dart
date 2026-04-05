import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<Map<String, dynamic>> _stockValueFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _stockValueFuture = ApiService.getStockValue();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    // Calculate Top 5 products by value
    final List<dynamic> sortedProducts = List.from(productProvider.products);
    sortedProducts.sort((a, b) {
      final valA = (a['quantity'] ?? 0) * (double.tryParse(a['price'].toString()) ?? 0);
      final valB = (b['quantity'] ?? 0) * (double.tryParse(b['price'].toString()) ?? 0);
      return valB.compareTo(valA);
    });

    final top5 = sortedProducts.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Reports')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: _stockValueFuture,
                builder: (context, snapshot) {
                  final value = snapshot.data?['total_stock_value']?.toString() ?? '...';
                  return Card(
                    color: Colors.blue.shade700,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text('Total Inventory Value', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('\$$value',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('Top 5 Products by Value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (top5.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: top5.map((p) {
                        final val = (p['quantity'] ?? 0) * (double.tryParse(p['price'].toString()) ?? 0);
                        return PieChartSectionData(
                          value: val,
                          title: p['name'].toString().substring(0, p['name'].toString().length > 5 ? 5 : p['name'].toString().length),
                          color: Colors.primaries[top5.indexOf(p) % Colors.primaries.length],
                          radius: 50,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              const Text('Low Stock Alerts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (productProvider.lowStockProducts.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('All stock levels are healthy'),
                  ),
                )
              else
                Column(
                  children: productProvider.lowStockProducts.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item['name']),
                        subtitle: Text('SKU: ${item['sku']}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Qty: ${item['quantity']}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
