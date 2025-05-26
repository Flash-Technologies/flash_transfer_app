import 'user.dart';

class RegisterRequest {
  final String email;
  final String password;
  final String countryName;
  final String? requestType;
  final String firstName;
  final String lastName;
  final String dob;
  final String permanentAddress;
  final String presentAddress;
  final String state;
  final String city;
  final String postalCode;
  final String gender;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.countryName,
    this.requestType = 'MOBILE',
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.permanentAddress,
    required this.presentAddress,
    required this.state,
    required this.city,
    required this.postalCode,
    required this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'countryName': countryName,
      'requestType': requestType,
      'firstName': firstName,
      'lastName': lastName,
      'dob': dob,
      'permanentAddress': permanentAddress,
      'presentAddress': presentAddress,
      'state': state,
      'city': city,
      'postalCode': postalCode,
      'gender': gender,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class RegistrationResponse {
  final String email;
  final bool verificationRequired;

  RegistrationResponse({
    required this.email,
    required this.verificationRequired,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      email: json['email'],
      verificationRequired: json['verificationRequired'] ?? false,
    );
  }
}

class CountryModel {
  final String name;
  final String flag;

  CountryModel({required this.name, required this.flag});

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      name: json['name']['common'],
      flag: json['flags']['svg'] ?? json['flags']['png'] ?? '',
    );
  }
}

class SocialAuthRequest {
  final String token;
  final String countryName;

  SocialAuthRequest({required this.token, required this.countryName});

  Map<String, dynamic> toJson() => {'token': token, 'countryName': countryName};
}

class WalletAuthRequest {
  final String walletAddress;

  WalletAuthRequest({required this.walletAddress});

  Map<String, dynamic> toJson() => {'walletAddress': walletAddress};
}
