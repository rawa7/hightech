class Brand {
  final String id;
  final String name;
  final String? image;
  final String createdAt;
  final BrandImageData? imageData;

  Brand({
    required this.id,
    required this.name,
    this.image,
    required this.createdAt,
    this.imageData,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      image: json['image']?.toString(),
      createdAt: json['created_at'] ?? '',
      imageData: json['image_data'] != null 
          ? BrandImageData.fromJson(json['image_data']) 
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

class BrandImageData {
  final String id;
  final String webPath;
  final String filename;

  BrandImageData({
    required this.id,
    required this.webPath,
    required this.filename,
  });

  factory BrandImageData.fromJson(Map<String, dynamic> json) {
    return BrandImageData(
      id: json['id'].toString(),
      webPath: json['web_path'] ?? '',
      filename: json['filename'] ?? '',
    );
  }
}
