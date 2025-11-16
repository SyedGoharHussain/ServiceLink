import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool navigateToDashboard;

  const SplashScreen({super.key, this.navigateToDashboard = false});

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
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // If navigateToDashboard is true, navigate after 5 seconds
    if (widget.navigateToDashboard) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          if (authProvider.isAuthenticated && authProvider.userModel != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        }
      });
    }
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
            Text(
              widget.navigateToDashboard ? 'Welcome back!' : 'Loading...',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.navigateToDashboard) ...[
              const SizedBox(height: 8),
              const Text(
                'Loading your dashboard...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
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
          angle: -(_controller.value * 2 * math.pi),
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
