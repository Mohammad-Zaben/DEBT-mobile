import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final LinkedProvider provider;
  
  const TransactionHistoryScreen({super.key, required this.provider});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  List<Transaction> _transactions = [];
  BalanceSummary? _balance;
  bool _isLoading = true;
  String? _error;
  
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
    
    _loadTransactions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current user to determine user ID
      final userResponse = await ApiService().getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        setState(() {
          _error = 'خطأ في جلب بيانات المستخدم';
          _isLoading = false;
        });
        return;
      }
      
      final userId = userResponse.data!.id;
      final providerId = widget.provider.providerId;
      
      // Load transactions and balance in parallel
      final transactionsResponse = await ApiService().getTransactionsPair(userId, providerId);
      final balanceResponse = await ApiService().getBalance(userId, providerId);
      
      setState(() {
        if (transactionsResponse.success && transactionsResponse.data != null) {
          _transactions = transactionsResponse.data!;
        } else {
          _error = transactionsResponse.error ?? 'خطأ في تحميل المعاملات';
        }
        
        if (balanceResponse.success && balanceResponse.data != null) {
          _balance = balanceResponse.data!;
        }
        
        _isLoading = false;
      });
      
      if (_transactions.isNotEmpty || _balance != null) {
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
        title: Text(widget.provider.providerName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
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
              'جاري تحميل المعاملات...',
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
              onPressed: _loadTransactions,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Balance Summary Card
          if (_balance != null) _buildBalanceCard(),
          
          // Transactions List
          Expanded(
            child: _transactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isLender = widget.provider.providerType == 'lender';
    final balance = double.parse(_balance!.balance);
    final isPositive = balance >= 0;
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLender
                ? (isPositive 
                    ? [AppTheme.warningColor, AppTheme.warningColor.withOpacity(0.8)]
                    : [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)])
                : [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isLender ? AppTheme.warningColor : AppTheme.successColor).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isLender 
                      ? (isPositive ? Icons.trending_up : Icons.trending_down)
                      : Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLender ? 'الرصيد' : 'إجمالي المدفوعات',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_balance!.balance} ريال',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (isLender) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white30),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إجمالي الديون',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_balance!.totalDebt} ريال',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إجمالي المدفوعات',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_balance!.totalPayments} ريال',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction, index);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction, int index) {
    final isDebt = transaction.type == TransactionType.debt;
    final isPending = transaction.status == TransactionStatus.pending;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Transaction Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isDebt ? AppTheme.warningColor : AppTheme.successColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isDebt ? Icons.trending_up : Icons.trending_down,
                  color: isDebt ? AppTheme.warningColor : AppTheme.successColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isDebt ? 'دين' : 'دفعة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDebt ? AppTheme.warningColor : AppTheme.successColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${transaction.amount} ريال',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.description ?? (isDebt ? 'دين جديد' : 'دفعة'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(transaction.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPending 
                                ? AppTheme.warningColor.withOpacity(0.1)
                                : AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPending ? 'في الانتظار' : 'مؤكد',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPending ? AppTheme.warningColor : AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد معاملات',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم تتم أي معاملات مع ${widget.provider.providerName}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}