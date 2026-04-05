import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _skuController.text = widget.product!['sku']?.toString() ?? '';
      _nameController.text = widget.product!['name']?.toString() ?? '';
      _quantityController.text = widget.product!['quantity']?.toString() ?? '0';
      _priceController.text = widget.product!['price']?.toString() ?? '0.00';
      _barcodeController.text = widget.product!['barcode']?.toString() ?? '';
    } else {
      _quantityController.text = '0';
      _priceController.text = '0.00';
    }
  }

  bool _isLoading = false;

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final productData = {
      'sku': _skuController.text.trim(),
      'name': _nameController.text.trim(),
      'quantity': int.parse(_quantityController.text),
      'price': double.parse(_priceController.text),
      'barcode': _barcodeController.text.trim(),
      'low_stock_threshold': 5, // Default
    };

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    try {
      if (isEdit) {
        await productProvider.updateProduct(
            widget.product!['id'], productData, authProvider.role!);
      } else {
        await productProvider.addProduct(productData, authProvider.role!);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Product updated successfully!'
                : 'Product added successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $errorMessage'),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {}),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateSku() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomSuffix = timestamp.substring(timestamp.length - 4);
    final generatedSku = 'SKU-${DateTime.now().year}$randomSuffix';
    setState(() {
      _skuController.text = generatedSku;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.softShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_rounded
                                : Icons.add_business_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit
                                    ? 'Edit Product Details'
                                    : 'New Product',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit
                                    ? 'Update the information below'
                                    : 'Fill in the product information',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    const Divider(),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── SKU ──
                    _buildLabel('SKU'),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextFormField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        hintText: 'e.g. SKU-001',
                        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                        suffixIcon: isEdit
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.auto_awesome_rounded,
                                    size: 20, color: AppTheme.primary),
                                tooltip: 'Generate SKU',
                                onPressed: _generateSku,
                              ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter SKU' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // ── Product Name ──
                    _buildLabel('Product Name'),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Wireless Mouse',
                        prefixIcon:
                            Icon(Icons.inventory_2_outlined, size: 20),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter Name' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // ── Quantity & Price Row ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Quantity'),
                              const SizedBox(height: AppTheme.spacingSm),
                              TextFormField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  prefixIcon:
                                      Icon(Icons.numbers_rounded, size: 20),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Enter Qty';
                                  final n = int.tryParse(v);
                                  if (n == null || n < 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Price (\$)'),
                              const SizedBox(height: AppTheme.spacingSm),
                              TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  prefixIcon: Icon(
                                      Icons.attach_money_rounded,
                                      size: 20),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) {
                                  if (v!.isEmpty) return 'Enter Price';
                                  final n = double.tryParse(v);
                                  if (n == null || n <= 0) return 'Price > 0';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // ── Barcode ──
                    _buildLabel('Barcode'),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1234567890',
                        prefixIcon: Icon(Icons.qr_code_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // ── Submit Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveForm,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdit ? 'Update Product' : 'Save Product',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    _skuController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }
}
