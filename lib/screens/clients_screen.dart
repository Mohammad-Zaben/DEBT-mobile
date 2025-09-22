import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';
import 'add_client_screen.dart';
import 'transaction_history_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen>
    with TickerProviderStateMixin {
  List<LinkedClient> _clients = [];
  Map<int, BalanceSummary> _balances = {};
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
    
    _loadClients();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current user to get provider ID
      final userResponse = await ApiService().getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        setState(() {
          _error = 'خطأ في جلب بيانات المستخدم';
          _isLoading = false;
        });
        return;
      }
      
      final providerId = userResponse.data!.id;
      
      // Load clients
      final clientsResponse = await ApiService().getMyClients();
      
      if (clientsResponse.success && clientsResponse.data != null) {
        final clients = clientsResponse.data!;
        
        // Load balances for each approved client
        final Map<int, BalanceSummary> balances = {};
        
        for (final client in clients) {
          if (client.status == LinkStatus.approved) {
            try {
              final balanceResponse = await ApiService().getBalance(client.userId, providerId);
              if (balanceResponse.success && balanceResponse.data != null) {
                balances[client.userId] = balanceResponse.data!;
              }
            } catch (e) {
              // Continue loading other balances if one fails
              print('Failed to load balance for client ${client.userId}: $e');
            }
          }
        }
        
        setState(() {
          _clients = clients;
          _balances = balances;
          _isLoading = false;
        });
        
        if (_clients.isNotEmpty) {
          _animationController.forward();
        }
      } else {
        setState(() {
          _error = clientsResponse.error ?? 'خطأ في تحميل العملاء';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddClient() async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddClientScreen(),
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

    // Reload clients if a new client was added
    if (result == true) {
      _loadClients();
    }
  }

  Future<void> _navigateToTransactionHistory(LinkedClient client) async {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TransactionHistoryScreen(client: client),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العملاء'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _navigateToAddClient,
            tooltip: 'إضافة عميل جديد',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadClients,
        color: AppTheme.primaryColor,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddClient,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add),
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
              'جاري تحميل العملاء...',
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
              onPressed: _loadClients,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_clients.isEmpty) {
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
              'لا توجد عملاء',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'لم تقم بربط أي عميل بعد',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddClient,
              icon: const Icon(Icons.person_add),
              label: const Text('إضافة عميل جديد'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Summary Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إجمالي العملاء',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_clients.length} عميل',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'مرتبط: ${_clients.where((c) => c.status == LinkStatus.approved).length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'في الانتظار: ${_clients.where((c) => c.status == LinkStatus.pending).length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Clients List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _clients.length,
              itemBuilder: (context, index) {
                final client = _clients[index];
                return _buildClientCard(client, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(LinkedClient client, int index) {
    final balance = _balances[client.userId];
    final isApproved = client.status == LinkStatus.approved;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: isApproved ? () => _navigateToTransactionHistory(client) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Client Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getStatusColor(client.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: _getStatusColor(client.status),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Client Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'رقم العميل: ${client.userId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    _buildStatusBadge(client.status),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Client Details
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
                              client.userEmail,
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
                            'مرتبط منذ ${_formatDate(client.createdAt)}',
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
                
                // Balance Info (only for approved clients)
                if (isApproved && balance != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          _getBalanceColor(balance.balance).withOpacity(0.1),
                          _getBalanceColor(balance.balance).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getBalanceColor(balance.balance).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getBalanceIcon(balance.balance),
                          color: _getBalanceColor(balance.balance),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الرصيد الحالي',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${balance.balance} ريال',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getBalanceColor(balance.balance),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action Buttons
                if (isApproved) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToTransactionHistory(client),
                      icon: const Icon(Icons.history),
                      label: const Text('عرض المعاملات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ] else if (client.status == LinkStatus.pending) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          color: AppTheme.warningColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'في انتظار موافقة العميل',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
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

  Color _getStatusColor(LinkStatus status) {
    switch (status) {
      case LinkStatus.approved:
        return AppTheme.successColor;
      case LinkStatus.pending:
        return AppTheme.warningColor;
      case LinkStatus.rejected:
        return AppTheme.errorColor;
    }
  }

  Color _getBalanceColor(String balanceStr) {
    final balance = double.parse(balanceStr);
    if (balance > 0) {
      return AppTheme.warningColor; // Client owes money
    } else if (balance < 0) {
      return AppTheme.successColor; // Provider owes money (overpaid)
    } else {
      return AppTheme.textSecondary; // Balanced
    }
  }

  IconData _getBalanceIcon(String balanceStr) {
    final balance = double.parse(balanceStr);
    if (balance > 0) {
      return Icons.trending_up; // Client owes money
    } else if (balance < 0) {
      return Icons.trending_down; // Provider owes money (overpaid)
    } else {
      return Icons.balance; // Balanced
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
}