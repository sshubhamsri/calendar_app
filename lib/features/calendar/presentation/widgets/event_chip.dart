import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/calendar_event.dart';

class EventChip extends StatelessWidget {
  const EventChip({
    super.key,
    required this.event,
    this.onTap,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (event.isHoliday) {
      return _HolidayLabel(title: event.title);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 16,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: event.color.withAlpha(230),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}

class OverflowChip extends StatelessWidget {
  const OverflowChip({super.key, required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(180),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          height: 1.7,
        ),
      ),
    );
  }
}

class _HolidayLabel extends StatelessWidget {
  const _HolidayLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9,
          color: AppColors.holidayText,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
