class AppConstants {
  AppConstants._();

  // Home widget identifiers
  static const String androidWidgetName = 'CalendarWidget';
  static const String androidWidgetAuthor = 'com.naehas.calendar_app';

  // Hive box names
  static const String eventsBoxName = 'calendar_events';
  static const String weatherBoxName = 'weather_cache';
  static const String settingsBoxName = 'app_settings';

  // Hive keys
  static const String selectedCalendarIdsKey = 'selected_calendar_ids';
  static const String weatherCityKey = 'weather_city';
  static const String weatherLatKey = 'weather_lat';
  static const String weatherLonKey = 'weather_lon';
  static const String useAutoLocationKey = 'use_auto_location';

  // home_widget shared keys
  static const String widgetEventsJsonKey = 'events_json';
  static const String widgetWeatherJsonKey = 'weather_json';
  static const String widgetSelectedDateKey = 'selected_date';

  // Weather API
  static const String weatherApiBaseUrl = 'https://api.openweathermap.org/data/2.5';
  // API key should be passed via --dart-define=WEATHER_API_KEY=<key>
  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: '',
  );
  static const int weatherCacheDurationHours = 3;

  // Calendar
  static const int monthPreloadBuffer = 1;
}
