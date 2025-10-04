class ProductType {
  final String id;
  final String name;
  final String? image;
  final String createdAt;
  final TypeImageData? imageData;

  ProductType({
    required this.id,
    required this.name,
    this.image,
    required this.createdAt,
    this.imageData,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      image: json['image']?.toString(),
      createdAt: json['created_at'] ?? '',
      imageData: json['image_data'] != null 
          ? TypeImageData.fromJson(json['image_data']) 
          : null,
    );
  }

  String get imageUrl {
    if (imageData?.webPath != null) {
      String path = imageData!.webPath;
      if (path.startsWith('/')) {
        return 'https://dasroor.com$path';
      }
      return 'https://dasroor.com/$path';
    }
    return '';
  }
}

class TypeImageData {
  final String id;
  final String webPath;
  final String filename;

  TypeImageData({
    required this.id,
    required this.webPath,
    required this.filename,
  });

  factory TypeImageData.fromJson(Map<String, dynamic> json) {
    return TypeImageData(
      id: json['id'].toString(),
      webPath: json['web_path'] ?? '',
      filename: json['filename'] ?? '',
    );
  }
}
