import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';
import 'otp_verification_screen.dart';

class CreateTransactionScreen extends StatefulWidget {
  final User currentUser;
  final LinkedClient? selectedClient;
  
  const CreateTransactionScreen({
    super.key, 
    required this.currentUser,
    this.selectedClient,
  });

  @override
  State<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedTransactionType = 'payment'; // 'debt' or 'payment'
  LinkedClient? _selectedClient;
  List<LinkedClient> _clients = [];
  bool _isLoading = false;
  bool _isLoadingClients = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _selectedClient = widget.selectedClient;
    
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
    
    _loadClients();
    _animationController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final response = await ApiService().getMyClients();
      setState(() {
        if (response.success && response.data != null) {
          _clients = response.data!;
          // Set first approved client as default if none selected
          if (_selectedClient == null && _clients.isNotEmpty) {
            _selectedClient = _clients.firstWhere(
              (client) => client.status == LinkStatus.approved,
              orElse: () => _clients.first,
            );
          }
        }
        _isLoadingClients = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingClients = false;
      });
      _showError('خطأ في تحميل العملاء');
    }
  }

  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate() || _selectedClient == null) {
      _showError('يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    setState(() => _isLoading = true);

    if (_selectedTransactionType == 'payment') {
      // Payment transaction - direct creation (auto-approved)
      await _createPaymentTransaction();
    } else {
      // Debt transaction - needs OTP verification
      await _createDebtTransaction();
    }
  }

  Future<void> _createPaymentTransaction() async {
    try {
      final response = await ApiService().createTransaction(
        userId: _selectedClient!.userId,
        type: 'payment',
        amount: _amountController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (response.success) {
        _showSuccess('تم إنشاء المعاملة بنجاح');
        _clearForm();
      } else {
        _showError(response.error ?? 'خطأ في إنشاء المعاملة');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في الاتصال بالخادم');
    }
  }

  Future<void> _createDebtTransaction() async {
    setState(() => _isLoading = false);
    
    // Navigate to OTP verification screen
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OtpVerificationScreen(
              userId: _selectedClient!.userId,
              amount: _amountController.text.trim(),
              description: _descriptionController.text.trim(),
              clientName: _selectedClient!.userName,
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
    );

    // If debt was successfully created, clear form
    if (result == true) {
      _clearForm();
    }
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedTransactionType = 'payment';
    });
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
      appBar: AppBar(
        title: const Text('إنشاء معاملة جديدة'),
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
                // Header Info
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.currentUser.isLender ? Icons.store : Icons.engineering,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.currentUser.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.currentUser.isLender ? 'مُقرض' : 'دافع',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Transaction Form
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
                            // Transaction Type Selection
                            const Text(
                              'نوع المعاملة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                // Payment option (always available)
                                Expanded(
                                  child: _buildTransactionTypeCard(
                                    type: 'payment',
                                    title: 'دفعة',
                                    subtitle: widget.currentUser.isLender 
                                        ? 'دفعة للعميل' 
                                        : 'دفعة للعامل',
                                    icon: Icons.trending_down,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                                
                                // Debt option (only for lenders)
                                if (widget.currentUser.isLender) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTransactionTypeCard(
                                      type: 'debt',
                                      title: 'دين',
                                      subtitle: 'دين على العميل',
                                      icon: Icons.trending_up,
                                      color: AppTheme.warningColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Client Selection
                            const Text(
                              'العميل',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            if (_isLoadingClients)
                              const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                            else if (_clients.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Text(
                                  'لا توجد عملاء مرتبطين',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              )
                            else
                              DropdownButtonFormField<LinkedClient>(
                                value: _selectedClient,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.person),
                                  hintText: 'اختر العميل',
                                ),
                                items: _clients
                                    .where((client) => client.status == LinkStatus.approved)
                                    .map((client) => DropdownMenuItem(
                                          value: client,
                                          child: Text(client.userName),
                                        ))
                                    .toList(),
                                onChanged: (client) {
                                  setState(() {
                                    _selectedClient = client;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'يرجى اختيار العميل';
                                  }
                                  return null;
                                },
                              ),

                            const SizedBox(height: 20),

                            // Amount Field
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'المبلغ',
                                prefixIcon: Icon(Icons.attach_money),
                                suffixText: 'ريال',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال المبلغ';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'يرجى إدخال مبلغ صحيح';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Description Field
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'الوصف (اختياري)',
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 32),

                            // Create Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _createTransaction,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(_selectedTransactionType == 'debt' 
                                        ? Icons.security 
                                        : Icons.check),
                                label: Text(_selectedTransactionType == 'debt' 
                                    ? 'التالي - التحقق بـ OTP' 
                                    : 'إنشاء المعاملة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedTransactionType == 'debt' 
                                      ? AppTheme.warningColor 
                                      : AppTheme.successColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),

                            // Info note for debt transactions
                            if (_selectedTransactionType == 'debt') ...[
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
                                      Icons.info_outline,
                                      color: AppTheme.warningColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'ستحتاج إلى رمز التحقق من العميل لإتمام الدين',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTransactionType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTransactionType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
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