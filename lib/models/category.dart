class Category {
  final String id;
  final String name;
  final String? image;
  final String createdAt;
  final CategoryImageData? imageData;

  Category({
    required this.id,
    required this.name,
    this.image,
    required this.createdAt,
    this.imageData,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      image: json['image']?.toString(),
      createdAt: json['created_at'] ?? '',
      imageData: json['image_data'] != null 
          ? CategoryImageData.fromJson(json['image_data']) 
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

class CategoryImageData {
  final String id;
  final String webPath;
  final String filename;

  CategoryImageData({
    required this.id,
    required this.webPath,
    required this.filename,
  });

  factory CategoryImageData.fromJson(Map<String, dynamic> json) {
    return CategoryImageData(
      id: json['id'].toString(),
      webPath: json['web_path'] ?? '',
      filename: json['filename'] ?? '',
    );
  }
}

