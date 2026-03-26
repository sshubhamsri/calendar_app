import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../calendar/data/models/calendar_event.dart';
import '../../../weather/data/models/weather_day.dart';

class WidgetSyncService {
  Future<void> syncToWidget({
    required List<CalendarEvent> events,
    required List<WeatherDay> weatherDays,
    required DateTime selectedDate,
  }) async {
    // Slim payload: only what the widget needs
    final eventsPayload = events.map((e) => {
          'title': e.title,
          'start': e.start.toIso8601String(),
          'end': e.end.toIso8601String(),
          'color': e.color.toARGB32(),
          'isHoliday': e.isHoliday,
          'isAllDay': e.isAllDay,
        }).toList();

    final weatherPayload = weatherDays.map((w) => {
          'date': w.date.toIso8601String(),
          'iconCode': w.iconCode,
          'tempMax': w.tempMax,
        }).toList();

    await Future.wait([
      HomeWidget.saveWidgetData<String>(
        AppConstants.widgetEventsJsonKey,
        jsonEncode(eventsPayload),
      ),
      HomeWidget.saveWidgetData<String>(
        AppConstants.widgetWeatherJsonKey,
        jsonEncode(weatherPayload),
      ),
      HomeWidget.saveWidgetData<String>(
        AppConstants.widgetSelectedDateKey,
        selectedDate.toIso8601String(),
      ),
    ]);

    await HomeWidget.updateWidget(
      name: AppConstants.androidWidgetName,
      iOSName: AppConstants.androidWidgetName,
    );
  }
}

final widgetSyncServiceProvider = Provider<WidgetSyncService>(
  (ref) => WidgetSyncService(),
);
