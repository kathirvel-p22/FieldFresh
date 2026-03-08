import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PaymentService {
  static final _client = Supabase.instance.client;

  // Set payment PIN (hashed)
  static Future<void> setPaymentPIN(String customerId, String pin) async {
    final pinHash = _hashPIN(pin);
    await _client.from('customer_payment_pins').upsert({
      'customer_id': customerId,
      'pin_hash': pinHash,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Verify payment PIN
  static Future<bool> verifyPaymentPIN(String customerId, String pin) async {
    try {
      final data = await _client
          .from('customer_payment_pins')
          .select('pin_hash')
          .eq('customer_id', customerId)
          .maybeSingle();

      if (data == null) return false;

      final storedHash = data['pin_hash'] as String;
      final inputHash = _hashPIN(pin);
      return storedHash == inputHash;
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  // Check if PIN is set
  static Future<bool> hasPINSet(String customerId) async {
    final data = await _client
        .from('customer_payment_pins')
        .select('id')
        .eq('customer_id', customerId)
        .maybeSingle();
    return data != null;
  }

  // Get customer bank accounts
  static Future<List<Map<String, dynamic>>> getBankAccounts(String customerId) async {
    final data = await _client
        .from('customer_bank_accounts')
        .select('*')
        .eq('customer_id', customerId)
        .order('is_primary', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Add bank account
  static Future<void> addBankAccount({
    required String customerId,
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    required String accountType,
  }) async {
    await _client.from('customer_bank_accounts').insert({
      'customer_id': customerId,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'bank_name': bankName,
      'account_type': accountType,
      'is_verified': true, // Auto-verify for demo
      'balance': 5000.00, // Demo balance
    });
  }

  // Set primary bank account
  static Future<void> setPrimaryAccount(String customerId, String accountId) async {
    // Remove primary from all accounts
    await _client
        .from('customer_bank_accounts')
        .update({'is_primary': false})
        .eq('customer_id', customerId);

    // Set new primary
    await _client
        .from('customer_bank_accounts')
        .update({'is_primary': true})
        .eq('id', accountId);
  }

  // Process payment
  static Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required String customerId,
    required String farmerId,
    required String bankAccountId,
    required double amount,
  }) async {
    try {
      // Check account balance
      final accountData = await _client
          .from('customer_bank_accounts')
          .select('balance')
          .eq('id', bankAccountId)
          .single();

      final balance = (accountData['balance'] as num).toDouble();

      if (balance < amount) {
        return {
          'success': false,
          'message': 'Insufficient balance',
        };
      }

      // Generate transaction ID
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      // Create payment transaction
      await _client.from('payment_transactions').insert({
        'order_id': orderId,
        'customer_id': customerId,
        'farmer_id': farmerId,
        'bank_account_id': bankAccountId,
        'amount': amount,
        'payment_method': 'bank_account',
        'transaction_status': 'success',
        'transaction_id': transactionId,
      });

      // Deduct from customer account
      await _client
          .from('customer_bank_accounts')
          .update({'balance': balance - amount})
          .eq('id', bankAccountId);

      // Update order payment status
      await _client.from('orders').update({
        'payment_status': 'paid',
        'payment_method': 'bank_account',
        'transaction_id': transactionId,
      }).eq('id', orderId);

      return {
        'success': true,
        'transaction_id': transactionId,
        'message': 'Payment successful',
      };
    } catch (e) {
      print('Payment error: $e');
      return {
        'success': false,
        'message': 'Payment failed: ${e.toString()}',
      };
    }
  }

  // Hash PIN for security
  static String _hashPIN(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Get payment history
  static Future<List<Map<String, dynamic>>> getPaymentHistory(String customerId) async {
    final data = await _client
        .from('payment_transactions')
        .select('*, orders(product_name, quantity, unit)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
