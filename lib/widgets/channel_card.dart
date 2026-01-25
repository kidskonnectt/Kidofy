import 'package:flutter/material.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChannelCard extends StatelessWidget {
  final String channelName;
  final String? channelAvatarUrl;
  final VoidCallback onTap;
  final VoidCallback? onBlock;

  const ChannelCard({
    super.key,
    required this.channelName,
    this.channelAvatarUrl,
    required this.onTap,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        height: 120, // Match typical small video card height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child:
                  channelAvatarUrl != null &&
                      channelAvatarUrl!.trim().isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: channelAvatarUrl!.trim(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox.shrink(),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            channelName.isEmpty ? '?' : channelName[0],
                            style: GoogleFonts.fredoka(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        channelName.isEmpty ? '?' : channelName[0],
                        style: GoogleFonts.fredoka(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    channelName,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Explore all videos!",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (val) {
                if (val == 'block' && onBlock != null) onBlock!();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Text('Block Channel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
