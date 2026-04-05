import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';

class StockAdjustScreen extends StatefulWidget {
  const StockAdjustScreen({super.key});

  @override
  State<StockAdjustScreen> createState() => _StockAdjustScreenState();
}

class _StockAdjustScreenState extends State<StockAdjustScreen> {
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  Map<String, dynamic>? _selectedProduct;
  bool _isLoading = false;

  void _searchProduct() async {
    final code = _barcodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final product = await ApiService.getProductByBarcode(code);
      setState(() {
        _selectedProduct = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product not found: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _scanBarcode() async {
    final scannedCode = await showDialog<String>(
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Scan Product')),
        body: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              Navigator.pop(context, barcodes.first.rawValue);
            }
          },
        ),
      ),
    );

    if (scannedCode != null) {
      _barcodeController.text = scannedCode;
      _searchProduct();
    }
  }

  void _submitAdjustment() async {
    if (_selectedProduct == null) return;
    if (_quantityController.text.isEmpty) return;

    final quantityChange = int.parse(_quantityController.text);
    final currentQuantity = _selectedProduct!['quantity'] ?? 0;

    if (currentQuantity + quantityChange < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Stock cannot fall below zero.'), backgroundColor: Colors.red),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    setState(() => _isLoading = true);
    try {
      await ApiService.adjustStock(
        productId: _selectedProduct!['id'],
        quantityChange: quantityChange,
        userId: authProvider.userId!,
        reason: _reasonController.text.trim(),
        role: authProvider.role!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully!'), backgroundColor: Colors.green),
        );
        productProvider.fetchProducts(); // Refresh status
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Adjustment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(labelText: 'Barcode', border: OutlineInputBorder()),
                    onFieldSubmitted: (_) => _searchProduct(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner, size: 32),
                  tooltip: 'Scan Barcode',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _searchProduct, child: const Text('Search Product')),
            if (_isLoading) ...[
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ] else if (_selectedProduct != null) ...[
              const SizedBox(height: 32),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(_selectedProduct!['name'], style: Theme.of(context).textTheme.headlineSmall),
                      Text('Current Quantity: ${_selectedProduct!['quantity']}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity Change (e.g. 5 or -2)',
                  border: OutlineInputBorder(),
                  helperText: 'Use positive for Stock-IN, negative for Stock-OUT',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Sale, Restock, Damage',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitAdjustment,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text('Confirm Adjustment', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
