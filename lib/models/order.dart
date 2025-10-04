class Order {
  final int? id;
  final int userId;
  final double totalAmount;
  final int pointsUsed;
  final String status;
  final DateTime? createdAt;
  final String? fullName;
  final String? email;
  final String? phone;
  final int? itemCount;
  final int? totalQuantity;
  final int? totalPointsEarned;
  final bool isPointsOrder;
  final List<OrderItem>? items;

  Order({
    this.id,
    required this.userId,
    required this.totalAmount,
    required this.pointsUsed,
    required this.status,
    this.createdAt,
    this.fullName,
    this.email,
    this.phone,
    this.itemCount,
    this.totalQuantity,
    this.totalPointsEarned,
    this.isPointsOrder = false,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      userId: json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'],
      totalAmount: double.parse(json['total_amount'].toString()),
      pointsUsed: json['points_used'] is String ? int.parse(json['points_used']) : (json['points_used'] ?? 0),
      status: json['status'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      itemCount: json['item_count'] != null 
          ? (json['item_count'] is String ? int.parse(json['item_count']) : json['item_count'])
          : null,
      totalQuantity: json['total_quantity'] != null
          ? (json['total_quantity'] is String ? int.parse(json['total_quantity']) : json['total_quantity'])
          : null,
      totalPointsEarned: json['total_points_earned'] != null
          ? (json['total_points_earned'] is String ? int.parse(json['total_points_earned']) : json['total_points_earned'])
          : null,
      isPointsOrder: json['is_points_order'] == true,
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'points_used': pointsUsed,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'item_count': itemCount,
      'total_quantity': totalQuantity,
      'total_points_earned': totalPointsEarned,
      'is_points_order': isPointsOrder,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'total_amount': totalAmount,
      'items': items?.map((item) => item.toCreateJson()).toList(),
      'points_used': pointsUsed,
      'status': status,
    };
  }
}

class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final int pointsEarned;
  final String? productName;
  final double? productPrice;
  final double? unitPrice;
  final String? image;
  final String? brandName;
  final String? typeName;
  final String? categoryName;
  final int? stock;
  final OrderItemImageData? imageData;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.pointsEarned,
    this.productName,
    this.productPrice,
    this.unitPrice,
    this.image,
    this.brandName,
    this.typeName,
    this.categoryName,
    this.stock,
    this.imageData,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      orderId: json['order_id'] is String ? int.parse(json['order_id']) : (json['order_id'] ?? 0),
      productId: json['product_id'] is String ? int.parse(json['product_id']) : json['product_id'],
      quantity: json['quantity'] is String ? int.parse(json['quantity']) : json['quantity'],
      price: double.parse(json['price'].toString()),
      pointsEarned: json['points_earned'] is String 
          ? int.parse(json['points_earned']) 
          : (json['points_earned'] ?? 0),
      productName: json['product_name'],
      productPrice: json['product_price'] != null 
          ? double.parse(json['product_price'].toString()) 
          : null,
      unitPrice: json['unit_price'] != null 
          ? double.parse(json['unit_price'].toString()) 
          : null,
      image: json['image'],
      brandName: json['brand_name'],
      typeName: json['type_name'],
      categoryName: json['category_name'],
      stock: json['stock'] is String ? int.parse(json['stock']) : json['stock'],
      imageData: json['image_data'] != null
          ? OrderItemImageData.fromJson(json['image_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'points_earned': pointsEarned,
      'product_name': productName,
      'product_price': productPrice,
      'unit_price': unitPrice,
      'image': image,
      'brand_name': brandName,
      'type_name': typeName,
      'category_name': categoryName,
      'stock': stock,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'points_earned': pointsEarned,
    };
  }

  String get imageUrl {
    return imageData?.webPath ?? '';
  }
}

class OrderItemImageData {
  final String id;
  final String webPath;
  final String filename;

  OrderItemImageData({
    required this.id,
    required this.webPath,
    required this.filename,
  });

  factory OrderItemImageData.fromJson(Map<String, dynamic> json) {
    return OrderItemImageData(
      id: json['id']?.toString() ?? '',
      webPath: json['web_path']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
    );
  }
}
