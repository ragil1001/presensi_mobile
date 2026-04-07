import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

/// Simple helper for image picker.
/// No longer uses recovery/caching mechanism as patrol now uses in-app camera.
class SafeImagePicker {
  SafeImagePicker._();

  static final ImagePicker _picker = ImagePicker();

  static Future<void> initialize() async {
    // No longer needs initialization - removed recovery mechanism
  }

  static Future<XFile?> pickImageFromCamera({
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    await _reduceMemoryPressure();

    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCameraDevice,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _reduceMemoryPressure() async {
    if (kIsWeb) return;
    try {
      final cache = PaintingBinding.instance.imageCache;
      cache.clear();
      cache.clearLiveImages();
    } catch (_) {}
  }
}
