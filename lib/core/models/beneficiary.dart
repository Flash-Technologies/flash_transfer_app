class Beneficiary {
  final int id;
  final String name;
  final String accountType;
  final Map<String, dynamic> accountDetails;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String city;
  final String country;
  final String email;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String purpose;
  final String sourceOfFunds;
  final String state;
  final String streetAddress;
  final String zipCode;

  Beneficiary({
    required this.id,
    required this.name,
    required this.accountType,
    required this.accountDetails,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.city,
    required this.country,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.purpose,
    required this.sourceOfFunds,
    required this.state,
    required this.streetAddress,
    required this.zipCode,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      accountType: json['accountType'] ?? '',
      accountDetails: json['accountDetails'] ?? {},
      userId: json['userId'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      purpose: json['purpose'] ?? '',
      sourceOfFunds: json['sourceOfFunds'] ?? '',
      state: json['state'] ?? '',
      streetAddress: json['streetAddress'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountType': accountType,
      'accountDetails': accountDetails,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'city': city,
      'country': country,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'purpose': purpose,
      'sourceOfFunds': sourceOfFunds,
      'state': state,
      'streetAddress': streetAddress,
      'zipCode': zipCode,
    };
  }

  String get fullName => '$firstName $lastName';
  String get displayName => name.isNotEmpty ? name : fullName;
  String get fullAddress => '$streetAddress, $city, $state $zipCode';
}

class BeneficiaryResponse {
  final bool success;
  final BeneficiaryData data;
  final String message;

  BeneficiaryResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory BeneficiaryResponse.fromJson(Map<String, dynamic> json) {
    return BeneficiaryResponse(
      success: json['success'] ?? false,
      data: BeneficiaryData.fromJson(json['data'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class BeneficiaryData {
  final List<Beneficiary> data;
  final BeneficiaryPagination pagination;

  BeneficiaryData({
    required this.data,
    required this.pagination,
  });

  factory BeneficiaryData.fromJson(Map<String, dynamic> json) {
    return BeneficiaryData(
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Beneficiary.fromJson(item))
          .toList() ?? [],
      pagination: BeneficiaryPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class BeneficiaryPagination {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  BeneficiaryPagination({
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory BeneficiaryPagination.fromJson(Map<String, dynamic> json) {
    return BeneficiaryPagination(
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      itemsPerPage: json['itemsPerPage'] ?? 20,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}