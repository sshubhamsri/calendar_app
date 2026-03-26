import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/calendar_event.dart';
import '../../domain/providers/calendar_provider.dart';

class CreateEditEventScreen extends ConsumerStatefulWidget {
  const CreateEditEventScreen({super.key, this.existingEvent});

  final CalendarEvent? existingEvent;

  @override
  ConsumerState<CreateEditEventScreen> createState() =>
      _CreateEditEventScreenState();
}

class _CreateEditEventScreenState
    extends ConsumerState<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isAllDay = false;
  String? _selectedCalendarId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    if (existing != null) {
      _titleController.text = existing.title;
      _descController.text = existing.description ?? '';
      _locationController.text = existing.location ?? '';
      _startDate = existing.start;
      _endDate = existing.end;
      _startTime = TimeOfDay.fromDateTime(existing.start);
      _endTime = TimeOfDay.fromDateTime(existing.end);
      _isAllDay = existing.isAllDay;
      _selectedCalendarId = existing.calendarId;
    } else {
      final now = DateTime.now();
      _startDate = now;
      _endDate = now;
      _startTime = TimeOfDay.fromDateTime(now);
      _endTime =
          TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources =
        ref.watch(calendarSourcesProvider).valueOrNull ?? [];
    final writableSources = sources.where((s) => !s.isReadOnly).toList();
    _selectedCalendarId ??=
        writableSources.isNotEmpty ? writableSources.first.id : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
            widget.existingEvent == null ? 'New Event' : 'Edit Event'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // All day toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All day',
                  style: TextStyle(color: AppColors.textPrimary)),
              value: _isAllDay,
              activeThumbColor: AppColors.accent,
              onChanged: (v) => setState(() => _isAllDay = v),
            ),

            // Dates
            _DateRow(
              label: 'Start',
              date: _startDate,
              time: _startTime,
              showTime: !_isAllDay,
              onDateTap: () => _pickDate(isStart: true),
              onTimeTap: () => _pickTime(isStart: true),
            ),
            _DateRow(
              label: 'End',
              date: _endDate,
              time: _endTime,
              showTime: !_isAllDay,
              onDateTap: () => _pickDate(isStart: false),
              onTimeTap: () => _pickTime(isStart: false),
            ),
            const SizedBox(height: 16),

            // Calendar selector
            if (writableSources.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedCalendarId,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(labelText: 'Calendar'),
                items: writableSources
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: s.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(s.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCalendarId = v),
              ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCalendarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No writable calendar available')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final start = _isAllDay
        ? DateTime(
            _startDate.year, _startDate.month, _startDate.day)
        : DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime.hour,
            _startTime.minute,
          );
    final end = _isAllDay
        ? DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59)
        : DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            _endTime.hour,
            _endTime.minute,
          );

    final event = CalendarEvent(
      id: widget.existingEvent?.id ?? '',
      calendarId: _selectedCalendarId!,
      title: _titleController.text.trim(),
      start: start,
      end: end,
      color: AppColors.accent,
      isAllDay: _isAllDay,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );

    await ref.read(calendarRepositoryProvider).createEvent(event);
    await ref.read(monthEventsProvider.notifier).refresh();

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.cardBackground),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.cardBackground),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.time,
    required this.showTime,
    required this.onDateTap,
    required this.onTimeTap,
  });

  final String label;
  final DateTime date;
  final TimeOfDay time;
  final bool showTime;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(date);
    final timeStr = time.format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: onDateTap,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.accent),
            child: Text(dateStr),
          ),
          if (showTime)
            TextButton(
              onPressed: onTimeTap,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary),
              child: Text(timeStr),
            ),
        ],
      ),
    );
  }
}
