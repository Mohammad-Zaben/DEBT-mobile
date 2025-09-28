import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));
    
    _initializeApp();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Start animations
      _logoController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      _fadeController.forward();
      
      // Initialize API service
      await ApiService().initialize();
      
      // Wait for animations to complete (minimum splash duration)
      await Future.delayed(const Duration(milliseconds: 2500));
      
      if (!mounted) return;
      
      // Check if user is already logged in
      final isLoggedIn = ApiService().isLoggedIn;
      
      if (isLoggedIn) {
        // Validate the token by making a test API call
        final isValidToken = await ApiService().validateToken();
        
        if (isValidToken) {
          // Token is valid, get user data and go to home
          final userResponse = await ApiService().getCurrentUser();
          if (userResponse.success && userResponse.data != null && mounted) {
            _navigateToHome(userResponse.data!);
            return;
          }
        }
        
        // Token is invalid or expired, clear it and go to welcome
        await ApiService().clearToken();
      }
      
      // User not logged in or token invalid, go to welcome screen
      if (mounted) {
        _navigateToWelcome();
      }
      
    } catch (e) {
      // Handle any errors by clearing token and going to welcome
      await ApiService().clearToken();
      if (mounted) {
        _navigateToWelcome();
      }
    }
  }

  void _navigateToWelcome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 0.3), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _navigateToHome(user) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            HomeScreen(user: user),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 0.3), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF1B5E20),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Animated Logo
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Transform.rotate(
                      angle: (1 - _rotationAnimation.value) * math.pi / 4,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 25,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 70,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // App Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'مدفوعاتي',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    letterSpacing: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'إدارة المدفوعات والديون',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'جاري التحميل...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Version/Copyright
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'الإصدار 1.0.0',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
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