import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/item.dart';
import '../models/storage.dart';
import '../models/storage_detail.dart';
import 'auth_service.dart';

class TagDto {
  final int id;
  final String name;

  const TagDto({required this.id, required this.name});

  factory TagDto.fromJson(Map<String, dynamic> json) {
    return TagDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

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

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final response = await http
        .put(
          _uri(path),
          headers: {'Content-Type': 'application/json', ..._authHeaders()},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) return null;
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
    double? quantity,
    DateTime? expiresAt,
    String? slug,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'categoryId': categoryId,
      'storageId': storageId,
      'slug': slug,
      'quantityType': quantityType,
      if (quantity != null) 'quantity': quantity,
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

  /// Deletes a barcode code from an item.
  Future<void> deleteItemCode(int itemId, int codeId) async {
    await _delete('/api/items/$itemId/codes/$codeId');
  }

  /// Deletes an image from an item.
  Future<void> deleteItemImage(int itemId, int imageId) async {
    await _delete('/api/items/$itemId/images/$imageId');
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

  /// Updates an existing item's fields.
  Future<void> updateItem({
    required int id,
    required String name,
    required int categoryId,
    required int storageId,
    int quantityType = 0,
    double? quantity,
    bool broken = false,
    String? note,
    String? slug,
    DateTime? expiresAt,
  }) async {
    final body = <String, dynamic>{
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'storageId': storageId,
      'slug': slug,
      'quantityType': quantityType,
      'quantity': quantity,
      'broken': broken,
      'note': note,
      if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
    };
    await _put('/api/items/$id', body);
  }

  /// Returns all tags.
  Future<List<TagDto>> getTags() async {
    final data = await _get('/api/tags/') as List<dynamic>;
    return data.map((t) => TagDto.fromJson(t as Map<String, dynamic>)).toList();
  }

  /// Creates a new tag and returns its id.
  Future<int> createTag(String name) async {
    final result = await _post('/api/tags/', {'name': name});
    if (result is int) return result;
    if (result is Map && result['value'] != null) return result['value'] as int;
    throw ApiException(0, 'Unexpected response from createTag');
  }

  /// Sets the tags on an item (replaces all existing tags).
  Future<void> setItemTags(int itemId, List<int> tagIds) async {
    await _put('/api/items/$itemId/tags', {'tagIds': tagIds});
  }

  /// Returns items expiring within the next 7 days (including already expired).
  Future<List<ItemListEntry>> getExpiringItems() async {
    final data = await _get('/api/items/expiring') as List<dynamic>;
    return data
        .map((i) => ItemListEntry.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  /// Returns all items, optionally filtered by [search] (matches name or tag).
  Future<List<ItemListEntry>> getAllItems({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['Search'] = search;
    final data = await _get('/api/items/', params.isEmpty ? null : params)
        as List<dynamic>;
    return data
        .map((i) => ItemListEntry.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  String imageUrl(String relativeOrAbsolute) {
    if (relativeOrAbsolute.startsWith('http')) return relativeOrAbsolute;
    return '${baseUrl.replaceAll(RegExp(r'/+$'), '')}$relativeOrAbsolute';
  }

  Future<void> _delete(String path) async {
    final response = await http
        .delete(_uri(path), headers: _authHeaders())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200 || response.statusCode == 204) return;
    if (response.statusCode == 401) {
      throw UnauthorizedException(response.headers['oauth-redirect']);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ---------------------------------------------------------------------------
  // Category management
  // ---------------------------------------------------------------------------

  Future<int> createCategory({
    required String name,
    int? parentId,
    String? slug,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (parentId != null) body['parentId'] = parentId;
    if (slug != null) body['slug'] = slug;
    final result = await _post('/api/categories/', body);
    if (result is int) return result;
    if (result is Map && result['value'] != null) return result['value'] as int;
    throw ApiException(0, 'Unexpected response from createCategory');
  }

  Future<void> deleteCategory(int id) async {
    await _delete('/api/categories/$id');
  }

  Future<void> renameCategory(int id, String name) async {
    await _put('/api/categories/$id', {'name': name});
  }

  // ---------------------------------------------------------------------------
  // Storage management
  // ---------------------------------------------------------------------------

  /// Returns the raw storage tree (unflattened).
  Future<List<StorageTreeResponse>> getStorageTree() async {
    final data = await _get('/api/storages/') as List<dynamic>;
    return data
        .map((s) => StorageTreeResponse.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Returns a storage's detail view (child storages + items).
  Future<StorageItemsResponse> getStorageDetail(int id) async {
    final data = await _get('/api/storages/$id') as Map<String, dynamic>;
    return StorageItemsResponse.fromJson(data);
  }

  Future<int> createStorage({
    required String name,
    required int storageTypeId,
    int? parentId,
    String? slug,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'storageTypeId': storageTypeId,
      if (parentId != null) 'parentId': parentId,
      if (slug != null) 'slug': slug,
    };
    final result = await _post('/api/storages/', body);
    if (result is int) return result;
    if (result is Map && result['value'] != null) return result['value'] as int;
    throw ApiException(0, 'Unexpected response from createStorage');
  }

  Future<void> deleteStorage(int id) async {
    await _delete('/api/storages/$id');
  }

  Future<void> updateStorage(int id, String name, int storageTypeId) async {
    await _put('/api/storages/$id', {'name': name, 'storageTypeId': storageTypeId});
  }

  // ---------------------------------------------------------------------------
  // Storage types
  // ---------------------------------------------------------------------------

  Future<List<StorageTypeDto>> getStorageTypes() async {
    final data = await _get('/api/storageTypes/') as List<dynamic>;
    return data
        .map((t) => StorageTypeDto.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Item image upload
  // ---------------------------------------------------------------------------

  /// Downloads [imageUrl] and uploads it as the item's image.
  Future<void> uploadItemImageFromUrl(int itemId, String imageUrl) async {
    final dlResponse = await http
        .get(Uri.parse(imageUrl))
        .timeout(const Duration(seconds: 30));
    if (dlResponse.statusCode != 200) {
      throw ApiException(dlResponse.statusCode, 'Failed to download image');
    }
    final uri = Uri.parse(imageUrl);
    final filename = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'photo.jpg';
    await uploadItemImageFromBytes(itemId, dlResponse.bodyBytes, filename);
  }

  /// Uploads raw [bytes] as a multipart image for the given item.
  Future<void> uploadItemImageFromBytes(
      int itemId, List<int> bytes, String filename) async {
    final uri = _uri('/api/items/$itemId/images');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders())
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 || response.statusCode == 201) return;
    if (response.statusCode == 401) {
      throw UnauthorizedException(response.headers['oauth-redirect']);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ---------------------------------------------------------------------------
  // Storage image upload / delete
  // ---------------------------------------------------------------------------

  /// Uploads raw [bytes] as a multipart image for the given storage.
  Future<void> uploadStorageImageFromBytes(
      int storageId, List<int> bytes, String filename) async {
    final uri = _uri('/api/storages/$storageId/images');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders())
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 || response.statusCode == 201) return;
    if (response.statusCode == 401) {
      throw UnauthorizedException(response.headers['oauth-redirect']);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// Deletes an image from a storage.
  Future<void> deleteStorageImage(int storageId, int imageId) async {
    await _delete('/api/storages/$storageId/images/$imageId');
  }
}
