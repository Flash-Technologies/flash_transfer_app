import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TransactionType { send, receive }

enum TransactionStatus { pending, completed, failed, cancelled, processing }

enum CurrencyType { fiat, crypto }

// Transaction Model
class TransactionModel {
  final String id;
  final String trackingNumber;
  final String senderName;
  final String senderEmail;
  final String receiverName;
  final String receiverEmail;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String receivingMethod;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  // Additional properties used in UI
  final TransactionType? type;
  final String? recipient;
  final DateTime? date;
  final String? avatar;
  final double? fee;
  final String? reference;
  final String? sender;
  final CurrencyType? currencyType;

  const TransactionModel({
    required this.id,
    required this.trackingNumber,
    required this.senderName,
    required this.senderEmail,
    required this.receiverName,
    required this.receiverEmail,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.receivingMethod,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.metadata,
    // Additional UI properties
    this.type,
    this.recipient,
    this.date,
    this.avatar,
    this.fee,
    this.reference,
    this.sender,
    this.currencyType,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      trackingNumber: json['trackingNumber'] ?? '',
      senderName: json['senderName'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      receiverName: json['receiverName'] ?? '',
      receiverEmail: json['receiverEmail'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      paymentMethod: json['paymentMethod'] ?? '',
      receivingMethod: json['receivingMethod'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      metadata: json['metadata'],
      // Additional UI properties
      type: json['type'] != null
          ? TransactionType.values.firstWhere(
              (e) => e.toString().split('.').last == json['type'],
              orElse: () => TransactionType.send,
            )
          : null,
      recipient: json['recipient'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      avatar: json['avatar'],
      fee: json['fee']?.toDouble(),
      reference: json['reference'],
      sender: json['sender'],
      currencyType: json['currencyType'] != null
          ? CurrencyType.values.firstWhere(
              (e) => e.toString().split('.').last == json['currencyType'],
              orElse: () => CurrencyType.fiat,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'receiverName': receiverName,
      'receiverEmail': receiverEmail,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'receivingMethod': receivingMethod,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
      // Additional UI properties
      'type': type?.toString().split('.').last,
      'recipient': recipient,
      'date': date?.toIso8601String(),
      'avatar': avatar,
      'fee': fee,
      'reference': reference,
      'sender': sender,
      'currencyType': currencyType?.toString().split('.').last,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? trackingNumber,
    String? senderName,
    String? senderEmail,
    String? receiverName,
    String? receiverEmail,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? receivingMethod,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    TransactionType? type,
    String? recipient,
    DateTime? date,
    String? avatar,
    double? fee,
    String? reference,
    String? sender,
    CurrencyType? currencyType,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverName: receiverName ?? this.receiverName,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receivingMethod: receivingMethod ?? this.receivingMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      type: type ?? this.type,
      recipient: recipient ?? this.recipient,
      date: date ?? this.date,
      avatar: avatar ?? this.avatar,
      fee: fee ?? this.fee,
      reference: reference ?? this.reference,
      sender: sender ?? this.sender,
      currencyType: currencyType ?? this.currencyType,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, trackingNumber: $trackingNumber, amount: $amount $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Recipient Model
class RecipientModel extends Equatable {
  final String id;
  final String name;
  final String country;
  final String flagAsset;
  final String? avatar;
  final double? lastSentAmount;
  final DateTime? lastSentDate;
  final bool isFavorite;
  final bool isBlocked;
  final String? email;
  final String? phone;
  final int totalTransactions;
  final double totalAmountSent;

  const RecipientModel({
    required this.id,
    required this.name,
    required this.country,
    required this.flagAsset,
    this.avatar,
    this.lastSentAmount,
    this.lastSentDate,
    this.isFavorite = false,
    this.isBlocked = false,
    this.email,
    this.phone,
    this.totalTransactions = 0,
    this.totalAmountSent = 0.0,
  });

  RecipientModel copyWith({
    String? id,
    String? name,
    String? country,
    String? flagAsset,
    String? avatar,
    double? lastSentAmount,
    DateTime? lastSentDate,
    bool? isFavorite,
    bool? isBlocked,
    String? email,
    String? phone,
    int? totalTransactions,
    double? totalAmountSent,
  }) {
    return RecipientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      flagAsset: flagAsset ?? this.flagAsset,
      avatar: avatar ?? this.avatar,
      lastSentAmount: lastSentAmount ?? this.lastSentAmount,
      lastSentDate: lastSentDate ?? this.lastSentDate,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalAmountSent: totalAmountSent ?? this.totalAmountSent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'flagAsset': flagAsset,
      'avatar': avatar,
      'lastSentAmount': lastSentAmount,
      'lastSentDate': lastSentDate?.toIso8601String(),
      'isFavorite': isFavorite,
      'isBlocked': isBlocked,
      'email': email,
      'phone': phone,
      'totalTransactions': totalTransactions,
      'totalAmountSent': totalAmountSent,
    };
  }

  factory RecipientModel.fromJson(Map<String, dynamic> json) {
    return RecipientModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      flagAsset: json['flagAsset'] ?? '',
      avatar: json['avatar'],
      lastSentAmount: json['lastSentAmount']?.toDouble(),
      lastSentDate: json['lastSentDate'] != null
          ? DateTime.parse(json['lastSentDate'])
          : null,
      isFavorite: json['isFavorite'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      email: json['email'],
      phone: json['phone'],
      totalTransactions: json['totalTransactions'] ?? 0,
      totalAmountSent: (json['totalAmountSent'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        country,
        flagAsset,
        avatar,
        lastSentAmount,
        lastSentDate,
        isFavorite,
        isBlocked,
        email,
        phone,
        totalTransactions,
        totalAmountSent,
      ];
}

// Invite Model
class InviteModel extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String country;
  final String flagAsset;
  final String? avatar;
  final InviteStatus status;
  final DateTime dateInvited;
  final DateTime? dateAccepted;
  final DateTime? dateCompleted;
  final double? rewardAmount;
  final String? referralCode;

  const InviteModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.country,
    required this.flagAsset,
    this.avatar,
    required this.status,
    required this.dateInvited,
    this.dateAccepted,
    this.dateCompleted,
    this.rewardAmount,
    this.referralCode,
  });

  InviteModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? country,
    String? flagAsset,
    String? avatar,
    InviteStatus? status,
    DateTime? dateInvited,
    DateTime? dateAccepted,
    DateTime? dateCompleted,
    double? rewardAmount,
    String? referralCode,
  }) {
    return InviteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      flagAsset: flagAsset ?? this.flagAsset,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      dateInvited: dateInvited ?? this.dateInvited,
      dateAccepted: dateAccepted ?? this.dateAccepted,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      referralCode: referralCode ?? this.referralCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        country,
        flagAsset,
        avatar,
        status,
        dateInvited,
        dateAccepted,
        dateCompleted,
        rewardAmount,
        referralCode,
      ];
}

enum InviteStatus { pending, accepted, completed, expired }

// Privacy Section Model
class PrivacySectionModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final List<PrivacySectionModel>? subsections;
  final bool isExpanded;

  const PrivacySectionModel({
    required this.id,
    required this.title,
    required this.content,
    this.subsections,
    this.isExpanded = false,
  });

  PrivacySectionModel copyWith({
    String? id,
    String? title,
    String? content,
    List<PrivacySectionModel>? subsections,
    bool? isExpanded,
  }) {
    return PrivacySectionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      subsections: subsections ?? this.subsections,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  List<Object?> get props => [id, title, content, subsections, isExpanded];
}

class Transaction {
  final String id;
  final String referenceId;
  final String type;
  final double amount;
  final double? destinationAmount;
  final double fee;
  final double totalAmount;
  final String currency;
  final double? exchangeRate;
  final String sourceType;
  final String destinationType;
  final String status;
  final int userId;
  final String? beneficiaryId;
  final String? blockchainTxHash;
  final String? destinationBlockchainTxHash;
  final String trackingNumber;
  final String? withdrawalStatus;
  final bool? cryptoTransactionConfirmed;
  final String? idempotencyKey;
  final String? webhookUrl;
  final String? kytVerificationId;
  final String? kytVerificationStatus;
  final Map<String, dynamic>? sourceDetails;
  final Map<String, dynamic>? destinationDetails;
  final Map<String, dynamic>? feeDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int version;
  final String? relatedTransactionId;
  final String? retryTransactionId;
  final String? blockchainNetwork;
  final String? destinationBlockchainNetwork;
  final String? paymentUrl;
  final String? paymentToken;
  final String? extTransactionId;
  final String? intTransactionId;
  final String? statusDescription;
  final String orderId;
  final bool isCrossChain;
  final String? sourceTransactionStatus;
  final String? destinationTransactionStatus;
  final bool useSystemLiquidity;
  final String? systemLiquidityWallet;
  final bool isUserManagedSourceWallet;
  final User? user;
  final String? beneficiary;
  final List<StatusHistory> statusHistory;

  Transaction({
    required this.id,
    required this.referenceId,
    required this.type,
    required this.amount,
    this.destinationAmount,
    required this.fee,
    required this.totalAmount,
    required this.currency,
    this.exchangeRate,
    required this.sourceType,
    required this.destinationType,
    required this.status,
    required this.userId,
    this.beneficiaryId,
    this.blockchainTxHash,
    this.destinationBlockchainTxHash,
    required this.trackingNumber,
    this.withdrawalStatus,
    this.cryptoTransactionConfirmed,
    this.idempotencyKey,
    this.webhookUrl,
    this.kytVerificationId,
    this.kytVerificationStatus,
    this.sourceDetails,
    this.destinationDetails,
    this.feeDetails,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.version,
    this.relatedTransactionId,
    this.retryTransactionId,
    this.blockchainNetwork,
    this.destinationBlockchainNetwork,
    this.paymentUrl,
    this.paymentToken,
    this.extTransactionId,
    this.intTransactionId,
    this.statusDescription,
    required this.orderId,
    required this.isCrossChain,
    this.sourceTransactionStatus,
    this.destinationTransactionStatus,
    required this.useSystemLiquidity,
    this.systemLiquidityWallet,
    required this.isUserManagedSourceWallet,
    this.user,
    this.beneficiary,
    required this.statusHistory,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      referenceId: json['referenceId'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      destinationAmount: json['destinationAmount']?.toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      exchangeRate: json['exchangeRate']?.toDouble(),
      sourceType: json['sourceType'] ?? '',
      destinationType: json['destinationType'] ?? '',
      status: json['status'] ?? '',
      userId: json['userId'] ?? 0,
      beneficiaryId: json['beneficiaryId']?.toString(),
      blockchainTxHash: json['blockchainTxHash'],
      destinationBlockchainTxHash: json['destinationBlockchainTxHash'],
      trackingNumber: json['trackingNumber'] ?? '',
      withdrawalStatus: json['withdrawalStatus'],
      cryptoTransactionConfirmed: json['cryptoTransactionConfirmed'],
      idempotencyKey: json['idempotencyKey'],
      webhookUrl: json['webhookUrl'],
      kytVerificationId: json['kytVerificationId'],
      kytVerificationStatus: json['kytVerificationStatus'],
      sourceDetails: json['sourceDetails'] is Map<String, dynamic> 
          ? json['sourceDetails'] 
          : null,
      destinationDetails: json['destinationDetails'] is Map<String, dynamic> 
          ? json['destinationDetails'] 
          : null,
      feeDetails: json['feeDetails'] is Map<String, dynamic> 
          ? json['feeDetails'] 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      version: json['version'] ?? 0,
      relatedTransactionId: json['relatedTransactionId'],
      retryTransactionId: json['retryTransactionId'],
      blockchainNetwork: json['blockchainNetwork'],
      destinationBlockchainNetwork: json['destinationBlockchainNetwork'],
      paymentUrl: json['paymentUrl'],
      paymentToken: json['paymentToken'],
      extTransactionId: json['extTransactionId'],
      intTransactionId: json['intTransactionId'],
      statusDescription: json['statusDescription'],
      orderId: json['orderId'] ?? '',
      isCrossChain: json['isCrossChain'] ?? false,
      sourceTransactionStatus: json['sourceTransactionStatus'],
      destinationTransactionStatus: json['destinationTransactionStatus'],
      useSystemLiquidity: json['useSystemLiquidity'] ?? false,
      systemLiquidityWallet: json['systemLiquidityWallet'],
      isUserManagedSourceWallet: json['isUserManagedSourceWallet'] ?? false,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      beneficiary: json['beneficiary']?.toString(),
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((e) => StatusHistory.fromJson(e))
              .toList() ??
          [],
    );
  }

  String get formattedType {
    switch (type) {
      case 'CASH_TO_CRYPTO':
        return 'Crypto Purchase';
      case 'CRYPTO_TO_CASH':
        return 'Crypto Sale';
      case 'CRYPTO_TO_CRYPTO':
        return 'Crypto Exchange';
      case 'CASH_TO_CASH':
        return 'Cash Transfer';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.refresh;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

class StatusHistory {
  final int id;
  final String transactionId;
  final String status;
  final String notes;
  final DateTime timestamp;

  StatusHistory({
    required this.id,
    required this.transactionId,
    required this.status,
    required this.notes,
    required this.timestamp,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      id: json['id'] ?? 0,
      transactionId: json['transactionId'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.refresh;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String loyaltyRank;
  final int loyaltyPoints;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.loyaltyRank,
    required this.loyaltyPoints,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      loyaltyRank: json['loyaltyRank'] ?? '',
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

class StatusDetails {
  final DateTime lastChecked;
  final String? blockchainStatus;
  final Map<String, dynamic>? loyalty;

  StatusDetails({
    required this.lastChecked,
    this.blockchainStatus,
    this.loyalty,
  });

  factory StatusDetails.fromJson(Map<String, dynamic> json) {
    return StatusDetails(
      lastChecked: DateTime.parse(json['lastChecked']),
      blockchainStatus: json['blockchainStatus'],
      loyalty: json['loyalty']?.cast<String, dynamic>(),
    );
  }
}

class TransactionStatusResponse {
  final bool success;
  final TransactionData data;
  final String message;

  TransactionStatusResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory TransactionStatusResponse.fromJson(Map<String, dynamic> json) {
    return TransactionStatusResponse(
      success: json['success'] ?? false,
      data: TransactionData.fromJson(json['data']),
      message: json['message'] ?? '',
    );
  }
}

class TransactionData {
  final Transaction transaction;
  final StatusDetails statusDetails;

  TransactionData({
    required this.transaction,
    required this.statusDetails,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    return TransactionData(
      transaction: Transaction.fromJson(json['transaction']),
      statusDetails: StatusDetails.fromJson(json['statusDetails']),
    );
  }
}
