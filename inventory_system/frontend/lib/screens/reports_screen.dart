/// Reports Screen
/// 
/// Generates visual representations (Pie Charts) of the inventory's value distribution.
/// Identifies the Top 5 most valuable products and allows exporting reports.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neo_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    Provider.of<ProductProvider>(context, listen: false).fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final isDark = AppTheme.isDark(context);
    final borderCol = AppTheme.borderColor(context);
    final textCol = AppTheme.textColor(context);

    // Aggregate inventory value and extract the top 5 highest-value products.
    // The remaining products' value is grouped into "Others".
    final List<dynamic> sortedProducts = List.from(productProvider.products);
    final double totalInventoryValue = sortedProducts.fold<double>(0, (sum, p) {
      final q = p['quantity'] ?? 0;
      final pr = double.tryParse(p['price'].toString()) ?? 0;
      return sum + (q * pr);
    });

    sortedProducts.sort((a, b) {
      final valA = (a['quantity'] ?? 0) * (double.tryParse(a['price'].toString()) ?? 0);
      final valB = (b['quantity'] ?? 0) * (double.tryParse(b['price'].toString()) ?? 0);
      return valB.compareTo(valA);
    });

    final top5 = sortedProducts.take(5).toList();
    final double top5Value = top5.fold<double>(0, (sum, p) {
      final q = p['quantity'] ?? 0;
      final pr = double.tryParse(p['price'].toString()) ?? 0;
      return sum + (q * pr);
    });
    
    final double othersValue = totalInventoryValue - top5Value;

    final List<Color> palette = [
      AppTheme.primary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.info,
      AppTheme.danger,
      isDark ? const Color(0xFF555566) : Colors.grey.shade400,
    ];

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REPORTS & ANALYTICS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 24 : 32,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Total Value Card
              NeoCard(
                color: AppTheme.info,
                child: Column(
                  children: [
                    const Text(
                      'TOTAL INVENTORY VALUE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${AppTheme.currencySymbol}${NumberFormat('#,###').format(totalInventoryValue)}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: isMobile ? 28 : 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'TOP 5 PRODUCTS BY VALUE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: textCol),
              ),
              const SizedBox(height: 16),
              if (top5.isNotEmpty) ...[
                isMobile
                    ? Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: _buildPieChart(top5, othersValue, totalInventoryValue, palette, borderCol),
                          ),
                          const SizedBox(height: 16),
                          _buildLegend(top5, othersValue, palette, textCol, borderCol),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              height: 220,
                              child: _buildPieChart(top5, othersValue, totalInventoryValue, palette, borderCol),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 5,
                            child: _buildLegend(top5, othersValue, palette, textCol, borderCol),
                          ),
                        ],
                      ),
              ],
              const SizedBox(height: 32),
              Text(
                'EXPORT REPORTS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: textCol),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ExportService.exportProductsToCSV(
                        productProvider.products,
                      ),
                      icon: const Icon(Icons.file_download_outlined, color: Colors.black),
                      label: const Text('DOWNLOAD CSV REPORT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'LOW STOCK ALERTS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: textCol),
              ),
              const SizedBox(height: 16),
              if (productProvider.lowStockProducts.isEmpty)
                NeoCard(
                  color: isDark ? const Color(0xFF1A3D2E) : AppTheme.successLight,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.success, size: 24),
                      const SizedBox(width: AppTheme.spacingMd),
                      Text(
                        'All stock levels are healthy',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: textCol,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: productProvider.lowStockProducts.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: borderCol, width: AppTheme.borderWidth),
                        boxShadow: AppTheme.adaptiveSoftShadow(context),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                        title: Text(
                          item['name'].toString().toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.w900, color: textCol),
                        ),
                        subtitle: Text(
                          'SKU: ${item['sku']}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.secondaryTextColor(context)),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: borderCol, width: 2),
                          ),
                          child: Text(
                            '${item['quantity']}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
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

  Widget _buildPieChart(List<dynamic> top5, double othersValue, double totalInventoryValue, List<Color> palette, Color borderCol) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 0,
        sections: [
          ...top5.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;
            final val = (p['quantity'] ?? 0) * (double.tryParse(p['price'].toString()) ?? 0);
            final percentage = totalInventoryValue > 0 ? (val / totalInventoryValue * 100) : 0.0;
            
            return PieChartSectionData(
              value: val,
              title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
              color: palette[index],
              borderSide: BorderSide(color: borderCol, width: 2),
            );
          }),
          if (othersValue > 0)
            PieChartSectionData(
              value: othersValue,
              title: (othersValue / totalInventoryValue * 100) > 5 
                  ? '${(othersValue / totalInventoryValue * 100).toStringAsFixed(1)}%' 
                  : '',
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
              color: palette[5],
              borderSide: BorderSide(color: borderCol, width: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<dynamic> top5, double othersValue, List<Color> palette, Color textCol, Color borderCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...top5.asMap().entries.map((entry) {
          final index = entry.key;
          final p = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: palette[index],
                    border: Border.all(color: borderCol, width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p['name'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: textCol,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (othersValue > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: palette[5],
                    border: Border.all(color: borderCol, width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'OTHERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textCol,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
