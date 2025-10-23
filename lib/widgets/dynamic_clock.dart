// [MODIFIED] lib/widgets/dynamic_clock.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:news_app/utils/app_colors.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:news_app/controllers/weather_controller.dart';
import 'package:news_app/models/weather_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Jarak Jarum jam dan Menit yang Sudah Disesuaikan (dalam persentase radius)
const double _hourHandLengthRatio = 0.4; // 40% dari radius
const double _minuteHandLengthRatio = 0.6; // 60% dari radius
const double _secondHandLengthRatio = 0.7; // 70% dari radius
// Radius baru untuk memastikan jarum menit (0.6) berada di dalam lingkaran
const double _baseRadius = 80.0; // Radius Dasar untuk kalkulasi

class AnalogClockPainter extends CustomPainter {
  final DateTime dateTime;
  final Color color;

  AnalogClockPainter(this.dateTime, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    Offset center = Offset(centerX, centerY);
    double radius = _baseRadius; // Gunakan radius yang disesuaikan

    // Lingkaran Jam (Deep Blue)
    Paint circlePaint = Paint()..color = AppColors.darkPrimary;
    canvas.drawCircle(center, radius, circlePaint);

    // Titik Pusat
    Paint dotPaint = Paint()..color = AppColors.accent;
    canvas.drawCircle(center, 5, dotPaint);

    // 💡 PERBAIKAN ANIMASI: Hitung posisi tangan dengan presisi milidetik
    final double ms = dateTime.millisecond / 1000;
    final double sec = dateTime.second + ms;
    final double min = dateTime.minute + sec / 60;
    final double hour = dateTime.hour % 12 + min / 60;

    // Hitung Sudut (Angle) dalam radian
    final double secondAngle = (sec * 6 * pi / 180) - pi / 2;
    final double minuteAngle = (min * 6 * pi / 180) - pi / 2;
    final double hourAngle = (hour * 30 * pi / 180) - pi / 2;

    // Jarum Jam (Length: _baseRadius * 0.4)
    double hourX =
        centerX +
        (radius * _hourHandLengthRatio) *
            cos(
              (dateTime.hour % 12 + dateTime.minute / 60) * 30 * pi / 180 -
                  pi / 2,
            );
    double hourY =
        centerY +
        (radius * _hourHandLengthRatio) *
            sin(
              (dateTime.hour % 12 + dateTime.minute / 60) * 30 * pi / 180 -
                  pi / 2,
            );
    canvas.drawLine(
      center,
      Offset(hourX, hourY),
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Jarum Menit (Length: _baseRadius * 0.6)
    double minuteX =
        centerX +
        (radius * _minuteHandLengthRatio) *
            cos(dateTime.minute * 6 * pi / 180 - pi / 2);
    double minuteY =
        centerY +
        (radius * _minuteHandLengthRatio) *
            sin(dateTime.minute * 6 * pi / 180 - pi / 2);
    canvas.drawLine(
      center,
      Offset(minuteX, minuteY),
      Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Jarum Detik (Length: _baseRadius * 0.7)
    double secondX =
        centerX +
        (radius * _secondHandLengthRatio) *
            cos(dateTime.second * 6 * pi / 180 - pi / 2);
    double secondY =
        centerY +
        (radius * _secondHandLengthRatio) *
            sin(dateTime.second * 6 * pi / 180 - pi / 2);
    canvas.drawLine(
      center,
      Offset(secondX, secondY),
      Paint()
        ..color = AppColors.error
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
// END AnalogClockPainter

class DynamicClock extends StatefulWidget {
  final double scrollPosition; // Menerima nilai scroll dari HomeView
  final VoidCallback onWeatherToggle;

  const DynamicClock({
    Key? key,
    required this.scrollPosition,
    required this.onWeatherToggle,
  }) : super(key: key);

  @override
  _DynamicClockState createState() => _DynamicClockState();
}

class _DynamicClockState extends State<DynamicClock> {
  final WeatherController _weatherController = Get.put(WeatherController());

  DateTime _dateTime = DateTime.now();
  bool _isAnalog = true; // Diubah ke Analog untuk default
  late Timer _timer;

  // STATE BARU: Mengontrol visibilitas panel cuaca
  bool _isWeatherPanelVisible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _dateTime = DateTime.now();
        });
      }
    });
  }

  void _toggleClockType() {
    setState(() {
      _isAnalog = !_isAnalog;
    });
  }

  Widget _buildToggleIcon() {
    return IconButton(
      icon: Icon(
        _isAnalog ? Icons.access_alarms_outlined : Icons.access_time_outlined,
        color: AppColors.accent,
      ),
      onPressed: _toggleClockType,
      tooltip: _isAnalog ? 'Ganti ke Jam Digital' : 'Ganti ke Jam Analog',
    );
  }

  Widget _buildDigitalClock() {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('EEE, dd MMMM yyyy');

    return Column(
      key: ValueKey('digital'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeFormat.format(_dateTime),
          style: TextStyle(
            fontSize: 40, // Dikecilkan sedikit agar lebih fleksibel
            fontWeight: FontWeight.bold,
            color: AppColors.onPrimary,
            fontFamily: 'RobotoMono',
          ),
        ),
        SizedBox(height: 4),
        Text(
          dateFormat.format(_dateTime),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherToggleIcon() {
    return IconButton(
      icon: Icon(Icons.cloud, color: AppColors.onPrimary.withOpacity(0.9)),
      onPressed: widget.onWeatherToggle, // Menggunakan callback dari widget
      tooltip: 'Perkiraan Cuaca',
    );
  }

  Widget _buildAnalogClock() {
    final dateFormat = DateFormat('EEE, dd MMMM yyyy');

    return Row(
      key: ValueKey('analog'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Jam Analog (Kiri)
        CustomPaint(
          painter: AnalogClockPainter(_dateTime, AppColors.accent),
          size: Size.square(_baseRadius * 2),
        ),

        SizedBox(width: 30), // Pemisah antara Jam dan Tanggal
        // 2. Tanggal dan Waktu Tambahan (Kanan)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tanggal Hari Ini',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onPrimary.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 4),
              Text(
                dateFormat.format(_dateTime),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                DateFormat(
                  'HH:mm:ss',
                ).format(_dateTime), // Waktu digital kecil pelengkap
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onPrimary.withOpacity(0.8),
                  fontFamily: 'RobotoMono',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET BARU: Panel Informasi Cuaca
  Widget _buildWeatherPanel() {
    return Obx(() {
      final weather = _weatherController.weatherData.value;

      if (_weatherController.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );
      }

      if (weather == null) {
        return Center(
          child: Text(
            'Gagal memuat cuaca.',
            style: TextStyle(color: AppColors.onPrimary.withOpacity(0.8)),
          ),
        );
      }

      // Ambil warna gradien berdasarkan kondisi cuaca
      final gradientColors =
          AppColors.getWeatherGradient(weather.iconCode)['key'] ??
          [AppColors.primary, AppColors.darkPrimary];

      return Container(
        margin: EdgeInsets.only(top: 10),
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
          children: [
            // Cuaca Saat Ini
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.onPrimary.withOpacity(0.9),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  weather.locationName,
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl:
                      'https://openweathermap.org/img/wn/${weather.iconCode}@2x.png',
                  height: 50,
                  width: 50,
                  color: AppColors.onPrimary,
                  errorWidget: (context, url, error) =>
                      Icon(Icons.error, color: AppColors.onPrimary),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.tempC.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weather.description.capitalize ?? '',
                      style: TextStyle(
                        color: AppColors.onPrimary.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Divider(color: AppColors.onPrimary.withOpacity(0.3), height: 20),

            // Perkiraan Cuaca Selanjutnya (Forecast)
            Text(
              'Perkiraan 5 Jam ke Depan:',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: weather.forecast
                    .map(
                      (f) => Container(
                        margin: EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('HH:mm').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  f.dt * 1000,
                                ),
                              ),
                              style: TextStyle(
                                color: AppColors.onPrimary.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                            CachedNetworkImage(
                              imageUrl:
                                  'https://openweathermap.org/img/wn/${f.iconCode}.png',
                              height: 30,
                              width: 30,
                              color: AppColors.onPrimary,
                            ),
                            Text(
                              '${f.tempC.toStringAsFixed(0)}°',
                              style: TextStyle(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  //belum bawah

  @override
  Widget build(BuildContext context) {
    // scrollPosition berkisar antara 0.0 (atas) hingga 1.0 (gulir penuh)

    // 1. Skala (Scale): Dari 1.0 (normal) ke 0.0 (hilang)
    final double scaleFactor = 1.0 - widget.scrollPosition;
    final double offsetX = 0 * widget.scrollPosition;

    // Sesuaikan tinggi maksimal kontainer untuk menampung panel cuaca baru
    final double maxClockHeight = _isWeatherPanelVisible ? 450 : 200;

    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Transform.scale(
        scale: scaleFactor,
        alignment: Alignment.centerLeft,
        child: Opacity(
          opacity: scaleFactor.clamp(0.0, 1.0),
          child: Container(
            // Menggunakan AnimatedSize untuk animasi ketinggian box
            child: AnimatedSize(
              duration: Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxClockHeight,
                ), // Batasan tinggi
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkPrimary.withOpacity(0.5),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'WIB (Waktu Lokal)',
                          style: TextStyle(
                            color: AppColors.onPrimary.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            // 💡 Tombol Cuaca
                            _buildWeatherToggleIcon(),
                            // Tombol Jam
                            _buildToggleIcon(),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),

                    // Container Jam
                    Container(
                      height: 160,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 500),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              final Animation<double> scaleAnimation =
                                  Tween<double>(begin: 0.8, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.fastOutSlowIn,
                                    ),
                                  );
                              final Animation<double> fadeAnimation =
                                  Tween<double>(
                                    begin: 0.0,
                                    end: 1.0,
                                  ).animate(animation);
                              return FadeTransition(
                                opacity: fadeAnimation,
                                child: ScaleTransition(
                                  scale: scaleAnimation,
                                  child: child,
                                ),
                              );
                            },
                        child: _isAnalog
                            ? _buildAnalogClock()
                            : _buildDigitalClock(),
                      ),
                    ),

                    // 💡 Panel Cuaca dengan Animasi Geser/Slide (Muncul di bawah Jam)
                    if (_isWeatherPanelVisible) _buildWeatherPanel(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
