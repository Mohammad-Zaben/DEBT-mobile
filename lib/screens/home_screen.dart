import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';
import 'welcome_screen.dart';
import 'otp_screen.dart';
import 'providers_list_screen.dart';
import 'create_transaction_screen.dart';
import 'clients_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ApiService().clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (route) => false,
      );
    }
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
          child: Column(
            children: [
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً، ${widget.user.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getUserRoleText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              
                              // Quick Actions
                              if (widget.user.isUser) ..._buildUserActions(),
                              if (widget.user.isProvider) ..._buildProviderActions(),
                              
                              const SizedBox(height: 30),
                              
                              // Recent Activity Section
                              _buildSectionHeader('النشاط الأخير'),
                              const SizedBox(height: 16),
                              
                              // Placeholder for recent transactions
                              Container(
                                width: double.infinity,
                                height: 200,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 48,
                                      color: AppTheme.textLight,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'لا توجد معاملات حتى الآن',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'ستظهر معاملاتك الأخيرة هنا',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textLight,
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

  String _getUserRoleText() {
    if (widget.user.isUser) {
      return 'مستخدم';
    } else if (widget.user.isProvider) {
      if (widget.user.isLender) {
        return 'مقرض';
      } else if (widget.user.isPayer) {
        return 'دافع';
      } else {
        return 'مزود خدمة';
      }
    } else if (widget.user.isAdmin) {
      return 'مدير';
    }
    return 'مستخدم';
  }

  List<Widget> _buildUserActions() {
    return [
      Row(
        children: [
          Expanded(
            child: _buildActionCard(
              title: 'رمز التحقق',
              subtitle: 'احصل على رمز OTP',
              icon: Icons.security,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => 
                        const OtpScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.ease)),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionCard(
              title: 'مزودي الخدمة',
              subtitle: 'عرض جميع المزودين',
              icon: Icons.people,
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => 
                        const ProvidersListScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.ease)),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildActionCard(
              title: 'الديون',
              subtitle: 'تتبع ديونك',
              icon: Icons.credit_card,
              color: AppTheme.warningColor,
              onTap: () {
                // TODO: Navigate to debts screen
                _showComingSoon('الديون');
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionCard(
              title: 'المدفوعات',
              subtitle: 'عرض المدفوعات',
              icon: Icons.payment,
              color: AppTheme.successColor,
              onTap: () {
                // TODO: Navigate to payments screen
                _showComingSoon('المدفوعات');
              },
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildProviderActions() {
    return [
      Row(
        children: [
          Expanded(
            child: _buildActionCard(
              title: 'معاملة جديدة',
              subtitle: widget.user.isLender ? 'إضافة دين أو دفعة' : 'إضافة دفعة',
              icon: Icons.add_card,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => 
                        CreateTransactionScreen(currentUser: widget.user),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.ease)),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionCard(
              title: 'العملاء',
              subtitle: 'إدارة العملاء',
              icon: Icons.group,
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => 
                        const ClientsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.ease)),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildActionCard(
              title: 'التقارير',
              subtitle: 'عرض الإحصائيات',
              icon: Icons.analytics,
              color: AppTheme.successColor,
              onTap: () {
                // TODO: Navigate to reports screen
                _showComingSoon('التقارير');
              },
            ),
          ),
          const SizedBox(width: 16),
          if (widget.user.isPayer)
            Expanded(
              child: _buildActionCard(
                title: 'أصحاب العمل',
                subtitle: 'إدارة أصحاب العمل',
                icon: Icons.business,
                color: AppTheme.warningColor,
                onTap: () {
                  // TODO: Navigate to employers screen
                  _showComingSoon('أصحاب العمل');
                },
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    ];
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature قريباً...'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}