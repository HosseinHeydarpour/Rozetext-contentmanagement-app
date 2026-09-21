import '../utils/shamsi_helper.dart';

class Post {
  final String id;
  final String title;
  final String caption;
  final String? videoUrl;
  final String? coverUrl;
  final DateTime scheduledDate;
  final String? shamsiDate;
  bool isPosted;
  DateTime? postedAt;
  final DateTime createdAt;
  final String? notes;
  final String? source;

  Post({
    required this.id,
    required this.title,
    required this.caption,
    this.videoUrl,
    this.coverUrl,
    required this.scheduledDate,
    this.shamsiDate,
    this.isPosted = false,
    this.postedAt,
    required this.createdAt,
    this.notes,
    this.source,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    DateTime parsedScheduled;
    try {
      parsedScheduled = DateTime.parse(json['scheduledDate'] as String);
    } catch (_) {
      parsedScheduled = DateTime.now();
    }

    DateTime parsedCreated;
    try {
      parsedCreated = DateTime.parse(json['createdAt'] as String);
    } catch (_) {
      parsedCreated = DateTime.now();
    }

    DateTime? parsedPostedAt;
    if (json['postedAt'] != null) {
      try {
        parsedPostedAt = DateTime.parse(json['postedAt'] as String);
      } catch (_) {}
    }

    return Post(
      id: json['id'] as String? ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'بدون عنوان',
      caption: json['caption'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      scheduledDate: parsedScheduled,
      shamsiDate: json['shamsiDate'] as String?,
      isPosted: json['isPosted'] == true,
      postedAt: parsedPostedAt,
      createdAt: parsedCreated,
      notes: json['notes'] as String?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'caption': caption,
      'videoUrl': videoUrl,
      'coverUrl': coverUrl,
      'scheduledDate': scheduledDate.toIso8601String(),
      'shamsiDate': shamsiDate,
      'isPosted': isPosted,
      'postedAt': postedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'source': source,
    };
  }

  /// Returns Persian Shamsi date string
  String get displayShamsiDate {
    if (shamsiDate != null && shamsiDate!.isNotEmpty) {
      return shamsiDate!;
    }
    return ShamsiHelper.formatFull(scheduledDate);
  }

  /// Relative date label (امروز, فردا, ...)
  String get relativeLabel => ShamsiHelper.getRelativeDayLabel(scheduledDate);

  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return scheduledDate.year == tomorrow.year &&
        scheduledDate.month == tomorrow.month &&
        scheduledDate.day == tomorrow.day;
  }

  bool get isPast {
    return scheduledDate.isBefore(DateTime.now()) && !isToday;
  }

  bool get isUpcoming {
    return scheduledDate.isAfter(DateTime.now()) && !isToday && !isTomorrow;
  }
}
