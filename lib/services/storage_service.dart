import 'image_base64_service.dart';

/// Storage service for handling image storage using base64 encoding
/// This eliminates the need for Firebase Storage (which requires Blaze plan)
/// Images are stored directly in Firestore as base64 strings
class StorageService {
  final ImageBase64Service _imageService = ImageBase64Service();

  /// Pick image from gallery and convert to base64
  Future<String?> pickImageFromGallery() async {
    try {
      return await _imageService.pickAndConvertToBase64FromGallery();
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick image from camera and convert to base64
  Future<String?> pickImageFromCamera() async {
    try {
      return await _imageService.pickAndConvertToBase64FromCamera();
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Upload profile image (actually just returns base64 string)
  /// Kept for backward compatibility with existing code
  Future<String> uploadProfileImage({
    required dynamic imageFile, // Can be File or String (base64)
    required String userId,
  }) async {
    try {
      // If imageFile is already a base64 string, return it
      if (imageFile is String) {
        return imageFile;
      }

      // This shouldn't happen with the new flow, but just in case
      throw Exception(
        'Invalid image format. Please use pickImageFromGallery or pickImageFromCamera',
      );
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  /// Delete image (no-op for base64, kept for compatibility)
  Future<void> deleteImage(String imageUrl) async {
    // No action needed for base64 - image is just stored in Firestore
    // This method is kept for backward compatibility
    return;
  }
}
