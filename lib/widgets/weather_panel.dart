// lib/widgets/weather_panel.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:news_app/controllers/weather_controller.dart';
import 'package:news_app/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class WeatherPanel extends GetView<WeatherController> {
  const WeatherPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final weather = controller.weatherData.value;

      if (controller.isLoading.value) {
        return Container(
          height: 150,
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
        );
      }
      
      if (controller.error.isNotEmpty) {
        return Container(
          height: 80,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Gagal memuat cuaca: ${controller.error.value}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      if (weather == null) {
        return SizedBox.shrink(); 
      }
      
      final gradientColors = AppColors.getWeatherGradient(weather.iconCode)['key'] ?? [AppColors.primary, AppColors.darkPrimary];
      
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cuaca Saat Ini & Lokasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.onPrimary.withOpacity(0.9), size: 16),
                    SizedBox(width: 4),
                    Text(
                      weather.locationName,
                      style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  '${weather.tempC.toStringAsFixed(1)}°C',
                  style: TextStyle(color: AppColors.onPrimary, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              weather.description.capitalize ?? '',
              style: TextStyle(color: AppColors.onPrimary.withOpacity(0.8), fontSize: 14),
            ),
            
            Divider(color: AppColors.onPrimary.withOpacity(0.3), height: 20),
            
            // Perkiraan Cuaca Selanjutnya (Forecast)
            Text(
              'Perkiraan 5 Jam ke Depan:',
              style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: weather.forecast.map((f) => Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(f.dt * 1000)),
                        style: TextStyle(color: AppColors.onPrimary.withOpacity(0.8), fontSize: 11),
                      ),
                      CachedNetworkImage(
                        imageUrl: 'https://openweathermap.org/img/wn/${f.iconCode}.png',
                        height: 30,
                        width: 30,
                        color: AppColors.onPrimary,
                        errorWidget: (context, url, error) => Icon(Icons.error, color: AppColors.onPrimary),
                      ),
                      Text(
                        '${f.tempC.toStringAsFixed(0)}°',
                        style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }
}