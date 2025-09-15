class TransactionResponse {
  final String id;
  final String referenceId;
  final String type;
  final double amount;
  final double? destinationAmount;
  final double fee;
  final double totalAmount;
  final String currency;
  final double exchangeRate;
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
  final Map<String, dynamic> sourceDetails;
  final Map<String, dynamic> destinationDetails;
  final Map<String, dynamic> feeDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int version;
  final String? relatedTransactionId;
  final String? retryTransactionId;
  final String blockchainNetwork;
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
  final String message;

  TransactionResponse({
    required this.id,
    required this.referenceId,
    required this.type,
    required this.amount,
    this.destinationAmount,
    required this.fee,
    required this.totalAmount,
    required this.currency,
    required this.exchangeRate,
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
    required this.sourceDetails,
    required this.destinationDetails,
    required this.feeDetails,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.version,
    this.relatedTransactionId,
    this.retryTransactionId,
    required this.blockchainNetwork,
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
    required this.message,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      id: json['id'] as String,
      referenceId: json['referenceId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      destinationAmount: json['destinationAmount'] != null
          ? (json['destinationAmount'] as num).toDouble()
          : null,
      fee: (json['fee'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      exchangeRate: (json['exchangeRate'] as num).toDouble(),
      sourceType: json['sourceType'] as String,
      destinationType: json['destinationType'] as String,
      status: json['status'] as String,
      userId: json['userId'] as int,
      beneficiaryId: json['beneficiaryId']?.toString(),
      blockchainTxHash: json['blockchainTxHash'] as String?,
      destinationBlockchainTxHash:
          json['destinationBlockchainTxHash'] as String?,
      trackingNumber: json['trackingNumber'] as String,
      withdrawalStatus: json['withdrawalStatus'] as String?,
      cryptoTransactionConfirmed: json['cryptoTransactionConfirmed'] as bool?,
      idempotencyKey: json['idempotencyKey'] as String?,
      webhookUrl: json['webhookUrl'] as String?,
      kytVerificationId: json['kytVerificationId'] as String?,
      kytVerificationStatus: json['kytVerificationStatus'] as String?,
      sourceDetails: json['sourceDetails'] as Map<String, dynamic>,
      destinationDetails: json['destinationDetails'] as Map<String, dynamic>,
      feeDetails: json['feeDetails'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      version: json['version'] as int,
      relatedTransactionId: json['relatedTransactionId'] as String?,
      retryTransactionId: json['retryTransactionId'] as String?,
      blockchainNetwork: json['blockchainNetwork'] as String,
      destinationBlockchainNetwork:
          json['destinationBlockchainNetwork'] as String?,
      paymentUrl: json['paymentUrl'] as String?,
      paymentToken: json['paymentToken'] as String?,
      extTransactionId: json['extTransactionId'] as String?,
      intTransactionId: json['intTransactionId'] as String?,
      statusDescription: json['statusDescription'] as String?,
      orderId: json['orderId'] as String,
      isCrossChain: json['isCrossChain'] as bool,
      sourceTransactionStatus: json['sourceTransactionStatus'] as String?,
      destinationTransactionStatus:
          json['destinationTransactionStatus'] as String?,
      useSystemLiquidity: json['useSystemLiquidity'] as bool,
      systemLiquidityWallet: json['systemLiquidityWallet'] as String?,
      isUserManagedSourceWallet: json['isUserManagedSourceWallet'] as bool,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceId': referenceId,
      'type': type,
      'amount': amount,
      'destinationAmount': destinationAmount,
      'fee': fee,
      'totalAmount': totalAmount,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'sourceType': sourceType,
      'destinationType': destinationType,
      'status': status,
      'userId': userId,
      'beneficiaryId': beneficiaryId,
      'blockchainTxHash': blockchainTxHash,
      'destinationBlockchainTxHash': destinationBlockchainTxHash,
      'trackingNumber': trackingNumber,
      'withdrawalStatus': withdrawalStatus,
      'cryptoTransactionConfirmed': cryptoTransactionConfirmed,
      'idempotencyKey': idempotencyKey,
      'webhookUrl': webhookUrl,
      'kytVerificationId': kytVerificationId,
      'kytVerificationStatus': kytVerificationStatus,
      'sourceDetails': sourceDetails,
      'destinationDetails': destinationDetails,
      'feeDetails': feeDetails,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'version': version,
      'relatedTransactionId': relatedTransactionId,
      'retryTransactionId': retryTransactionId,
      'blockchainNetwork': blockchainNetwork,
      'destinationBlockchainNetwork': destinationBlockchainNetwork,
      'paymentUrl': paymentUrl,
      'paymentToken': paymentToken,
      'extTransactionId': extTransactionId,
      'intTransactionId': intTransactionId,
      'statusDescription': statusDescription,
      'orderId': orderId,
      'isCrossChain': isCrossChain,
      'sourceTransactionStatus': sourceTransactionStatus,
      'destinationTransactionStatus': destinationTransactionStatus,
      'useSystemLiquidity': useSystemLiquidity,
      'systemLiquidityWallet': systemLiquidityWallet,
      'isUserManagedSourceWallet': isUserManagedSourceWallet,
      'message': message,
    };
  }

  // Backward compatibility getters
  String get transactionId => id;
}

class PaymentInstructions {
  final String method;
  final String recipientAddress;
  final double amount;
  final String currency;
  final String network;
  final String? reference;
  final Map<String, dynamic>? additionalInfo;

  PaymentInstructions({
    required this.method,
    required this.recipientAddress,
    required this.amount,
    required this.currency,
    required this.network,
    this.reference,
    this.additionalInfo,
  });

  factory PaymentInstructions.fromJson(Map<String, dynamic> json) {
    return PaymentInstructions(
      method: json['method'] as String,
      recipientAddress: json['recipientAddress'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      network: json['network'] as String,
      reference: json['reference'] as String?,
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'recipientAddress': recipientAddress,
      'amount': amount,
      'currency': currency,
      'network': network,
      'reference': reference,
      'additionalInfo': additionalInfo,
    };
  }
}
