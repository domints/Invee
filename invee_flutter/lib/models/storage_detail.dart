import 'item.dart';

class StorageTypeDto {
  final int id;
  final String name;

  const StorageTypeDto({required this.id, required this.name});

  factory StorageTypeDto.fromJson(Map<String, dynamic> json) {
    return StorageTypeDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class StorageListEntry {
  final int id;
  final String name;
  final String? slug;
  final StorageTypeDto type;

  const StorageListEntry({
    required this.id,
    required this.name,
    this.slug,
    required this.type,
  });

  factory StorageListEntry.fromJson(Map<String, dynamic> json) {
    return StorageListEntry(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      type: StorageTypeDto.fromJson(json['type'] as Map<String, dynamic>),
    );
  }
}

class StorageItemsResponse {
  final int id;
  final String name;
  final StorageTypeDto type;
  final int? parentId;
  final String? parentSlug;
  final List<StorageListEntry> childStorages;
  final List<ItemListEntry> items;
  final List<ImageDto> images;

  const StorageItemsResponse({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.parentSlug,
    required this.childStorages,
    required this.items,
    required this.images,
  });

  factory StorageItemsResponse.fromJson(Map<String, dynamic> json) {
    return StorageItemsResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      type: StorageTypeDto.fromJson(json['type'] as Map<String, dynamic>),
      parentId: json['parentId'] as int?,
      parentSlug: json['parentSlug'] as String?,
      childStorages: (json['childStorages'] as List<dynamic>? ?? [])
          .map((s) => StorageListEntry.fromJson(s as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => ItemListEntry.fromJson(i as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>? ?? [])
          .map((i) => ImageDto.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
