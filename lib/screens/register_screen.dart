import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'user'; // 'user' or 'provider'
  String _selectedProviderType = 'lender'; // 'lender' or 'payer'
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    ApiResponse<User> response;
    
    if (_selectedRole == 'user') {
      response = await ApiService().registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      // Provider registration (Note: This requires admin privileges in your API)
      response = await ApiService().createProvider(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        providerType: _selectedProviderType,
      );
    }

    setState(() => _isLoading = false);

    if (response.success) {
      _showSuccess('تم إنشاء الحساب بنجاح!');
      // Navigate to login screen
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                  const LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.ease)),
                  ),
                  child: child,
                );
              },
            ),
          );
        }
      });
    } else {
      _showError(response.error ?? 'خطأ في إنشاء الحساب');
    }
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      iconSize: 28,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'أنشئ حسابك للبدء في تتبع مدفوعاتك',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Register Form
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Account Type Selection
                              const Text(
                                'نوع الحساب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildRoleCard(
                                      title: 'مستخدم',
                                      subtitle: 'عامل أو موظف',
                                      icon: Icons.person,
                                      value: 'user',
                                      isSelected: _selectedRole == 'user',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildRoleCard(
                                      title: 'مزود خدمة',
                                      subtitle: 'مقاول أو صاحب محل',
                                      icon: Icons.business,
                                      value: 'provider',
                                      isSelected: _selectedRole == 'provider',
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Provider Type Selection (only if provider is selected)
                              if (_selectedRole == 'provider') ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'نوع مزود الخدمة',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildProviderTypeCard(
                                        title: 'مُقرض',
                                        subtitle: 'صاحب محل أو متجر',
                                        icon: Icons.store,
                                        value: 'lender',
                                        isSelected: _selectedProviderType == 'lender',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildProviderTypeCard(
                                        title: 'دافع',
                                        subtitle: 'مقاول يدفع للعمال',
                                        icon: Icons.engineering,
                                        value: 'payer',
                                        isSelected: _selectedProviderType == 'payer',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              
                              const SizedBox(height: 24),
                              
                              // Name Field
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'الاسم الكامل',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال الاسم';
                                  }
                                  if (value.length < 3) {
                                    return 'الاسم يجب أن يكون أكثر من 3 أحرف';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال البريد الإلكتروني';
                                  }
                                  if (!value.contains('@')) {
                                    return 'يرجى إدخال بريد إلكتروني صالح';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال كلمة المرور';
                                  }
                                  if (value.length < 6) {
                                    return 'كلمة المرور يجب أن تكون أكثر من 6 أحرف';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  labelText: 'تأكيد كلمة المرور',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى تأكيد كلمة المرور';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'كلمة المرور غير متطابقة';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Register Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('إنشاء الحساب'),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'لديك حساب بالفعل؟ ',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProviderType = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? AppTheme.secondaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppTheme.secondaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? AppTheme.secondaryColor : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}