/// Export Service
/// 
/// Provides functionality for downloading data tables as CSV files.
/// This is heavily used in the frontend to export product and transaction reports.
/// Currently optimized for Flutter Web using HTML Blob downloads.

import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../utils/file_saver.dart' as fs;

class ExportService {
  /// Converts the given list of products into a CSV format and triggers a download.
  /// 
  /// Calculates the total 'Value' of the product based on its available quantity 
  /// and price on the fly before exporting.
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
    _downloadFile(
      csvContent,
      'inventory_export_${_timestamp()}.csv',
      'text/csv',
    );
  }

  /// Converts the list of transactions (history logs) into a CSV format and triggers download.
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
    _downloadFile(
      csvContent,
      'transactions_export_${_timestamp()}.csv',
      'text/csv',
    );
  }

  /// Internal utility to trigger file downloads in the browser.
  /// 
  /// It creates a temporary HTML anchor (`<a>`) tag, sets its `href` to the blob data,
  /// simulates a click to start the download, and then removes it instantly.
  static void _downloadFile(String content, String fileName, String mimeType) {
    fs.saveFile(content, fileName, mimeType);
  }

  static String _timestamp() {
    return DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
  }
}
