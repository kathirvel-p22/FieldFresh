import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';
import '../../../services/cart_service.dart';
import '../order/cart_screen.dart';

class CustomerFeedScreen extends StatefulWidget {
  const CustomerFeedScreen({super.key});
  @override
  State<CustomerFeedScreen> createState() => _CustomerFeedScreenState();
}

class _CustomerFeedScreenState extends State<CustomerFeedScreen> {
  String _selectedCategory = 'all';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  int _cartCount = 0;

  // Demo location (Chennai - same as product defaults)
  final double _customerLat = 13.0827;
  final double _customerLng = 80.2707;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartCount();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final products = await SupabaseService.getNearbyProductsWithScore(
        customerLat: _customerLat,
        customerLng: _customerLng,
        radiusKm: 25,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final count = await CartService.getCartCount(user.id);
        if (mounted) {
          setState(() => _cartCount = count);
        }
      }
    } catch (e) {
      print('Error loading cart count: $e');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        // ─── Header ───
        SliverAppBar(
          expandedHeight: 150,
          floating: true,
          pinned: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.customerGradient),
              child: SafeArea(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.location_on,
                                        color: Colors.white70, size: 13),
                                    Text(' Chennai, TN',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12))
                                  ]),
                                  Text('Fresh Market 🌾',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                ]),
                            Row(
                              children: [
                                // Cart button
                                Stack(
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const CartScreen(),
                                          ),
                                        );
                                        // Reload cart count when returning
                                        if (result == true || result == null) {
                                          _loadCartCount();
                                        }
                                      },
                                      icon: const Icon(Icons.shopping_cart_outlined,
                                          color: Colors.white, size: 26),
                                    ),
                                    if (_cartCount > 0)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          child: Text(
                                            _cartCount > 9 ? '9+' : '$_cartCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                IconButton(
                                    onPressed: () =>
                                        context.go(AppRoutes.notifications),
                                    icon: const Icon(Icons.notifications_outlined,
                                        color: Colors.white, size: 26)),
                              ],
                            ),
                          ]),
                      const SizedBox(height: 8),
                      Container(
                          height: 44,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22)),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: const InputDecoration(
                                hintText: 'Search vegetables, fruits...',
                                prefixIcon: Icon(Icons.search,
                                    size: 20, color: AppColors.textHint),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 12)),
                          )),
                    ]),
              )),
            ),
          ),
        ),
        // ─── Category Chips ───
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              itemCount: ProductCategories.all.length + 1,
              itemBuilder: (_, i) {
                final isAll = i == 0;
                final cat = isAll
                    ? {'id': 'all', 'name': 'All', 'icon': '🌱'}
                    : ProductCategories.all[i - 1];
                final selected = _selectedCategory == cat['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat['id'] as String);
                    _loadProducts();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.grey.shade300)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(cat['icon'] as String,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(cat['name'] as String,
                          style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
        // ─── Product Grid ───
        _loading
            ? SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((_, i) => _ShimmerCard(),
                      childCount: 6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72),
                ))
            : _buildProductGrid(),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }

  Widget _buildProductGrid() {
    var products = _products;
    if (_searchQuery.isNotEmpty) {
      products = products
          .where((p) => (p['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (products.isEmpty) {
      return const SliverToBoxAdapter(
          child: SizedBox(
              height: 300,
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text('🌿', style: TextStyle(fontSize: 64)),
                    SizedBox(height: 12),
                    Text('No fresh produce nearby right now',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text('Check back soon!',
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ]))));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
            (_, i) => AdvancedProductCard(product: products[i]),
            childCount: products.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68),
      ),
    );
  }
}

class AdvancedProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  const AdvancedProductCard({super.key, required this.product});
  @override
  State<AdvancedProductCard> createState() => _AdvancedProductCardState();
}

class _AdvancedProductCardState extends State<AdvancedProductCard> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final validUntil = DateTime.parse(p['valid_until'] as String);
    final remaining = validUntil.difference(DateTime.now());
    final score = p['freshness_score'] as int;
    final distance = (p['distance_km'] as double).toStringAsFixed(1);
    final freshnessLabel = p['freshness_label'] as String;

    final scoreColor = SupabaseService.getFreshnessColor(score);
    final timerColor = remaining.isNegative
        ? AppColors.error
        : remaining.inHours < 2
            ? AppColors.error
            : remaining.inHours < 6
                ? AppColors.warning
                : AppColors.success;

    String timerText;
    if (remaining.isNegative) {
      timerText = 'Expired';
    } else if (remaining.inHours > 0)
      timerText = '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    else
      timerText = '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';

    final imageUrls = p['image_urls'] as List<dynamic>?;
    final farmerName = p['users']['name'] as String?;
    final farmerRating = (p['users']['rating'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () => context.go('/customer/product/${p['id']}', extra: p),
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusL)),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: imageUrls != null && imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrls.first as String,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _CategoryEmoji(
                            p['category_icon'] as String? ?? '🌱'))
                    : _CategoryEmoji(p['category_icon'] as String? ?? '🌱'),
              ),
            ),
            // Freshness badge top-left
            Positioned(
                top: 8,
                left: 8,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('$score',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(freshnessLabel,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 8)),
                      ],
                    ))),
            // Distance badge top-right
            Positioned(
                top: 8,
                right: 8,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text('$distance km',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600)),
                      ],
                    ))),
            // Farmer info gradient bottom
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65)
                        ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter)),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(farmerName ?? 'Farmer',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis)),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 11),
                                const SizedBox(width: 2),
                                Text(farmerRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10)),
                              ],
                            ),
                          ],
                        )))),
          ])),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              const SizedBox(height: 2),
              Text('₹${p['price_per_unit']}/${p['unit']}',
                  style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 5),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: timerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer, size: 10, color: timerColor),
                    const SizedBox(width: 3),
                    Text(timerText,
                        style: TextStyle(
                            fontSize: 9,
                            color: timerColor,
                            fontWeight: FontWeight.w600)),
                  ])),
              const SizedBox(height: 6),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.go('/customer/product/${p['id']}', extra: p),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    child: const Text('Order Now'),
                  )),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _CategoryEmoji extends StatelessWidget {
  final String emoji;
  const _CategoryEmoji(this.emoji);
  @override
  Widget build(BuildContext context) => Container(
      color: const Color(0xFFF0F7F0),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 52))));
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL))));
}
