import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post.dart';

class ExportResult {
  final bool captionCopied;
  final bool videoSaved;
  final bool coverSaved;
  final String? message;

  ExportResult({
    required this.captionCopied,
    required this.videoSaved,
    required this.coverSaved,
    this.message,
  });
}

class ExportService {
  /// Copy caption directly to device clipboard
  static Future<bool> copyCaptionToClipboard(String caption) async {
    if (caption.trim().isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: caption));
    return true;
  }

  /// Download and save video/cover to Android gallery, and copy caption
  static Future<ExportResult> exportPostToDevice(Post post) async {
    bool captionCopied = false;
    bool videoSaved = false;
    bool coverSaved = false;

    // 1. Copy caption to clipboard
    if (post.caption.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: post.caption));
      captionCopied = true;
    }

    final tempDir = await getTemporaryDirectory();

    // 2. Download & Save Video
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      try {
        final videoUri = Uri.parse(post.videoUrl!);
        final response = await http.get(videoUri);

        if (response.statusCode == 200) {
          final tempVideoPath = '${tempDir.path}/${post.id}_video.mp4';
          final tempFile = File(tempVideoPath);
          await tempFile.writeAsBytes(response.bodyBytes);

          // Save to device photo gallery
          try {
            await Gal.putVideo(tempVideoPath);
            videoSaved = true;
          } catch (_) {
            // Fallback if gal fails or permission not yet granted
          }
        }
      } catch (e) {
        // Log video download error
      }
    }

    // 3. Download & Save Cover
    if (post.coverUrl != null && post.coverUrl!.isNotEmpty) {
      try {
        final coverUri = Uri.parse(post.coverUrl!);
        final response = await http.get(coverUri);

        if (response.statusCode == 200) {
          final tempCoverPath = '${tempDir.path}/${post.id}_cover.jpg';
          final tempFile = File(tempCoverPath);
          await tempFile.writeAsBytes(response.bodyBytes);

          // Save to device photo gallery
          try {
            await Gal.putImage(tempCoverPath);
            coverSaved = true;
          } catch (_) {}
        }
      } catch (e) {
        // Log cover download error
      }
    }

    String message = '';
    if (captionCopied) message += 'کپشن کپی شد. ';
    if (videoSaved) message += 'ویدیو در گالری ذخیره شد. ';
    if (coverSaved) message += 'کاور در گالری ذخیره شد. ';

    return ExportResult(
      captionCopied: captionCopied,
      videoSaved: videoSaved,
      coverSaved: coverSaved,
      message: message.trim(),
    );
  }

  /// Open Android Share Sheet or launch Instagram directly
  static Future<void> shareToInstagram(Post post) async {
    // Copy caption first
    if (post.caption.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: post.caption));
    }

    // If local video exists or can be shared
    if (post.videoUrl != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final tempVideoPath = '${tempDir.path}/${post.id}_share.mp4';
        final tempFile = File(tempVideoPath);

        if (!await tempFile.exists()) {
          final res = await http.get(Uri.parse(post.videoUrl!));
          if (res.statusCode == 200) {
            await tempFile.writeAsBytes(res.bodyBytes);
          }
        }

        if (await tempFile.exists()) {
          await Share.shareXFiles(
            [XFile(tempVideoPath)],
            text: post.caption,
            subject: post.title,
          );
          return;
        }
      } catch (_) {}
    }

    // Fallback: share text
    if (post.caption.isNotEmpty) {
      await Share.share(post.caption, subject: post.title);
    }
  }
}
