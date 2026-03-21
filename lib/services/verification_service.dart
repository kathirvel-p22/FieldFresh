import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'image_service.dart';

enum VerificationType {
  phone,
  document,
  location,
  selfie,
  address,
}

enum VerificationStatus {
  pending,
  inProgress,
  approved,
  rejected,
  expired,
}

class VerificationDocument {
  final String id;
  final String userId;
  final VerificationType type;
  final String documentType; // 'aadhar', 'pan', 'driving_license', 'passport', etc.
  final List<String> imageUrls;
  final Map<String, dynamic> extractedData;
  final VerificationStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  VerificationDocument({
    required this.id,
    required this.userId,
    required this.type,
    required this.documentType,
    required this.imageUrls,
    required this.extractedData,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.verifiedAt,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: json['id'],
      userId: json['user_id'],
      type: VerificationType.values.firstWhere(
        (t) => t.name == json['verification_type'],
      ),
      documentType: json['document_type'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      extractedData: json['extracted_data'] ?? {},
      status: VerificationStatus.values.firstWhere(
        (s) => s.name == json['status'],
      ),
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      verifiedAt: json['verified_at'] != null 
        ? DateTime.parse(json['verified_at'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'verification_type': type.name,
      'document_type': documentType,
      'image_urls': imageUrls,
      'extracted_data': extractedData,
      'status': status.name,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}

class LocationVerification {
  final double latitude;
  final double longitude;
  final String address;
  final String photoUrl;
  final DateTime timestamp;
  final double accuracy;

  LocationVerification({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.photoUrl,
    required this.timestamp,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'photo_url': photoUrl,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
    };
  }
}

class VerificationService {
  static final VerificationService _instance = VerificationService._internal();
  factory VerificationService() => _instance;
  VerificationService._internal();

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send OTP for phone verification
  Future<bool> sendPhoneOTP(String phoneNumber) async {
    try {
      await SupabaseService.signInWithOtp(phoneNumber);
      return true;
    } catch (e) {
      debugPrint('Failed to send OTP: $e');
      return false;
    }
  }

  /// Verify phone OTP
  Future<bool> verifyPhoneOTP(String phoneNumber, String otp) async {
    try {
      final response = await SupabaseService.verifyOTP(phoneNumber, otp);
      
      if (response.user != null) {
        // Record phone verification
        await _recordVerification(
          response.user!.id,
          VerificationType.phone,
          'phone_number',
          [],
          {
            'phone_number': phoneNumber,
            'verified_at': DateTime.now().toIso8601String(),
            'method': 'otp',
          },
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to verify OTP: $e');
      return false;
    }
  }

  /// Upload and verify identity document
  Future<String?> submitDocumentVerification({
    required String userId,
    required String documentType,
    required List<XFile> images,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Upload images
      final imageUrls = <String>[];
      for (final image in images) {
        final url = await ImageService.uploadImage(image);
        if (url != null) {
          imageUrls.add(url);
        }
      }

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload document images');
      }

      // Extract basic data from document type
      final extractedData = {
        'document_type': documentType,
        'image_count': imageUrls.length,
        'submitted_at': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      // Record verification request
      final verificationId = await _recordVerification(
        userId,
        VerificationType.document,
        documentType,
        imageUrls,
        extractedData,
      );

      return verificationId;
    } catch (e) {
      debugPrint('Failed to submit document verification: $e');
      return null;
    }
  }

  /// Capture and verify current location with photo
  Future<String?> submitLocationVerification({
    required String userId,
    required String address,
  }) async {
    try {
      // Check location permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        throw Exception('Location permission denied');
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Take photo at location
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) {
        throw Exception('Photo is required for location verification');
      }

      // Upload location photo
      final photoUrl = await ImageService.uploadImage(image);
      if (photoUrl == null) {
        throw Exception('Failed to upload location photo');
      }

      // Create location verification data
      final locationData = LocationVerification(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        photoUrl: photoUrl,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );

      // Record verification
      final verificationId = await _recordVerification(
        userId,
        VerificationType.location,
        'current_location',
        [photoUrl],
        locationData.toJson(),
      );

      return verificationId;
    } catch (e) {
      debugPrint('Failed to submit location verification: $e');
      return null;
    }
  }

  /// Take selfie with document for verification
  Future<String?> submitSelfieVerification({
    required String userId,
    required String documentType,
  }) async {
    try {
      // Take selfie
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image == null) {
        throw Exception('Selfie is required for verification');
      }

      // Upload selfie
      final photoUrl = await ImageService.uploadImage(image);
      if (photoUrl == null) {
        throw Exception('Failed to upload selfie');
      }

      // Record selfie verification
      final verificationId = await _recordVerification(
        userId,
        VerificationType.selfie,
        'selfie_with_document',
        [photoUrl],
        {
          'document_type': documentType,
          'selfie_url': photoUrl,
          'captured_at': DateTime.now().toIso8601String(),
        },
      );

      return verificationId;
    } catch (e) {
      debugPrint('Failed to submit selfie verification: $e');
      return null;
    }
  }

  /// Submit address proof verification
  Future<String?> submitAddressVerification({
    required String userId,
    required String documentType,
    required XFile image,
    required String address,
  }) async {
    try {
      // Upload address proof image
      final imageUrl = await ImageService.uploadImage(image);
      if (imageUrl == null) {
        throw Exception('Failed to upload address proof');
      }

      // Record address verification
      final verificationId = await _recordVerification(
        userId,
        VerificationType.address,
        documentType,
        [imageUrl],
        {
          'address': address,
          'document_type': documentType,
          'submitted_at': DateTime.now().toIso8601String(),
        },
      );

      return verificationId;
    } catch (e) {
      debugPrint('Failed to submit address verification: $e');
      return null;
    }
  }

  /// Get user's verification status
  Future<Map<VerificationType, VerificationStatus>> getUserVerificationStatus(
    String userId,
  ) async {
    try {
      final verifications = await _supabase
          .from('user_verifications')
          .select('*')
          .eq('user_id', userId);

      final statusMap = <VerificationType, VerificationStatus>{};

      for (final verification in verifications) {
        final type = VerificationType.values.firstWhere(
          (t) => t.name == verification['verification_type'],
        );
        final status = VerificationStatus.values.firstWhere(
          (s) => s.name == verification['status'],
        );
        statusMap[type] = status;
      }

      return statusMap;
    } catch (e) {
      debugPrint('Failed to get verification status: $e');
      return {};
    }
  }

  /// Get user's verification documents
  Future<List<VerificationDocument>> getUserVerifications(String userId) async {
    try {
      final verifications = await _supabase
          .from('user_verifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return verifications
          .map((v) => VerificationDocument.fromJson(v))
          .toList();
    } catch (e) {
      debugPrint('Failed to get user verifications: $e');
      return [];
    }
  }

  /// Check if user is fully verified
  Future<bool> isUserFullyVerified(String userId) async {
    try {
      final status = await getUserVerificationStatus(userId);
      
      // Required verifications for full verification
      final requiredTypes = [
        VerificationType.phone,
        VerificationType.document,
        VerificationType.location,
        VerificationType.selfie,
      ];

      for (final type in requiredTypes) {
        if (status[type] != VerificationStatus.approved) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Failed to check verification status: $e');
      return false;
    }
  }

  /// Get verification progress percentage
  Future<double> getVerificationProgress(String userId) async {
    try {
      final status = await getUserVerificationStatus(userId);
      
      const totalSteps = 4; // phone, document, location, selfie
      var completedSteps = 0;

      final requiredTypes = [
        VerificationType.phone,
        VerificationType.document,
        VerificationType.location,
        VerificationType.selfie,
      ];

      for (final type in requiredTypes) {
        if (status[type] == VerificationStatus.approved) {
          completedSteps++;
        }
      }

      return completedSteps / totalSteps;
    } catch (e) {
      debugPrint('Failed to calculate verification progress: $e');
      return 0.0;
    }
  }

  /// Record verification in database
  Future<String> _recordVerification(
    String userId,
    VerificationType type,
    String documentType,
    List<String> imageUrls,
    Map<String, dynamic> extractedData,
  ) async {
    try {
      final result = await _supabase
          .from('user_verifications')
          .insert({
            'user_id': userId,
            'verification_type': type.name,
            'document_type': documentType,
            'image_urls': imageUrls,
            'extracted_data': extractedData,
            'status': VerificationStatus.pending.name,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return result['id'];
    } catch (e) {
      debugPrint('Failed to record verification: $e');
      rethrow;
    }
  }

  /// Admin: Approve verification
  Future<void> approveVerification(
    String verificationId,
    String adminId,
    {String? notes}
  ) async {
    try {
      await _supabase
          .from('user_verifications')
          .update({
            'status': VerificationStatus.approved.name,
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': adminId,
            'admin_notes': notes,
          })
          .eq('id', verificationId);
    } catch (e) {
      debugPrint('Failed to approve verification: $e');
      rethrow;
    }
  }

  /// Admin: Reject verification
  Future<void> rejectVerification(
    String verificationId,
    String adminId,
    String reason,
  ) async {
    try {
      await _supabase
          .from('user_verifications')
          .update({
            'status': VerificationStatus.rejected.name,
            'rejection_reason': reason,
            'verified_by': adminId,
          })
          .eq('id', verificationId);
    } catch (e) {
      debugPrint('Failed to reject verification: $e');
      rethrow;
    }
  }
}