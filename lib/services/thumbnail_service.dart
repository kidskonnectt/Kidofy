import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};

  static Future<Uint8List?> getVideoThumbnailBytes(
    String? videoUrl, {
    int maxWidth = 512,
    int quality = 75,
  }) async {
    final url = (videoUrl ?? '').trim();
    if (url.isEmpty) return null;

    final cached = _memoryCache[url];
    if (cached != null) return cached;

    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        quality: quality,
      );

      if (bytes != null && bytes.isNotEmpty) {
        // Basic memory cap to avoid growing forever.
        if (_memoryCache.length > 250) {
          _memoryCache.clear();
        }
        _memoryCache[url] = bytes;
      }

      return bytes;
    } catch (e) {
      debugPrint('ThumbnailService error: $e');
      return null;
    }
  }
}
