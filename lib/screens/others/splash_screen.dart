import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Title
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppConstants.appSlogan,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),

            // Animated circular loader with service icons
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Center dot
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Rotating icons
                      ..._buildRotatingIcons(),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 40),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRotatingIcons() {
    final icons = [
      {'icon': Icons.construction, 'label': 'Carpenter'},
      {'icon': Icons.plumbing, 'label': 'Plumber'},
      {'icon': Icons.electrical_services, 'label': 'Electrician'},
      {'icon': Icons.build, 'label': 'Mechanic'},
      {'icon': Icons.format_paint, 'label': 'Painter'},
      {'icon': Icons.handyman, 'label': 'Handyman'},
    ];

    return List.generate(icons.length, (index) {
      final angle =
          (2 * math.pi / icons.length) * index +
          (_controller.value * 2 * math.pi);
      final radius = 80.0;
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);

      return Transform.translate(
        offset: Offset(x, y),
        child: Transform.rotate(
          angle:
              -(_controller.value *
                  2 *
                  math.pi), // Counter-rotate to keep upright
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icons[index]['icon'] as IconData,
              color: AppConstants.primaryColor,
              size: 28,
            ),
          ),
        ),
      );
    });
  }
}
