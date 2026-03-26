import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/calendar_date_utils.dart';
import '../../data/models/calendar_event.dart';
import '../../../weather/data/models/weather_day.dart';
import 'event_chip.dart';

const int _maxVisibleEvents = 2;

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.date,
    required this.currentMonth,
    this.events = const [],
    this.weather,
    this.onTap,
    this.onEventTap,
  });

  final DateTime date;
  final int currentMonth;
  final List<CalendarEvent> events;
  final WeatherDay? weather;
  final VoidCallback? onTap;
  final void Function(CalendarEvent)? onEventTap;

  bool get _isToday => CalendarDateUtils.isToday(date);
  bool get _isCurrentMonth => date.month == currentMonth;
  bool get _isSunday => date.weekday == DateTime.sunday;

  @override
  Widget build(BuildContext context) {
    final textColor = !_isCurrentMonth
        ? AppColors.textMuted
        : _isSunday
            ? AppColors.sundayRed
            : AppColors.textPrimary;

    final holidays = events.where((e) => e.isHoliday).toList();
    final nonHolidays = events.where((e) => !e.isHoliday).toList();

    final visibleEvents = nonHolidays.take(_maxVisibleEvents).toList();
    final overflowCount = nonHolidays.length - visibleEvents.length;

    // Leading color accent if any event exists
    final firstColor = nonHolidays.isNotEmpty
        ? nonHolidays.first.color
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Day number row
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 3, right: 3),
              child: Row(
                children: [
                  if (firstColor != null)
                    Container(
                      width: 3,
                      height: 14,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: firstColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  _DayNumber(
                    day: date.day,
                    isToday: _isToday,
                    color: textColor,
                  ),
                  if (weather != null && _isCurrentMonth) ...[
                    const Spacer(),
                    _WeatherIcon(weather: weather!),
                  ],
                ],
              ),
            ),

            // Events
            if (_isCurrentMonth) ...[
              ...visibleEvents.map(
                (e) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: EventChip(
                    event: e,
                    onTap: () => onEventTap?.call(e),
                  ),
                ),
              ),
              if (overflowCount > 0)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: OverflowChip(
                    count: overflowCount,
                    color: firstColor ?? AppColors.accent,
                  ),
                ),
              // Holiday label (below events)
              if (holidays.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  child: EventChip(event: holidays.first),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.day,
    required this.isToday,
    required this.color,
  });

  final int day;
  final bool isToday;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (isToday) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.todayCircle,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.todayText,
            height: 1,
          ),
        ),
      );
    }

    return Text(
      '$day',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1,
      ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  const _WeatherIcon({required this.weather});

  final WeatherDay weather;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      weather.iconUrl,
      width: 18,
      height: 18,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
