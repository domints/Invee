class ItemListEntry {
  final int id;
  final String name;
  final String? slug;
  final String quantityType;
  final double? quantity;
  final String? level;
  final bool broken;
  final bool borrowed;
  final DateTime addedAt;
  final DateTime? expiresAt;
  final List<String> tags;

  const ItemListEntry({
    required this.id,
    required this.name,
    this.slug,
    required this.quantityType,
    this.quantity,
    this.level,
    required this.broken,
    required this.borrowed,
    required this.addedAt,
    this.expiresAt,
    required this.tags,
  });

  factory ItemListEntry.fromJson(Map<String, dynamic> json) {
    return ItemListEntry(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      quantityType: json['quantityType']?.toString() ?? '0',
      quantity: (json['quantity'] as num?)?.toDouble(),
      level: json['level']?.toString(),
      broken: json['broken'] as bool? ?? false,
      borrowed: json['borrowed'] as bool? ?? false,
      addedAt: DateTime.parse(json['addedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

class ItemCodeDto {
  final int id;
  final String codeType;
  final String contents;

  const ItemCodeDto({
    required this.id,
    required this.codeType,
    required this.contents,
  });

  factory ItemCodeDto.fromJson(Map<String, dynamic> json) {
    return ItemCodeDto(
      id: json['id'] as int,
      codeType: json['codeType']?.toString() ?? '',
      contents: json['contents'] as String,
    );
  }
}

class ImageDto {
  final int id;
  final String url;
  final int order;

  const ImageDto({required this.id, required this.url, required this.order});

  factory ImageDto.fromJson(Map<String, dynamic> json) {
    return ImageDto(
      id: json['id'] as int,
      url: json['url'] as String,
      order: json['order'] as int? ?? 0,
    );
  }
}

class CategoryRef {
  final int id;
  final String name;
  final String? slug;

  const CategoryRef({required this.id, required this.name, this.slug});

  factory CategoryRef.fromJson(Map<String, dynamic> json) {
    return CategoryRef(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String?,
    );
  }
}

class StorageRef {
  final int id;
  final String name;
  final String? slug;

  const StorageRef({required this.id, required this.name, this.slug});

  factory StorageRef.fromJson(Map<String, dynamic> json) {
    return StorageRef(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String?,
    );
  }
}

class BorrowingDto {
  final String status;
  final DateTime? start;
  final DateTime? end;
  final String borrower;
  final String? comment;

  const BorrowingDto({
    required this.status,
    this.start,
    this.end,
    required this.borrower,
    this.comment,
  });

  factory BorrowingDto.fromJson(Map<String, dynamic> json) {
    return BorrowingDto(
      status: json['status']?.toString() ?? '',
      start:
          json['start'] != null ? DateTime.parse(json['start'] as String) : null,
      end: json['end'] != null ? DateTime.parse(json['end'] as String) : null,
      borrower: json['borrower'] as String? ?? '',
      comment: json['comment'] as String?,
    );
  }
}

class ItemResponse {
  final int id;
  final String name;
  final String? slug;
  final String quantityType;
  final double? quantity;
  final String? level;
  final StorageRef storage;
  final CategoryRef category;
  final String? note;
  final bool broken;
  final DateTime addedAt;
  final DateTime? expiresAt;
  final List<BorrowingDto> borrowings;
  final List<String> tags;
  final List<ItemCodeDto> codes;
  final List<ImageDto> images;

  const ItemResponse({
    required this.id,
    required this.name,
    this.slug,
    required this.quantityType,
    this.quantity,
    this.level,
    required this.storage,
    required this.category,
    this.note,
    required this.broken,
    required this.addedAt,
    this.expiresAt,
    required this.borrowings,
    required this.tags,
    required this.codes,
    required this.images,
  });

  factory ItemResponse.fromJson(Map<String, dynamic> json) {
    return ItemResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      quantityType: json['quantityType']?.toString() ?? '0',
      quantity: (json['quantity'] as num?)?.toDouble(),
      level: json['level']?.toString(),
      storage: StorageRef.fromJson(json['storage'] as Map<String, dynamic>),
      category: CategoryRef.fromJson(json['category'] as Map<String, dynamic>),
      note: json['note'] as String?,
      broken: json['broken'] as bool? ?? false,
      addedAt: DateTime.parse(json['addedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      borrowings: (json['borrowings'] as List<dynamic>? ?? [])
          .map((b) => BorrowingDto.fromJson(b as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      codes: (json['codes'] as List<dynamic>? ?? [])
          .map((c) => ItemCodeDto.fromJson(c as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>? ?? [])
          .map((i) => ImageDto.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isBorrowed =>
      borrowings.any((b) => b.status == '1' || b.status == 'Active');
}
