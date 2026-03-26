import 'package:flutter/material.dart';

class CalendarSource {
  final String id;
  final String name;
  final Color color;
  final bool isReadOnly;
  bool isSelected;

  CalendarSource({
    required this.id,
    required this.name,
    required this.color,
    this.isReadOnly = false,
    this.isSelected = true,
  });

  CalendarSource copyWith({
    String? id,
    String? name,
    Color? color,
    bool? isReadOnly,
    bool? isSelected,
  }) {
    return CalendarSource(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'isReadOnly': isReadOnly,
        'isSelected': isSelected,
      };

  factory CalendarSource.fromJson(Map<String, dynamic> json) => CalendarSource(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        isReadOnly: json['isReadOnly'] as bool? ?? false,
        isSelected: json['isSelected'] as bool? ?? true,
      );
}
