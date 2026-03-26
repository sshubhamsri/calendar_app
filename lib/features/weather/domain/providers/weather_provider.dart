import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/weather_day.dart';
import '../../data/repositories/weather_repository.dart';

final _dioProvider = Provider<Dio>((ref) => Dio());

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => WeatherRepository(ref.watch(_dioProvider)),
);

final weatherSettingsProvider =
    StateNotifierProvider<WeatherSettingsNotifier, WeatherSettings>(
  (ref) => WeatherSettingsNotifier(),
);

class WeatherSettings {
  final bool useAutoLocation;
  final String city;
  final double? lat;
  final double? lon;

  const WeatherSettings({
    this.useAutoLocation = false,
    this.city = '',
    this.lat,
    this.lon,
  });
}

class WeatherSettingsNotifier extends StateNotifier<WeatherSettings> {
  WeatherSettingsNotifier() : super(const WeatherSettings()) {
    _load();
  }

  void _load() {
    final box = Hive.box(AppConstants.settingsBoxName);
    state = WeatherSettings(
      useAutoLocation:
          box.get(AppConstants.useAutoLocationKey, defaultValue: false)
              as bool,
      city: box.get(AppConstants.weatherCityKey, defaultValue: '') as String,
      lat: box.get(AppConstants.weatherLatKey) as double?,
      lon: box.get(AppConstants.weatherLonKey) as double?,
    );
  }

  Future<void> setCity(String city) async {
    final box = Hive.box(AppConstants.settingsBoxName);
    await box.put(AppConstants.weatherCityKey, city);
    await box.put(AppConstants.useAutoLocationKey, false);
    state = WeatherSettings(city: city, useAutoLocation: false);
  }

  Future<bool> enableAutoLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return false;

    final position = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.low),
    );

    final box = Hive.box(AppConstants.settingsBoxName);
    await box.put(AppConstants.useAutoLocationKey, true);
    await box.put(AppConstants.weatherLatKey, position.latitude);
    await box.put(AppConstants.weatherLonKey, position.longitude);

    state = WeatherSettings(
      useAutoLocation: true,
      lat: position.latitude,
      lon: position.longitude,
    );
    return true;
  }

  Future<void> disableAutoLocation() async {
    final box = Hive.box(AppConstants.settingsBoxName);
    await box.put(AppConstants.useAutoLocationKey, false);
    state = WeatherSettings(
      city: state.city,
      useAutoLocation: false,
    );
  }
}

final weatherForecastProvider =
    FutureProvider<List<WeatherDay>>((ref) async {
  final repo = ref.watch(weatherRepositoryProvider);
  final settings = ref.watch(weatherSettingsProvider);

  if (settings.useAutoLocation &&
      settings.lat != null &&
      settings.lon != null) {
    return repo.fetchForecast(lat: settings.lat!, lon: settings.lon!);
  }

  if (settings.city.isNotEmpty) {
    final cached = repo.getCachedByCity(settings.city);
    if (cached != null) return cached;
    return repo.fetchForecastByCity(settings.city);
  }

  return [];
});

// Map of date -> WeatherDay for quick lookup in day cells
final weatherByDateProvider =
    Provider<Map<DateTime, WeatherDay>>((ref) {
  final forecast = ref.watch(weatherForecastProvider).valueOrNull ?? [];
  return {
    for (final w in forecast)
      DateTime(w.date.year, w.date.month, w.date.day): w,
  };
});
