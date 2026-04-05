import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = "";

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
      appBar: AppBar(
        title: const Text('Inventory Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or SKU...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => productProvider.fetchProducts(),
        child: productProvider.isLoading && productProvider.products.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : filteredProducts.isEmpty
                ? const Center(child: Text('No matching products found.'))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final id = product['id'];
                      final quantity = product['quantity'] ?? 0;
                      final threshold = product['low_stock_threshold'] ?? 5;
                      final isLowStock = quantity <= threshold;

                      return ListTile(
                        title: Text(product['name'] ?? 'No Name'),
                        subtitle: Text('SKU: ${product['sku']} | Price: \$${product['price']}'),
                        leading: CircleAvatar(
                          backgroundColor: isLowStock ? Colors.orange.shade100 : Colors.blue.shade100,
                          foregroundColor: isLowStock ? Colors.orange : Colors.blue,
                          child: Text(quantity.toString()),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductFormScreen(product: product),
                                  ),
                                ).then((_) => productProvider.fetchProducts());
                              },
                            ),
                            if (isAdmin)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Product?'),
                                          content: const Text('Are you sure you want to delete this item?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      ) ??
                                      false;

                                  if (confirm) {
                                    await productProvider.deleteProduct(id, authProvider.role!);
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductFormScreen()),
                ).then((_) => Provider.of<ProductProvider>(context, listen: false).fetchProducts());
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
