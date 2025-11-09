import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

/// Service for fetching weather data from OpenWeatherMap API
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // OpenWeatherMap API Key
  static const String _apiKey = '2bcdd31403466596c80115eb4c57f955';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // Default location (Ho Chi Minh City, District 12 coordinates)
  static const double _defaultLat = 10.8500;
  static const double _defaultLon = 106.6500;
  static const String _defaultLocationName = 'P. Trung Mỹ Tây';

  /// Fetch weather data from OpenWeatherMap API
  /// Uses GPS coordinates if provided, otherwise uses default location
  Future<WeatherModel> fetchWeather({
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      final lat = latitude ?? _defaultLat;
      final lon = longitude ?? _defaultLon;
      final locName = locationName ?? _defaultLocationName;

      final uri = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherModel.fromOpenWeatherMap(data, locName);
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if API fails
      debugPrint('Error fetching weather from API: $e');
      return _getFallbackWeather(locationName);
    }
  }

  /// Auto-update weather based on current GPS location
  /// In production, integrate with geolocator package to get real GPS coordinates
  Future<WeatherModel> fetchWeatherAuto() async {
    // TODO: Integrate with geolocator package for real GPS location
    // For now, use default location (Ho Chi Minh City)
    return fetchWeather(
      latitude: _defaultLat,
      longitude: _defaultLon,
      locationName: _defaultLocationName,
    );
  }

  /// Fallback weather data if API fails
  WeatherModel _getFallbackWeather(String? locationName) {
    return WeatherModel(
      locationName: locationName ?? _defaultLocationName,
      temperature: 29.0,
      humidity: 75,
      windSpeed: 8.0,
      weatherIcon: '⛅',
      condition: 'partly_cloudy',
    );
  }
}

