class Product {
  final String id;
  final String name;
  final String brandId;
  final String typeId;
  final String categoryId;
  final String price;
  final String stock;
  final String? image;
  final String pointsRequired;
  final String sellWithPoints;
  final String pointsEarned;
  final String createdAt;
  final String? brand;
  final String? type;
  final String? category;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? image6;
  final String? image7;
  final String? image8;
  final ProductImages? images;

  Product({
    required this.id,
    required this.name,
    required this.brandId,
    required this.typeId,
    required this.categoryId,
    required this.price,
    required this.stock,
    this.image,
    required this.pointsRequired,
    required this.sellWithPoints,
    required this.pointsEarned,
    required this.createdAt,
    this.brand,
    this.type,
    this.category,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.image6,
    this.image7,
    this.image8,
    this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      brandId: json['brand_id'].toString(),
      typeId: json['type_id'].toString(),
      categoryId: json['category_id'].toString(),
      price: json['price'].toString(),
      stock: json['stock'].toString(),
      image: json['image']?.toString(),
      pointsRequired: json['points_required'].toString(),
      sellWithPoints: json['sell_with_points'] ?? 'no',
      pointsEarned: json['points_earned'].toString(),
      createdAt: json['created_at'] ?? '',
      brand: json['brand'],
      type: json['type'],
      category: json['category'],
      image2: json['image2']?.toString(),
      image3: json['image3']?.toString(),
      image4: json['image4']?.toString(),
      image5: json['image5']?.toString(),
      image6: json['image6']?.toString(),
      image7: json['image7']?.toString(),
      image8: json['image8']?.toString(),
      images: json['images'] != null ? ProductImages.fromJson(json['images']) : null,
    );
  }

  double get priceAsDouble => double.tryParse(price) ?? 0.0;
  int get stockAsInt => int.tryParse(stock) ?? 0;
  int get pointsRequiredAsInt => int.tryParse(pointsRequired) ?? 0;
  int get pointsEarnedAsInt => int.tryParse(pointsEarned) ?? 0;
  
  String get imageUrl {
    if (images?.image != null) {
      return images!.image!.imageUrl;
    }
    return '';
  }
  
  List<String> get allImageUrls {
    List<String> urls = [];
    if (images?.image != null) urls.add(images!.image!.imageUrl);
    if (images?.image2 != null) urls.add(images!.image2!.imageUrl);
    if (images?.image3 != null) urls.add(images!.image3!.imageUrl);
    if (images?.image4 != null) urls.add(images!.image4!.imageUrl);
    if (images?.image5 != null) urls.add(images!.image5!.imageUrl);
    if (images?.image6 != null) urls.add(images!.image6!.imageUrl);
    if (images?.image7 != null) urls.add(images!.image7!.imageUrl);
    if (images?.image8 != null) urls.add(images!.image8!.imageUrl);
    return urls;
  }
}

class ProductImages {
  final ImageFile? image;
  final ImageFile? image2;
  final ImageFile? image3;
  final ImageFile? image4;
  final ImageFile? image5;
  final ImageFile? image6;
  final ImageFile? image7;
  final ImageFile? image8;

  ProductImages({
    this.image,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.image6,
    this.image7,
    this.image8,
  });

  factory ProductImages.fromJson(Map<String, dynamic> json) {
    return ProductImages(
      image: json['image'] != null ? ImageFile.fromJson(json['image']) : null,
      image2: json['image2'] != null ? ImageFile.fromJson(json['image2']) : null,
      image3: json['image3'] != null ? ImageFile.fromJson(json['image3']) : null,
      image4: json['image4'] != null ? ImageFile.fromJson(json['image4']) : null,
      image5: json['image5'] != null ? ImageFile.fromJson(json['image5']) : null,
      image6: json['image6'] != null ? ImageFile.fromJson(json['image6']) : null,
      image7: json['image7'] != null ? ImageFile.fromJson(json['image7']) : null,
      image8: json['image8'] != null ? ImageFile.fromJson(json['image8']) : null,
    );
  }
}

class ImageFile {
  final String id;
  final String webPath;
  final String filename;

  ImageFile({
    required this.id,
    required this.webPath,
    required this.filename,
  });

  factory ImageFile.fromJson(Map<String, dynamic> json) {
    return ImageFile(
      id: json['id'].toString(),
      webPath: json['web_path'] ?? '',
      filename: json['filename'] ?? '',
    );
  }

  String get imageUrl {
    // Convert the relative path to absolute URL
    if (webPath.startsWith('/')) {
      return 'https://dasroor.com$webPath';
    }
    // Handle different path formats
    String cleanPath = webPath
        .replaceAll('..\\/', '')
        .replaceAll('../', '')
        .replaceAll('\\', '/');
    
    // If path doesn't start with /, add it
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    
    String finalUrl = 'https://dasroor.com$cleanPath';
    print('Image URL: $finalUrl (from webPath: $webPath)');
    return finalUrl;
  }
}
