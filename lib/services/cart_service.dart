import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService {
  static const String _cartKey = 'cart_items';
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  double get totalAmount {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isEmpty => _cartItems.isEmpty;

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);
      if (cartData != null) {
        final List<dynamic> jsonList = jsonDecode(cartData);
        _cartItems = jsonList.map((json) => CartItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading cart: $e');
      _cartItems = [];
    }
  }

  Future<void> saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = jsonEncode(_cartItems.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartData);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    print('Adding to cart: ${product.name} (ID: ${product.id})');
    final existingItemIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    
    if (existingItemIndex != -1) {
      _cartItems[existingItemIndex].quantity += quantity;
      print('Updated existing item quantity to: ${_cartItems[existingItemIndex].quantity}');
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
      print('Added new item to cart. Total items: ${_cartItems.length}');
    }
    
    await saveCart();
    print('Cart saved. Total items in cart: ${_cartItems.length}');
  }

  Future<void> removeFromCart(String productId) async {
    _cartItems.removeWhere((item) => item.product.id == productId);
    await saveCart();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }
    
    final existingItemIndex = _cartItems.indexWhere((item) => item.product.id == productId);
    if (existingItemIndex != -1) {
      _cartItems[existingItemIndex].quantity = quantity;
      await saveCart();
    }
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    await saveCart();
  }

  bool isInCart(String productId) {
    return _cartItems.any((item) => item.product.id == productId);
  }

  int getItemQuantity(String productId) {
    final item = _cartItems.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(product: Product(
        id: '',
        name: '',
        brandId: '',
        typeId: '',
        categoryId: '',
        price: '0',
        stock: '0',
        pointsRequired: '0',
        sellWithPoints: 'no',
        pointsEarned: '0',
        createdAt: '',
      )),
    );
    return item.quantity;
  }
}
