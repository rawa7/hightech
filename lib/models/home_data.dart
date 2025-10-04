import 'brand.dart';
import 'product_type.dart';
import 'category.dart' as category_model;
import 'product.dart';

class HomeData {
  final List<Brand> brands;
  final List<ProductType> types;
  final List<category_model.Category> categories;
  final List<Product> newItems;
  final List<Product> discountItems;
  final List<Product> pickedItems;
  final List<Product> mostSales;
  final List<Product> mostPoints;
  final List<Product> mostSoldPoints;

  HomeData({
    required this.brands,
    required this.types,
    required this.categories,
    required this.newItems,
    required this.discountItems,
    required this.pickedItems,
    required this.mostSales,
    required this.mostPoints,
    required this.mostSoldPoints,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      brands: (json['brands'] as List?)
          ?.map((e) => Brand.fromJson(e))
          .toList() ?? [],
      types: (json['types'] as List?)
          ?.map((e) => ProductType.fromJson(e))
          .toList() ?? [],
      categories: (json['categories'] as List?)
          ?.map((e) => category_model.Category.fromJson(e))
          .toList() ?? [],
      newItems: (json['new_items'] as List?)
          ?.map((e) => Product.fromJson(e))
          .toList() ?? [],
      discountItems: (json['discount_items'] as List?)
          ?.map((e) => Product.fromJson(e))
          .toList() ?? [],
      pickedItems: (json['picked_items'] as List?)
          ?.map((e) => Product.fromJson(e))
          .toList() ?? [],
      mostSales: (json['most_sales'] as List?)
          ?.map((e) => Product.fromJson(e))
          .toList() ?? [],
      mostPoints: (json['most_points'] as List?)
          ?.map((e) => Product.fromJson(e))
          .toList() ?? [],
      mostSoldPoints: (json['most_sold_points'] as List?)
          ?.map((e) => Product.fromJson(e))
          .toList() ?? [],
    );
  }
}

