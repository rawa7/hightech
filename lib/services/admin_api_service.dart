import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class AdminApiService {
  static const String _baseUrl = 'https://dasroor.com/hightech';

  /// Get all orders (admin only)
  static Future<List<Order>> getAllOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin_orders.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        debugPrint('Failed to fetch orders: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  /// Get orders filtered by status
  static Future<List<Order>> getOrdersByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin_orders.php?status=$status'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        debugPrint('Failed to fetch orders by status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching orders by status: $e');
      return [];
    }
  }

  /// Get single order by ID
  static Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin_orders.php?id=$orderId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Order.fromJson(data);
      } else {
        debugPrint('Failed to fetch order: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching order: $e');
      return null;
    }
  }

  /// Update order status (admin only)
  /// Status options: 'pending', 'Accepted', 'delivered'
  static Future<Map<String, dynamic>> updateOrderStatus(
      int orderId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/admin_orders.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Order status updated successfully',
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to update order status',
        };
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Accept an order (change status to "Accepted")
  static Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    return await updateOrderStatus(orderId, 'Accepted');
  }

  /// Deliver an order (change status to "delivered")
  static Future<Map<String, dynamic>> deliverOrder(int orderId) async {
    return await updateOrderStatus(orderId, 'delivered');
  }

  /// Get orders count by status
  static Future<Map<String, int>> getOrdersCountByStatus() async {
    try {
      final orders = await getAllOrders();
      final Map<String, int> counts = {
        'pending': 0,
        'Accepted': 0,
        'delivered': 0,
      };

      for (var order in orders) {
        final status = order.status.toLowerCase();
        if (counts.containsKey(status)) {
          counts[status] = (counts[status] ?? 0) + 1;
        }
      }

      return counts;
    } catch (e) {
      debugPrint('Error getting orders count: $e');
      return {'pending': 0, 'Accepted': 0, 'delivered': 0};
    }
  }
}

