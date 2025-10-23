// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:news_app/models/weather_model.dart';

class WeatherService {
  // GANTI DENGAN API KEY ANDA SENDIRI
  static const String _weatherApiKey = 'e3613382a6cc2cb4a4eade6ef120bbc5'; 
  static const String _baseUrl = 'https://api.openweathermap.org/data/3.0/onecall';

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi dinonaktifkan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak permanen.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
  }

  Future<WeatherModel> fetchWeather(double lat, double lon) async {
    if (_weatherApiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
      throw Exception('OpenWeatherMap API Key belum diatur!');
    }
    
    final uri = Uri.parse(
      '$_baseUrl?lat=$lat&lon=$lon&exclude=minutely,daily,alerts&units=metric&appid=$_weatherApiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      // Untuk tujuan demonstrasi, LocationName disetting manual
      jsonData['timezone'] = 'Lokasi Pengguna'; 
      return WeatherModel.fromJson(jsonData);
    } else {
      throw Exception('Gagal memuat data cuaca: ${response.statusCode}');
    }
  }
}