import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class CustomerReviewsScreen extends StatefulWidget {
  const CustomerReviewsScreen({super.key});
  @override
  State<CustomerReviewsScreen> createState() => _CustomerReviewsScreenState();
}

class _CustomerReviewsScreenState extends State<CustomerReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  double _avgRating = 0.0;
  final Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    try {
      final farmerId = SupabaseService.currentUserId;
      if (farmerId == null) return;

      // Get reviews from database
      final client = Supabase.instance.client;
      final reviews = await client
          .from('reviews')
          .select('*, users!reviews_customer_id_fkey(name, profile_image)')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      // Calculate statistics
      if (reviews.isNotEmpty) {
        final totalRating =
            reviews.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
        _avgRating = totalRating / reviews.length;

        // Calculate rating distribution
        for (final review in reviews) {
          final rating = review['rating'] as int;
          _ratingDistribution[rating] = (_ratingDistribution[rating] ?? 0) + 1;
        }
      }

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(reviews);
        _loading = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: _reviews.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('⭐', style: TextStyle(fontSize: 64)),
                          SizedBox(height: 12),
                          Text(
                            'No reviews yet',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Complete orders to receive reviews',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rating Summary Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusL),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                // Average Rating
                                Column(
                                  children: [
                                    Text(
                                      _avgRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (index) => Icon(
                                          index < _avgRating.floor()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_reviews.length} reviews',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),

                                // Rating Distribution
                                Expanded(
                                  child: Column(
                                    children: [5, 4, 3, 2, 1].map((rating) {
                                      final count =
                                          _ratingDistribution[rating] ?? 0;
                                      final percentage = _reviews.isNotEmpty
                                          ? count / _reviews.length
                                          : 0.0;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Text(
                                              '$rating',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.star,
                                              size: 12,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: percentage,
                                                  minHeight: 6,
                                                  backgroundColor:
                                                      Colors.grey.shade200,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation(
                                                    Colors.amber,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$count',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Reviews List
                          const Text(
                            'All Reviews',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._reviews
                              .map((review) => _ReviewCard(review: review)),
                        ],
                      ),
                    ),
            ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] as int;
    final freshnessRating = review['freshness_rating'] as int?;
    final comment = review['comment'] as String?;
    final customerName = review['users']?['name'] as String? ?? 'Customer';
    final createdAt = DateTime.parse(review['created_at'] as String);
    final timeAgo = _getTimeAgo(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  customerName[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (freshnessRating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.eco,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Freshness: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < freshnessRating ? Icons.star : Icons.star_border,
                    color: AppColors.success,
                    size: 14,
                  ),
                ),
              ],
            ),
          ],
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
