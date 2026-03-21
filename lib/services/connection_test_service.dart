import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ConnectionTestService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Test basic Supabase connection
  static Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing Supabase connection...');

      // Test 1: Simple query to check connection
      await _client.from('users').select('count').limit(1);

      debugPrint('✅ Basic connection test passed');
      return true;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Test database tables existence
  static Future<Map<String, bool>> testTables() async {
    final tables = {
      'users': false,
      'products': false,
      'orders': false,
      'session_tokens': false,
      'trust_verifications': false,
    };

    for (final tableName in tables.keys) {
      try {
        await _client.from(tableName).select('*').limit(1);
        tables[tableName] = true;
        debugPrint('✅ Table $tableName exists');
      } catch (e) {
        debugPrint('❌ Table $tableName missing or inaccessible: $e');
      }
    }

    return tables;
  }

  /// Test user creation (simplified)
  static Future<String?> testUserCreation(String phone, String role) async {
    try {
      debugPrint('🔍 Testing user creation...');

      // Check if user already exists
      final existing = await _client
          .from('users')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();

      if (existing != null) {
        debugPrint('✅ User already exists: ${existing['id']}');
        return existing['id'];
      }

      // Create new user with minimal data
      final result = await _client
          .from('users')
          .insert({
            'phone': phone,
            'role': role,
            'is_verified': false,
            'is_kyc_done': false,
          })
          .select('id')
          .single();

      debugPrint('✅ User created successfully: ${result['id']}');
      return result['id'];
    } catch (e) {
      debugPrint('❌ User creation failed: $e');
      return null;
    }
  }

  /// Get connection status with detailed info
  static Future<Map<String, dynamic>> getConnectionStatus() async {
    final status = <String, dynamic>{
      'connected': false,
      'tables': <String, bool>{},
      'error': null,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Test basic connection
      status['connected'] = await testConnection();

      if (status['connected']) {
        // Test tables
        status['tables'] = await testTables();
      }
    } catch (e) {
      status['error'] = e.toString();
    }

    return status;
  }

  /// Initialize minimal user session (bypass enterprise services)
  static Future<bool> initializeSimpleSession(String phone, String role) async {
    try {
      debugPrint('🚀 Initializing simple session...');

      // Test connection first
      if (!await testConnection()) {
        throw Exception('Database connection failed');
      }

      // Create or get user
      final userId = await testUserCreation(phone, role);
      if (userId == null) {
        throw Exception('Failed to create/get user');
      }

      // Store user ID in Supabase service (existing method)
      await SupabaseService.setDemoUserId(userId);

      debugPrint('✅ Simple session initialized for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Simple session initialization failed: $e');
      return false;
    }
  }
}
