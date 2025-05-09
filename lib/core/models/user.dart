class User {
  final int? id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final bool? twoFactorEnabled;
  final int? loyaltyPoints;
  final String? loyaltyRank;
  final String? walletAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isAdmin;
  final bool? isKycVerified;
  final String? authMethod;
  final bool? emailVerified;
  final bool? isActive;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final String? profileImage;
  final String? socialProvider;
  final String? countryName;
  final String? city;
  final String? dob;
  final String? gender;
  final String? permanentAddress;
  final String? postalCode;
  final String? presentAddress;
  final String? state;
  final String? token;

  User({
    this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.twoFactorEnabled,
    this.loyaltyPoints,
    this.loyaltyRank,
    this.walletAddress,
    this.createdAt,
    this.updatedAt,
    this.isAdmin,
    this.isKycVerified,
    this.authMethod,
    this.emailVerified,
    this.isActive,
    this.lastLoginAt,
    this.lastLoginIp,
    this.profileImage,
    this.socialProvider,
    this.countryName,
    this.city,
    this.dob,
    this.gender,
    this.permanentAddress,
    this.postalCode,
    this.presentAddress,
    this.state,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      twoFactorEnabled: json['twoFactorEnabled'],
      loyaltyPoints: json['loyaltyPoints'],
      loyaltyRank: json['loyaltyRank'],
      walletAddress: json['walletAddress'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isAdmin: json['isAdmin'],
      isKycVerified: json['isKycVerified'],
      authMethod: json['authMethod'],
      emailVerified: json['emailVerified'],
      isActive: json['isActive'],
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt']) : null,
      lastLoginIp: json['lastLoginIp'],
      profileImage: json['profileImage'],
      socialProvider: json['socialProvider'],
      countryName: json['countryName'],
      city: json['city'],
      dob: json['dob'],
      gender: json['gender'],
      permanentAddress: json['permanentAddress'],
      postalCode: json['postalCode'],
      presentAddress: json['presentAddress'],
      state: json['state'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'twoFactorEnabled': twoFactorEnabled,
      'loyaltyPoints': loyaltyPoints,
      'loyaltyRank': loyaltyRank,
      'walletAddress': walletAddress,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isAdmin': isAdmin,
      'isKycVerified': isKycVerified,
      'authMethod': authMethod,
      'emailVerified': emailVerified,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'lastLoginIp': lastLoginIp,
      'profileImage': profileImage,
      'socialProvider': socialProvider,
      'countryName': countryName,
      'city': city,
      'dob': dob,
      'gender': gender,
      'permanentAddress': permanentAddress,
      'postalCode': postalCode,
      'presentAddress': presentAddress,
      'state': state,
      'token': token,
    };
  }
}