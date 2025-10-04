import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/banner.dart' as banner_model;
import '../models/product.dart';
import '../models/brand.dart';
import '../models/product_type.dart';
import '../models/category.dart' as category_model;
import '../models/home_data.dart';

class TechApiService {
  static const String _baseUrl = 'https://dasroor.com/hightech';

  // Get home page data (all sections)
  static Future<HomeData?> getHomeData() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/home.php'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return HomeData.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching home data: $e');
    }
    return null;
  }

  // Get all categories
  static Future<List<category_model.Category>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories.php'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => category_model.Category.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
    return [];
  }

  // Get active banners
  static Future<List<banner_model.Banner>> getBanners({bool activeOnly = true}) async {
    try {
      final url = activeOnly ? '$_baseUrl/banners.php?active=1' : '$_baseUrl/banners.php';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => banner_model.Banner.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching banners: $e');
    }
    return [];
  }

  // Get all products or filter by criteria
  static Future<List<Product>> getProducts({
    String? brandId,
    String? typeId,
    String? categoryId,
  }) async {
    try {
      String url = '$_baseUrl/products.php';
      List<String> params = [];
      
      if (brandId != null && brandId.isNotEmpty) params.add('brand_id=$brandId');
      if (typeId != null && typeId.isNotEmpty) params.add('type_id=$typeId');
      if (categoryId != null && categoryId.isNotEmpty) params.add('category_id=$categoryId');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
    return [];
  }

  // Get single product by ID
  static Future<Product?> getProduct(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products.php?id=$id'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');
    }
    return null;
  }

  // Get all brands
  static Future<List<Brand>> getBrands() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/brands.php'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Brand.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching brands: $e');
    }
    return [];
  }

  // Get all product types
  static Future<List<ProductType>> getTypes() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/types.php'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductType.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching types: $e');
    }
    return [];
  }
}
