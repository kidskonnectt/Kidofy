import 'dart:io';

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
    return ProfileLocalStore.getOfflineVideoPath(profile.id, videoId);
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

    await ProfileLocalStore.addOfflineVideo(profile.id, video.id);
    await ProfileLocalStore.setOfflineVideoPath(profile.id, video.id, filePath);

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
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete downloaded file: $e');
      }
    }

    await ProfileLocalStore.removeOfflineVideo(profile.id, videoId);
    await ProfileLocalStore.removeOfflineVideoPath(profile.id, videoId);
  }
}
