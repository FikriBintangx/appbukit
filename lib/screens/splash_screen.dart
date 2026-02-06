import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tiara_fin/screens/admin_screens.dart';
import 'package:tiara_fin/screens/auth_screens.dart';
import 'package:tiara_fin/screens/user_screens.dart';
import 'package:tiara_fin/services.dart';
import 'package:tiara_fin/widgets/custom_loading.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Use a precise start time for truly time-based animation logic in the painter
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // The controller here drives the repaint loop at the device's refresh rate.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duration doesn't strictly matter for free-running time loop
    )..repeat();

    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Artificial delay to ensure splash is visible for at least a moment (luxurious feel)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final AuthService auth = AuthService();
      final userId = await auth.getCurrentUserId();
      final user = await auth.getCurrentUser();

      if (!mounted) return;

      if (userId != null && user != null) {
        if (user.role == 'admin' || user.role == 'ketua_rt') {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AdminMainScreen(),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const UserMainScreen(),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Defined colors based on the user request for Material You / Dynamic
    // Using simple transparencies of primary for depth
    final waveColor1 = colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.1);
    final waveColor2 = colorScheme.secondary.withValues(alpha: isDark ? 0.15 : 0.1);
    final waveColor3 = colorScheme.tertiary.withValues(alpha: isDark ? 0.15 : 0.1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Waves
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Determine elapsed time exactly for smooth physics
                final double elapsedSeconds = DateTime.now().difference(_startTime).inMilliseconds / 1000.0;
                return CustomPaint(
                  painter: WavePainter(
                    time: elapsedSeconds,
                    colors: [waveColor1, waveColor2, waveColor3],
                    context: context,
                  ),
                );
              },
            ),
          ),
          
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                const HouseLoadingWidget(size: 80),
                const SizedBox(height: 24),
                
                // App Name with slight fade/slide could be added, but keeping it minimal as requested
                Text(
                  'Tiara Finance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Loading Indicator (Simple)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          
          // Optional footer or version info
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double time;
  final List<Color> colors;
  final BuildContext context;

  WavePainter({required this.time, required this.colors, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    // Configuration for waves
    // We draw 3 waves with different frequencies and speeds
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Wave 1: Slow, large amplitude
    _drawWave(canvas, size, paint, 
      color: colors[0], 
      amplitude: size.height * 0.05, 
      frequency: 1.0, 
      speed: 0.5, 
      offset: 0,
      baseHeightRatio: 0.85
    );

    // Wave 2: Medium speed
    _drawWave(canvas, size, paint, 
      color: colors[1], 
      amplitude: size.height * 0.04, 
      frequency: 1.5, 
      speed: 0.7, 
      offset: math.pi,
      baseHeightRatio: 0.88
    );

    // Wave 3: Faster, smaller details
    _drawWave(canvas, size, paint, 
      color: colors[2], 
      amplitude: size.height * 0.03, 
      frequency: 2.0, 
      speed: 0.9, 
      offset: math.pi / 2,
      baseHeightRatio: 0.92
    );
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, {
    required Color color,
    required double amplitude,
    required double frequency,
    required double speed,
    required double offset,
    required double baseHeightRatio,
  }) {
    paint.color = color;
    final path = Path();
    
    final double baseHeight = size.height * baseHeightRatio;
    
    path.moveTo(0, size.height);
    path.lineTo(0, baseHeight);

    // Draw sine wave
    for (double x = 0; x <= size.width; x++) {
      // time-based phase shift
      final double phase = time * speed + offset;
      // normalized x position [0, 2pi] * frequency
      final double normalizedX = (x / size.width) * 2 * math.pi * frequency;
      
      final double y = baseHeight + math.sin(normalizedX + phase) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
