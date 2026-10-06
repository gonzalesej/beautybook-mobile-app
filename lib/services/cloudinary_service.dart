import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

/// Handles picking a photo and uploading it to Cloudinary.
class CloudinaryService {
  static final _cloudinary = CloudinaryPublic('u9qcwhrl', 'beautybook', cache: false);

  /// Opens the gallery/file picker and returns the picked file, or null if cancelled.
  static Future<XFile?> pickImage() async {
    return ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
  }

  /// Uploads a picked file to Cloudinary and returns its secure URL.
  /// Returns null if the upload fails or times out.
  static Future<String?> upload(XFile file) async {
    try {
      final CloudinaryResponse response;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        response = await _cloudinary
            .uploadFile(
              CloudinaryFile.fromBytesData(
                bytes,
                identifier: file.name,
                resourceType: CloudinaryResourceType.Image,
              ),
            )
            .timeout(const Duration(seconds: 20));
      } else {
        response = await _cloudinary
            .uploadFile(
              CloudinaryFile.fromFile(
                file.path,
                identifier: file.name,
                resourceType: CloudinaryResourceType.Image,
              ),
            )
            .timeout(const Duration(seconds: 20));
      }
      return response.secureUrl;
    } catch (e) {
      print('CLOUDINARY UPLOAD ERROR: $e');
      return null;
    }
  }
}