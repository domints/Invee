class StorageTreeResponse {
  final int id;
  final int? parentId;
  final int storageTypeId;
  final String name;
  final List<StorageTreeResponse> children;

  const StorageTreeResponse({
    required this.id,
    this.parentId,
    required this.storageTypeId,
    required this.name,
    required this.children,
  });

  factory StorageTreeResponse.fromJson(Map<String, dynamic> json) {
    return StorageTreeResponse(
      id: json['id'] as int,
      parentId: json['parentId'] as int?,
      storageTypeId: json['storageTypeId'] as int? ?? 0,
      name: json['name'] as String,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((c) => StorageTreeResponse.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Flat storage entry used in UI dropdowns. [displayName] includes the
/// full path (e.g. "Basement / Shelf A").
class StorageEntry {
  final int id;
  final String name;
  final String displayName;

  const StorageEntry({
    required this.id,
    required this.name,
    required this.displayName,
  });
}

class ExternalProductLookupResult {
  final String productName;
  final List<String> tags;
  final String? frontImageUrl;

  const ExternalProductLookupResult({
    required this.productName,
    required this.tags,
    this.frontImageUrl,
  });

  factory ExternalProductLookupResult.fromJson(Map<String, dynamic> json) {
    return ExternalProductLookupResult(
      productName: json['productName'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      frontImageUrl: json['frontImageUrl'] as String?,
    );
  }
}
