import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class OrderService {
  static const String baseUrl = 'https://dasroor.com/hightech';
  
  /// Create a points-based order (for Points Shop purchases)
  /// 
  /// This uses the new simplified API that creates the order and item in ONE call
  Future<Map<String, dynamic>> createPointsOrder({
    required int userId,
    required Product product,
    required int pointsRequired,
    int quantity = 1,
  }) async {
    try {
      print('');
      print('╔════════════════════════════════════════════════════════════════');
      print('║ POINTS ORDER REQUEST - DETAILED DEBUG');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Creating points order for product: ${product.name}');
      print('║ Product ID: ${product.id}');
      print('║ User ID: $userId');
      print('║ Points Required: $pointsRequired');
      print('║ Quantity: $quantity');
      print('╚════════════════════════════════════════════════════════════════');
      print('');

      // New simplified API - ONE call creates order AND item
      print('┌─ SINGLE API CALL: Creating complete points order');
      print('│');
      
      final pointsOrderUrl = '$baseUrl/points_order_items.php';
      final requestData = {
        'user_id': userId,
        'product_id': int.parse(product.id),
        'quantity': quantity,
      };
      
      print('│  📍 REQUEST URL: $pointsOrderUrl');
      print('│  📤 REQUEST METHOD: POST');
      print('│  📋 REQUEST HEADERS: {"Content-Type": "application/json"}');
      print('│  📦 REQUEST BODY:');
      print('│     ${jsonEncode(requestData)}');
      print('│');
      print('│  ℹ️  This single call will:');
      print('│     1. Validate product and user points');
      print('│     2. Create order (total_amount = 0)');
      print('│     3. Add order item (price = 0)');
      print('│     4. Deduct points from user');
      print('│     5. Create points history record');
      print('│');
      
      final response = await http.post(
        Uri.parse(pointsOrderUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('│  📥 RESPONSE STATUS: ${response.statusCode}');
      print('│  📥 RESPONSE BODY:');
      print('│     ${response.body}');
      print('└─ END API CALL');
      print('');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        print('╔════════════════════════════════════════════════════════════════');
        print('║ ✅ POINTS ORDER CREATED SUCCESSFULLY');
        print('╠════════════════════════════════════════════════════════════════');
        print('║ Order ID: ${responseData['order_id']}');
        print('║ Item ID: ${responseData['item_id']}');
        print('║ Product: ${product.name} (ID: ${product.id})');
        print('║ Points Spent: ${responseData['points_spent']}');
        print('║ Price: ${responseData['price']} (should be 0)');
        print('║ Points Earned: ${responseData['points_earned']} (should be 0)');
        print('║ Message: ${responseData['message']}');
        print('╚════════════════════════════════════════════════════════════════');
        print('');
        
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ ERROR: Points order creation failed!');
        print('   Status Code: ${response.statusCode}');
        print('   Error Details: ${errorData['error']}');
        print('');
        print('   Possible reasons:');
        print('   • Missing required parameters (user_id, product_id, quantity)');
        print('   • Product not available for points purchase');
        print('   • Insufficient stock');
        print('   • Insufficient points');
        print('');
        throw Exception(errorData['error'] ?? 'Failed to create points order');
      }
    } catch (e) {
      print('');
      print('╔════════════════════════════════════════════════════════════════');
      print('║ ❌ POINTS ORDER CREATION FAILED');
      print('╠════════════════════════════════════════════════════════════════');
      print('║ Error: $e');
      print('╚════════════════════════════════════════════════════════════════');
      print('');
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
