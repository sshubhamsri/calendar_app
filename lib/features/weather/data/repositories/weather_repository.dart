import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/weather_day.dart';

class WeatherRepository {
  WeatherRepository(this._dio);

  final Dio _dio;

  Future<List<WeatherDay>> fetchForecast({
    required double lat,
    required double lon,
  }) async {
    final cached = _getCached(lat, lon);
    if (cached != null) return cached;

    final response = await _dio.get(
      '${AppConstants.weatherApiBaseUrl}/forecast',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': AppConstants.weatherApiKey,
        'units': 'metric',
        'cnt': 7,
      },
    );

    final list = (response.data['list'] as List)
        .map((e) => WeatherDay.fromApiEntry(e as Map<String, dynamic>))
        .toList();

    await _cache(lat, lon, list);
    return list;
  }

  Future<List<WeatherDay>> fetchForecastByCity(String city) async {
    final response = await _dio.get(
      '${AppConstants.weatherApiBaseUrl}/forecast',
      queryParameters: {
        'q': city,
        'appid': AppConstants.weatherApiKey,
        'units': 'metric',
        'cnt': 7,
      },
    );

    final list = (response.data['list'] as List)
        .map((e) => WeatherDay.fromApiEntry(e as Map<String, dynamic>))
        .toList();

    await _cacheByCity(city, list);
    return list;
  }

  List<WeatherDay>? _getCached(double lat, double lon) {
    final box = Hive.box(AppConstants.weatherBoxName);
    final key = _latLonKey(lat, lon);
    final entry = box.get(key);
    if (entry == null) return null;

    final map = jsonDecode(entry as String) as Map<String, dynamic>;
    final fetchedAt = DateTime.parse(map['fetchedAt'] as String);
    if (DateTime.now().difference(fetchedAt).inHours >=
        AppConstants.weatherCacheDurationHours) {
      return null;
    }

    final days = (map['data'] as List)
        .map((e) => WeatherDay.fromJson(e as Map<String, dynamic>))
        .toList();
    return days;
  }

  Future<void> _cache(
      double lat, double lon, List<WeatherDay> days) async {
    final box = Hive.box(AppConstants.weatherBoxName);
    final key = _latLonKey(lat, lon);
    await box.put(
      key,
      jsonEncode({
        'fetchedAt': DateTime.now().toIso8601String(),
        'data': days.map((d) => d.toJson()).toList(),
      }),
    );
  }

  Future<void> _cacheByCity(String city, List<WeatherDay> days) async {
    final box = Hive.box(AppConstants.weatherBoxName);
    await box.put(
      'city_$city',
      jsonEncode({
        'fetchedAt': DateTime.now().toIso8601String(),
        'data': days.map((d) => d.toJson()).toList(),
      }),
    );
  }

  List<WeatherDay>? getCachedByCity(String city) {
    final box = Hive.box(AppConstants.weatherBoxName);
    final entry = box.get('city_$city');
    if (entry == null) return null;

    final map = jsonDecode(entry as String) as Map<String, dynamic>;
    final fetchedAt = DateTime.parse(map['fetchedAt'] as String);
    if (DateTime.now().difference(fetchedAt).inHours >=
        AppConstants.weatherCacheDurationHours) {
      return null;
    }

    return (map['data'] as List)
        .map((e) => WeatherDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _latLonKey(double lat, double lon) =>
      'latlon_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
}
