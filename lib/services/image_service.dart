import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'image_compression_service.dart';

class ImageService {
  static final _picker = ImagePicker();
  static final _dio = Dio();

  static Future<File?> pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1080);
    if (x == null) return null;
    final file = File(x.path);
    // Compress if needed
    return await ImageCompressionService.compressImage(file);
  }

  static Future<File?> pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1080);
    if (x == null) return null;
    final file = File(x.path);
    // Compress if needed
    return await ImageCompressionService.compressImage(file);
  }

  static Future<List<File>> pickMultiple() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1080);
    final files = imgs.map((x) => File(x.path)).toList();
    // Compress all images
    return await ImageCompressionService.compressMultiple(files);
  }

  static Future<String?> uploadToCloudinary(File image) async {
    try {
      final fd = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
        'upload_preset': AppStrings.cloudinaryUploadPreset,
        'folder': 'fieldfresh/products'
      });
      final r = await _dio.post(
        'https://api.cloudinary.com/v1_1/${AppStrings.cloudinaryCloud}/image/upload',
        data: fd
      );
      return r.data['secure_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> uploadMultiple(List<File> images) async {
    final urls = await Future.wait(images.map(uploadToCloudinary));
    return urls.whereType<String>().toList();
  }
}
