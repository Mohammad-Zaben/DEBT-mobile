// User Models
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? providerType;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.providerType,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      providerType: json['provider_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isUser => role == 'User';
  bool get isProvider => role == 'Provider';
  bool get isAdmin => role == 'Admin';
  bool get isLender => providerType == 'lender';
  bool get isPayer => providerType == 'payer';
}

// User Public Info Model (for searching users)
class UserPublicInfo {
  final int id;
  final String name;
  final String email;

  UserPublicInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserPublicInfo.fromJson(Map<String, dynamic> json) {
    return UserPublicInfo(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

// Provider Models
class LinkedProvider {
  final int id;
  final int providerId;
  final String providerName;
  final String providerEmail;
  final LinkStatus status;
  final DateTime createdAt;
  final String? providerType; // 'lender' or 'payer' - can be null from API

  LinkedProvider({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerEmail,
    required this.status,
    required this.createdAt,
    this.providerType,
  });

  factory LinkedProvider.fromJson(Map<String, dynamic> json) {
    return LinkedProvider(
      id: json['id'],
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      providerEmail: json['provider_email'],
      status: LinkStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      providerType: json['provider_type'],
    );
  }
}

class LinkedClient {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final LinkStatus status;
  final DateTime createdAt;

  LinkedClient({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.createdAt,
  });

  factory LinkedClient.fromJson(Map<String, dynamic> json) {
    return LinkedClient(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userEmail: json['user_email'],
      status: LinkStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class UserProviderLink {
  final int id;
  final int userId;
  final int providerId;
  final LinkStatus status;
  final DateTime createdAt;

  UserProviderLink({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.status,
    required this.createdAt,
  });

  factory UserProviderLink.fromJson(Map<String, dynamic> json) {
    return UserProviderLink(
      id: json['id'],
      userId: json['user_id'],
      providerId: json['provider_id'],
      status: LinkStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

enum LinkStatus { pending, approved, rejected }

// Transaction Models
class Transaction {
  final int id;
  final int userId;
  final int providerId;
  final TransactionType type;
  final String amount;
  final TransactionStatus status;
  final DateTime date;
  final String? description;

  Transaction({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.type,
    required this.amount,
    required this.status,
    required this.date,
    this.description,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      providerId: json['provider_id'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      amount: json['amount'].toString(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }
}

enum TransactionType { debt, payment }
enum TransactionStatus { pending, confirmed }

// Balance Models
class BalanceSummary {
  final int userId;
  final int providerId;
  final String totalDebt;
  final String totalPayments;
  final String balance;

  BalanceSummary({
    required this.userId,
    required this.providerId,
    required this.totalDebt,
    required this.totalPayments,
    required this.balance,
  });

  factory BalanceSummary.fromJson(Map<String, dynamic> json) {
    return BalanceSummary(
      userId: json['user_id'],
      providerId: json['provider_id'],
      totalDebt: json['total_debt'].toString(),
      totalPayments: json['total_payments'].toString(),
      balance: json['balance'].toString(),
    );
  }
}

// Employer Models (for Payer providers)
class Employer {
  final int id;
  final String name;
  final String? contactInfo;
  final int createdBy;
  final DateTime createdAt;
  final int paymentCount;

  Employer({
    required this.id,
    required this.name,
    this.contactInfo,
    required this.createdBy,
    required this.createdAt,
    this.paymentCount = 0,
  });

  factory Employer.fromJson(Map<String, dynamic> json) {
    return Employer(
      id: json['id'],
      name: json['name'],
      contactInfo: json['contact_info'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      paymentCount: json['payment_count'] ?? 0,
    );
  }
}

// Work Payment Models (for Payer providers)
class WorkPayment {
  final int id;
  final int employerId;
  final String employerName;
  final int providerId;
  final String amount;
  final String? description;
  final DateTime? paymentDate;
  final DateTime createdAt;

  WorkPayment({
    required this.id,
    required this.employerId,
    required this.employerName,
    required this.providerId,
    required this.amount,
    this.description,
    this.paymentDate,
    required this.createdAt,
  });

  factory WorkPayment.fromJson(Map<String, dynamic> json) {
    return WorkPayment(
      id: json['id'],
      employerId: json['employer_id'],
      employerName: json['employer_name'],
      providerId: json['provider_id'],
      amount: json['amount'].toString(),
      description: json['description'],
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class WorkPaymentSummary {
  final int totalPayments;
  final String totalAmount;
  final int employersCount;
  final DateTime? lastPaymentDate;

  WorkPaymentSummary({
    required this.totalPayments,
    required this.totalAmount,
    required this.employersCount,
    this.lastPaymentDate,
  });

  factory WorkPaymentSummary.fromJson(Map<String, dynamic> json) {
    return WorkPaymentSummary(
      totalPayments: json['total_payments'],
      totalAmount: json['total_amount'].toString(),
      employersCount: json['employers_count'],
      lastPaymentDate: json['last_payment_date'] != null 
          ? DateTime.parse(json['last_payment_date'])
          : null,
    );
  }
}


// Add this class to your existing lib/models/models.dart file

class UserProviderInvitation {
  final int id;
  final int providerId;
  final String providerName;
  final String providerEmail;
  final LinkStatus status;
  final DateTime createdAt;

  UserProviderInvitation({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerEmail,
    required this.status,
    required this.createdAt,
  });

  factory UserProviderInvitation.fromJson(Map<String, dynamic> json) {
    return UserProviderInvitation(
      id: json['id'],
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      providerEmail: json['provider_email'],
      status: LinkStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}