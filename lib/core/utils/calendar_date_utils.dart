class CalendarDateUtils {
  CalendarDateUtils._();

  /// Returns the ISO 8601 week number for the given [date].
  static int weekNumber(DateTime date) {
    final dayOfYear = int.parse(
      date.difference(DateTime(date.year, 1, 1)).inDays.toString(),
    );
    // Week 1 is the week containing the first Thursday of the year.
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      return weekNumber(DateTime(date.year - 1, 12, 31));
    }
    if (woy > 52) {
      final dec31 = DateTime(date.year, 12, 31);
      if (dec31.weekday >= 4) return 1;
    }
    return woy;
  }

  /// Returns a list of [DateTime] representing all days in the calendar grid
  /// for the given [year] and [month], starting from Monday.
  /// Includes leading/trailing days from adjacent months to complete the grid.
  static List<DateTime> monthGridDays(int year, int month) {
    final firstOfMonth = DateTime(year, month, 1);
    final lastOfMonth = DateTime(year, month + 1, 0);

    // Monday = 1, Sunday = 7
    final leadingDays = (firstOfMonth.weekday - 1) % 7;
    final trailingDays = (7 - lastOfMonth.weekday) % 7;

    final start = firstOfMonth.subtract(Duration(days: leadingDays));
    final totalDays = lastOfMonth.day + leadingDays + trailingDays;

    return List.generate(
      totalDays,
      (i) => start.add(Duration(days: i)),
    );
  }

  /// Returns the distinct week numbers present in a calendar grid.
  static List<int> weekNumbersForGrid(List<DateTime> gridDays) {
    final seen = <int>{};
    final result = <int>[];
    for (final day in gridDays) {
      final w = weekNumber(day);
      if (!seen.contains(w)) {
        seen.add(w);
        result.add(w);
      }
    }
    return result;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  static DateTime firstDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime lastDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  /// Returns the name of the month (e.g. "MAR").
  static String monthName(int month) {
    const names = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return names[month - 1];
  }
}
