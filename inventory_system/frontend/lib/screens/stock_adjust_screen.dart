import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
      if (!mounted) return;
      setState(() {
        _selectedProduct = product;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
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
        const SnackBar(
          content: Text('Error: Stock cannot fall below zero.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

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
          const SnackBar(
            content: Text('Stock updated successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        productProvider.fetchProducts(); // Refresh status
        setState(() {
          _selectedProduct = null;
          _barcodeController.clear();
          _quantityController.clear();
          _reasonController.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Text(
                  'Stock Adjustment',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan or enter a barcode to adjust stock levels',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Step 1: Search ──
                _buildSectionCard(
                  stepNumber: '1',
                  title: 'Find Product',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                hintText: 'Enter barcode...',
                                prefixIcon: Icon(
                                  Icons.qr_code_rounded,
                                  size: 20,
                                ),
                              ),
                              onSubmitted: (_) => _searchProduct(),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          _buildIconButton(
                            icon: Icons.qr_code_scanner_rounded,
                            tooltip: 'Scan',
                            onTap: _scanBarcode,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _searchProduct,
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Search Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary.withAlpha(20),
                            foregroundColor: AppTheme.primary,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // ── Loading ──
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (_selectedProduct != null) ...[
                  // ── Step 2: Product Info ──
                  _buildSectionCard(
                    stepNumber: '2',
                    title: 'Product Found',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedProduct!['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text(
                                      'Current Stock: ',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusFull,
                                        ),
                                      ),
                                      child: Text(
                                        '${_selectedProduct!['quantity']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // ── Step 3: Adjustment ──
                  _buildSectionCard(
                    stepNumber: '3',
                    title: 'Make Adjustment',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Quantity Change'),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 5 or -2',
                            prefixIcon: Icon(Icons.swap_vert_rounded, size: 20),
                            helperText:
                                'Positive = Stock IN, Negative = Stock OUT',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        _buildLabel('Reason'),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Sale, Restock, Damage',
                            prefixIcon: Icon(Icons.notes_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _submitAdjustment,
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 20,
                            ),
                            label: const Text(
                              'Confirm Adjustment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String stepNumber,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          child,
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: AppTheme.textPrimary,
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
