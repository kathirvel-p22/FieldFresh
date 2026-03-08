class ProductModel {
  final String id, farmerId, name, category, unit, status;
  final String? farmerName, farmerImage, description, farmAddress;
  final double? farmerRating, latitude, longitude;
  final double pricePerUnit, quantityTotal, quantityLeft;
  final List<String> imageUrls;
  final DateTime harvestTime, validUntil, createdAt;
  final int freshnessScore, orderCount;

  ProductModel(
      {required this.id,
      required this.farmerId,
      this.farmerName,
      this.farmerImage,
      this.farmerRating,
      required this.name,
      required this.category,
      this.description,
      required this.pricePerUnit,
      required this.unit,
      required this.quantityTotal,
      required this.quantityLeft,
      required this.imageUrls,
      required this.harvestTime,
      required this.validUntil,
      this.freshnessScore = 85,
      this.latitude,
      this.longitude,
      this.farmAddress,
      this.status = 'active',
      this.orderCount = 0,
      required this.createdAt});

  bool get isActive =>
      status == 'active' &&
      validUntil.isAfter(DateTime.now()) &&
      quantityLeft > 0;
  bool get isExpired => validUntil.isBefore(DateTime.now());
  bool get isSoldOut => quantityLeft <= 0;
  Duration get timeRemaining => validUntil.difference(DateTime.now());
  bool get isUrgent => timeRemaining.inHours < 2 && !timeRemaining.isNegative;

  String get categoryIcon {
    const icons = {
      'vegetables': '🥦',
      'leafy': '🥬',
      'fruits': '🍎',
      'dairy': '🥛',
      'grains': '🌾',
      'herbs': '🌿',
      'roots': '🥕',
      'flowers': '🌸'
    };
    return icons[category] ?? '🌱';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
      id: json['id'] ?? '',
      farmerId: json['farmer_id'] ?? '',
      farmerName: json['users']?['name'] ?? json['farmer_name'],
      farmerImage: json['users']?['profile_image'],
      farmerRating: (json['users']?['rating'] as num?)?.toDouble() ??
          (json['farmer_rating'] as num?)?.toDouble(),
      name: json['name'] ?? '',
      category: json['category'] ?? 'vegetables',
      description: json['description'],
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] ?? 'kg',
      quantityTotal: (json['quantity_total'] as num?)?.toDouble() ?? 0,
      quantityLeft: (json['quantity_left'] as num?)?.toDouble() ?? 0,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      harvestTime:
          DateTime.tryParse(json['harvest_time'] ?? '') ?? DateTime.now(),
      validUntil: DateTime.tryParse(json['valid_until'] ?? '') ??
          DateTime.now().add(const Duration(hours: 12)),
      freshnessScore: json['freshness_score'] ?? 85,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      farmAddress: json['farm_address'],
      status: json['status'] ?? 'active',
      orderCount: json['order_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now());

  Map<String, dynamic> toJson() {
    final map = {
      'farmer_id': farmerId,
      'name': name,
      'category': category,
      'description': description,
      'price_per_unit': pricePerUnit,
      'unit': unit,
      'quantity_total': quantityTotal,
      'quantity_left': quantityLeft,
      'image_urls': imageUrls,
      'harvest_time': harvestTime.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'freshness_score': freshnessScore,
      'status': status
    };

    // Only add latitude/longitude if they're not null
    // This allows database defaults to be used
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;

    return map;
  }
  // Note: farm_address removed temporarily - add it back after updating database schema
}
