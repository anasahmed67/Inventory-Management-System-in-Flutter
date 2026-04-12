import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = "";
  String _activeFilter = 'All';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot reduce stock below zero'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
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

    // Apply search + filter
    var filteredProducts = productProvider.products.where((p) {
      final query = _searchQuery.toLowerCase();
      final name = (p['name'] ?? '').toString().toLowerCase();
      final sku = (p['sku'] ?? '').toString().toLowerCase();
      return name.contains(query) || sku.contains(query);
    }).toList();

    // ── Item 6: Apply filter chips ──
    if (_activeFilter == 'Low Stock') {
      filteredProducts = filteredProducts.where((p) {
        final qty = p['quantity'] ?? 0;
        final threshold = p['low_stock_threshold'] ?? 5;
        return qty <= threshold && qty > 0;
      }).toList();
    } else if (_activeFilter == 'In Stock') {
      filteredProducts = filteredProducts.where((p) {
        final qty = p['quantity'] ?? 0;
        final threshold = p['low_stock_threshold'] ?? 5;
        return qty > threshold;
      }).toList();
    } else if (_activeFilter == 'Out of Stock') {
      filteredProducts = filteredProducts.where((p) {
        final qty = p['quantity'] ?? 0;
        return qty == 0;
      }).toList();
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      floatingActionButton: isMobile && isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductFormScreen(),
                  ),
                );
                if (!context.mounted) return;
                productProvider.fetchProducts();
              },
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      body: Padding(
        padding: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900, fontSize: isMobile ? 24 : 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${filteredProducts.length} items in inventory',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderIconButton(
                      icon: Icons.file_download_outlined,
                      tooltip: 'Export CSV',
                      onTap: () => ExportService.exportProductsToCSV(
                        productProvider.products,
                      ),
                    ),
                    if (isAdmin && !isMobile) ...[
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
                          productProvider.fetchProducts();
                        },
                        icon: const Icon(Icons.add_rounded, size: 20, color: Colors.black),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                        ),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Search Bar ──
            Container(
              decoration: BoxDecoration(
                boxShadow: AppTheme.adaptiveSoftShadow(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or SKU...',
                  prefixIcon: Icon(Icons.search_rounded, size: 22),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Item 6: Filter Chips ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'In Stock', 'Low Stock', 'Out of Stock']
                    .map((filter) => Padding(
                          padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                          child: _buildFilterChip(filter),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Product List ──
            Expanded(
              child: productProvider.isLoading && productProvider.products.isEmpty
                  // ── Item 7: Skeleton Loading ──
                  ? ListView.builder(
                      itemCount: 5,
                      itemBuilder: (_, _) => const ProductCardSkeleton(),
                    )
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: AppTheme.hintColor(context),
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Text(
                                'No products found',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppTheme.hintColor(context)),
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

  // ── Item 6: Filter Chip Builder ──
  Widget _buildFilterChip(String label) {
    final isActive = _activeFilter == label;
    final isDark = AppTheme.isDark(context);
    final borderCol = AppTheme.borderColor(context);

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: AnimatedContainer(
        duration: AppTheme.quickAnim,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isActive ? (isDark ? AppTheme.primary : Colors.black) : borderCol,
            width: 2,
          ),
          boxShadow: isActive ? AppTheme.shadowSm : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.black : AppTheme.textColor(context),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ── Item 1: Product Card with NeoCard press effect ──
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
    final name = product['name'] ?? 'No Name';
    final sku = product['sku'] ?? 'NO-SKU';
    final isLoading = _loadingIds.contains(id);
    final borderCol = AppTheme.borderColor(context);
    final textCol = AppTheme.textColor(context);
    final isDark = AppTheme.isDark(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;

        return _NeoProductCard(
          borderCol: borderCol,
          isDark: isDark,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isLowStock ? AppTheme.danger : AppTheme.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: borderCol, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            quantity.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                          ),
                          const Text('QTY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 8, color: Colors.black)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: textCol),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isNarrow)
                                _buildActionPopup(product, productProvider, authProvider, isAdmin, id),
                            ],
                          ),
                          Text(
                            'SKU: $sku',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.hintColor(context), fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildInfoChip('${AppTheme.currencySymbol}${NumberFormat('#,###.##').format(price)}'),
                              if (isLowStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF3D1F1F) : AppTheme.dangerLight,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                    border: Border.all(color: borderCol, width: 1),
                                  ),
                                  child: const Text(
                                    'LOW STOCK',
                                    style: TextStyle(color: AppTheme.danger, fontSize: 9, fontWeight: FontWeight.w900),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isNarrow) ...[
                      const SizedBox(width: AppTheme.spacingMd),
                      _buildActionButtons(product, productProvider, authProvider, isAdmin, id),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderCol, width: 1.5)),
                  color: AppTheme.surfaceVariantColor(context),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QUICK STOCK ADJUST',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5, color: textCol),
                    ),
                    Row(
                      children: [
                        _buildQuickIconButton(
                          icon: Icons.remove_rounded,
                          color: AppTheme.warning,
                          onTap: isLoading ? null : () => _quickAdjustQuantity(product, -1, productProvider, authProvider),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickIconButton(
                          icon: Icons.add_rounded,
                          color: AppTheme.success,
                          onTap: isLoading ? null : () => _quickAdjustQuantity(product, 1, productProvider, authProvider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> product, ProductProvider provider, AuthProvider authProvider, bool isAdmin, int id) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          color: AppTheme.primary,
          tooltip: 'Edit',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProductFormScreen(product: product)),
            ).then((_) => provider.fetchProducts());
          },
        ),
        if (isAdmin) ...[
          const SizedBox(width: AppTheme.spacingSm),
          _buildActionButton(
            icon: Icons.delete_outline_rounded,
            color: AppTheme.danger,
            tooltip: 'Delete',
            onTap: () => _handleDelete(product, provider, authProvider, id),
          ),
        ],
      ],
    );
  }

  Widget _buildActionPopup(Map<String, dynamic> product, ProductProvider provider, AuthProvider authProvider, bool isAdmin, int id) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: (val) {
        if (val == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductFormScreen(product: product)),
          ).then((_) => provider.fetchProducts());
        } else if (val == 'delete') {
          _handleDelete(product, provider, authProvider, id);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('EDIT')),
        if (isAdmin) const PopupMenuItem(value: 'delete', child: Text('DELETE')),
      ],
      icon: Icon(Icons.more_vert_rounded, color: AppTheme.textColor(context)),
    );
  }

  Future<void> _handleDelete(Map<String, dynamic> product, ProductProvider provider, AuthProvider authProvider, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE PRODUCT?', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16)),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;
    if (confirm) {
      try {
        await provider.deleteProduct(id, authProvider.role!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PRODUCT DELETED SUCCESSFULLY'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('DELETE FAILED: $errorMsg'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  Widget _buildInfoChip(String text) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.infoLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor(context), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.w800,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderColor(context), width: 1.5),
            ),
            child: Icon(icon, color: Colors.black, size: 20),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.info,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderColor(context), width: 2),
              boxShadow: AppTheme.adaptiveSoftShadow(context),
            ),
            child: Icon(icon, color: Colors.black, size: 24),
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.borderColor(context), width: 1.5),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Product card with neo-brutalist styling (no hover animation)
class _NeoProductCard extends StatelessWidget {
  final Widget child;
  final Color borderCol;
  final bool isDark;

  const _NeoProductCard({
    required this.child,
    required this.borderCol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderCol, width: AppTheme.borderWidth),
        boxShadow: AppTheme.adaptiveShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd - 1),
        child: child,
      ),
    );
  }
}

