import 'dart:io';
import 'package:kidsapp/services/download_bus.dart';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/services/profile_local_store.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static Future<String?> getDownloadedPathForCurrentProfile(
    String videoId,
  ) async {
    final profile = MockData.currentProfile.value;
    if (profile == null) return null;
    
    final fileName = await ProfileLocalStore.getOfflineVideoPath(profile.id, videoId);
    if (fileName == null || fileName.isEmpty) return null;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}${Platform.pathSeparator}downloads${Platform.pathSeparator}$fileName';
    
    if (await File(filePath).exists()) {
      return filePath;
    }
    return null;
  }

  static Future<String?> getDownloadedThumbnailPath(String videoId) async {
    final profile = MockData.currentProfile.value;
    if (profile == null) return null;

    final fileName = await ProfileLocalStore.getOfflineVideoPath(profile.id, videoId);
    if (fileName == null || fileName.isEmpty) return null;

    final thumbFileName = fileName.replaceFirst('.mp4', '_thumb.jpg');
    final dir = await getApplicationDocumentsDirectory();
    final thumbPath = '${dir.path}${Platform.pathSeparator}downloads${Platform.pathSeparator}$thumbFileName';

    if (await File(thumbPath).exists()) {
      return thumbPath;
    }
    return null;
  }

  static Future<String> downloadVideoForCurrentProfile(Video video) async {
    final profile = MockData.currentProfile.value;
    if (profile == null) {
      throw StateError('No active profile');
    }
    if (video.videoUrl == null || video.videoUrl!.isEmpty) {
      throw StateError('Video has no playable URL');
    }

    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(
      '${dir.path}${Platform.pathSeparator}downloads',
    );
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    // Keep file name stable per video so re-download overwrites.
    final safeId = video.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filePath = '${downloadsDir.path}${Platform.pathSeparator}$safeId.mp4';
    final file = File(filePath);

    debugPrint('Downloading ${video.videoUrl} -> $filePath');

    final resp = await http.get(Uri.parse(video.videoUrl!));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('Download failed (${resp.statusCode})');
    }

    await file.writeAsBytes(resp.bodyBytes, flush: true);
    
    // Download and cache thumbnail for offline use
    if (video.thumbnailUrl.isNotEmpty) {
      try {
        final thumbResp = await http.get(Uri.parse(video.thumbnailUrl));
        if (thumbResp.statusCode == 200) {
          final thumbPath = '${downloadsDir.path}${Platform.pathSeparator}${safeId}_thumb.jpg';
          await File(thumbPath).writeAsBytes(thumbResp.bodyBytes);
          // Store relative thumb path or just a flag
        }
      } catch (e) {
        debugPrint('Failed to download thumbnail: $e');
      }
    }
    
    // Save metadata locally so it persists even if Supabase fetch fails (offline)
    await ProfileLocalStore.saveVideoMetadata(video);

    await ProfileLocalStore.addOfflineVideo(profile.id, video.id);
    final fileName = '$safeId.mp4';
    await ProfileLocalStore.setOfflineVideoPath(profile.id, video.id, fileName);

    DownloadBus().notifyChanged();
    return filePath;
  }

  static Future<void> removeDownloadedVideoForCurrentProfile(
    String videoId,
  ) async {
    final profile = MockData.currentProfile.value;
    if (profile == null) return;

    final path = await ProfileLocalStore.getOfflineVideoPath(
      profile.id,
      videoId,
    );
    if (path != null && path.isNotEmpty) {
      try {
        final videoFile = File(path);
        if (await videoFile.exists()) {
          await videoFile.delete();
        }
        
        // Also remove thumbnail
        final thumbPath = path.replaceFirst('.mp4', '_thumb.jpg');
        final thumbFile = File(thumbPath);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete downloaded files: $e');
      }
    }

    await ProfileLocalStore.removeOfflineVideo(profile.id, videoId);
    await ProfileLocalStore.removeOfflineVideoPath(profile.id, videoId);
    await ProfileLocalStore.removeVideoMetadata(videoId);
    
    DownloadBus().notifyChanged();
  }
}
