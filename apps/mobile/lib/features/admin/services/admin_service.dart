import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../api/api_client.dart';
import '../models/admin_models.dart';

class AdminService {
  AdminService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AdminResident>> getResidents({
    String? query,
    String? postalCode,
    String? houseNumber,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (postalCode != null && postalCode.trim().isNotEmpty) {
      queryParams['postalCode'] = postalCode.trim();
    }
    if (houseNumber != null && houseNumber.trim().isNotEmpty) {
      queryParams['houseNumber'] = houseNumber.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }
    final uri = Uri(
      path: '/api/admin/residents',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = await _apiClient.getJsonFlexible(
      uri.toString(),
      includeAdminKey: !kReleaseMode,
    );
    final list = _extractList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(AdminResident.fromJson)
        .toList();
  }

  Future<String> createResident(AdminResidentInput input) async {
    final data = await _apiClient.postJson(
      '/api/admin/residents',
      input.toJson(),
      includeAdminKey: !kReleaseMode,
    );
    final residentId = data['residentId'];
    if (residentId is String) {
      return residentId;
    }
    throw ApiException('Unerwartetes JSON-Format');
  }

  Future<AdminImportSummary> importResidentsFromCsv({
    required Uint8List bytes,
    required String filename,
  }) async {
    final data = await _apiClient.postMultipartFile(
      '/api/admin/residents/import',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      includeAdminKey: !kReleaseMode,
    );
    return AdminImportSummary.fromJson(data);
  }

  Future<BulkActivationResult> generateActivationCodes({
    required List<String> residentIds,
    required int expiresInDays,
  }) async {
    final data = await _apiClient.postJson(
      '/api/admin/activation-codes/bulk',
      {
        'residentIds': residentIds,
        'expiresInDays': expiresInDays,
      },
      includeAdminKey: !kReleaseMode,
    );
    return BulkActivationResult.fromJson(data);
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final list = data['data'] ?? data['residents'];
      if (list is List<dynamic>) {
        return list;
      }
    }
    return const <dynamic>[];
  }
}
