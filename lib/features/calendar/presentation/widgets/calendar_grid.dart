import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/calendar_date_utils.dart';
import '../../data/models/calendar_event.dart';
import '../../domain/providers/calendar_provider.dart';
import '../../../weather/domain/providers/weather_provider.dart';
import 'day_cell.dart';
import 'week_number_column.dart';

class CalendarGrid extends ConsumerWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    this.onDayTap,
    this.onEventTap,
  });

  final DateTime month;
  final void Function(DateTime)? onDayTap;
  final void Function(CalendarEvent)? onEventTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridDays =
        CalendarDateUtils.monthGridDays(month.year, month.month);
    final weekNumbers =
        CalendarDateUtils.weekNumbersForGrid(gridDays);
    final eventsByDate = ref.watch(eventsByDateProvider);
    final weatherByDate = ref.watch(weatherByDateProvider);

    final rowCount = gridDays.length ~/ 7;

    return Column(
      children: [
        // Day-of-week header
        _DayHeader(),

        // Grid body
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Week numbers
              SizedBox(
                width: 24,
                child: WeekNumberColumn(weekNumbers: weekNumbers),
              ),
              // Calendar cells
              Expanded(
                child: Column(
                  children: List.generate(rowCount, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(7, (col) {
                          final date = gridDays[row * 7 + col];
                          final dayKey = DateTime(
                              date.year, date.month, date.day);
                          final events = eventsByDate[dayKey] ?? [];
                          final weather = weatherByDate[dayKey];
                          return Expanded(
                            child: DayCell(
                              date: date,
                              currentMonth: month.month,
                              events: events,
                              weather: weather,
                              onTap: () => onDayTap?.call(date),
                              onEventTap: onEventTap,
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Row(
        children: _labels.asMap().entries.map((entry) {
          final isSunday = entry.key == 6;
          return Expanded(
            child: Center(
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSunday
                      ? AppColors.sundayRed
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
