import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../utils/app_colors.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final VoidCallback onPostUpdated;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.onPostUpdated,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isExporting = false;
  bool _isVideoLoading = true;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    if (_post.videoUrl == null || _post.videoUrl!.isEmpty) {
      setState(() => _isVideoLoading = false);
      return;
    }

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(_post.videoUrl!),
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFE1306C),
          handleColor: const Color(0xFFE1306C),
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );

      setState(() => _isVideoLoading = false);
    } catch (e) {
      setState(() {
        _isVideoLoading = false;
        _videoError = 'امکان بارگذاری ویدیو از سرور محلی میسر نشد.';
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _handleTogglePosted(bool value) async {
    setState(() => _post.isPosted = value);
    final updated = await ApiService.togglePostedStatus(_post.id);
    if (updated != null) {
      setState(() => _post = updated);
    }
    widget.onPostUpdated();
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    final result = await ExportService.exportPostToDevice(_post);

    if (!mounted) return;
    setState(() => _isExporting = false);

    // Show Confirmation Dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppColors.emerald, size: 32),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'آماده برای انتشار در اینستاگرام!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.message ?? 'فایل‌ها در گالری ذخیره شدند و کپشن کپی شد.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ExportService.shareToInstagram(_post);
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'باز کردن اینستاگرام و انتشار',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1306C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('بستن', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          _post.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _post.isPosted
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: _post.isPosted ? AppColors.emerald : Colors.white70,
            ),
            tooltip: 'تغییر وضعیت به منتشر شده',
            onPressed: () => _handleTogglePosted(!_post.isPosted),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Player or Cover Area
            Container(
              color: Colors.black,
              constraints: const BoxConstraints(maxHeight: 400),
              child: _buildMediaPreview(),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Date Ribbon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _post.isPosted
                              ? AppColors.emerald.withValues(alpha: 0.2)
                              : Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _post.isPosted
                                ? AppColors.emerald.withValues(alpha: 0.4)
                                : Colors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _post.isPosted ? 'منتشر شده' : 'در انتظار انتشار',
                          style: TextStyle(
                            color: _post.isPosted
                                ? AppColors.emerald
                                : Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.pinkAccent),
                          const SizedBox(width: 4),
                          Text(
                            _post.displayShamsiDate,
                            style: const TextStyle(
                              color: Colors.pinkAccent,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 1-Tap Export Button
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_for_offline_rounded, size: 22),
                    label: Text(
                      _isExporting
                          ? 'در حال دانلود رسانه و کپی کپشن...'
                          : 'دانلود در گالری و کپی کپشن (1-Tap Export)',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE1306C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Caption Box with Copy Button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'متن کپشن',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                await ExportService.copyCaptionToClipboard(
                                    _post.caption);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('متن کپشن کپی شد'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('کپی متن',
                                  style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.pinkAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _post.caption.isNotEmpty
                              ? _post.caption
                              : 'هیچ کپشنی برای این پست وارد نشده است.',
                          style: TextStyle(
                            color: _post.caption.isNotEmpty
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Post ID & Source Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'منبع: ${_post.source == 'watch_folder' ? 'پوشه پایش خودکار' : 'داشبورد وب'}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                        Text(
                          'شناسه: ${_post.id}',
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_isVideoLoading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE1306C)),
        ),
      );
    }

    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }

    if (_post.coverUrl != null && _post.coverUrl!.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: _post.coverUrl!,
          fit: BoxFit.contain,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white38, size: 48),
            const SizedBox(height: 8),
            Text(
              _videoError ?? 'رسانه‌ای برای نمایش موجود نیست',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
