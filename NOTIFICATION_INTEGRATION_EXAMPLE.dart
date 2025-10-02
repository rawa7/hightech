// Example: How to integrate notification settings into your HomeScreen

// Add this import to your HomeScreen
import 'screens/notification_settings_screen.dart';

// Add this button/tile in your HomeScreen or Settings menu
class NotificationMenuTile extends StatelessWidget {
  const NotificationMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications, color: Color(0xFF316AE9)),
      title: const Text('Notifications'),
      subtitle: const Text('Manage notification settings'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationSettingsScreen(),
          ),
        );
      },
    );
  }
}

// Or add as a Card button
class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationSettingsScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF316AE9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF316AE9),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage your notifications',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BACKEND INTEGRATION EXAMPLES
// ============================================================

// 1. Send FCM token to backend after login (in your LoginScreen)
Future<void> _handleLoginSuccess(String userId) async {
  // Get FCM token
  String? fcmToken = NotificationService().fcmToken;
  
  // Send to backend
  if (fcmToken != null) {
    try {
      final response = await http.post(
        Uri.parse('YOUR_API_URL/update-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': fcmToken,
        }),
      );
      
      if (response.statusCode == 200) {
        print('FCM token updated successfully');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}

// 2. Backend PHP endpoint to receive FCM token
/*
<?php
// update-fcm-token.php
header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);
$userId = $data['user_id'] ?? null;
$fcmToken = $data['fcm_token'] ?? null;

if (!$userId || !$fcmToken) {
    echo json_encode(['success' => false, 'message' => 'Missing parameters']);
    exit;
}

// Update FCM token in database
$stmt = $conn->prepare("UPDATE users SET fcm_token = ?, fcm_token_updated_at = NOW() WHERE id = ?");
$stmt->bind_param("si", $fcmToken, $userId);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'FCM token updated']);
} else {
    echo json_encode(['success' => false, 'message' => 'Database error']);
}
?>
*/

// 3. Subscribe to topics based on user preferences
Future<void> _updateNotificationPreferences(bool receivePromotions) async {
  if (receivePromotions) {
    await NotificationService().subscribeToTopic('promotions');
  } else {
    await NotificationService().unsubscribeFromTopic('promotions');
  }
}

// 4. Handle notification navigation in NotificationService
// Update _handleNotificationTap in lib/services/notification_service.dart
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  
  // Navigate based on notification type
  if (data['type'] == 'order') {
    navigatorKey.currentState?.pushNamed(
      '/order-detail',
      arguments: data['orderId'],
    );
  } else if (data['type'] == 'promotion') {
    navigatorKey.currentState?.pushNamed('/shop');
  } else if (data['type'] == 'product') {
    navigatorKey.currentState?.pushNamed(
      '/product-detail',
      arguments: data['productId'],
    );
  }
}

// ============================================================
// BACKEND: SEND NOTIFICATIONS FROM PHP
// ============================================================

/*
<?php
class NotificationService {
    private $serverKey;
    
    public function __construct($serverKey) {
        $this->serverKey = $serverKey;
    }
    
    // Send to single device
    public function sendToDevice($fcmToken, $title, $body, $data = []) {
        $notification = [
            'to' => $fcmToken,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
            ],
            'data' => $data,
            'priority' => 'high',
        ];
        
        return $this->sendRequest($notification);
    }
    
    // Send to topic
    public function sendToTopic($topic, $title, $body, $data = []) {
        $notification = [
            'to' => '/topics/' . $topic,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
            ],
            'data' => $data,
            'priority' => 'high',
        ];
        
        return $this->sendRequest($notification);
    }
    
    // Send to multiple devices
    public function sendToMultipleDevices($fcmTokens, $title, $body, $data = []) {
        $notification = [
            'registration_ids' => $fcmTokens,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
            ],
            'data' => $data,
            'priority' => 'high',
        ];
        
        return $this->sendRequest($notification);
    }
    
    private function sendRequest($notification) {
        $url = 'https://fcm.googleapis.com/fcm/send';
        $headers = [
            'Authorization: key=' . $this->serverKey,
            'Content-Type: application/json',
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($notification));
        
        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        return [
            'success' => $httpCode == 200,
            'response' => json_decode($result, true)
        ];
    }
}

// Usage examples:
$fcmServerKey = 'YOUR_SERVER_KEY_FROM_FIREBASE_CONSOLE';
$notificationService = new NotificationService($fcmServerKey);

// 1. Order status update
$notificationService->sendToDevice(
    $userFcmToken,
    'Order Shipped',
    'Your order #12345 has been shipped',
    ['type' => 'order', 'orderId' => '12345', 'status' => 'shipped']
);

// 2. Promotion to all subscribers
$notificationService->sendToTopic(
    'promotions',
    'Flash Sale!',
    '50% off all electronics. Limited time only!',
    ['type' => 'promotion', 'category' => 'electronics']
);

// 3. Announcement to all users
$notificationService->sendToTopic(
    'all_users',
    'New Feature Available',
    'Check out our new product catalog!',
    ['type' => 'announcement']
);

// 4. Send to multiple admins
$adminTokens = ['token1', 'token2', 'token3'];
$notificationService->sendToMultipleDevices(
    $adminTokens,
    'Low Stock Alert',
    'Product X is running low on stock',
    ['type' => 'stock_alert', 'productId' => '123']
);
?>
*/


