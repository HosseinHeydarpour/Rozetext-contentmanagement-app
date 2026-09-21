import 'package:flutter_test/flutter_test.dart';
import '../lib/models/post.dart';
import '../lib/utils/shamsi_helper.dart';

void main() {
  group('ShamsiHelper Tests', () {
    test('Converts Gregorian date to Jalali correctly', () {
      // 2026-03-21 is approximately 1405/01/01 (Nowruz)
      final jalali = ShamsiHelper.gregorianToJalali(2024, 3, 20);
      expect(jalali[0], 1403);
      expect(jalali[1], 1);
      expect(jalali[2], 1);
    });

    test('Converts English digits to Persian digits', () {
      final persian = ShamsiHelper.toPersianDigits('2024/09/21');
      expect(persian, '۲۰۲۴/۰۹/۲۱');
    });

    test('Relative label identifies today', () {
      final now = DateTime.now();
      final label = ShamsiHelper.getRelativeDayLabel(now);
      expect(label, 'امروز');
    });
  });

  group('Post Model Tests', () {
    test('Serializes and deserializes JSON correctly', () {
      final json = {
        'id': 'post_test_123',
        'title': 'پست تستی',
        'caption': 'متن کپشن تستی #اینستاگرام',
        'videoUrl': 'http://192.168.1.50:3000/media/video.mp4',
        'coverUrl': 'http://192.168.1.50:3000/media/cover.jpg',
        'scheduledDate': '2026-10-15T18:30:00.000Z',
        'shamsiDate': '۱۴۰۵/۰۷/۲۳ - ۱۸:۳۰',
        'isPosted': false,
        'createdAt': '2026-09-21T10:00:00.000Z',
        'notes': 'یادداشت تستی',
        'source': 'dashboard',
      };

      final post = Post.fromJson(json);

      expect(post.id, 'post_test_123');
      expect(post.title, 'پست تستی');
      expect(post.isPosted, false);
      expect(post.videoUrl, 'http://192.168.1.50:3000/media/video.mp4');

      // Check toJson
      final serialized = post.toJson();
      expect(serialized['id'], 'post_test_123');
      expect(serialized['title'], 'پست تستی');
      expect(serialized['isPosted'], false);
    });
  });
}
