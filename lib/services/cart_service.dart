import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  static final _client = Supabase.instance.client;

  // Add item to cart
  static Future<void> addToCart({
    required String customerId,
    required String productId,
    required double quantity,
    required String unit,
    required double pricePerUnit,
  }) async {
    // Check if item already exists
    final existing = await _client
        .from('shopping_cart')
        .select('quantity')
        .eq('customer_id', customerId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      // Update existing item - add to quantity
      final currentQty = (existing['quantity'] as num).toDouble();
      await _client
          .from('shopping_cart')
          .update({
            'quantity': currentQty + quantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('customer_id', customerId)
          .eq('product_id', productId);
    } else {
      // Insert new item
      await _client.from('shopping_cart').insert({
        'customer_id': customerId,
        'product_id': productId,
        'quantity': quantity,
        'unit': unit,
        'price_per_unit': pricePerUnit,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Get cart items
  static Future<List<Map<String, dynamic>>> getCartItems(String customerId) async {
    final data = await _client
        .from('shopping_cart')
        .select('*, products(*, users(name, phone, rating))')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Update cart item quantity
  static Future<void> updateCartQuantity({
    required String customerId,
    required String productId,
    required double quantity,
  }) async {
    await _client
        .from('shopping_cart')
        .update({
          'quantity': quantity,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('customer_id', customerId)
        .eq('product_id', productId);
  }

  // Remove item from cart
  static Future<void> removeFromCart({
    required String customerId,
    required String productId,
  }) async {
    await _client
        .from('shopping_cart')
        .delete()
        .eq('customer_id', customerId)
        .eq('product_id', productId);
  }

  // Clear entire cart
  static Future<void> clearCart(String customerId) async {
    await _client.from('shopping_cart').delete().eq('customer_id', customerId);
  }

  // Get cart count
  static Future<int> getCartCount(String customerId) async {
    final data = await _client
        .from('shopping_cart')
        .select('id')
        .eq('customer_id', customerId);
    return data.length;
  }

  // Calculate cart total
  static double calculateCartTotal(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(0.0, (sum, item) {
      final quantity = (item['quantity'] as num).toDouble();
      final price = (item['price_per_unit'] as num).toDouble();
      return sum + (quantity * price);
    });
  }
}
