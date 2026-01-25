import 'dart:convert';
import 'package:http/http.dart' as http;

class BunnyService {
  static const String storageName = 'kidskonnect';
  static const String storageHost = 'storage.bunnycdn.com';
  static const String cdnHost = 'kidskonnect.b-cdn.net';
  static const String apiKey =
      '53c81d83-2bbe-4004-b053a4f408dd-f62a-4e2c'; // Be careful with exposing this on client side!

  // Ideally, sensitive operations like upload/delete should be done server-side.
  // But for this integration task, we'll put it here.

  static String getFileUrl(String path) {
    // Normalization: Remove leading doubles slashes or slashes
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Check if the path is already a full URL or relative
    if (path.startsWith('http')) {
      return path;
    }

    // Bunny storage structure as requested:
    // Videos -> video/filename (User provided "video folder")
    // Avatars -> images/avatars/filename
    // Thumbnails -> images/thumbnails/filename

    // We assume the DB stores the relative path like 'video/bunny.mp4' or 'images/avatars/1.png'
    // If the DB only stores 'bunny.mp4' and we know it's a video, the calling service should prepend 'video/'
    // However, for safety, this method just blindly constructs the URL from the given path.
    // It's safer to store the full relative path in the DB.

    return 'https://$cdnHost/$path';
  }

  // Example method to list files if needed, or fetch metadata from Bunny
  Future<List<String>> listVideos() async {
    final url = Uri.parse('https://$storageHost/$storageName/');
    final response = await http.get(
      url,
      headers: {'AccessKey': apiKey, 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e['ObjectName'] as String).toList();
    } else {
      throw Exception(
        'Failed to load videos from Bunny: ${response.statusCode}',
      );
    }
  }
}
