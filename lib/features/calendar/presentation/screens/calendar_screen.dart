import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/calendar_date_utils.dart';
import '../../domain/providers/calendar_provider.dart';
import '../../../weather/domain/providers/weather_provider.dart';
import '../../../widget_sync/domain/providers/widget_sync_provider.dart';
import '../widgets/calendar_grid.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late PageController _pageController;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncWidget() {
    final events = ref.read(monthEventsProvider).valueOrNull ?? [];
    final weather = ref.read(weatherForecastProvider).valueOrNull ?? [];
    ref.read(widgetSyncServiceProvider).syncToWidget(
          events: events,
          weatherDays: weather,
          selectedDate: _currentMonth,
        );
  }

  void _goToPreviousMonth() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextMonth() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToToday() {
    _pageController.animateToPage(
      1000,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  DateTime _monthFromPage(int page) {
    final now = DateTime.now();
    final delta = page - 1000;
    return DateTime(now.year, now.month + delta);
  }

  @override
  Widget build(BuildContext context) {
    // Trigger widget sync when events load
    ref.listen(monthEventsProvider, (_, next) {
      if (next.hasValue) _syncWidget();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              month: _currentMonth,
              onPrevious: _goToPreviousMonth,
              onNext: _goToNextMonth,
              onTodayTap: _goToToday,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  final newMonth = _monthFromPage(page);
                  setState(() => _currentMonth = newMonth);
                  ref.read(selectedMonthProvider.notifier).state = newMonth;
                },
                itemBuilder: (context, page) {
                  final month = _monthFromPage(page);
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    child: CalendarGrid(
                      month: month,
                      onDayTap: (date) =>
                          context.push('/day/${ date.toIso8601String()}'),
                      onEventTap: (event) =>
                          context.push('/event/${event.id}', extra: event),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_event',
        onPressed: () => context.push('/create-event'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onTodayTap,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTodayTap;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Previous
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          // Month name
          Text(
            CalendarDateUtils.monthName(month.month),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 4),
          // Next
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          // Add event (also on FAB but here as icon)
          IconButton(
            onPressed: () => GoRouter.of(context).push('/create-event'),
            icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Today indicator
          GestureDetector(
            onTap: _isCurrentMonth ? null : onTodayTap,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textPrimary, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${DateTime.now().day}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Settings
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => GoRouter.of(context).push('/settings'),
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
