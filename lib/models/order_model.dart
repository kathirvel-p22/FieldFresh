class OrderModel {
  final String id, customerId, farmerId, productId, deliveryType, status, paymentStatus;
  final String? customerName, customerPhone, productName, productImage, deliveryAddress, paymentId, razorpayOrderId, trackingNote;
  final double quantity, pricePerUnit, totalAmount, platformFee, deliveryCharge;
  final double? deliveryLat, deliveryLng;
  final String unit;
  final DateTime createdAt;
  final DateTime? confirmedAt, deliveredAt;

  OrderModel({required this.id, required this.customerId, this.customerName, this.customerPhone,
    required this.farmerId, required this.productId, this.productName, this.productImage,
    required this.quantity, required this.unit, required this.pricePerUnit,
    required this.totalAmount, this.platformFee = 0, this.deliveryCharge = 0,
    required this.deliveryType, this.deliveryAddress, this.status = 'pending',
    this.paymentStatus = 'pending', this.paymentId, this.razorpayOrderId, this.trackingNote,
    this.deliveryLat, this.deliveryLng, required this.createdAt, this.confirmedAt, this.deliveredAt});

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'] ?? '', customerId: json['customer_id'] ?? '',
    customerName: json['customer_name'], customerPhone: json['customer_phone'],
    farmerId: json['farmer_id'] ?? '', productId: json['product_id'] ?? '',
    productName: json['product_name'] ?? json['products']?['name'],
    productImage: json['product_image'] ?? (json['products']?['image_urls'] as List?)?.isNotEmpty == true ? (json['products']['image_urls'] as List).first : null,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    unit: json['unit'] ?? 'kg', pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0,
    totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
    deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0,
    deliveryType: json['delivery_type'] ?? 'delivery', deliveryAddress: json['delivery_address'],
    status: json['status'] ?? 'pending', paymentStatus: json['payment_status'] ?? 'pending',
    paymentId: json['payment_id'], razorpayOrderId: json['razorpay_order_id'],
    trackingNote: json['tracking_note'],
    deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
    deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    confirmedAt: json['confirmed_at'] != null ? DateTime.tryParse(json['confirmed_at']) : null,
    deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at']) : null);

  Map<String, dynamic> toJson() => {
    'customer_id': customerId, 'farmer_id': farmerId, 'product_id': productId,
    'product_name': productName, 'quantity': quantity, 'unit': unit,
    'price_per_unit': pricePerUnit, 'total_amount': totalAmount,
    'platform_fee': platformFee, 'delivery_charge': deliveryCharge,
    'delivery_type': deliveryType, 'delivery_address': deliveryAddress,
    'status': status, 'payment_status': paymentStatus};

  int get statusStep {
    switch (status) {
      case 'pending': return 0;
      case 'confirmed': return 1;
      case 'packed': return 2;
      case 'dispatched': return 3;
      case 'delivered': return 4;
      default: return 0;
    }
  }
}
