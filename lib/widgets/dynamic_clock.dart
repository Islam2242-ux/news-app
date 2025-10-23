// lib/widgets/dynamic_clock.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:news_app/utils/app_colors.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:news_app/controllers/weather_controller.dart';
// ... (Import model cuaca jika diperlukan)

const double _hourHandLengthRatio = 0.4; 
const double _minuteHandLengthRatio = 0.6; 
const double _secondHandLengthRatio = 0.7; 
// PERBAIKAN: Radius lebih kecil agar tidak overflow
const double _baseRadius = 70.0; // Dikecilkan dari 80.0

// ... (AnalogClockPainter tetap sama)
class AnalogClockPainter extends CustomPainter {
  final DateTime dateTime;
  final Color accentColor;

  AnalogClockPainter(this.dateTime, this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(centerX, centerY);

    final fillBrush = Paint()..color = AppColors.onPrimary;
    final strokeBrush = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final centerDotBrush = Paint()..color = accentColor;

    canvas.drawCircle(Offset(centerX, centerY), radius - 4, fillBrush);
    canvas.drawCircle(Offset(centerX, centerY), radius - 4, strokeBrush);

    // Draw hour marks
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * pi / 180;
      final x1 = centerX + (radius - 10) * cos(angle);
      final y1 = centerY + (radius - 10) * sin(angle);
      final x2 = centerX + (radius - 5) * cos(angle);
      final y2 = centerY + (radius - 5) * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), strokeBrush);
    }

    // Draw hands
    // Hour hand
    final hour = dateTime.hour % 12;
    final hourAngle = (hour * 30 + (dateTime.minute / 60) * 30) * pi / 180;
    _drawHand(
      canvas,
      centerX,
      centerY,
      radius * _hourHandLengthRatio,
      hourAngle,
      Paint()..color = AppColors.textPrimary..strokeWidth = 4..strokeCap = StrokeCap.round,
    );

    // Minute hand
    final minuteAngle = (dateTime.minute * 6 + (dateTime.second / 60) * 6) * pi / 180;
    _drawHand(
      canvas,
      centerX,
      centerY,
      radius * _minuteHandLengthRatio,
      minuteAngle,
      Paint()..color = AppColors.textPrimary..strokeWidth = 3..strokeCap = StrokeCap.round,
    );

    // Second hand
    final secondAngle = (dateTime.second * 6) * pi / 180;
    _drawHand(
      canvas,
      centerX,
      centerY,
      radius * _secondHandLengthRatio,
      secondAngle,
      Paint()..color = accentColor..strokeWidth = 2..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(Offset(centerX, centerY), 4, centerDotBrush);
  }

  void _drawHand(Canvas canvas, double centerX, double centerY, double length,
      double angle, Paint paint) {
    final x = centerX + length * cos(angle - pi / 2); // Adjust for 12 o'clock at top
    final y = centerY + length * sin(angle - pi / 2);
    canvas.drawLine(Offset(centerX, centerY), Offset(x, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
class DynamicClock extends StatefulWidget {
  final double scrollPosition; 
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
  bool _isAnalog = true; 
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Timer yang halus (50ms) tetap dipertahankan
    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _dateTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); 
    super.dispose();
  }
  
  void _toggleClockType() {
    setState(() {
      _isAnalog = !_isAnalog;
    });
  }

  // PERBAIKAN 4: Tambahkan InkWell untuk Animasi Tekan pada Ikon Jam
  Widget _buildToggleIcon() {
    return InkWell(
      onTap: _toggleClockType,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          _isAnalog ? Icons.access_alarms_outlined : Icons.access_time_outlined,
          color: AppColors.accent,
        ),
      ),
    );
  }
  
  // PERBAIKAN 4: Tambahkan InkWell untuk Animasi Tekan pada Ikon Cuaca
  Widget _buildWeatherToggleIcon() {
    return InkWell(
      onTap: widget.onWeatherToggle,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          Icons.cloud, 
          color: AppColors.onPrimary.withOpacity(0.9)
        ),
      ),
    );
  }

  // ... (_buildDigitalClock dan _buildAnalogClock tetap sama, namun akan menggunakan _baseRadius yang baru)

  Widget _buildDigitalClock() {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('EEE, dd MMMM yyyy');

    return Center(
      key: ValueKey('digital'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeFormat.format(_dateTime),
            style: TextStyle(
              fontSize: 40, 
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
      ),
    );
  }

  Widget _buildAnalogClock() {
    final dateFormat = DateFormat('EEE, dd MMMM yyyy');

    // PERBAIKAN 2: Mengurangi lebar pemisah untuk memberi ruang
    const double spaceBetweenClockAndDate = 15.0;

    return Row(
      key: ValueKey('analog'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Jam Analog (Kiri)
        CustomPaint(
          painter: AnalogClockPainter(_dateTime, AppColors.accent),
          size: Size.square(_baseRadius * 2),
        ),

        SizedBox(width: spaceBetweenClockAndDate),
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
                DateFormat('HH:mm:ss').format(_dateTime),
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


  @override
  Widget build(BuildContext context) {
    final double scaleFactor = 1.0 - widget.scrollPosition;
    final double offsetX = -100 * widget.scrollPosition; 
    
    // Perbaikan: Tinggi dasar kontainer dikurangi
    const double defaultContainerHeight = 180; // Dikecilkan dari 200

    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Transform.scale(
        scale: scaleFactor,
        alignment: Alignment.centerLeft, 
        child: Opacity(
          opacity: scaleFactor.clamp(0.0, 1.0), 
          child: Container(
            height: defaultContainerHeight, // Menggunakan tinggi yang lebih kecil
            // PERBAIKAN 2: Kurangi margin dan padding agar tidak terlalu menjorok ke bawah
            padding: EdgeInsets.all(12), // Dari 20 ke 12
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Dari 12 ke 8
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
                        _buildWeatherToggleIcon(),
                        SizedBox(width: 4), // Spasi antar ikon
                        _buildToggleIcon(),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8), // Dikecilkan dari 15
                
                // Container Jam (Expanded untuk menempati sisa ruang)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final Animation<double> scaleAnimation = Tween<double>(
                        begin: 0.8,
                        end: 1.0, 
                      ).animate(CurvedAnimation(
                        parent: animation, 
                        curve: Curves.fastOutSlowIn,
                      ));
                      final Animation<double> fadeAnimation = Tween<double>(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}