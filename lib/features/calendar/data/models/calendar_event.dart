import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String calendarId;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;
  final bool isAllDay;
  final String? description;
  final String? location;
  final bool isHoliday;

  const CalendarEvent({
    required this.id,
    required this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
    this.isAllDay = false,
    this.description,
    this.location,
    this.isHoliday = false,
  });

  bool get isMultiDay =>
      end.difference(start).inDays >= 1 &&
      !(isAllDay && end.difference(start).inDays == 1);

  CalendarEvent copyWith({
    String? id,
    String? calendarId,
    String? title,
    DateTime? start,
    DateTime? end,
    Color? color,
    bool? isAllDay,
    String? description,
    String? location,
    bool? isHoliday,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      description: description,
      location: location,
      isHoliday: isHoliday ?? this.isHoliday,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'calendarId': calendarId,
        'title': title,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'color': color.toARGB32(),
        'isAllDay': isAllDay,
        'description': description,
        'location': location,
        'isHoliday': isHoliday,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        calendarId: json['calendarId'] as String,
        title: json['title'] as String,
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        color: Color(json['color'] as int),
        isAllDay: json['isAllDay'] as bool? ?? false,
        description: json['description'] as String?,
        location: json['location'] as String?,
        isHoliday: json['isHoliday'] as bool? ?? false,
      );
}
