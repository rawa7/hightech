import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class OrderService {
  static const String baseUrl = 'https://dasroor.com/hightech';
  
  /// Create a points-based order (for Points Shop purchases)
  Future<Map<String, dynamic>> createPointsOrder({
    required int userId,
    required Product product,
    required int pointsRequired,
    int quantity = 1,
  }) async {
    try {
      print('========== POINTS ORDER REQUEST DEBUG ==========');
      print('Creating points order for product: ${product.name}');
      print('Product ID: ${product.id}');
      print('User ID: $userId');
      print('Points Required: $pointsRequired');
      print('Quantity: $quantity');
      print('===============================================');

      // WORKAROUND: Create a temporary "valid" product first to get order_id
      // We'll find a cheap product (product_id: 1) to create the base order
      // Then replace it with the actual points item via points_order_items.php
      
      print('Step 1: Creating base order to get order_id...');
      final baseOrderResponse = await http.post(
        Uri.parse('$baseUrl/orders.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'items': [
            {
              'product_id': 1,  // Use product ID 1 as temporary placeholder
              'quantity': 1,
            }
          ],
          'points_used': 0,
          'status': 'pending',  // Pending until we add the points item
        }),
      );

      print('Base order status: ${baseOrderResponse.statusCode}');
      print('Base order response: ${baseOrderResponse.body}');

      if (baseOrderResponse.statusCode != 200) {
        final errorData = jsonDecode(baseOrderResponse.body);
        throw Exception('Failed to create base order: ${errorData['error']}');
      }

      final baseData = jsonDecode(baseOrderResponse.body);
      final int orderId = baseData['order_id'] is int 
          ? baseData['order_id'] 
          : int.parse(baseData['order_id'].toString());
      print('Created base order with ID: $orderId');

      // Step 2: Delete the temporary item we just created
      // (We'll add the actual points item instead)
      print('Step 2: Replacing with points-based item...');
      
      // Add the actual product as a points-based item
      final response = await http.post(
        Uri.parse('$baseUrl/points_order_items.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
          'product_id': int.parse(product.id),
          'quantity': quantity,
        }),
      );

      print('Points item status: ${response.statusCode}');
      print('Points item response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Update order status to 'paid' and points_used
        print('Step 3: Updating order status...');
        await http.put(
          Uri.parse('$baseUrl/orders.php?id=$orderId'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'status=paid',
        );
        
        print('========== POINTS ORDER RESPONSE DEBUG ==========');
        print('Server response: ${jsonEncode(responseData)}');
        print('=================================================');
        
        return {
          'message': 'Points order created successfully',
          'order_id': orderId,
          ...responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('Points item creation failed: $errorData');
        throw Exception(errorData['error'] ?? 'Failed to add points item');
      }
    } catch (e) {
      print('Error creating points order: $e');
      throw Exception('Failed to create points order: $e');
    }
  }
  
  /// Create a new order from cart items
  Future<Map<String, dynamic>> createOrder({
    required int userId,
    required List<CartItem> cartItems,
    int pointsUsed = 0,
    String status = 'pending',
  }) async {
    try {
      // Convert cart items to order items
      final List<OrderItem> orderItems = cartItems.map((cartItem) => OrderItem(
        orderId: 0, // Will be set by the server
        productId: int.parse(cartItem.product.id),
        quantity: cartItem.quantity,
        price: cartItem.totalPrice,
        pointsEarned: cartItem.product.pointsEarnedAsInt * cartItem.quantity,
      )).toList();
      
      final double totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

      // Create order object
      final order = Order(
        userId: userId,
        totalAmount: totalAmount,
        pointsUsed: pointsUsed,
        status: status,
        items: orderItems,
      );

      final orderJson = order.toCreateJson();
      print('========== ORDER REQUEST DEBUG ==========');
      print('Creating order with data: ${jsonEncode(orderJson)}');
      print('Points Used: $pointsUsed');
      print('Total Amount: $totalAmount');
      print('Items Count: ${cartItems.length}');
      print('========================================');

      final response = await http.post(
        Uri.parse('$baseUrl/orders.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderJson),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('========== ORDER RESPONSE DEBUG ==========');
        print('Server response: ${jsonEncode(responseData)}');
        print('==========================================');
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
