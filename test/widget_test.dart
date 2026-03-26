import 'package:flutter_test/flutter_test.dart';

import 'package:calendar_app/core/utils/calendar_date_utils.dart';

void main() {
  group('CalendarDateUtils', () {
    test('monthGridDays returns correct count for March 2026', () {
      // March 2026: starts on Sunday (day 7 in ISO weekday)
      final days = CalendarDateUtils.monthGridDays(2026, 3);
      expect(days.length % 7, 0);
    });

    test('isToday returns true for current date', () {
      expect(CalendarDateUtils.isToday(DateTime.now()), isTrue);
    });

    test('isSameDay returns false for different days', () {
      final a = DateTime(2026, 3, 1);
      final b = DateTime(2026, 3, 2);
      expect(CalendarDateUtils.isSameDay(a, b), isFalse);
    });

    test('monthName returns correct abbreviation', () {
      expect(CalendarDateUtils.monthName(3), 'MAR');
      expect(CalendarDateUtils.monthName(12), 'DEC');
    });
  });
}
