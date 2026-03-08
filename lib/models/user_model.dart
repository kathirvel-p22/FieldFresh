class UserModel {
  final String id;
  final String phone;
  final String? name;
  final String role;
  final String? profileImage;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int radiusKm;
  final String language;
  final String? fcmToken;
  final bool isVerified;
  final bool isKycDone;
  final DateTime createdAt;

  UserModel({required this.id, required this.phone, this.name, required this.role,
    this.profileImage, this.latitude, this.longitude, this.address, this.radiusKm = 25,
    this.language = 'en', this.fcmToken, this.isVerified = false, this.isKycDone = false,
    required this.createdAt});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '', phone: json['phone'] ?? '', name: json['name'],
    role: json['role'] ?? 'customer', profileImage: json['profile_image'],
    latitude: (json['latitude'] as num?)?.toDouble(), longitude: (json['longitude'] as num?)?.toDouble(),
    address: json['address'], radiusKm: json['radius_km'] ?? 25, language: json['language'] ?? 'en',
    fcmToken: json['fcm_token'], isVerified: json['is_verified'] ?? false, isKycDone: json['is_kyc_done'] ?? false,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now());

  Map<String, dynamic> toJson() => {
    'id': id, 'phone': phone, 'name': name, 'role': role, 'profile_image': profileImage,
    'latitude': latitude, 'longitude': longitude, 'address': address, 'radius_km': radiusKm,
    'language': language, 'fcm_token': fcmToken, 'is_verified': isVerified, 'is_kyc_done': isKycDone,
    'created_at': createdAt.toIso8601String()};

  UserModel copyWith({String? name, String? profileImage, double? latitude, double? longitude,
    String? address, int? radiusKm, String? fcmToken, bool? isVerified, bool? isKycDone}) =>
    UserModel(id: id, phone: phone, name: name ?? this.name, role: role,
      profileImage: profileImage ?? this.profileImage, latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude, address: address ?? this.address,
      radiusKm: radiusKm ?? this.radiusKm, language: language, fcmToken: fcmToken ?? this.fcmToken,
      isVerified: isVerified ?? this.isVerified, isKycDone: isKycDone ?? this.isKycDone,
      createdAt: createdAt);
}
