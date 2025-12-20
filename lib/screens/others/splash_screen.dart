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
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    if (widget.navigateToDashboard) {
      _navigateWhenReady();
    }
  }

  Future<void> _navigateWhenReady() async {
    // Wait minimum animation time (1.5 seconds) for nice visual effect
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted || _hasNavigated) return;
    
    final authProvider = context.read<AuthProvider>();
    
    // Check if already authenticated
    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      _navigateToMain();
      return;
    }
    
    // Wait for auth to initialize (max 3 seconds)
    int waitCount = 0;
    while (waitCount < 6 && mounted && !_hasNavigated) {
      await Future.delayed(const Duration(milliseconds: 500));
      waitCount++;
      
      if (authProvider.isAuthenticated && authProvider.userModel != null) {
        _navigateToMain();
        return;
      }
    }
    
    // If still authenticated but no user model, try refresh
    if (authProvider.isAuthenticated && authProvider.userModel == null) {
      try {
        await authProvider.refreshUserProfile();
        if (mounted && authProvider.userModel != null && !_hasNavigated) {
          _navigateToMain();
        }
      } catch (e) {
        debugPrint('Splash refresh error: $e');
      }
    }
  }

  void _navigateToMain() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
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
              
              const Spacer(),

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
                        // Center pulsing dot
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.2),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Container(
                              width: 12 * value,
                              height: 12 * value,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        ),
                        // Rotating icons
                        ..._buildRotatingIcons(),
                      ],
                    );
                  },
                ),
              ),

              const Spacer(),
              
              // Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.navigateToDashboard ? 'Welcome back!' : 'Loading...',
                  key: ValueKey(widget.navigateToDashboard),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.navigateToDashboard) ...[
                const SizedBox(height: 8),
                const Text(
                  'Preparing your dashboard...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
              
              const Spacer(flex: 2),
              
              // Version/copyright at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRotatingIcons() {
    final icons = [
      Icons.construction,
      Icons.plumbing,
      Icons.electrical_services,
      Icons.build,
      Icons.format_paint,
      Icons.handyman,
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
              icons[index],
              color: AppConstants.primaryColor,
              size: 28,
            ),
          ),
        ),
      );
    });
  }
}
