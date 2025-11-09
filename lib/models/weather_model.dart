class WeatherModel {
  final String locationName;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String weatherIcon; // Emoji icon
  final String condition; // "sunny", "rainy", "cloudy", etc.

  WeatherModel({
    required this.locationName,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherIcon,
    required this.condition,
  });

  /// Parse from OpenWeatherMap API response
  factory WeatherModel.fromOpenWeatherMap(
    Map<String, dynamic> json,
    String locationName,
  ) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>?;

    final temperature = (main['temp'] as num).toDouble();
    final humidity = main['humidity'] as int;
    final windSpeed = (wind?['speed'] as num?)?.toDouble() ?? 0.0;
    
    // Convert m/s to km/h
    final windSpeedKmh = windSpeed * 3.6;

    // Map OpenWeatherMap icon code to emoji
    final iconCode = weather['icon'] as String;
    final weatherIcon = _getWeatherEmoji(iconCode);
    
    // Map condition
    final condition = _mapCondition(weather['main'] as String);

    return WeatherModel(
      locationName: json['name'] as String? ?? locationName,
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeedKmh,
      weatherIcon: weatherIcon,
      condition: condition,
    );
  }

  /// Parse from custom JSON format
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      locationName: json['locationName'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      weatherIcon: json['weatherIcon'] as String,
      condition: json['condition'] as String,
    );
  }

  /// Map OpenWeatherMap icon codes to emoji
  static String _getWeatherEmoji(String iconCode) {
    // OpenWeatherMap icon codes mapping
    // Format: {condition}{time}, where time is d (day) or n (night)
    final iconMap = {
      '01d': '☀️', // clear sky day
      '01n': '🌙', // clear sky night
      '02d': '⛅', // few clouds day
      '02n': '☁️', // few clouds night
      '03d': '☁️', // scattered clouds
      '03n': '☁️',
      '04d': '☁️', // broken clouds
      '04n': '☁️',
      '09d': '🌧️', // shower rain
      '09n': '🌧️',
      '10d': '🌦️', // rain day
      '10n': '🌧️', // rain night
      '11d': '⛈️', // thunderstorm
      '11n': '⛈️',
      '13d': '❄️', // snow
      '13n': '❄️',
      '50d': '🌫️', // mist
      '50n': '🌫️',
    };
    return iconMap[iconCode] ?? '☀️';
  }

  /// Map OpenWeatherMap condition to our condition string
  static String _mapCondition(String mainCondition) {
    final conditionMap = {
      'Clear': 'sunny',
      'Clouds': 'cloudy',
      'Rain': 'rainy',
      'Drizzle': 'rainy',
      'Thunderstorm': 'rainy',
      'Snow': 'snowy',
      'Mist': 'cloudy',
      'Fog': 'cloudy',
      'Haze': 'cloudy',
    };
    return conditionMap[mainCondition] ?? 'sunny';
  }

  Map<String, dynamic> toJson() {
    return {
      'locationName': locationName,
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'weatherIcon': weatherIcon,
      'condition': condition,
    };
  }
}

