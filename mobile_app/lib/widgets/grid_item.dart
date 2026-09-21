import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../utils/app_colors.dart';

class GridItem extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const GridItem({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            border: Border.all(color: Colors.black, width: 0.5),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image Cover
              if (post.coverUrl != null && post.coverUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: post.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF0F172A),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF0F172A),
                    child: const Icon(Icons.broken_image, color: Colors.white24),
                  ),
                )
              else
                Container(
                  color: const Color(0xFF0F172A),
                  child: const Center(
                    child: Icon(Icons.movie, color: Colors.white30, size: 36),
                  ),
                ),

              // Gradient Overlay for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Video Indicator (Top Left for RTL)
              if (post.videoUrl != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.video_library_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),

              // Status Indicator (Top Right)
              Positioned(
                top: 6,
                right: 6,
                child: post.isPosted
                    ? Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: post.isToday
                              ? Colors.pink
                              : Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.relativeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),

              // Bottom Title / Shamsi Date
              Positioned(
                bottom: 4,
                left: 6,
                right: 6,
                child: Text(
                  post.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
