import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Service for handling image to base64 conversion and vice versa
/// This allows storing images directly in Firestore without needing Firebase Storage
class ImageBase64Service {
  final ImagePicker _picker = ImagePicker();

  // Maximum image dimensions to keep base64 size reasonable
  static const int maxWidth = 800;
  static const int maxHeight = 800;
  static const int imageQuality = 85;

  /// Pick image from gallery and convert to base64
  Future<String?> pickAndConvertToBase64FromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final File file = File(image.path);
        return await _fileToBase64(file);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick and convert image: $e');
    }
  }

  /// Pick image from camera and convert to base64
  Future<String?> pickAndConvertToBase64FromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final File file = File(image.path);
        return await _fileToBase64(file);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to capture and convert image: $e');
    }
  }

  /// Convert File to base64 string with compression
  Future<String> _fileToBase64(File imageFile) async {
    try {
      // Read file as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed to keep base64 size reasonable
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height > image.width ? maxHeight : null,
        );
      }

      // Encode as JPEG with quality compression
      final List<int> compressedBytes = img.encodeJpg(
        image,
        quality: imageQuality,
      );

      // Convert to base64
      final String base64String = base64Encode(compressedBytes);

      // Add data URI prefix for complete base64 image string
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  /// Convert base64 string to Image widget
  static Image base64ToImage(String base64String, {BoxFit fit = BoxFit.cover}) {
    try {
      // Remove data URI prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains('base64,')) {
        cleanBase64 = base64String.split('base64,').last;
      }

      // Decode base64 to bytes
      final Uint8List bytes = base64Decode(cleanBase64);

      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, color: Colors.red);
        },
      );
    } catch (e) {
      print('Error converting base64 to image: $e');
      return Image.asset(
        'assets/images/placeholder.png',
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 50, color: Colors.grey);
        },
      );
    }
  }

  /// Get image provider from base64 string (for CircleAvatar, etc.)
  static ImageProvider? base64ToImageProvider(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }

    try {
      // Remove data URI prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains('base64,')) {
        cleanBase64 = base64String.split('base64,').last;
      }

      // Decode base64 to bytes
      final Uint8List bytes = base64Decode(cleanBase64);

      return MemoryImage(bytes);
    } catch (e) {
      print('Error converting base64 to image provider: $e');
      return null;
    }
  }

  /// Validate base64 string
  static bool isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }

    try {
      // Remove data URI prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains('base64,')) {
        cleanBase64 = base64String.split('base64,').last;
      }

      // Try to decode
      base64Decode(cleanBase64);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get estimated size of base64 string in KB
  static double getBase64SizeInKB(String base64String) {
    try {
      String cleanBase64 = base64String;
      if (base64String.contains('base64,')) {
        cleanBase64 = base64String.split('base64,').last;
      }

      // Base64 size is approximately 4/3 of original bytes
      // But the string itself is what matters in Firestore
      return cleanBase64.length / 1024;
    } catch (e) {
      return 0;
    }
  }
}
