import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionService {
  // Compress image for optimal performance
  static Future<File?> compressImage(File file, {int quality = 70, int maxWidth = 1024}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxWidth,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original if compression fails
    }
  }

  // Compress multiple images
  static Future<List<File>> compressMultiple(List<File> files) async {
    final compressed = <File>[];
    for (final file in files) {
      final result = await compressImage(file);
      if (result != null) compressed.add(result);
    }
    return compressed;
  }

  // Get file size in MB
  static Future<double> getFileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  // Check if image needs compression
  static Future<bool> needsCompression(File file, {double maxSizeMB = 2.0}) async {
    final sizeMB = await getFileSizeMB(file);
    return sizeMB > maxSizeMB;
  }
}
