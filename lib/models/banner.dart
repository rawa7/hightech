class Banner {
  final String id;
  final String title;
  final String image;
  final String? link;
  final String status;
  final String createdAt;
  final BannerImageData? imageData;

  Banner({
    required this.id,
    required this.title,
    required this.image,
    this.link,
    required this.status,
    required this.createdAt,
    this.imageData,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      image: json['image'].toString(),
      link: json['link'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] ?? '',
      imageData: json['image_data'] != null
          ? BannerImageData.fromJson(json['image_data'])
          : null,
    );
  }

  String get imageUrl {
    // First try image_data (recommended structure)
    if (imageData?.webPath != null) {
      String path = imageData!.webPath;
      // If path already starts with http, return as is
      if (path.startsWith('http')) {
        return path;
      }
      // If path starts with /, prepend domain only
      if (path.startsWith('/')) {
        return 'https://dasroor.com$path';
      }
      // Otherwise add full base path
      return 'https://dasroor.com/hightech/$path';
    }
    
    // Fallback: try to construct from image field
    if (image.isNotEmpty) {
      // If image field contains a number (file ID), construct path
      if (int.tryParse(image) != null) {
        return 'https://dasroor.com/hightech/images/$image.png';
      }
      // If it's already a path or URL
      if (image.startsWith('http')) {
        return image;
      }
      return 'https://dasroor.com/hightech/$image';
    }
    
    return '';
  }
}

class BannerImageData {
  final String id;
  final String webPath;
  final String filename;

  BannerImageData({
    required this.id,
    required this.webPath,
    required this.filename,
  });

  factory BannerImageData.fromJson(Map<String, dynamic> json) {
    return BannerImageData(
      id: json['id']?.toString() ?? '',
      webPath: json['web_path']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
    );
  }
}
