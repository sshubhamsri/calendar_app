import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/calendar_event.dart';
import '../../domain/providers/calendar_provider.dart';

class DayEventsScreen extends ConsumerStatefulWidget {
  const DayEventsScreen({super.key, required this.date});

  final DateTime date;

  @override
  ConsumerState<DayEventsScreen> createState() => _DayEventsScreenState();
}

class _DayEventsScreenState extends ConsumerState<DayEventsScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure the events provider loads for the right month.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedMonthProvider.notifier).state =
          DateTime(widget.date.year, widget.date.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('EEE, MMM d, yyyy').format(widget.date);
    final eventsAsync = ref.watch(monthEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'day_add_event',
        onPressed: () => context.push('/create-event'),
        child: const Icon(Icons.add),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: const Text(
                    'Could not load events',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
        ),
        data: (events) {
          final dayEvents = events.where((e) {
            final s = e.start;
            return s.year == widget.date.year &&
                s.month == widget.date.month &&
                s.day == widget.date.day;
          }).toList()
            ..sort((a, b) {
              if (a.isAllDay && !b.isAllDay) return -1;
              if (!a.isAllDay && b.isAllDay) return 1;
              return a.start.compareTo(b.start);
            });

          if (dayEvents.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    'No events',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: dayEvents.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) =>
                _EventTile(event: dayEvents[index]),
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final timeLabel = event.isAllDay
        ? 'All day'
        : '${timeFormat.format(event.start)} – ${timeFormat.format(event.end)}';

    return InkWell(
      onTap: () => context.push('/event/${event.id}', extra: event),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: event.isHoliday ? AppColors.holidayText : event.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!event.isHoliday)
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
