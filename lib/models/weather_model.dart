// lib/models/weather_model.dart

class WeatherModel {
  final String locationName;
  final double tempC;
  final String description;
  final String iconCode;
  final List<ForecastDay> forecast;

  WeatherModel({
    required this.locationName,
    required this.tempC,
    required this.description,
    required this.iconCode,
    required this.forecast,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // OpenWeatherMap example parsing (disederhanakan)
    final current = json['current'];
    final hourly = json['hourly'] as List;

    return WeatherModel(
      locationName: json['timezone'], 
      tempC: current['temp'].toDouble(),
      description: current['weather'][0]['description'],
      iconCode: current['weather'][0]['icon'],
      forecast: hourly.take(5).map((e) => ForecastDay.fromJson(e)).toList(),
    );
  }
}

class ForecastDay {
  final int dt;
  final double tempC;
  final String iconCode;

  ForecastDay({required this.dt, required this.tempC, required this.iconCode});

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      dt: json['dt'],
      tempC: json['temp'].toDouble(),
      iconCode: json['weather'][0]['icon'],
    );
  }
}