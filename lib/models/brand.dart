class Brand {
  final String id;
  final String name;
  final String createdAt;

  Brand({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
