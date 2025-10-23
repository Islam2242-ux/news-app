// lib/controllers/weather_controller.dart
import 'package:get/get.dart';
import 'package:news_app/models/weather_model.dart';
import 'package:news_app/services/weather_service.dart';

class WeatherController extends GetxController {
  final WeatherService _weatherService = WeatherService();
  
  final RxBool isLoading = false.obs;
  final Rx<WeatherModel?> weatherData = Rx<WeatherModel?>(null);
  final RxString error = ''.obs;

  @override
  void onInit() {
    fetchCurrentWeather();
    super.onInit();
  }

  Future<void> fetchCurrentWeather() async {
    isLoading.value = true;
    error.value = '';
    
    try {
      final position = await _weatherService.getCurrentLocation();
      final data = await _weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );
      weatherData.value = data;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Weather Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}