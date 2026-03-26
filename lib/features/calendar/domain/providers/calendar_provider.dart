import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/calendar_event.dart';
import '../../data/models/calendar_source.dart';
import '../../data/repositories/calendar_repository.dart';

// --- Repository provider ---

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepository(),
);

// --- Permission state ---

final calendarPermissionProvider =
    StateNotifierProvider<CalendarPermissionNotifier, AsyncValue<bool>>(
  (ref) => CalendarPermissionNotifier(
    ref.watch(calendarRepositoryProvider),
  ),
);

class CalendarPermissionNotifier
    extends StateNotifier<AsyncValue<bool>> {
  CalendarPermissionNotifier(this._repo) : super(const AsyncValue.loading()) {
    _check();
  }

  final CalendarRepository _repo;

  Future<void> _check() async {
    final granted = await _repo.hasReadPermission();
    state = AsyncValue.data(granted);
  }

  Future<void> request() async {
    state = const AsyncValue.loading();
    final granted = await _repo.requestReadPermission();
    state = AsyncValue.data(granted);
  }
}

// --- Calendars list ---

final calendarSourcesProvider =
    StateNotifierProvider<CalendarSourcesNotifier, AsyncValue<List<CalendarSource>>>(
  (ref) => CalendarSourcesNotifier(ref.watch(calendarRepositoryProvider)),
);

class CalendarSourcesNotifier
    extends StateNotifier<AsyncValue<List<CalendarSource>>> {
  CalendarSourcesNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetch();
  }

  final CalendarRepository _repo;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final sources = await _repo.fetchAllCalendars();
      state = AsyncValue.data(sources);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSource(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.map((s) {
      if (s.id == id) return s.copyWith(isSelected: !s.isSelected);
      return s;
    }).toList();
    state = AsyncValue.data(updated);
    await _repo.saveSelectedCalendarIds(
      updated.where((s) => s.isSelected).map((s) => s.id).toList(),
    );
  }
}

// --- Selected month ---

final selectedMonthProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

// --- Events for selected month ---

final monthEventsProvider = StateNotifierProvider<MonthEventsNotifier,
    AsyncValue<List<CalendarEvent>>>((ref) {
  final repo = ref.watch(calendarRepositoryProvider);
  final month = ref.watch(selectedMonthProvider);
  final sources = ref.watch(calendarSourcesProvider).valueOrNull ?? [];
  return MonthEventsNotifier(repo, month, sources);
});

class MonthEventsNotifier
    extends StateNotifier<AsyncValue<List<CalendarEvent>>> {
  MonthEventsNotifier(this._repo, this._month, this._sources)
      : super(const AsyncValue.loading()) {
    _loadFromCacheThenFetch();
  }

  final CalendarRepository _repo;
  final DateTime _month;
  final List<CalendarSource> _sources;

  Future<void> _loadFromCacheThenFetch() async {
    // Show cached immediately for snappy UI
    final cached =
        _repo.getCachedEventsForMonth(_month.year, _month.month);
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    }

    final selectedIds = _sources
        .where((s) => s.isSelected)
        .map((s) => s.id)
        .toList();
    if (selectedIds.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final events = await _repo.fetchEventsForMonth(
        calendarIds: selectedIds,
        year: _month.year,
        month: _month.month,
      );
      state = AsyncValue.data(events);
    } catch (e, st) {
      if (state.valueOrNull == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() => _loadFromCacheThenFetch();

  Future<void> deleteEvent(String calendarId, String eventId) async {
    await _repo.deleteEvent(calendarId, eventId);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.where((e) => e.id != eventId).toList(),
    );
  }
}

// --- Events grouped by date (for day cell lookup) ---

final eventsByDateProvider =
    Provider<Map<DateTime, List<CalendarEvent>>>((ref) {
  final events = ref.watch(monthEventsProvider).valueOrNull ?? [];
  final map = <DateTime, List<CalendarEvent>>{};
  for (final event in events) {
    final day = DateTime(
        event.start.year, event.start.month, event.start.day);
    map.putIfAbsent(day, () => []).add(event);
  }
  return map;
});
