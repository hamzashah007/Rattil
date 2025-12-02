import 'package:flutter/material.dart';
import 'package:rattil/screens/auth/sign_in.dart';
import 'dart:async';
import 'package:rattil/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;

  late AnimationController _titleController;
  late Animation<double> _titleFadeAnimation;

  late AnimationController _subtitleController;
  late Animation<double> _subtitleFadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Logo fade and scale
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Title fade
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeIn));

    // Subtitle fade
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _subtitleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    // Pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations with stagger
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _titleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _subtitleController.forward();
    });

    // Auto navigation after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal500 = const Color.fromARGB(255, 65, 255, 233);
    final teal700 = const Color.fromARGB(255, 18, 105, 98);
    final white = AppColors.white;
    final tealLight = AppColors.tealLight;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [teal500, teal700],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _logoFadeAnimation,
                child: ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 150,
                      height:150,
                      color: white, // Tint icon white
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FadeTransition(
                opacity: _titleFadeAnimation,
                child: Text(
                  'Rattil',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _subtitleFadeAnimation,
                child: Text(
                  'Learn Quran with Ease',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: tealLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}