import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/image_service.dart';

/// Shared Camera / Gallery bottom sheet used across detail & edit screens.
///
/// Returns a picked [XFile] whose path is **persisted** into app documents
/// (IMG1), or null if the user cancels.
Future<XFile?> pickPhotoFromCameraOrGallery(
  BuildContext context, {
  int imageQuality = 85,
  String persistPrefix = 'photo',
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (_) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final picked =
      await ImagePicker().pickImage(source: source, imageQuality: imageQuality);
  if (picked == null) return null;
  final durable = await ImageService()
      .persistPickedPath(picked.path, prefix: persistPrefix);
  return XFile(durable);
}
