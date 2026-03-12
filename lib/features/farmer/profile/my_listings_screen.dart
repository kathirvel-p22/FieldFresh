import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants.dart';
import '../../../models/product_model.dart';
import '../../../services/supabase_service.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});
  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<ProductModel> _products = [];
  bool _loading = true;
  String _filter = 'all'; // all, active, expired, sold_out

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    print('DEBUG: Loading products...');
    setState(() => _loading = true);
    try {
      final farmerId = SupabaseService.currentUserId;
      if (farmerId == null) {
        print('DEBUG: No farmer ID found');
        setState(() => _loading = false);
        return;
      }

      // Force a fresh query by adding a timestamp parameter
      final products = await SupabaseService.getFarmerProducts(farmerId);
      print('DEBUG: Loaded ${products.length} products from service');
      
      if (mounted) {
        setState(() {
          _products = products;
          _loading = false;
        });
        print('DEBUG: UI updated with ${_products.length} products');
        
        // Print product names for verification
        for (final product in _products) {
          print('DEBUG: Product in list: ${product.name} (ID: ${product.id})');
        }
      }
    } catch (e) {
      print('Error loading products: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<ProductModel> get _filteredProducts {
    switch (_filter) {
      case 'active':
        return _products.where((p) => p.isActive).toList();
      case 'expired':
        return _products.where((p) => p.isExpired).toList();
      case 'sold_out':
        return _products.where((p) => p.isSoldOut).toList();
      default:
        return _products;
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('DEBUG: Starting deletion process for product: $productId');
        
        // Find the product to delete
        final productToDelete = _products.firstWhere(
          (product) => product.id == productId,
          orElse: () => throw Exception('Product not found in local list'),
        );
        
        print('DEBUG: Found product to delete: ${productToDelete.name}');
        
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Text('Deleting product...'),
                ],
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Actually delete the product from database
        await SupabaseService.deleteProduct(productId);
        
        print('DEBUG: Product deleted from database successfully');
        
        // FORCE UI UPDATE: Remove from local list immediately
        if (mounted) {
          setState(() {
            _products.removeWhere((product) => product.id == productId);
            print('DEBUG: Removed product from local list. New count: ${_products.length}');
          });
        }
        
        // Wait a moment, then force refresh from database
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (mounted) {
          print('DEBUG: Force refreshing from database...');
          
          // Clear the list first to force a complete refresh
          setState(() {
            _products.clear();
            _loading = true;
          });
          
          // Load fresh data from database
          await _loadProducts();
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('ERROR: Failed to delete product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting product: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              print('DEBUG: Manual refresh triggered');
              setState(() {
                _products.clear();
                _loading = true;
              });
              await _loadProducts();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                _FilterChip('All', 'all', _products.length),
                const SizedBox(width: 8),
                _FilterChip('Active', 'active',
                    _products.where((p) => p.isActive).length),
                const SizedBox(width: 8),
                _FilterChip('Expired', 'expired',
                    _products.where((p) => p.isExpired).length),
                const SizedBox(width: 8),
                _FilterChip('Sold Out', 'sold_out',
                    _products.where((p) => p.isSoldOut).length),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📦', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 12),
                            Text(
                              _filter == 'all'
                                  ? 'No products yet'
                                  : 'No $_filter products',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Post your harvest to get started',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          print('DEBUG: Pull-to-refresh triggered');
                          await _loadProducts();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _ProductCard(
                              product: product,
                              onDelete: () => _deleteProduct(product.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _FilterChip(String label, String value, int count) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.secondary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onDelete;
  const _ProductCard({required this.product, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = product.isActive
        ? AppColors.success
        : product.isExpired
            ? AppColors.error
            : AppColors.warning;

    final statusText = product.isActive
        ? 'Active'
        : product.isExpired
            ? 'Expired'
            : 'Sold Out';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusL),
                  bottomLeft: Radius.circular(AppSizes.radiusL),
                ),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: product.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrls.first,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF0F7F0),
                            child: Center(
                              child: Text(
                                product.categoryIcon,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0F7F0),
                          child: Center(
                            child: Text(
                              product.categoryIcon,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                ),
              ),

              // Product Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${product.pricePerUnit}/${product.unit}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.quantityLeft}/${product.quantityTotal} ${product.unit}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.isExpired
                                ? 'Expired'
                                : '${product.timeRemaining.inHours}h left',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSizes.radiusL),
                bottomRight: Radius.circular(AppSizes.radiusL),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // Edit product
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Edit feature coming soon')),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
