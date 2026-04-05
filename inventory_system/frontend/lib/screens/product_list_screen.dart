import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = "";
  final Set<int> _loadingIds = {};

  void _quickAdjustQuantity(
    Map<String, dynamic> product,
    int change,
    ProductProvider provider,
    AuthProvider auth,
  ) async {
    final id = product['id'];
    final currentQty = product['quantity'] ?? 0;

    if (currentQty + change < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot reduce stock below zero'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _loadingIds.add(id));
    try {
      await provider.quickAdjustStock(
        productId: id,
        quantityChange: change,
        userId: auth.userId!,
        role: auth.role!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to adjust stock: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingIds.remove(id));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';
    final productProvider = Provider.of<ProductProvider>(context);

    final filteredProducts = productProvider.products.where((p) {
      final query = _searchQuery.toLowerCase();
      final name = (p['name'] ?? '').toString().toLowerCase();
      final sku = (p['sku'] ?? '').toString().toLowerCase();
      return name.contains(query) || sku.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${filteredProducts.length} items in inventory',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  _buildHeaderIconButton(
                    icon: Icons.file_download_outlined,
                    tooltip: 'Export CSV',
                    onTap: () => ExportService.exportProductsToCSV(
                      productProvider.products,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductFormScreen(),
                        ),
                      );
                      if (!context.mounted) return;
                      Provider.of<ProductProvider>(
                        context,
                        listen: false,
                      ).fetchProducts();
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add Product'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Search Bar ──
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.softShadow,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or SKU...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Product List ──
            Expanded(
              child:
                  productProvider.isLoading && productProvider.products.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'No products found',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => productProvider.fetchProducts(),
                      child: ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductCard(
                            product,
                            isAdmin,
                            productProvider,
                            authProvider,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    bool isAdmin,
    ProductProvider productProvider,
    AuthProvider authProvider,
  ) {
    final id = product['id'];
    final quantity = product['quantity'] ?? 0;
    final threshold = product['low_stock_threshold'] ?? 5;
    final isLowStock = quantity <= threshold;
    final price = double.tryParse(product['price'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: isLowStock
            ? Border.all(color: AppTheme.danger.withAlpha(40))
            : null,
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            // ── Quantity Badge ──
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isLowStock
                    ? AppTheme.dangerLight
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    quantity.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: isLowStock ? AppTheme.danger : AppTheme.primary,
                    ),
                  ),
                  Text(
                    'qty',
                    style: TextStyle(
                      fontSize: 10,
                      color: isLowStock
                          ? AppTheme.danger.withAlpha(150)
                          : AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),

            // ── Quick Adjust Buttons ──
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuickIconButton(
                  icon: Icons.add_rounded,
                  color: AppTheme.success,
                  onTap: _loadingIds.contains(id)
                      ? null
                      : () => _quickAdjustQuantity(
                          product,
                          1,
                          productProvider,
                          authProvider,
                        ),
                ),
                const SizedBox(height: 4),
                _buildQuickIconButton(
                  icon: Icons.remove_rounded,
                  color: AppTheme.danger,
                  onTap: _loadingIds.contains(id)
                      ? null
                      : () => _quickAdjustQuantity(
                          product,
                          -1,
                          productProvider,
                          authProvider,
                        ),
                ),
              ],
            ),
            const SizedBox(width: AppTheme.spacingMd),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoChip('SKU: ${product['sku']}'),
                      const SizedBox(width: AppTheme.spacingSm),
                      _buildInfoChip(
                        '${AppTheme.currencySymbol}${NumberFormat('#,###.##').format(price)}',
                      ),
                      if (isLowStock) ...[
                        const SizedBox(width: AppTheme.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerLight,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: const Text(
                            'Low Stock',
                            style: TextStyle(
                              color: AppTheme.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Actions ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  color: AppTheme.primary,
                  tooltip: 'Edit',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductFormScreen(product: product),
                      ),
                    ).then((_) => productProvider.fetchProducts());
                  },
                ),
                if (isAdmin) ...[
                  const SizedBox(width: AppTheme.spacingSm),
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: AppTheme.danger,
                    tooltip: 'Delete',
                    onTap: () async {
                      final confirm =
                          await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Product?'),
                              content: const Text(
                                'Are you sure you want to delete this item?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.danger,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (confirm) {
                        await productProvider.deleteProduct(
                          id,
                          authProvider.role!,
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Center(
            child: Icon(
              icon,
              color: onTap == null ? color.withAlpha(100) : color,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
