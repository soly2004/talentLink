import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../error/failures.dart';

/// Wraps `image_picker` and handles the cross-platform [XFile] it returns.
/// The image is downsized at pick time so it fits comfortably in Firestore.
class PhotoService {
  PhotoService(this._picker);
  final ImagePicker _picker;

  Future<Uint8List?> pick(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 70,
      );
      if (file == null) return null; // user cancelled
      return file.readAsBytes(); // works on Android, iOS and web
    } on PlatformException catch (e) {
      final denied = e.code.contains('access_denied');
      throw PermissionFailure(
        denied
            ? 'Camera or photo access is blocked. Enable it in Settings to add a picture.'
            : 'Could not open the camera. Please try again.',
      );
    }
  }
}
