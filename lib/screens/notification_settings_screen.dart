import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  String? _fcmToken;
  bool _isLoadingToken = false;
  final Set<String> _subscribedTopics = {};

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    setState(() => _isLoadingToken = true);
    
    try {
      final token = NotificationService().fcmToken;
      setState(() {
        _fcmToken = token;
        _isLoadingToken = false;
      });
    } catch (e) {
      setState(() => _isLoadingToken = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading token: $e')),
        );
      }
    }
  }

  Future<void> _copyTokenToClipboard() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM Token copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _subscribeToTopic(String topic) async {
    try {
      await NotificationService().subscribeToTopic(topic);
      setState(() => _subscribedTopics.add(topic));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscribed to $topic'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subscribing: $e')),
        );
      }
    }
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    try {
      await NotificationService().unsubscribeFromTopic(topic);
      setState(() => _subscribedTopics.remove(topic));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unsubscribed from $topic'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unsubscribing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FCM Token Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.key, color: Color(0xFF316AE9)),
                      const SizedBox(width: 8),
                      const Text(
                        'FCM Device Token',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingToken)
                    const Center(child: CircularProgressIndicator())
                  else if (_fcmToken != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _copyTokenToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Token'),
                    ),
                  ] else
                    const Text('Token not available'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notification Topics Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Color(0xFF316AE9)),
                      const SizedBox(width: 8),
                      const Text(
                        'Notification Topics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Subscribe to topics to receive targeted notifications',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildTopicTile('all_users', 'All Users', 'General announcements for all users'),
                  _buildTopicTile('promotions', 'Promotions', 'Special offers and discounts'),
                  _buildTopicTile('new_products', 'New Products', 'Latest product announcements'),
                  _buildTopicTile('order_updates', 'Order Updates', 'Updates about your orders'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Information Section
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'About Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Receive updates about your orders and deliveries\n'
                    '• Get notified about special promotions and offers\n'
                    '• Stay informed about new products\n'
                    '• Manage your preferences anytime',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Test Section (for development)
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Testing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'To test notifications:\n'
                    '1. Copy your FCM token above\n'
                    '2. Go to Firebase Console\n'
                    '3. Navigate to Cloud Messaging\n'
                    '4. Send a test message using your token',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTile(String topic, String title, String description) {
    final isSubscribed = _subscribedTopics.contains(topic);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        value: isSubscribed,
        onChanged: (value) {
          if (value) {
            _subscribeToTopic(topic);
          } else {
            _unsubscribeFromTopic(topic);
          }
        },
        title: Text(title),
        subtitle: Text(description),
        secondary: Icon(
          isSubscribed ? Icons.notifications_active : Icons.notifications_off,
          color: isSubscribed ? const Color(0xFF316AE9) : Colors.grey,
        ),
      ),
    );
  }
}

