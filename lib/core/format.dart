import 'package:intl/intl.dart';

abstract final class Fmt {
  static final NumberFormat _number = NumberFormat.decimalPattern('en_US');
  static final DateFormat _longDate = DateFormat('d MMMM y', 'en_US');
  static final DateFormat _shortDate = DateFormat('d MMM', 'en_US');

  static String money(num value) => 'TSh ${_number.format(value.round())}';

  static String moneyPrecise(num value) => 'TSh ${_number.format(value)}';

  static String number(num value) => _number.format(value.round());

  static String date(DateTime value) => _longDate.format(value);

  static String shortDate(DateTime value) => _shortDate.format(value);

  static String dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static DateTime parseDayKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? DateTime.now().month,
      int.tryParse(parts[2]) ?? DateTime.now().day,
    );
  }

  static bool sameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);

  static DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime startOfWeek(DateTime value) {
    final day = startOfDay(value);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime endOfWeek(DateTime value) {
    final start = startOfWeek(value);
    return DateTime(start.year, start.month, start.day + 7);
  }

  static DateTime startOfMonth(DateTime value) =>
      DateTime(value.year, value.month);

  static DateTime endOfMonth(DateTime value) =>
      DateTime(value.year, value.month + 1);

  static bool inRange(DateTime value, DateTime start, DateTime end) =>
      !value.isBefore(start) && value.isBefore(end);

  static String initials(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return 'MU';
    if (words.length == 1) return words.first.substring(0, 2).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
