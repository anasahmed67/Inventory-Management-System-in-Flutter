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
      'low_stock_threshold': 5,
    };

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    try {
      if (isEdit) {
        await productProvider.updateProduct(
          widget.product!['id'],
          productData,
          authProvider.role!,
        );
      } else {
        await productProvider.addProduct(productData, authProvider.role!);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Product updated successfully!' : 'Product added successfully!'),
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
    final isNarrow = MediaQuery.of(context).size.width < 450;
    final borderCol = AppTheme.borderColor(context);
    final textCol = AppTheme.textColor(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: Text(isEdit ? 'EDIT PRODUCT' : 'ADD NEW PRODUCT', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: borderCol, width: AppTheme.borderWidth),
                boxShadow: AppTheme.adaptiveShadow(context),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: borderCol, width: 2),
                          ),
                          child: Icon(isEdit ? Icons.edit_rounded : Icons.add_business_rounded, color: Colors.black, size: 24),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEdit ? 'PRODUCT DETAILS' : 'NEW PRODUCT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: textCol)),
                              Text(isEdit ? 'Update info below' : 'Fill details below', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.secondaryTextColor(context), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Divider(color: borderCol, thickness: 1.5),
                    const SizedBox(height: AppTheme.spacingLg),

                    // SKU
                    _buildLabel('SKU CODE'),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextFormField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        hintText: 'e.g. SKU-001',
                        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                        suffixIcon: isEdit ? null : IconButton(
                          onPressed: _generateSku,
                          icon: Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: AppTheme.textColor(context),
                          ),
                          tooltip: 'Auto-generate SKU',
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter SKU' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Product Name
                    _buildLabel('PRODUCT NAME'),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Wireless Mouse',
                        prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter Name' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Quantity & Price
                    if (isNarrow) ...[
                      _buildLabel('QUANTITY'),
                      const SizedBox(height: AppTheme.spacingSm),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.numbers_rounded, size: 20)),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Enter Qty' : null,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildLabel('UNIT PRICE'),
                      const SizedBox(height: AppTheme.spacingSm),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.payments_outlined, size: 20)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Enter Price' : null,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('QUANTITY'),
                                const SizedBox(height: AppTheme.spacingSm),
                                TextFormField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(prefixIcon: Icon(Icons.numbers_rounded, size: 20)),
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v!.isEmpty ? 'Enter Qty' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('UNIT PRICE'),
                                const SizedBox(height: AppTheme.spacingSm),
                                TextFormField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(prefixIcon: Icon(Icons.payments_outlined, size: 20)),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) => v!.isEmpty ? 'Enter Price' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Barcode
                    _buildLabel('BARCODE (OPTIONAL)'),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1234567890',
                        prefixIcon: Icon(Icons.qr_code_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveForm,
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                            : Text(isEdit ? 'UPDATE PRODUCT' : 'SAVE PRODUCT', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
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
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 13,
        color: AppTheme.textColor(context),
        letterSpacing: 0.5,
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
