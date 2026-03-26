import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/data/models/calendar_event.dart';
import '../../features/calendar/domain/providers/calendar_provider.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/calendar/presentation/screens/create_edit_event_screen.dart';
import '../../features/calendar/presentation/screens/event_detail_screen.dart';
import '../../features/calendar/presentation/screens/permission_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/permission',
    redirect: (context, state) {
      final granted = ref.read(calendarPermissionProvider).valueOrNull;
      final onPermission = state.matchedLocation == '/permission';

      if (granted == true && onPermission) return '/';
      if (granted == false && !onPermission) return '/permission';
      return null;
    },
    routes: [
      GoRoute(
        path: '/permission',
        builder: (context, state) => const PermissionScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (_, state) {
          final event = state.extra as CalendarEvent;
          return EventDetailScreen(event: event);
        },
      ),
      GoRoute(
        path: '/create-event',
        builder: (_, state) => CreateEditEventScreen(
          existingEvent: state.extra as CalendarEvent?,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
