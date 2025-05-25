import 'package:equatable/equatable.dart';

enum TransactionType { send, receive }
enum TransactionStatus { pending, completed, failed, cancelled, processing }
enum CurrencyType { fiat, crypto }

// Transaction Model
class TransactionModel extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;
  final String currency;
  final String recipient;
  final String? sender;
  final DateTime date;
  final TransactionStatus status;
  final String? avatar;
  final double? fee;
  final String? reference;
  final String? description;
  final String? trackingNumber;
  final CurrencyType currencyType;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.recipient,
    this.sender,
    required this.date,
    required this.status,
    this.avatar,
    this.fee,
    this.reference,
    this.description,
    this.trackingNumber,
    this.currencyType = CurrencyType.fiat,
  });

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? currency,
    String? recipient,
    String? sender,
    DateTime? date,
    TransactionStatus? status,
    String? avatar,
    double? fee,
    String? reference,
    String? description,
    String? trackingNumber,
    CurrencyType? currencyType,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      recipient: recipient ?? this.recipient,
      sender: sender ?? this.sender,
      date: date ?? this.date,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      fee: fee ?? this.fee,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      currencyType: currencyType ?? this.currencyType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'amount': amount,
      'currency': currency,
      'recipient': recipient,
      'sender': sender,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'avatar': avatar,
      'fee': fee,
      'reference': reference,
      'description': description,
      'trackingNumber': trackingNumber,
      'currencyType': currencyType.toString().split('.').last,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.send,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      recipient: json['recipient'] ?? '',
      sender: json['sender'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      avatar: json['avatar'],
      fee: json['fee']?.toDouble(),
      reference: json['reference'],
      description: json['description'],
      trackingNumber: json['trackingNumber'],
      currencyType: CurrencyType.values.firstWhere(
        (e) => e.toString().split('.').last == json['currencyType'],
        orElse: () => CurrencyType.fiat,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id, type, amount, currency, recipient, sender, date, status,
    avatar, fee, reference, description, trackingNumber, currencyType
  ];
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
    id, name, country, flagAsset, avatar, lastSentAmount, lastSentDate,
    isFavorite, isBlocked, email, phone, totalTransactions, totalAmountSent
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
    id, name, email, phone, country, flagAsset, avatar, status,
    dateInvited, dateAccepted, dateCompleted, rewardAmount, referralCode
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