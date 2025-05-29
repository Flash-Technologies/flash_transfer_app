import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/beneficiary.dart';

class BeneficiaryService {
  final ApiClient _apiClient;

  BeneficiaryService(this._apiClient);

  Future<BeneficiaryResponse> getBeneficiaries({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        Endpoints.beneficiaries,
        queryParameters: queryParams,
      );

      return BeneficiaryResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch beneficiaries: $e');
    }
  }

  Future<Beneficiary> getBeneficiaryById(int id) async {
    try {
      final response = await _apiClient.get('/api/beneficiary/$id');

      if (response.data['success'] == true && response.data['data'] != null) {
        return Beneficiary.fromJson(response.data['data']);
      } else {
        throw Exception('Beneficiary not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch beneficiary: $e');
    }
  }

  Future<bool> deleteBeneficiary(int id) async {
    try {
      final response = await _apiClient.delete('/api/beneficiary/$id');
      return response.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to delete beneficiary: $e');
    }
  }

  Future<Beneficiary> createBeneficiary(
      Map<String, dynamic> beneficiaryData) async {
    try {
      final response = await _apiClient.post(
        Endpoints.createBeneficiary,
        data: beneficiaryData,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return Beneficiary.fromJson(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to create beneficiary');
      }
    } catch (e) {
      throw Exception('Failed to create beneficiary: $e');
    }
  }
}
