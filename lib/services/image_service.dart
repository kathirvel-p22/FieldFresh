import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

class ImageService {
  static final _picker = ImagePicker();
  static final _dio = dio.Dio();
  static final _supabase = Supabase.instance.client;

  static Future<XFile?> pickFromCamera() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 80, 
        maxWidth: 1080
      );
      return x;
    } catch (e) {
      print('DEBUG: Camera picker error: $e');
      return null;
    }
  }

  static Future<XFile?> pickFromGallery() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 80, 
        maxWidth: 1080
      );
      return x;
    } catch (e) {
      print('DEBUG: Gallery picker error: $e');
      return null;
    }
  }

  static Future<List<XFile>> pickMultiple() async {
    try {
      final imgs = await _picker.pickMultiImage(
        imageQuality: 80, 
        maxWidth: 1080
      );
      return imgs;
    } catch (e) {
      print('DEBUG: Multiple picker error: $e');
      return [];
    }
  }

  // Primary upload method - handles both web and mobile
  static Future<String?> uploadImage(XFile image) async {
    print('DEBUG: Starting image upload...');
    print('DEBUG: Image name: ${image.name}');
    print('DEBUG: Image path: ${image.path}');
    
    try {
      // Get file size
      final fileSize = await image.length();
      print('DEBUG: Image size: $fileSize bytes');
      
      // Check file size (limit to 10MB)
      if (fileSize > 10 * 1024 * 1024) {
        print('DEBUG: File too large: $fileSize bytes');
        return null;
      }
      
      // Try Supabase Storage first (more reliable)
      final supabaseUrl = await _uploadToSupabase(image);
      if (supabaseUrl != null) {
        print('DEBUG: Supabase upload successful: $supabaseUrl');
        return supabaseUrl;
      }
      
      // Fallback to Cloudinary
      print('DEBUG: Supabase failed, trying Cloudinary...');
      final cloudinaryUrl = await _uploadToCloudinary(image);
      if (cloudinaryUrl != null) {
        print('DEBUG: Cloudinary upload successful: $cloudinaryUrl');
        return cloudinaryUrl;
      }
      
      print('DEBUG: All upload methods failed');
      return null;
    } catch (e) {
      print('DEBUG: Upload error: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      return null;
    }
  }

  // Supabase Storage upload (primary method) - Web compatible
  static Future<String?> _uploadToSupabase(XFile image) async {
    try {
      print('DEBUG: Starting Supabase upload...');
      
      // Check file size (limit to 10MB)
      final fileSize = await image.length();
      if (fileSize > 10 * 1024 * 1024) {
        print('DEBUG: File too large for Supabase: $fileSize bytes');
        return null;
      }
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = image.name.split('.').last.toLowerCase();
      final fileName = 'fieldfresh_${timestamp}_image.$extension';
      final filePath = 'images/$fileName';
      
      print('DEBUG: Uploading to Supabase path: $filePath');
      print('DEBUG: File size: $fileSize bytes');
      
      // Read file as bytes (works on both web and mobile)
      final bytes = await image.readAsBytes();
      print('DEBUG: File read as ${bytes.length} bytes');
      
      // Upload to Supabase Storage
      final uploadResult = await _supabase.storage
          .from('fieldfresh-images')
          .uploadBinary(filePath, bytes);
      
      print('DEBUG: Supabase upload result: $uploadResult');
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from('fieldfresh-images')
          .getPublicUrl(filePath);
      
      print('DEBUG: Supabase public URL: $publicUrl');
      
      if (publicUrl.isNotEmpty) {
        return publicUrl;
      } else {
        print('DEBUG: Empty public URL returned');
        return null;
      }
      
    } catch (e) {
      print('DEBUG: Supabase upload failed: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      return null;
    }
  }

  // Cloudinary upload (fallback method) - Web compatible
  static Future<String?> _uploadToCloudinary(XFile image) async {
    try {
      print('DEBUG: Starting Cloudinary upload...');
      
      // Check file size (limit to 10MB)
      final fileSize = await image.length();
      if (fileSize > 10 * 1024 * 1024) {
        print('DEBUG: File too large for Cloudinary: $fileSize bytes');
        return null;
      }
      
      // Read file as bytes for web compatibility
      final bytes = await image.readAsBytes();
      
      // Try unsigned upload first (no authentication required)
      try {
        print('DEBUG: Trying unsigned Cloudinary upload...');
        final fd = dio.FormData.fromMap({
          'file': dio.MultipartFile.fromBytes(bytes, filename: image.name),
          'upload_preset': 'ml_default', // Use Cloudinary's default unsigned preset
        });
        
        final r = await _dio.post(
          'https://api.cloudinary.com/v1_1/${AppStrings.cloudinaryCloud}/image/upload',
          data: fd,
          options: dio.Options(
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        );
        
        print('DEBUG: Unsigned Cloudinary response status: ${r.statusCode}');
        print('DEBUG: Unsigned Cloudinary response: ${r.data}');
        
        final url = r.data['secure_url'] as String?;
        if (url != null) {
          return url;
        }
      } catch (unsignedError) {
        print('DEBUG: Unsigned upload failed: $unsignedError');
      }
      
      // Try with a simple upload (no preset)
      try {
        print('DEBUG: Trying simple Cloudinary upload...');
        final fd = dio.FormData.fromMap({
          'file': dio.MultipartFile.fromBytes(bytes, filename: image.name),
          'api_key': '123456789012345', // Dummy API key for testing
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        });
        
        final r = await _dio.post(
          'https://api.cloudinary.com/v1_1/${AppStrings.cloudinaryCloud}/image/upload',
          data: fd,
          options: dio.Options(
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        );
        
        print('DEBUG: Simple Cloudinary response: ${r.data}');
        final url = r.data['secure_url'] as String?;
        if (url != null) {
          return url;
        }
      } catch (simpleError) {
        print('DEBUG: Simple upload also failed: $simpleError');
      }
      
      return null;
    } catch (e) {
      print('DEBUG: Cloudinary upload failed: $e');
      return null;
    }
  }

  // Legacy method for backward compatibility - converts File to XFile
  static Future<String?> uploadToCloudinary(File image) async {
    final xFile = XFile(image.path);
    return await uploadImage(xFile);
  }

  static Future<List<String>> uploadMultiple(List<XFile> images) async {
    print('DEBUG: Uploading ${images.length} images...');
    final urls = <String>[];
    
    for (int i = 0; i < images.length; i++) {
      print('DEBUG: Uploading image ${i + 1}/${images.length}...');
      final url = await uploadImage(images[i]);
      if (url != null) {
        urls.add(url);
        print('DEBUG: Image ${i + 1} uploaded successfully');
      } else {
        print('DEBUG: Image ${i + 1} upload failed');
      }
    }
    
    print('DEBUG: Upload complete. ${urls.length}/${images.length} images uploaded successfully');
    return urls;
  }

  // Legacy method for File list compatibility
  static Future<List<String>> uploadMultipleFiles(List<File> files) async {
    final xFiles = files.map((f) => XFile(f.path)).toList();
    return await uploadMultiple(xFiles);
  }
}