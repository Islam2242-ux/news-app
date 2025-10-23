import 'package:flutter/material.dart';

class AppColors {
  // Deep Sea Blue (Biru Tua Laut) untuk kesan 'Kepercayaan'
  static const Color primary = Color(0xFF0A406A); // Biru Tua Utama
  static const Color darkPrimary = Color(0xFF072B45); // Biru Tua Sangat Gelap (untuk AppBar)
  static const Color accent = Color(0xFF5AB9F1); // Biru Cerah (untuk elemen interaktif/tombol)
  
  static const Color background = Color(0xFFF0F3F5); // Abu-abu terang untuk latar belakang
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackground = Color(0xFF121212);
  static const Color onSurface = Color(0xFF121212);
  static const Color onError = Colors.white;

  // Warna Teks
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Warna Tambahan
  static const Color divider = Color(0xFFE0E0E0);
  static const Color cardShadow = Color(0x1A000000);

  static Map<String, List<Color>> getWeatherGradient(String iconCode) {
    if (iconCode.contains('d')) { // Siang Hari
      if (iconCode.startsWith('01')) { // Cerah
        return {'key': [Color(0xFF5AB9F1), Color(0xFF0A406A)]}; // Accent ke Primary
      } else if (iconCode.startsWith('09') || iconCode.startsWith('10')) { // Hujan/Gerimis
        return {'key': [Color(0xFF607D8B), Color(0xFF455A64)]}; // Abu-abu Biru
      } else if (iconCode.startsWith('04')) { // Berawan Tebal
        return {'key': [Color(0xFFAAB8C2), Color(0xFF757F9A)]}; // Abu-abu Cerah
      }
    }
    // Default atau Malam Hari (Mengikuti tema gelap aplikasi)
    return {'key': [Color(0xFF0A406A), Color(0xFF072B45)]}; 
  }
}