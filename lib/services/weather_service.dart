import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service for fetching weather data from OpenWeatherMap API
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // OpenWeatherMap API Key
  static const String _apiKey = '2bcdd31403466596c80115eb4c57f955';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

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

      final response = await http
          .get(uri)
          .timeout(
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
  Future<WeatherModel> fetchWeatherAuto() async {
    try {
      // 1. Check permissions and get current position
      Position position = await _determinePosition();

      // 2. Get address from coordinates (Reverse Geocoding)
      String locationName = await _getAddressFromCoordinates(position);

      // 3. Fetch weather with current location
      return await fetchWeather(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
      );
    } catch (e) {
      debugPrint('Error getting location or weather: $e');
      // Fallback to default location if permission denied or error
      return fetchWeather(
        latitude: _defaultLat,
        longitude: _defaultLon,
        locationName: _defaultLocationName,
      );
    }
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Get address from coordinates
  Future<String> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Debug: Log all placemark fields to see what data we have
        debugPrint('=== Placemark Debug ===');
        debugPrint('subLocality: ${place.subLocality}');
        debugPrint('locality: ${place.locality}');
        debugPrint('subAdministrativeArea: ${place.subAdministrativeArea}');
        debugPrint('administrativeArea: ${place.administrativeArea}');
        debugPrint('name: ${place.name}');
        debugPrint('thoroughfare: ${place.thoroughfare}');
        debugPrint('subThoroughfare: ${place.subThoroughfare}');
        debugPrint('======================');

        List<String> parts = [];

        // Priority 1: Ward/Commune from subLocality or locality
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        } else if (place.locality != null &&
            place.locality!.isNotEmpty &&
            place.locality != place.administrativeArea) {
          parts.add(place.locality!);
        }

        // Priority 2: District (always add if available)
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          parts.add(place.subAdministrativeArea!);
        }

        // Only show City if we have no other information
        if (parts.isEmpty &&
            place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }

        if (parts.isNotEmpty) {
          String result = parts.join(', ');
          debugPrint('Final location name: $result');
          return result;
        }
      }
      return _defaultLocationName;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return _defaultLocationName;
    }
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
