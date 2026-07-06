import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/item.dart';
import '../models/storage.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when the server returns 401.  [authUrl] is the OIDC login URL
/// extracted from the `OAuth-Redirect` response header (may be null if the
/// header was absent).
class UnauthorizedException implements Exception {
  final String? authUrl;
  UnauthorizedException([this.authUrl]);

  @override
  String toString() => 'UnauthorizedException(authUrl: $authUrl)';
}

class HealthResponse {
  final String status;
  final String database;
  final String version;

  HealthResponse({
    required this.status,
    required this.database,
    required this.version,
  });

  bool get isHealthy => status == 'ok';

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] as String? ?? 'unknown',
      database: json['database'] as String? ?? 'unknown',
      version: json['version'] as String? ?? 'unknown',
    );
  }
}

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final cleaned = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleaned$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, String> _authHeaders() {
    final jwt = AuthService.jwtToken;
    if (jwt != null) return {'Authorization': 'Bearer $jwt'};
    return {};
  }

  Future<dynamic> _get(String path, [Map<String, String>? queryParams]) async {
    final response = await http
        .get(_uri(path, queryParams), headers: _authHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    if (response.statusCode == 401) {
      final redirectHeader = response.headers['oauth-redirect'];
      throw UnauthorizedException(redirectHeader);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final response = await http
        .post(
          _uri(path),
          headers: {'Content-Type': 'application/json', ..._authHeaders()},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    if (response.statusCode == 401) {
      final redirectHeader = response.headers['oauth-redirect'];
      throw UnauthorizedException(redirectHeader);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// Calls `/api/health` and returns the parsed response, or null if the
  /// server is unreachable or returns an unexpected error.
  Future<HealthResponse?> checkHealth() async {
    try {
      final data = await http
          .get(_uri('/api/health'))
          .timeout(const Duration(seconds: 10));
      if (data.statusCode == 200) {
        return HealthResponse.fromJson(
            jsonDecode(data.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true when the server is reachable (health endpoint responds).
  Future<bool> testConnection() async {
    final health = await checkHealth();
    return health != null;
  }

  /// Returns true when the stored session cookie is accepted by the server.
  Future<bool> verifyAuth() async {
    try {
      await _get('/api/user/login');
      return true;
    } on UnauthorizedException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<CategoryTreeResponse>> getCategoryTree() async {
    final data = await _get('/api/categories/') as List<dynamic>;
    return data
        .map((c) => CategoryTreeResponse.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<ItemListEntry>> getCategoryItems(int categoryId) async {
    final data =
        await _get('/api/categories/$categoryId/items') as List<dynamic>;
    return data
        .map((i) => ItemListEntry.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<ItemResponse> getItem(int itemId) async {
    final data =
        await _get('/api/items/$itemId') as Map<String, dynamic>;
    return ItemResponse.fromJson(data);
  }

  /// Returns the item id if the code is found, null if not found (404).
  Future<int?> lookupByCode(String contents, {String? codeType}) async {
    final trimmed = contents.trim();
    if (trimmed.isEmpty) return null;
    final params = <String, String>{'Contents': trimmed};
    try {
      final data = await _get('/api/items/byCode', params);
      if (data is int) return data;
      if (data is Map && data['value'] != null) return data['value'] as int?;
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Returns a flat list of all storages (tree flattened depth-first).
  Future<List<StorageEntry>> getStorages() async {
    final data = await _get('/api/storages/') as List<dynamic>;
    final tree = data
        .map((s) => StorageTreeResponse.fromJson(s as Map<String, dynamic>))
        .toList();
    final flat = <StorageEntry>[];
    void flatten(StorageTreeResponse node, String prefix) {
      final label = prefix.isEmpty ? node.name : '$prefix / ${node.name}';
      flat.add(StorageEntry(id: node.id, name: node.name, displayName: label));
      for (final child in node.children) {
        flatten(child, label);
      }
    }
    for (final root in tree) {
      flatten(root, '');
    }
    return flat;
  }

  /// Creates a new item and returns its id.
  Future<int> createItem({
    required String name,
    required int categoryId,
    required int storageId,
    int quantityType = 0,
    DateTime? expiresAt,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'categoryId': categoryId,
      'storageId': storageId,
      'slug': null,
      'quantityType': quantityType,
      if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
    };
    final result = await _post('/api/items/', body);
    if (result is int) return result;
    if (result is Map && result['value'] != null) return result['value'] as int;
    throw ApiException(0, 'Unexpected response from createItem');
  }

  /// Adds a barcode code to an existing item.
  Future<void> addItemCode(int itemId, int codeType, String contents) async {
    await _post('/api/items/$itemId/codes', {
      'codeType': codeType,
      'contents': contents,
    });
  }

  /// Looks up a product by barcode via the Open Food Facts proxy.
  /// Returns null when not found (404).
  Future<ExternalProductLookupResult?> lookupProductByBarcode(
      String barcode) async {
    try {
      final data =
          await _get('/api/products/barcode/$barcode') as Map<String, dynamic>;
      return ExternalProductLookupResult.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  String imageUrl(String relativeOrAbsolute) {
    if (relativeOrAbsolute.startsWith('http')) return relativeOrAbsolute;
    return '${baseUrl.replaceAll(RegExp(r'/+$'), '')}$relativeOrAbsolute';
  }
}
