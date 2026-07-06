class CategoryTreeResponse {
  final int id;
  final int? parentId;
  final String name;
  final String? slug;
  final List<CategoryTreeResponse> children;

  const CategoryTreeResponse({
    required this.id,
    this.parentId,
    required this.name,
    this.slug,
    required this.children,
  });

  factory CategoryTreeResponse.fromJson(Map<String, dynamic> json) {
    return CategoryTreeResponse(
      id: json['id'] as int,
      parentId: json['parentId'] as int?,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((c) => CategoryTreeResponse.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
