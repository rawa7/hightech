import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class OrderService {
  static const String baseUrl = 'https://dasroor.com/hightech';
  
  /// Create a new order from cart items or single product
  Future<Map<String, dynamic>> createOrder({
    required int userId,
    required List<CartItem> cartItems,
    int pointsUsed = 0,
    String status = 'pending',
    Product? singleProduct,
  }) async {
    try {
      List<OrderItem> orderItems;
      double totalAmount;
      
      // Check if this is a single product purchase with points
      if (singleProduct != null) {
        orderItems = [
          OrderItem(
            orderId: 0,
            productId: int.parse(singleProduct.id),
            quantity: 1,
            price: 0.0, // Zero price when buying with points
            pointsEarned: 0, // No points earned when buying with points
          )
        ];
        totalAmount = 0.0; // Zero amount when buying with points
      } else {
        // Convert cart items to order items
        orderItems = cartItems.map((cartItem) => OrderItem(
          orderId: 0, // Will be set by the server
          productId: int.parse(cartItem.product.id),
          quantity: cartItem.quantity,
          price: cartItem.totalPrice,
          pointsEarned: cartItem.product.pointsEarnedAsInt * cartItem.quantity,
        )).toList();
        totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      }

      // Create order object
      final order = Order(
        userId: userId,
        totalAmount: totalAmount,
        pointsUsed: pointsUsed,
        status: status,
        items: orderItems,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/orders.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(order.toCreateJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Order created successfully: $responseData');
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        print('Order creation failed: $errorData');
        throw Exception(errorData['error'] ?? 'Failed to create order');
      }
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get orders for a specific user
  Future<List<Order>> getUserOrders(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders.php?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Get a specific order by ID
  Future<Order> getOrder(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders.php?id=$orderId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch order');
      }
    } catch (e) {
      print('Error fetching order: $e');
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Update order status
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders.php?id=$orderId'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'status=$status',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Order status updated: $responseData');
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update order');
      }
    } catch (e) {
      print('Error updating order: $e');
      throw Exception('Failed to update order: $e');
    }
  }

  /// Delete an order
  Future<Map<String, dynamic>> deleteOrder(int orderId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/orders.php?id=$orderId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Order deleted: $responseData');
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete order');
      }
    } catch (e) {
      print('Error deleting order: $e');
      throw Exception('Failed to delete order: $e');
    }
  }
}
