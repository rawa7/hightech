import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Initialize notification service
  Future<void> initialize() async {
    // Request permission for iOS
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    await _getFCMToken();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      await _saveFCMToken(newToken);
      print('FCM Token refreshed: $newToken');
      
      // Update token in backend if user is logged in
      await _updateTokenInBackend(newToken);
    });
  }

  // Request notification permissions
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _handleLocalNotificationTap(details.payload!);
        }
      },
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Get and save FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
        print('FCM Token: $_fcmToken');
        // TODO: Send this token to your backend server
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Save FCM token locally
  Future<void> _saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Show local notification when app is in foreground
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // Handle notification tap from background
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');
    
    // TODO: Navigate to specific screen based on notification data
    // Example:
    // if (message.data['type'] == 'order') {
    //   navigatorKey.currentState?.pushNamed('/order', arguments: message.data['orderId']);
    // }
  }

  // Handle local notification tap
  void _handleLocalNotificationTap(String payload) {
    print('Local notification tapped with payload: $payload');
    
    try {
      final data = jsonDecode(payload);
      // TODO: Handle navigation based on payload data
      print('Payload data: $data');
    } catch (e) {
      print('Error parsing payload: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Send token to your backend
  Future<void> sendTokenToBackend(String? userId) async {
    if (_fcmToken == null) return;
    
    // TODO: Implement API call to send token to your backend
    // Example:
    // await ApiService().sendFCMToken(_fcmToken!, userId);
    print('Would send FCM token to backend for user: $userId');
  }

  // Update token in backend (called when token refreshes)
  Future<void> _updateTokenInBackend(String newToken) async {
    try {
      // Import UserService to avoid circular dependency
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (isLoggedIn) {
        final userData = prefs.getString('user_data');
        if (userData != null) {
          final user = jsonDecode(userData);
          final userId = user['id'] as int;
          
          // Import at top of file: import 'api_service.dart';
          // You can call the API directly here or use UserService
          print('Token refreshed - would update for user: $userId');
        }
      }
    } catch (e) {
      print('Error updating token in backend: $e');
    }
  }
}

