import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Persists user-picked photos into the app documents directory (IMG1).
///
/// [ImagePicker] returns temporary cache paths that the OS may purge. Always
/// copy through [persistPickedPath] / [saveUserImage] before storing a path
/// on a domain model.
class ImageService {
  static final ImageService instance = ImageService._();
  factory ImageService() => instance;
  ImageService._();

  static const String userImagesDir = 'user_images';

  /// Override for unit tests (skips [getApplicationDocumentsDirectory]).
  Directory? debugDocumentsOverride;

  Future<Directory> _documentsDir() async {
    if (debugDocumentsOverride != null) return debugDocumentsOverride!;
    return getApplicationDocumentsDirectory();
  }

  /// Copies a temp pick path into durable storage. Returns the new path, or
  /// the original [tempPath] if the file is missing / copy fails.
  Future<String> persistPickedPath(
    String tempPath, {
    String prefix = 'photo',
  }) async {
    if (tempPath.isEmpty) return tempPath;
    try {
      final src = File(tempPath);
      if (!await src.exists()) return tempPath;

      // Already under our documents tree — leave as-is.
      final docs = await _documentsDir();
      final userImagesPath = '${docs.path}/$userImagesDir';
      if (tempPath.startsWith(userImagesPath)) return tempPath;

      await Directory(userImagesPath).create(recursive: true);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = _extensionOf(tempPath);
      final safePrefix =
          prefix.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').clampLen(40);
      final destPath = '$userImagesPath/${safePrefix}_$timestamp$ext';
      final saved = await src.copy(destPath);
      return saved.path;
    } catch (e) {
      if (kDebugMode) print('Error persisting user image: $e');
      return tempPath;
    }
  }

  /// Saves a user image to the app's documents directory.
  /// Returns the file path if successful, null if failed.
  Future<String?> saveUserImage(File imageFile, String itemId) async {
    try {
      if (!await imageFile.exists()) return null;
      return await persistPickedPath(imageFile.path, prefix: itemId);
    } catch (e) {
      if (kDebugMode) print('Error saving user image: $e');
      return null;
    }
  }

  /// Deletes a user image file (only under app documents `user_images`).
  Future<void> deleteUserImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final docs = await _documentsDir();
      final userImagesPath = '${docs.path}/$userImagesDir';
      if (!path.startsWith(userImagesPath)) return;
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      if (kDebugMode) print('Error deleting user image: $e');
    }
  }

  /// Gets the total size of user images directory.
  Future<int> getUserImagesSize() async {
    try {
      final directory = await _documentsDir();
      final userImagesPath = '${directory.path}/$userImagesDir';
      final dir = Directory(userImagesPath);
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      await for (final file in dir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      return totalSize;
    } catch (e) {
      if (kDebugMode) print('Error getting user images size: $e');
      return 0;
    }
  }

  /// Cleans up orphaned user images (images not referenced in any items).
  Future<int> cleanupOrphanedImages(List<String> activeImagePaths) async {
    try {
      final directory = await _documentsDir();
      final userImagesPath = '${directory.path}/$userImagesDir';
      final dir = Directory(userImagesPath);
      if (!await dir.exists()) return 0;

      final active = activeImagePaths.toSet();
      int deletedCount = 0;
      await for (final file in dir.list(recursive: true)) {
        if (file is File && !active.contains(file.path)) {
          await file.delete();
          deletedCount++;
        }
      }
      return deletedCount;
    } catch (e) {
      if (kDebugMode) print('Error cleaning up orphaned images: $e');
      return 0;
    }
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot == path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext.length > 5) return '.jpg';
    return ext;
  }
}

extension on String {
  String clampLen(int max) => length <= max ? this : substring(0, max);
}
