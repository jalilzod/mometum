import 'package:intl/intl.dart';

import '../l10n/strings.dart';

/// Locale-aware formatting. Uses `S.current` and `Intl.defaultLocale`, which
/// the app keeps in sync with the selected language.
abstract final class Fmt {
  static S get _s => S.current;

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  static String time(DateTime d) => DateFormat.jm().format(d);

  /// "Today, 3:00 PM", "Tomorrow, 9:00 AM", "Mon, 3:00 PM", "Dec 4, 3:00 PM".
  static String due(DateTime d, [DateTime? now]) {
    now ??= DateTime.now();
    final days = dayStart(d).difference(dayStart(now)).inDays;
    final t = time(d);
    if (days == 0) return '${_s.today}, $t';
    if (days == 1) return '${_s.tomorrow}, $t';
    if (days == -1) return '${_s.yesterday}, $t';
    if (days > 1 && days < 7) return '${_cap(DateFormat.E().format(d))}, $t';
    if (d.year == now.year) return '${DateFormat.MMMd().format(d)}, $t';
    return '${DateFormat.yMMMd().format(d)}, $t';
  }

  /// "in 2h 10m" / "2h 10m overdue".
  static String relative(DateTime d, [DateTime? now]) {
    now ??= DateTime.now();
    final diff = d.difference(now);
    final s = compact(diff.abs());
    return diff.isNegative ? _s.overdueBy(s) : _s.inTime(s);
  }

  static String compact(Duration d) {
    final s = _s;
    if (d.inDays >= 1) return '${d.inDays}${s.unitD} ${d.inHours % 24}${s.unitH}';
    if (d.inHours >= 1) return '${d.inHours}${s.unitH} ${d.inMinutes % 60}${s.unitM}';
    if (d.inMinutes >= 1) return '${d.inMinutes}${s.unitM}';
    return '${d.inSeconds}${s.unitS}';
  }

  /// 01:23:45 style stopwatch.
  static String clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  static String hours(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes}${_s.unitM}';
    final h = d.inMinutes / 60;
    return '${h.toStringAsFixed(h >= 10 ? 0 : 1)}${_s.unitH}';
  }

  static String reminder(int? minutes) {
    if (minutes == null) return _s.reminderNone;
    if (minutes == 0) return _s.reminderAtTime;
    if (minutes < 60) return _s.reminderMin(minutes);
    if (minutes < 1440) return _s.reminderHours(minutes ~/ 60);
    return _s.reminderDays(minutes ~/ 1440);
  }

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 5) return _s.greetLate;
    if (h < 12) return _s.greetMorning;
    if (h < 17) return _s.greetAfternoon;
    return _s.greetEvening;
  }

  static String longDate(DateTime d) => _cap(DateFormat.MMMMEEEEd().format(d));

  /// "1 PM" / "13:00" for an hour of the day.
  static String hour(int h) => DateFormat.j().format(DateTime(2000, 1, 1, h));

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
