import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/constants.dart';
import '../../../models/product_model.dart';
import '../../../services/supabase_service.dart';
import '../../../services/cart_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final dynamic product;
  const ProductDetailScreen({super.key, required this.productId, this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  int _qty = 1;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.product is ProductModel) {
      _product = widget.product as ProductModel;
      _loading = false;
    } else {
      _fetchProduct();
    }
    _startTimer();
  }

  Future<void> _fetchProduct() async {
    try {
      final productData = await SupabaseService.getProductWithFarmerDetails(widget.productId);
      if (productData != null) {
        final p = ProductModel.fromJson(productData);
        setState(() { _product = p; _loading = false; });
      } else {
        // Fallback to nearby products
        final products = await SupabaseService.getNearbyProducts(lat: 0, lng: 0);
        final p = products.firstWhere((p) => p.id == widget.productId, orElse: () => products.first);
        setState(() { _product = p; _loading = false; });
      }
    } catch (e) { 
      print('Error fetching product: $e');
      setState(() => _loading = false); 
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_product == null) return const Scaffold(body: Center(child: Text('Product not found')));
    final p = _product!;
    final remaining = p.validUntil.difference(DateTime.now());
    final score = p.freshnessScore;
    final scoreColor = score >= 75 ? AppColors.freshHigh : score >= 50 ? AppColors.freshMedium : AppColors.freshLow;
    final timerColor = remaining.isNegative ? AppColors.error : remaining.inHours < 2 ? AppColors.error : AppColors.warning;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 300, pinned: true,
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: p.imageUrls.isNotEmpty
                ? CachedNetworkImage(imageUrl: p.imageUrls.first, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: Colors.grey.shade100,
                        child: Center(child: Text(p.categoryIcon, style: const TextStyle(fontSize: 80)))))
                : Container(color: Colors.grey.shade100,
                    child: Center(child: Text(p.categoryIcon, style: const TextStyle(fontSize: 80)))),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${p.pricePerUnit}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  Text('per ${p.unit}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE8F5E9), child: Text('👨‍🌾', style: TextStyle(fontSize: 14))),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.farmerName ?? 'Local Farmer', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    Text(' ${p.farmerRating?.toStringAsFixed(1) ?? '4.5'} • Verified Farmer',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ])),
                Text('🕐 ${_formatAgo(p.harvestTime)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 14),
              // Freshness Score
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: scoreColor.withOpacity(0.07), borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    border: Border.all(color: scoreColor.withOpacity(0.3))),
                child: Row(children: [
                  CircularPercentIndicator(
                    radius: 38, lineWidth: 8, percent: score / 100,
                    center: Text('$score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scoreColor)),
                    progressColor: scoreColor, backgroundColor: scoreColor.withOpacity(0.15),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Freshness Score', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scoreColor)),
                    Text(score >= 85 ? 'Ultra Fresh 🌟 — Just Harvested!' : score >= 70 ? 'Very Fresh ✅' : score >= 55 ? 'Fresh 🟡' : 'Good 🟠',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(p.farmAddress ?? 'Nearby Farm', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ])),
                ]),
              ),
              const SizedBox(height: 10),
              // Countdown Timer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: timerColor.withOpacity(0.08), borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    border: Border.all(color: timerColor.withOpacity(0.4))),
                child: Row(children: [
                  Icon(Icons.timer, color: timerColor, size: 28),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Listing expires in', style: TextStyle(fontSize: 12, color: timerColor.withOpacity(0.8))),
                    Text(
                      remaining.isNegative ? '⛔ EXPIRED' :
                        '${remaining.inHours.toString().padLeft(2,'0')}:${(remaining.inMinutes % 60).toString().padLeft(2,'0')}:${(remaining.inSeconds % 60).toString().padLeft(2,'0')}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: timerColor, fontFeatures: const []),
                    ),
                  ]),
                  const Spacer(),
                  if (remaining.inHours < 2 && !remaining.isNegative)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(6)),
                        child: const Text('⚡ URGENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.inventory_2, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('${p.quantityLeft} ${p.unit} available', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('${p.categoryIcon} ${p.category}', style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600))),
              ]),
              if (p.description != null && p.description!.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('About this product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 6),
                Text(p.description!, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
              ],
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(color: AppColors.surface,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))]),
        child: Row(children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.primary.withOpacity(0.4)), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.remove, size: 18), color: AppColors.primary,
                  onPressed: () { if (_qty > 1) setState(() => _qty--); }),
              SizedBox(width: 28, child: Text('$_qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary))),
              IconButton(icon: const Icon(Icons.add, size: 18), color: AppColors.primary,
                  onPressed: () { if (_qty < p.quantityLeft) setState(() => _qty++); }),
            ]),
          ),
          const SizedBox(width: 8),
          // Add to Cart button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: p.isActive ? () => _handleAddToCart(context, p) : null,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: const Text('Add to Cart'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Order Now button
          Expanded(
            child: ElevatedButton(
              onPressed: p.isActive ? () => _handleOrderNow(context, p) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM))),
              child: Text(p.isActive ? '₹${(p.pricePerUnit * _qty).toStringAsFixed(0)}' : 'Unavailable',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  String _formatAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  Future<void> _handleAddToCart(BuildContext context, ProductModel p) async {
    // Get current user ID (works with demo mode)
    final userId = SupabaseService.currentUserId;
    
    // Debug: Print user ID
    print('DEBUG: Current User ID: $userId');
    
    if (userId == null) {
      print('DEBUG: User ID is null - showing login message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please login first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    print('DEBUG: Adding to cart for user: $userId, product: ${p.id}');

    // Show loading
    bool dialogShown = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogShown = true;

      // Add to cart
      await CartService.addToCart(
        customerId: userId,
        productId: p.id,
        quantity: _qty.toDouble(),
        unit: p.unit,
        pricePerUnit: p.pricePerUnit,
      );

      print('DEBUG: Successfully added to cart');

      // Close loading
      if (context.mounted && dialogShown) {
        Navigator.pop(context);
        dialogShown = false;
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Added $_qty ${p.unit} of ${p.name} to cart'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error adding to cart: $e');
      
      // Close loading if still showing
      if (context.mounted && dialogShown) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleOrderNow(BuildContext context, ProductModel p) async {
    // Get current user ID (works with demo mode)
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please login first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Show loading
    bool dialogShown = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogShown = true;

      // Add to cart
      await CartService.addToCart(
        customerId: userId,
        productId: p.id,
        quantity: _qty.toDouble(),
        unit: p.unit,
        pricePerUnit: p.pricePerUnit,
      );

      // Close loading
      if (context.mounted && dialogShown) {
        Navigator.pop(context);
        dialogShown = false;
      }

      // Navigate to cart screen (customer home will show cart tab)
      if (context.mounted) {
        context.go(AppRoutes.customerHome);
        
        // Show message after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Item added! Go to Cart tab to checkout'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } catch (e) {
      // Close loading if still showing
      if (context.mounted && dialogShown) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
