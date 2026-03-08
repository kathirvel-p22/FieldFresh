import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static Box? _cacheBox;

  // Initialize cache
  static Future<void> initialize() async {
    _cacheBox = await Hive.openBox('app_cache');
  }

  // Cache product data
  static Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    await _cacheBox?.put('products', products);
    await _cacheBox?.put('products_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  // Get cached products
  static List<Map<String, dynamic>>? getCachedProducts({int maxAgeMinutes = 5}) {
    final timestamp = _cacheBox?.get('products_timestamp') as int?;
    if (timestamp == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > maxAgeMinutes * 60 * 1000) return null;

    final cached = _cacheBox?.get('products');
    if (cached is List) {
      return cached.cast<Map<String, dynamic>>();
    }
    return null;
  }

  // Cache user data
  static Future<void> cacheUserData(String userId, Map<String, dynamic> data) async {
    await _cacheBox?.put('user_$userId', data);
  }

  // Get cached user data
  static Map<String, dynamic>? getCachedUserData(String userId) {
    final cached = _cacheBox?.get('user_$userId');
    if (cached is Map) {
      return Map<String, dynamic>.from(cached);
    }
    return null;
  }

  // Cache farmer profile
  static Future<void> cacheFarmerProfile(String farmerId, Map<String, dynamic> data) async {
    await _cacheBox?.put('farmer_$farmerId', data);
    await _cacheBox?.put('farmer_${farmerId}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  // Get cached farmer profile
  static Map<String, dynamic>? getCachedFarmerProfile(String farmerId, {int maxAgeMinutes = 10}) {
    final timestamp = _cacheBox?.get('farmer_${farmerId}_timestamp') as int?;
    if (timestamp == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > maxAgeMinutes * 60 * 1000) return null;

    final cached = _cacheBox?.get('farmer_$farmerId');
    if (cached is Map) {
      return Map<String, dynamic>.from(cached);
    }
    return null;
  }

  // Cache search results
  static Future<void> cacheSearchResults(String query, List<Map<String, dynamic>> results) async {
    await _cacheBox?.put('search_$query', results);
    await _cacheBox?.put('search_${query}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  // Get cached search results
  static List<Map<String, dynamic>>? getCachedSearchResults(String query, {int maxAgeMinutes = 3}) {
    final timestamp = _cacheBox?.get('search_${query}_timestamp') as int?;
    if (timestamp == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > maxAgeMinutes * 60 * 1000) return null;

    final cached = _cacheBox?.get('search_$query');
    if (cached is List) {
      return cached.cast<Map<String, dynamic>>();
    }
    return null;
  }

  // Clear all cache
  static Future<void> clearAll() async {
    await _cacheBox?.clear();
  }

  // Clear specific cache
  static Future<void> clearCache(String key) async {
    await _cacheBox?.delete(key);
  }

  // Get cache size
  static int getCacheSize() {
    return _cacheBox?.length ?? 0;
  }

  // Clear old cache (older than specified days)
  static Future<void> clearOldCache({int days = 7}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxAge = days * 24 * 60 * 60 * 1000;

    final keys = _cacheBox?.keys.toList() ?? [];
    for (final key in keys) {
      if (key.toString().endsWith('_timestamp')) {
        final timestamp = _cacheBox?.get(key) as int?;
        if (timestamp != null && (now - timestamp) > maxAge) {
          final dataKey = key.toString().replaceAll('_timestamp', '');
          await _cacheBox?.delete(dataKey);
          await _cacheBox?.delete(key);
        }
      }
    }
  }
}
