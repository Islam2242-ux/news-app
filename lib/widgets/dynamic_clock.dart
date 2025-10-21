// [MODIFIED] lib/widgets/dynamic_clock.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:news_app/utils/app_colors.dart';
import 'dart:math';

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

  const DynamicClock({Key? key, required this.scrollPosition})
    : super(key: key);

  @override
  _DynamicClockState createState() => _DynamicClockState();
}

class _DynamicClockState extends State<DynamicClock> {
  DateTime _dateTime = DateTime.now();
  bool _isAnalog = true; // Diubah ke Analog untuk default

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 1), (timer) {
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

  // 💡 MODIFIKASI LAYOUT: Jam Analog di kiri dengan Tanggal di kanan
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

  @override
  Widget build(BuildContext context) {
    // scrollPosition berkisar antara 0.0 (atas) hingga 1.0 (gulir penuh)

    // 1. Skala (Scale): Dari 1.0 (normal) ke 0.0 (hilang)
    final double scaleFactor = 1.0 - widget.scrollPosition;

    // 2. Geser (Translate): Geser ke kiri seiring menghilang
    final double offsetX =
        0 * widget.scrollPosition; // Geser 100 piksel ke kiri

    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Transform.scale(
        scale: scaleFactor,
        alignment: Alignment.centerLeft, // PENTING: Mengecil ke arah kiri
        child: Opacity(
          opacity: scaleFactor.clamp(0.0, 1.0), // Opacity mengikuti skala
          child: Container(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    _buildToggleIcon(),
                  ],
                ),
                SizedBox(height: 0),
                Container(
                  height: 160,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final scale = Tween<double>(begin: 0.5, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          // Kurva: Cepat di awal, lambat di akhir (Fast-Slow)
                          curve: Curves.fastEaseInToSlowEaseOut,
                        ),
                      );
                      final fade = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: fade,
                        child: ScaleTransition(scale: scale, child: child),
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
