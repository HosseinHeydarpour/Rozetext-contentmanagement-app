import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../services/export_service.dart';
import '../utils/app_colors.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final ValueChanged<bool> onTogglePosted;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onTogglePosted,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // slate-800
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: post.isPosted
                ? AppColors.emerald.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (post.coverUrl != null && post.coverUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: post.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF0F172A),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF0F172A),
                          child: const Icon(Icons.image, color: Colors.white38),
                        ),
                      )
                    else
                      Container(
                        color: const Color(0xFF0F172A),
                        child: const Icon(
                          Icons.movie_creation_outlined,
                          color: Colors.white38,
                          size: 32,
                        ),
                      ),
                    // Video indicator
                    if (post.videoUrl != null)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Post Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: post.isPosted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildStatusBadge(),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Shamsi Date & Relative label
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Colors.pink.shade300,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.displayShamsiDate,
                          style: TextStyle(
                            color: Colors.pink.shade200,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Caption Snippet
                  if (post.caption.isNotEmpty)
                    Text(
                      post.caption,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 6),

                  // Bottom Action Bar: Toggle Posted & Copy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Toggle Checkbox
                      InkWell(
                        onTap: () => onTogglePosted(!post.isPosted),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: post.isPosted,
                                  onChanged: (val) {
                                    if (val != null) onTogglePosted(val);
                                  },
                                  activeColor: AppColors.emerald,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                post.isPosted ? 'منتشر شد' : 'انتشار در اینستاگرام',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: post.isPosted
                                      ? AppColors.emeraldLight
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Quick Copy Caption Button
                      if (post.caption.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          color: Colors.white60,
                          tooltip: 'کپی کپشن',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () async {
                            await ExportService.copyCaptionToClipboard(
                                post.caption);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('کپشن با موفقیت کپی شد'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (post.isPosted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: AppColors.emerald, size: 10),
            SizedBox(width: 3),
            Text(
              'پست شده',
              style: TextStyle(color: AppColors.emerald, fontSize: 10),
            ),
          ],
        ),
      );
    }

    if (post.isToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.pink.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.pink.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'امروز',
          style: TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Text(
        post.relativeLabel,
        style: const TextStyle(color: Colors.amber, fontSize: 10),
      ),
    );
  }
}
