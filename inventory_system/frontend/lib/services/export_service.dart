import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExportService {
  /// Exports product list to CSV
  static void exportProductsToCSV(List<dynamic> products) {
    List<List<dynamic>> rows = [];
    
    // Headers
    rows.add(['SKU', 'Name', 'Description', 'Quantity', 'Price', 'Value']);

    for (var p in products) {
      final qty = p['quantity'] ?? 0;
      final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
      rows.add([
        p['sku'],
        p['name'],
        p['description'] ?? '',
        qty,
        price,
        (qty * price).toStringAsFixed(2),
      ]);
    }

    String csvContent = const ListToCsvConverter().convert(rows);
    _downloadFile(csvContent, 'inventory_export_${_timestamp()}.csv', 'text/csv');
  }

  /// Exports transaction list to CSV
  static void exportTransactionsToCSV(List<dynamic> transactions) {
    List<List<dynamic>> rows = [];
    
    // Headers
    rows.add(['Date', 'Product', 'Type', 'Quantity', 'User', 'Reason']);

    for (var tx in transactions) {
      rows.add([
        tx['transaction_date'],
        tx['product_name'],
        tx['type'],
        tx['quantity'],
        tx['user_name'],
        tx['reason'] ?? '',
      ]);
    }

    String csvContent = const ListToCsvConverter().convert(rows);
    _downloadFile(csvContent, 'transactions_export_${_timestamp()}.csv', 'text/csv');
  }

  /// Helper to handle downloads based on platform
  static void _downloadFile(String content, String fileName, String mimeType) {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile/desktop, we'd use path_provider and dart:io
      // Since the user is on Chrome, web implementation is priority.
      print('Download not implemented for this platform');
    }
  }

  static String _timestamp() {
    return DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
  }
}
