import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants.dart';
import '../../../services/cart_service.dart';
import '../../../services/supabase_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId != null) {
        final items = await CartService.getCartItems(customerId);
        setState(() {
          _cartItems = items;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading cart: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _updateQuantity(String productId, double newQuantity) async {
    if (newQuantity <= 0) {
      _removeItem(productId);
      return;
    }

    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId != null) {
        await CartService.updateCartQuantity(
          customerId: customerId,
          productId: productId,
          quantity: newQuantity,
        );
        _loadCart();
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> _removeItem(String productId) async {
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId != null) {
        await CartService.removeFromCart(
          customerId: customerId,
          productId: productId,
        );
        _loadCart();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Item removed from cart')),
          );
        }
      }
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  Future<void> _proceedToCheckout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(cartItems: _cartItems),
      ),
    ).then((_) => _loadCart());
  }

  @override
  Widget build(BuildContext context) {
    final total = CartService.calculateCartTotal(_cartItems);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final customerId = SupabaseService.currentUserId;
                if (customerId != null) {
                  await CartService.clearCart(customerId);
                  _loadCart();
                }
              },
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🛒', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 12),
                      Text('Your cart is empty',
                          style: TextStyle(fontSize: 18)),
                      SizedBox(height: 4),
                      Text('Add products from the market',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return _buildCartItem(item);
                        },
                      ),
                    ),
                    _buildBottomBar(total),
                  ],
                ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>;
    final quantity = (item['quantity'] as num).toDouble();
    final pricePerUnit = (item['price_per_unit'] as num).toDouble();
    final unit = item['unit'] as String;
    final productName = product['name'] as String;
    final imageUrls = product['image_urls'] as List<dynamic>?;
    final imageUrl = imageUrls != null && imageUrls.isNotEmpty
        ? imageUrls.first as String
        : null;
    final farmer = product['users'] as Map<String, dynamic>?;
    final farmerName = farmer?['name'] ?? 'Farmer';

    final itemTotal = quantity * pricePerUnit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.background,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Center(
                          child: Text('🌱', style: TextStyle(fontSize: 32)),
                        ),
                      )
                    : const Center(
                        child: Text('🌱', style: TextStyle(fontSize: 32)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by $farmerName',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$pricePerUnit/$unit',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () => _updateQuantity(
                                  product['id'], quantity - 1),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                quantity.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () => _updateQuantity(
                                  product['id'], quantity + 1),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${itemTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _removeItem(product['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
