import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';
import 'transaction_history_screen.dart';

class ProvidersListScreen extends StatefulWidget {
  const ProvidersListScreen({super.key});

  @override
  State<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends State<ProvidersListScreen>
    with TickerProviderStateMixin {
  List<LinkedProvider> _providers = [];
  bool _isLoading = true;
  String? _error;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    
    _loadProviders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService().getMyProviders();
      
      setState(() {
        if (response.success && response.data != null) {
          _providers = response.data!;
        } else {
          _error = response.error ?? 'خطأ في تحميل البيانات';
        }
        _isLoading = false;
      });
      
      if (_providers.isNotEmpty) {
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مزودو الخدمة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProviders,
        color: AppTheme.primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'جاري تحميل مزودي الخدمة...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProviders,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مزودو خدمة',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'لم تقم بربط أي مزود خدمة بعد',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to add provider screen
                _showComingSoon('إضافة مزود خدمة');
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة مزود خدمة'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _providers.length,
        itemBuilder: (context, index) {
          final provider = _providers[index];
          return _buildProviderCard(provider, index);
        },
      ),
    );
  }

  Widget _buildProviderCard(LinkedProvider provider, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: provider.status == LinkStatus.approved
              ? () => _navigateToTransactionHistory(provider)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Provider Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getProviderColor(provider.providerType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        _getProviderIcon(provider.providerType),
                        size: 30,
                        color: _getProviderColor(provider.providerType),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Provider Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.providerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getProviderTypeText(provider.providerType),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getProviderColor(provider.providerType),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    _buildStatusBadge(provider.status),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Provider Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.providerEmail,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'مرتبط منذ ${_formatDate(provider.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Button
                if (provider.status == LinkStatus.approved) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToTransactionHistory(provider),
                      icon: const Icon(Icons.history),
                      label: const Text('عرض المعاملات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getProviderColor(provider.providerType),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LinkStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case LinkStatus.approved:
        color = AppTheme.successColor;
        text = 'مرتبط';
        icon = Icons.check_circle;
        break;
      case LinkStatus.pending:
        color = AppTheme.warningColor;
        text = 'في الانتظار';
        icon = Icons.pending;
        break;
      case LinkStatus.rejected:
        color = AppTheme.errorColor;
        text = 'مرفوض';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProviderColor(String? providerType) {
    switch (providerType) {
      case 'lender':
        return AppTheme.warningColor;
      case 'payer':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getProviderIcon(String? providerType) {
    switch (providerType) {
      case 'lender':
        return Icons.store;
      case 'payer':
        return Icons.engineering;
      default:
        return Icons.business;
    }
  }

  String _getProviderTypeText(String? providerType) {
    switch (providerType) {
      case 'lender':
        return 'مُقرض (محل أو متجر)';
      case 'payer':
        return 'دافع (مقاول)';
      default:
        return 'مزود خدمة';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'اليوم';
    } else if (difference == 1) {
      return 'أمس';
    } else if (difference < 7) {
      return '$difference أيام';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks ${weeks == 1 ? 'أسبوع' : 'أسابيع'}';
    } else {
      final months = (difference / 30).floor();
      return '$months ${months == 1 ? 'شهر' : 'أشهر'}';
    }
  }

  void _navigateToTransactionHistory(LinkedProvider provider) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TransactionHistoryScreen(provider: provider),
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