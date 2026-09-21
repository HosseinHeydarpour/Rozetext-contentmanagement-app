class ShamsiHelper {
  static const List<String> persianMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  static const List<String> persianWeekdays = [
    'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه', 'یکشنبه'
  ];

  /// Converts Gregorian date to Jalali (Solar Hijri) [year, month, day]
  static List<int> gregorianToJalali(int gy, int gm, int gd) {
    final gDM = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    int jy = (gy <= 1600) ? 0 : 979;
    gy -= (gy <= 1600) ? 621 : 1600;
    final gy2 = (gm > 2) ? (gy + 1) : gy;
    int days = (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) -
        80 +
        gd +
        gDM[gm - 1];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    jy += (days - 1) ~/ 365;
    if (days > 0) days = (days - 1) % 365;
    final jm = (days < 186) ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
    final jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
    return [jy, jm, jd];
  }

  /// Formats a DateTime to Persian string: "چهارشنبه ۱۵ مهر ۱۴۰۳ - ساعت ۱۸:۳۰"
  static String formatFull(DateTime dateTime) {
    final j = gregorianToJalali(dateTime.year, dateTime.month, dateTime.day);
    final weekdayName = persianWeekdays[dateTime.weekday - 1];
    final monthName = persianMonths[j[1] - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$weekdayName ${toPersianDigits(j[2].toString())} $monthName ${toPersianDigits(j[0].toString())} - ساعت ${toPersianDigits('$hour:$minute')}';
  }

  /// Formats short date: "۱۵ مهر"
  static String formatShort(DateTime dateTime) {
    final j = gregorianToJalali(dateTime.year, dateTime.month, dateTime.day);
    final monthName = persianMonths[j[1] - 1];
    return '${toPersianDigits(j[2].toString())} $monthName';
  }

  /// Converts English digits to Persian digits
  static String toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], persian[i]);
    }
    return input;
  }

  /// Returns relative day label (امروز, فردا, دیروز, etc.)
  static String getRelativeDayLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'امروز';
    if (diff == 1) return 'فردا';
    if (diff == -1) return 'دیروز';
    if (diff > 1 && diff < 7) return 'تا $diff روز آینده';
    return formatShort(dateTime);
  }
}
