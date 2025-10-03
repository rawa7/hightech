import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/product.dart';

class ApiService {
  static const String _baseUrl = 'https://dasroor.com/hightech/users.php';
  static const String _authUrl = 'https://dasroor.com/hightech/auth.php';
  static const String _fcmTokenUrl = 'https://dasroor.com/hightech/api/fcm_token_api.php';

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_authUrl?action=register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data.containsKey('user')) {
          final user = User.fromJson(data['user']);
          return {'success': true, 'user': user, 'message': data['message']};
        } else {
          return {'success': true, 'data': data};
        }
      } else {
        return {'success': false, 'error': data is Map && data.containsKey('error') ? data['error'] : 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_authUrl?action=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data.containsKey('user')) {
        try {
          final user = User.fromJson(data['user']);
          return {'success': true, 'user': user, 'message': data['message']};
        } catch (e) {
          return {'success': false, 'error': 'Error parsing user data: $e'};
        }
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        try {
          final user = User.fromJson(data);
          return {'success': true, 'user': user};
        } catch (e) {
          return {'success': false, 'error': 'Error parsing profile data: $e'};
        }
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('https://dasroor.com/hightech/products.php'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        try {
          final List<dynamic> jsonList = jsonDecode(response.body);
          final products = jsonList.map((json) => Product.fromJson(json)).toList();
          return {'success': true, 'products': products};
        } catch (e) {
          return {'success': false, 'error': 'Error parsing products data: $e'};
        }
      } else {
        return {'success': false, 'error': 'Failed to fetch products'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ==================== FCM TOKEN MANAGEMENT ====================
  
  /// Save or update FCM token for a user
  static Future<Map<String, dynamic>> saveFCMToken({
    required int userId,
    required String fcmToken,
    required String deviceType, // 'android', 'ios', or 'web'
    String? deviceInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_fcmTokenUrl?action=save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': fcmToken,
          'device_type': deviceType,
          'device_info': deviceInfo,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to save FCM token'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Delete FCM token (on logout)
  static Future<Map<String, dynamic>> deleteFCMToken(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_fcmTokenUrl?action=delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to delete FCM token'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Delete all FCM tokens for a user (complete logout from all devices)
  static Future<Map<String, dynamic>> deleteAllUserTokens(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_fcmTokenUrl?action=delete_by_user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to delete user tokens'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
