import 'package:get/get.dart';
import 'package:news_app/controllers/news_controller.dart';
import 'package:news_app/controllers/weather_controller.dart'; // <=== IMPORT BARU

class AppBindings implements Bindings {
  @override
  void dependencies() {
    Get.put<NewsController>(NewsController(), permanent: true);
    Get.put<WeatherController>(WeatherController()); // <=== TAMBAHKAN CONTROLLER CUACA
  }
}
