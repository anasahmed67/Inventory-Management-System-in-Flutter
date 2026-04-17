/// Chart Widgets
/// 
/// Reusable wrappers around the `fl_chart` library to render the dashboard's Analytics.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders a Pie Chart summarizing overall stock health (Healthy vs Low vs Out of Stock).
class StockStatusChart extends StatelessWidget {
  final Map<String, dynamic> summary;

  const StockStatusChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final healthy = double.tryParse(summary['healthy'].toString()) ?? 0;
    final lowStock = double.tryParse(summary['low_stock'].toString()) ?? 0;
    final outOfStock = double.tryParse(summary['out_of_stock'].toString()) ?? 0;
    final total = healthy + lowStock + outOfStock;

    if (total == 0) {
      return const Center(child: Text('No data available'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: AppTheme.success,
            value: healthy,
            title: healthy > 0
                ? '${((healthy / total) * 100).toStringAsFixed(0)}%'
                : '',
            radius: 50,
            borderSide: const BorderSide(color: Colors.black, width: 2),
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          PieChartSectionData(
            color: AppTheme.warning,
            value: lowStock,
            title: lowStock > 0
                ? '${((lowStock / total) * 100).toStringAsFixed(0)}%'
                : '',
            radius: 50,
            borderSide: const BorderSide(color: Colors.black, width: 2),
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          PieChartSectionData(
            color: AppTheme.danger,
            value: outOfStock,
            title: outOfStock > 0
                ? '${((outOfStock / total) * 100).toStringAsFixed(0)}%'
                : '',
            radius: 50,
            borderSide: const BorderSide(color: Colors.black, width: 2),
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a Bar Chart displaying the inventory quantities of the Top 5 most valuable products.
class TopProductsChart extends StatelessWidget {
  final List<dynamic> products;

  const TopProductsChart({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            products.fold<double>(0, (max, p) {
              final qty = double.tryParse(p['quantity'].toString()) ?? 0;
              return qty > max ? qty : max;
            }) *
            1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${products[groupIndex]['name']}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
                children: [
                  TextSpan(
                    text: '${rod.toY.toInt()} units',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < products.length) {
                  final name = products[index]['name'].toString();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 8)}..' : name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(products.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY:
                    double.tryParse(products[index]['quantity'].toString()) ??
                    0,
                color: AppTheme.primary,
                width: 22,
                borderSide: const BorderSide(color: Colors.black, width: 2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
