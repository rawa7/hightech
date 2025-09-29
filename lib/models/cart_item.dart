import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.priceAsDouble * quantity;
  
  Map<String, dynamic> toJson() {
    return {
      'product': {
        'id': product.id,
        'name': product.name,
        'brand_id': product.brandId,
        'type_id': product.typeId,
        'category_id': product.categoryId,
        'price': product.price,
        'stock': product.stock,
        'image': product.image,
        'points_required': product.pointsRequired,
        'sell_with_points': product.sellWithPoints,
        'points_earned': product.pointsEarned,
        'created_at': product.createdAt,
        'brand': product.brand,
        'type': product.type,
        'category': product.category,
        'image2': product.image2,
        'image3': product.image3,
        'image4': product.image4,
        'image5': product.image5,
        'image6': product.image6,
        'image7': product.image7,
        'image8': product.image8,
        'images': product.images != null ? {
          'image': product.images!.image != null ? {
            'id': product.images!.image!.id,
            'web_path': product.images!.image!.webPath,
            'filename': product.images!.image!.filename,
          } : null,
          'image2': product.images!.image2 != null ? {
            'id': product.images!.image2!.id,
            'web_path': product.images!.image2!.webPath,
            'filename': product.images!.image2!.filename,
          } : null,
        } : null,
      },
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
    );
  }
  
  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.product.id == product.id;
  }

  @override
  int get hashCode => product.id.hashCode;
}
