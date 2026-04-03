import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kidsapp/models/mock_data.dart';
import 'package:kidsapp/services/download_service.dart';
import 'package:kidsapp/services/interaction_service.dart';
import 'package:kidsapp/services/thumbnail_service.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoCard extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;
  final VoidCallback? onBlock;
  final VoidCallback? onRemove;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.onBlock,
    this.onRemove,
  });

  String _formatDuration(String raw) {
    // ... no changes to formatDuration ...
    final s = raw.trim();
    if (s.isEmpty) return '';

    final parts = s.split(':').map((p) => p.trim()).toList();
    final nums = parts.map((p) => int.tryParse(p) ?? 0).toList();

    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    if (nums.length == 3) {
      hours = nums[0];
      minutes = nums[1];
      seconds = nums[2];
    } else if (nums.length == 2) {
      minutes = nums[0];
      seconds = nums[1];
    } else if (nums.length == 1) {
      seconds = nums[0];
    }

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (hours <= 0) return '$mm:$ss';

    final hh = hours.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  Color _getBgColor() {
    // Randomized color based on ID hash
    final hash = video.id.hashCode;
    final colors = [
      Colors.blue.shade900,
      Colors.purple.shade900,
      Colors.brown.shade900,
      Colors.teal.shade900,
      Colors.blueGrey.shade900,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final thumbUrl = video.thumbnailUrl.trim();
    final videoUrl = (video.videoUrl ?? '').trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail - 16:9 Aspect Ratio
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    // Logic for Shorts vs Regular
                    video.isShorts
                        ? Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: _getBgColor(), // Darkish color
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 9 / 16,
                                child: thumbUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: thumbUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : FutureBuilder(
                                        future:
                                            ThumbnailService.getVideoThumbnailBytes(
                                              videoUrl,
                                            ),
                                        builder: (context, snapshot) {
                                          final bytes = snapshot.data;
                                          if (bytes == null || bytes.isEmpty) {
                                            return Container(
                                              color: Colors.black26,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.white70,
                                                size: 42,
                                              ),
                                            );
                                          }
                                          return Image.memory(
                                            bytes,
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                          );
                                        },
                                      ),
                              ),
                            ),
                          )
                        : FutureBuilder<String?>(
                            future: DownloadService.getDownloadedThumbnailPath(video.id),
                            builder: (context, snapshot) {
                              final localThumb = snapshot.data;
                              if (localThumb != null && localThumb.isNotEmpty) {
                                return Image.file(
                                  File(localThumb),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              }
                              
                              if (thumbUrl.isNotEmpty) {
                                return CachedNetworkImage(
                                  imageUrl: thumbUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey[200]),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.videocam_off,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }
                              
                              return FutureBuilder(
                                future: ThumbnailService.getVideoThumbnailBytes(videoUrl),
                                builder: (context, snapshot) {
                                  final bytes = snapshot.data;
                                  if (bytes == null || bytes.isEmpty) {
                                    return Container(color: Colors.grey[200]);
                                  }
                                  return Image.memory(
                                    bytes,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  );
                                },
                              );
                            },
                          ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDuration(video.duration),
                          style: GoogleFonts.fredoka(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ), // Narrower
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        video.channelAvatarUrl != null &&
                            video.channelAvatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: video.channelAvatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const SizedBox.shrink(),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  video.channelName.isEmpty
                                      ? '?'
                                      : video.channelName[0],
                                  style: GoogleFonts.fredoka(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              video.channelName.isEmpty
                                  ? '?'
                                  : video.channelName[0],
                              style: GoogleFonts.fredoka(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title, // Fixed: removed invalid property access
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.channelName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<String?>(
                    future: DownloadService.getDownloadedPathForCurrentProfile(video.id),
                    builder: (context, snapshot) {
                      final isDownloaded = snapshot.data != null;
                      
                      return PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) async {
                          if (value == 'download') {
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Downloading...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              await DownloadService.downloadVideoForCurrentProfile(
                                video,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Download Complete!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          } else if (value == 'remove_download') {
                            if (onRemove != null) {
                              onRemove!();
                            } else {
                              try {
                                await DownloadService.removeDownloadedVideoForCurrentProfile(
                                  video.id,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Removed from downloads'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          } else if (value == 'report') {
                            // Show Report Dialog
                            showDialog(
                              context: context,
                              builder: (context) {
                                final controller = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Report Video'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      hintText: 'Reason',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (controller.text.isNotEmpty) {
                                          InteractionService.submitReport(
                                            video.id,
                                            controller.text,
                                            'Reported from Card',
                                          );
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Report submitted.'),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Submit'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            if (!video.isShorts && (onRemove == null || !isDownloaded))
                              const PopupMenuItem(
                                value: 'download',
                                child: Text('Download'),
                              ),
                            if (isDownloaded && onRemove != null)
                              const PopupMenuItem(
                                value: 'remove_download',
                                child: Text('Remove Download'),
                              ),
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('Report'),
                            ),
                          ];
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
