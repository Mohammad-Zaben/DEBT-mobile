import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with TickerProviderStateMixin {
  String _currentOtp = '';
  bool _isLoading = false;
  Timer? _otpTimer;
  int _secondsRemaining = 0;
  
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _generateNewOtp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _generateNewOtp() async {
    setState(() {
      _isLoading = true;
      _currentOtp = '';
    });

    // Fixed OTP as requested - simple approach
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _currentOtp = '1'; // Fixed OTP number as requested
      _isLoading = false;
      _secondsRemaining = 300; // OTP valid for 5 minutes
    });

    // Start pulse animation for the OTP
    _pulseController.repeat(reverse: true);
    
    // Start countdown timer
    _startOtpTimer();
    
    // Show success message
    _showMessage('رمز التحقق جاهز للاستخدام', AppTheme.successColor);
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          _pulseController.stop();
          _currentOtp = '';
          _showMessage('انتهت صلاحية رمز التحقق', AppTheme.warningColor);
        }
      });
    });
  }

  void _copyOtpToClipboard() {
    if (_currentOtp.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _currentOtp));
      HapticFeedback.lightImpact();
      _showMessage('تم نسخ رمز التحقق', AppTheme.primaryColor);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رمز التحقق'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Icon and Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'رمز التحقق الآمن',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'استخدم هذا الرمز للتحقق من العمليات المالية',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // OTP Display Card
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_isLoading) ...[
                          const CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'جاري إنشاء رمز التحقق...',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ] else if (_currentOtp.isNotEmpty) ...[
                          const Text(
                            'رمز التحقق الحالي',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // OTP Display
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(60),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _currentOtp,
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Timer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'رمز ثابت جاهز للاستخدام',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Copy Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _copyOtpToClipboard,
                              icon: const Icon(Icons.copy),
                              label: const Text('نسخ الرمز'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.timer_off,
                            size: 64,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لا يوجد رمز تحقق نشط',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Generate New OTP Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateNewOtp,
                  icon: const Icon(Icons.security),
                  label: const Text('عرض رمز التحقق'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'كيفية الاستخدام',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'أعط هذا الرمز لمزود الخدمة عند إضافة دين جديد للتحقق من العملية',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}