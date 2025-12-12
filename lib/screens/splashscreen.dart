import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:rattil/screens/auth/sign_in.dart';
// import 'package:rattil/screens/home_screen.dart';
import 'dart:async';
import 'package:rattil/utils/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    // Start animations with stagger after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      _logoController.forward();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _titleController.forward();
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _subtitleController.forward();
      });

      // Auto navigation after 3 seconds (longer for iOS)
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) {
          _navigateBasedOnAuthState();
        }
      });
    });
  }

  void _navigateBasedOnAuthState() {
    if (!mounted) return;
    
    // FIREBASE DISABLED - Always go to SignInScreen
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   // User is logged in, go to HomeScreen
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => HomeScreen()),
    //   );
    // } else {
      // User is not logged in, go to SignInScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    // }
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
      backgroundColor: teal500,
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
                    child: SvgPicture.asset(
                      'assets/icon/app_icon.svg',
                      width: 150,
                      height: 150,
                      colorFilter: ColorFilter.mode(white, BlendMode.srcIn),
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