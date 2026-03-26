import 'dart:convert';

import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/calendar_date_utils.dart';
import '../models/calendar_event.dart';
import '../models/calendar_source.dart';

class CalendarRepository {
  CalendarRepository() : _plugin = DeviceCalendar();

  final DeviceCalendar _plugin;

  // --- Permission ---

  Future<bool> requestReadPermission() async {
    final status = await _plugin.requestPermissions();
    return status == CalendarPermissionStatus.granted;
  }

  Future<bool> hasReadPermission() async {
    final status = await _plugin.hasPermissions();
    return status == CalendarPermissionStatus.granted;
  }

  // --- Calendar Sources ---

  Future<List<CalendarSource>> fetchAllCalendars() async {
    final calendars = await _plugin.listCalendars();
    final selectedIds = _selectedCalendarIds();

    return calendars.map((cal) {
      final color = _parseColor(cal.colorHex);
      return CalendarSource(
        id: cal.id,
        name: cal.name,
        color: color,
        isReadOnly: cal.readOnly,
        isSelected: selectedIds.isEmpty || selectedIds.contains(cal.id),
      );
    }).toList();
  }

  Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFF4A90D9);
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return const Color(0xFF4A90D9);
  }

  Set<String> _selectedCalendarIds() {
    final box = Hive.box(AppConstants.settingsBoxName);
    final stored = box.get(AppConstants.selectedCalendarIdsKey);
    if (stored == null) return {};
    return Set<String>.from(jsonDecode(stored as String) as List);
  }

  Future<void> saveSelectedCalendarIds(List<String> ids) async {
    final box = Hive.box(AppConstants.settingsBoxName);
    await box.put(AppConstants.selectedCalendarIdsKey, jsonEncode(ids));
  }

  // --- Events ---

  Future<List<CalendarEvent>> fetchEventsForRange({
    required List<String> calendarIds,
    required DateTime start,
    required DateTime end,
  }) async {
    final rawEvents = await _plugin.listEvents(
      start,
      end,
      calendarIds: calendarIds,
    );

    final events = rawEvents.map(_mapEvent).toList();
    await _cacheEvents(events, start);
    return events;
  }

  CalendarEvent _mapEvent(Event e) {
    return CalendarEvent(
      id: e.instanceId,
      calendarId: e.calendarId,
      title: e.title,
      start: e.startDate,
      end: e.endDate,
      color: const Color(0xFF4A90D9),
      isAllDay: e.isAllDay,
      description: e.description,
      location: e.location,
    );
  }

  Future<void> _cacheEvents(
      List<CalendarEvent> events, DateTime monthStart) async {
    final box = Hive.box(AppConstants.eventsBoxName);
    final key = '${monthStart.year}_${monthStart.month}';
    final json = jsonEncode(events.map((e) => e.toJson()).toList());
    await box.put(key, json);
  }

  List<CalendarEvent> getCachedEventsForMonth(int year, int month) {
    final box = Hive.box(AppConstants.eventsBoxName);
    final key = '${year}_$month';
    final raw = box.get(key);
    if (raw == null) return [];
    final list = jsonDecode(raw as String) as List;
    return list
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Create / Delete ---

  Future<String?> createEvent(CalendarEvent event) async {
    return await _plugin.createEvent(
      calendarId: event.calendarId,
      title: event.title,
      startDate: event.start,
      endDate: event.end,
      isAllDay: event.isAllDay,
      description: event.description,
      location: event.location,
    );
  }

  Future<void> deleteEvent(String calendarId, String eventId) async {
    await _plugin.deleteEvent(eventId: eventId);
  }

  Future<List<CalendarEvent>> fetchEventsForMonth({
    required List<String> calendarIds,
    required int year,
    required int month,
  }) async {
    final start = CalendarDateUtils.firstDayOfMonth(DateTime(year, month));
    final end = CalendarDateUtils.lastDayOfMonth(DateTime(year, month));
    return fetchEventsForRange(
      calendarIds: calendarIds,
      start: CalendarDateUtils.startOfDay(start),
      end: CalendarDateUtils.endOfDay(end),
    );
  }
}
