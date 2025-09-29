class ProductType {
  final String id;
  final String name;
  final String createdAt;

  ProductType({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
