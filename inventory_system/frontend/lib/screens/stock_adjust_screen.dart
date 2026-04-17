/// Stock Adjust Screen
/// 
/// Dedicated screen for rigorous stock modifications (e.g., audits, damage write-offs).
/// Features a built-in barcode scanner to quickly pull up a product and adjust its quantity.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neo_card.dart';

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

  /// Calls the backend to retrieve a single product matching the typed/scanned barcode or SKU.
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

  /// Opens a camera dialog using `mobile_scanner` to scan a physical barcode.
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
    final isDark = AppTheme.isDark(context);
    final borderCol = AppTheme.borderColor(context);
    final textCol = AppTheme.textColor(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan or enter a barcode or SKU to adjust stock levels',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Step 1: Search ──
                _buildSectionCard(
                  context: context,
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
                                hintText: 'Enter barcode or SKU...',
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
                          icon: const Icon(Icons.search_rounded, size: 18, color: Colors.black),
                          label: const Text('Search Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
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
                    context: context,
                    stepNumber: '2',
                    title: 'Product Found',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: borderCol, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              border: Border.all(color: borderCol, width: 2),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: textCol,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedProduct!['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: textCol,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Current Stock: ',
                                      style: TextStyle(
                                        color: AppTheme.secondaryTextColor(context),
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
                    context: context,
                    stepNumber: '3',
                    title: 'Make Adjustment',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Quantity Change', context),
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
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // ── Item 9: Preset Quantity Chips ──
                        _buildLabel('Quick Select', context),
                        const SizedBox(height: AppTheme.spacingSm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPresetChip('+1', 1),
                            _buildPresetChip('+5', 5),
                            _buildPresetChip('+10', 10),
                            _buildPresetChip('-1', -1),
                            _buildPresetChip('-5', -5),
                            _buildPresetChip('-10', -10),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        _buildLabel('Reason', context),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Sale, Restock, Damage',
                            prefixIcon: Icon(Icons.notes_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),

                        // ── Item 12: Confirmation Preview ──
                        if (_quantityController.text.isNotEmpty) ...[
                          _buildConfirmationPreview(context),
                          const SizedBox(height: AppTheme.spacingMd),
                        ],

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _submitAdjustment,
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 22,
                              color: Colors.black,
                            ),
                            label: const Text(
                              'Confirm Adjustment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
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

  // ── Item 9: Preset Chip Builder ──
  Widget _buildPresetChip(String label, int value) {
    final isPositive = value > 0;
    final isDark = AppTheme.isDark(context);
    final borderCol = AppTheme.borderColor(context);
    final isActive = _quantityController.text == value.toString();

    return GestureDetector(
      onTap: () {
        setState(() {
          _quantityController.text = value.toString();
        });
      },
      child: AnimatedContainer(
        duration: AppTheme.quickAnim,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isPositive ? AppTheme.success : AppTheme.danger)
              : (isDark ? AppTheme.darkSurfaceVariant : AppTheme.surfaceVariant),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isActive ? Colors.black : borderCol,
            width: 2,
          ),
          boxShadow: isActive ? AppTheme.shadowSm : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.black : AppTheme.textColor(context),
          ),
        ),
      ),
    );
  }

  // ── Item 12: Confirmation Preview Card ──
  Widget _buildConfirmationPreview(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final borderCol = AppTheme.borderColor(context);
    final quantityChange = int.tryParse(_quantityController.text) ?? 0;
    final currentQty = _selectedProduct!['quantity'] ?? 0;
    final newQty = currentQty + quantityChange;
    final productName = _selectedProduct!['name'] ?? 'Unknown';
    final isPositive = quantityChange >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: isPositive
            ? (isDark ? const Color(0xFF1A3D2E) : AppTheme.successLight)
            : (isDark ? const Color(0xFF3D1F1F) : AppTheme.dangerLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderCol, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                size: 18,
                color: AppTheme.textColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                'PREVIEW',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor(context),
              ),
              children: [
                TextSpan(
                  text: isPositive ? 'Adding ' : 'Removing ',
                ),
                TextSpan(
                  text: '${isPositive ? '+' : ''}$quantityChange',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isPositive ? AppTheme.success : AppTheme.danger,
                  ),
                ),
                TextSpan(text: ' to '),
                TextSpan(
                  text: productName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$currentQty → $newQty units',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textColor(context),
            ),
          ),
          if (newQty < 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠ Warning: Stock will go below zero!',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required Widget child,
  }) {
    final textCol = AppTheme.textColor(context);

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.warning,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: textCol,
                  letterSpacing: 1.1,
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
    final borderCol = AppTheme.borderColor(context);

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
              color: AppTheme.surfaceVariantColor(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: borderCol, width: 2),
            ),
            child: Icon(icon, color: AppTheme.textColor(context), size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: AppTheme.textColor(context),
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
