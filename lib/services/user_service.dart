import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/user.dart';
import 'notification_service.dart';
import 'api_service.dart';

class UserService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Save user and register FCM token
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
    
    // Register FCM token with backend
    await _registerFCMToken(user.id);
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Logout user and delete FCM token from backend
  static Future<void> logout() async {
    // Get FCM token before clearing data
    final fcmToken = NotificationService().fcmToken;
    
    // Delete FCM token from backend
    if (fcmToken != null) {
      await ApiService.deleteFCMToken(fcmToken);
      print('FCM token deleted from backend on logout');
    }
    
    // Clear local data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// Register FCM token with backend when user logs in
  static Future<void> _registerFCMToken(int userId) async {
    try {
      final fcmToken = NotificationService().fcmToken;
      
      if (fcmToken == null) {
        print('No FCM token available yet');
        return;
      }

      // Get device info
      String deviceType = 'android';
      String? deviceInfo;
      
      if (Platform.isAndroid) {
        deviceType = 'android';
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        deviceInfo = '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        deviceInfo = '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      }

      // Send to backend
      final result = await ApiService.saveFCMToken(
        userId: userId,
        fcmToken: fcmToken,
        deviceType: deviceType,
        deviceInfo: deviceInfo,
      );

      if (result['success'] == true) {
        print('✅ FCM token registered with backend successfully');
      } else {
        print('⚠️ Failed to register FCM token: ${result['error']}');
      }
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }

  /// Update FCM token (call this when token refreshes)
  static Future<void> updateFCMToken(String newToken) async {
    final user = await getUser();
    if (user != null && await isLoggedIn()) {
      await _registerFCMToken(user.id);
    }
  }
}
