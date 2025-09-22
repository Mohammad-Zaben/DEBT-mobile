import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';
import 'create_transaction_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final LinkedProvider? provider;
  final LinkedClient? client;
  
  const TransactionHistoryScreen({
    super.key, 
    this.provider,
    this.client,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  List<Transaction> _transactions = [];
  BalanceSummary? _balance;
  bool _isLoading = true;
  String? _error;
  User? _currentUser;
  
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
      // Get current user first
      final userResponse = await ApiService().getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        setState(() {
          _error = 'خطأ في جلب بيانات المستخدم';
          _isLoading = false;
        });
        return;
      }
      
      _currentUser = userResponse.data!;
      
      // Determine user ID and provider ID based on context
      int userId, providerId;
      
      if (widget.provider != null) {
        // Called from user's perspective (viewing provider transactions)
        userId = _currentUser!.id;
        providerId = widget.provider!.providerId;
      } else if (widget.client != null) {
        // Called from provider's perspective (viewing client transactions)
        userId = widget.client!.userId;
        providerId = _currentUser!.id;
      } else {
        setState(() {
          _error = 'خطأ في البيانات المرسلة';
          _isLoading = false;
        });
        return;
      }
      
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

  void _navigateToCreateTransaction() {
    if (_currentUser == null) return;
    
    // Create LinkedClient object for the create transaction screen
    LinkedClient? targetClient;
    
    if (widget.client != null) {
      // Provider viewing client - pass the client directly
      targetClient = widget.client!;
    } else if (widget.provider != null) {
      // User viewing provider - this shouldn't happen as users don't create transactions
      // But we handle it just in case
      return;
    }
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CreateTransactionScreen(
              currentUser: _currentUser!,
              selectedClient: targetClient,
            ),
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
    ).then((result) {
      // Reload transactions if a new transaction was created
      if (result == true) {
        _loadTransactions();
      }
    });
  }

  String _getScreenTitle() {
    if (widget.provider != null) {
      return widget.provider!.providerName;
    } else if (widget.client != null) {
      return widget.client!.userName;
    } else {
      return 'المعاملات';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Show add transaction button only for providers viewing client transactions
          if (_currentUser != null && 
              _currentUser!.isProvider && 
              widget.client != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _navigateToCreateTransaction,
              tooltip: 'إضافة معاملة جديدة',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        color: AppTheme.primaryColor,
        child: _buildBody(),
      ),
      // Floating action button for providers
      floatingActionButton: (_currentUser != null && 
                           _currentUser!.isProvider && 
                           widget.client != null)
          ? FloatingActionButton(
              onPressed: _navigateToCreateTransaction,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
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
          
          // Add Transaction Card (for providers)
          if (_currentUser != null && 
              _currentUser!.isProvider && 
              widget.client != null)
            _buildAddTransactionCard(),
          
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
    final isProvider = _currentUser?.isProvider ?? false;
    final isLender = _currentUser?.isLender ?? false;
    final balance = double.parse(_balance!.balance);
    final isPositive = balance >= 0;
    
    Color cardColor;
    String balanceTitle;
    
    if (isProvider) {
      if (isLender) {
        // Lender provider - positive balance means client owes money
        cardColor = isPositive ? AppTheme.warningColor : AppTheme.successColor;
        balanceTitle = 'الرصيد';
      } else {
        // Payer provider - balance represents payments made
        cardColor = AppTheme.successColor;
        balanceTitle = 'إجمالي المدفوعات';
      }
    } else {
      // User viewing provider - positive balance means they owe money
      cardColor = isPositive ? AppTheme.warningColor : AppTheme.successColor;
      balanceTitle = 'الرصيد';
    }
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor,
              cardColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
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
                  isProvider && isLender
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
                        balanceTitle,
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
            
            if (isProvider && isLender) ...[
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

  Widget _buildAddTransactionCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: _navigateToCreateTransaction,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.add_card,
                      color: AppTheme.primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إضافة معاملة جديدة',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser!.isLender 
                              ? 'إضافة دين أو دفعة لهذا العميل'
                              : 'إضافة دفعة لهذا العميل',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textLight,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
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
            widget.client != null 
                ? 'لم تتم أي معاملات مع ${widget.client!.userName}'
                : 'لم تتم أي معاملات بعد',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Add transaction button for empty state
          if (_currentUser != null && 
              _currentUser!.isProvider && 
              widget.client != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateTransaction,
              icon: const Icon(Icons.add),
              label: const Text('إضافة معاملة أولى'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
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