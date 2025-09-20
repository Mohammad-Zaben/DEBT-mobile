import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class OtpVerificationScreen extends StatefulWidget {
  final int userId;
  final String amount;
  final String description;
  final String clientName;
  
  const OtpVerificationScreen({
    super.key,
    required this.userId,
    required this.amount,
    required this.description,
    required this.clientName,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndCreateDebt() async {
    if (_otpController.text.trim().isEmpty) {
      _showError('يرجى إدخال رمز التحقق');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().createTransaction(
        userId: widget.userId,
        type: 'debt',
        amount: widget.amount,
        otp: _otpController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (response.success) {
        _showSuccessDialog();
      } else {
        _showError(response.error ?? 'خطأ في إنشاء الدين');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في الاتصال بالخادم');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'تم إنشاء الدين بنجاح!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'تم تسجيل دين بقيمة ${widget.amount} ريال على ${widget.clientName}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Return to create transaction with success
                },
                child: const Text('تم'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد الدين'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Title and Icon
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.security,
                          size: 40,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'تأكيد إنشاء الدين',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'يرجى الحصول على رمز التحقق من العميل',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Transaction Details Card
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفاصيل الدين',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildDetailRow('العميل', widget.clientName),
                          const SizedBox(height: 8),
                          _buildDetailRow('المبلغ', '${widget.amount} ريال'),
                          if (widget.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow('الوصف', widget.description),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // OTP Input Card
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'رمز التحقق',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'أدخل رمز التحقق',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'اطلب من العميل فتح تطبيق "ديت مي" والذهاب إلى صفحة رمز التحقق',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _verifyAndCreateDebt,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('تأكيد إنشاء الدين'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}