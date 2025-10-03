<?php
/**
 * Send Notification to User(s) by User ID
 * 
 * This script fetches FCM tokens from the database and sends notifications
 * to specific users.
 * 
 * Usage:
 * - Run directly: php send_notification_to_user.php
 * - Include in other scripts: require 'send_notification_to_user.php';
 */

// ==================== CONFIGURATION ====================
$PROJECT_ID = 'hightech-bab87';
$SERVICE_ACCOUNT_FILE = __DIR__ . '/firebase-service-account.json';

// Database configuration
$DB_HOST = 'localhost';
$DB_NAME = 'hightech_db';
$DB_USER = 'your_username';
$DB_PASS = 'your_password';

// ==================== DATABASE CONNECTION ====================
function getDatabaseConnection() {
    global $DB_HOST, $DB_NAME, $DB_USER, $DB_PASS;
    
    try {
        $pdo = new PDO("mysql:host=$DB_HOST;dbname=$DB_NAME;charset=utf8mb4", $DB_USER, $DB_PASS);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $pdo;
    } catch (PDOException $e) {
        die("Database connection failed: " . $e->getMessage() . "\n");
    }
}

// ==================== GET USER TOKENS ====================
function getUserTokens($userId) {
    $pdo = getDatabaseConnection();
    
    $stmt = $pdo->prepare("
        SELECT fcm_token, device_type, device_info 
        FROM fcm_tokens 
        WHERE user_id = ? AND is_active = TRUE
    ");
    $stmt->execute([$userId]);
    
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

// ==================== GET ALL ACTIVE TOKENS ====================
function getAllActiveTokens() {
    $pdo = getDatabaseConnection();
    
    $stmt = $pdo->query("
        SELECT user_id, fcm_token, device_type, device_info 
        FROM fcm_tokens 
        WHERE is_active = TRUE
    ");
    
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

// ==================== OAUTH2 TOKEN FUNCTION ====================
function getAccessToken($serviceAccountFile) {
    if (!file_exists($serviceAccountFile)) {
        throw new Exception("Service account file not found: $serviceAccountFile");
    }
    
    $serviceAccount = json_decode(file_get_contents($serviceAccountFile), true);
    
    $now = time();
    $header = ['alg' => 'RS256', 'typ' => 'JWT'];
    $payload = [
        'iss' => $serviceAccount['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600
    ];
    
    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(json_encode($header)));
    $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(json_encode($payload)));
    $signatureInput = $base64UrlHeader . '.' . $base64UrlPayload;
    
    $privateKey = openssl_pkey_get_private($serviceAccount['private_key']);
    openssl_sign($signatureInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
    openssl_free_key($privateKey);
    
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    $jwt = $signatureInput . '.' . $base64UrlSignature;
    
    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    
    $response = curl_exec($ch);
    curl_close($ch);
    
    $tokenData = json_decode($response, true);
    return $tokenData['access_token'];
}

// ==================== SEND NOTIFICATION TO SINGLE TOKEN ====================
function sendToToken($fcmToken, $title, $body, $data = []) {
    global $PROJECT_ID, $SERVICE_ACCOUNT_FILE;
    
    $accessToken = getAccessToken($SERVICE_ACCOUNT_FILE);
    $url = "https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send";
    
    $message = [
        'message' => [
            'token' => $fcmToken,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => array_map('strval', $data),
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'sound' => 'default',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    'channel_id' => 'high_importance_channel'
                ]
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'alert' => [
                            'title' => $title,
                            'body' => $body,
                        ],
                        'sound' => 'default',
                    ]
                ]
            ]
        ]
    ];
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'success' => $httpCode === 200,
        'http_code' => $httpCode,
        'response' => json_decode($result, true)
    ];
}

// ==================== SEND NOTIFICATION TO USER ====================
function sendNotificationToUser($userId, $title, $body, $data = []) {
    $tokens = getUserTokens($userId);
    
    if (empty($tokens)) {
        echo "❌ No active tokens found for user ID: $userId\n";
        return [
            'success' => false,
            'message' => 'No active tokens found',
            'user_id' => $userId
        ];
    }
    
    echo "📱 Found " . count($tokens) . " active device(s) for user ID: $userId\n\n";
    
    $results = [];
    foreach ($tokens as $tokenData) {
        $fcmToken = $tokenData['fcm_token'];
        $deviceType = $tokenData['device_type'];
        $deviceInfo = $tokenData['device_info'];
        
        echo "Sending to: $deviceType ($deviceInfo)\n";
        
        $result = sendToToken($fcmToken, $title, $body, $data);
        
        if ($result['success']) {
            echo "✅ Sent successfully!\n";
        } else {
            echo "❌ Failed to send\n";
        }
        
        $results[] = [
            'device' => $deviceInfo,
            'result' => $result
        ];
        
        echo "---\n";
    }
    
    return [
        'success' => true,
        'user_id' => $userId,
        'devices_count' => count($tokens),
        'results' => $results
    ];
}

// ==================== SEND NOTIFICATION TO MULTIPLE USERS ====================
function sendNotificationToUsers($userIds, $title, $body, $data = []) {
    $results = [];
    
    foreach ($userIds as $userId) {
        echo "\n=== Sending to User ID: $userId ===\n";
        $results[$userId] = sendNotificationToUser($userId, $title, $body, $data);
    }
    
    return $results;
}

// ==================== BROADCAST TO ALL USERS ====================
function broadcastNotification($title, $body, $data = []) {
    $allTokens = getAllActiveTokens();
    
    if (empty($allTokens)) {
        echo "❌ No active tokens found in database\n";
        return ['success' => false, 'message' => 'No active tokens'];
    }
    
    echo "📢 Broadcasting to " . count($allTokens) . " device(s)...\n\n";
    
    $results = [];
    foreach ($allTokens as $tokenData) {
        $userId = $tokenData['user_id'];
        $fcmToken = $tokenData['fcm_token'];
        $deviceInfo = $tokenData['device_info'] ?? 'Unknown device';
        
        echo "User $userId - $deviceInfo: ";
        
        $result = sendToToken($fcmToken, $title, $body, $data);
        echo ($result['success'] ? "✅ Sent" : "❌ Failed") . "\n";
        
        $results[] = [
            'user_id' => $userId,
            'device' => $deviceInfo,
            'success' => $result['success']
        ];
    }
    
    return $results;
}

// ==================== MAIN EXECUTION (if run directly) ====================
if (php_sapi_name() === 'cli' && basename(__FILE__) === basename($_SERVER['SCRIPT_FILENAME'])) {
    echo "╔══════════════════════════════════════════════════════════╗\n";
    echo "║     Send Notification to User - HighTech App            ║\n";
    echo "╚══════════════════════════════════════════════════════════╝\n\n";
    
    // Example 1: Send to specific user
    $userId = 1; // Change this to your user ID
    
    $result = sendNotificationToUser(
        $userId,
        '🎉 Welcome Back!',
        'Thank you for using HighTech. Check out our new products!',
        [
            'type' => 'welcome',
            'action' => 'open_home',
            'timestamp' => date('Y-m-d H:i:s')
        ]
    );
    
    echo "\n" . str_repeat("=", 60) . "\n";
    echo "Final Result: " . ($result['success'] ? '✅ SUCCESS' : '❌ FAILED') . "\n";
    echo str_repeat("=", 60) . "\n";
    
    // Example 2: Uncomment to send to multiple users
    /*
    $userIds = [1, 2, 3];
    sendNotificationToUsers(
        $userIds,
        'Special Offer!',
        '50% off on all products today!'
    );
    */
    
    // Example 3: Uncomment to broadcast to all users
    /*
    broadcastNotification(
        'System Announcement',
        'The app will be under maintenance from 2 AM to 4 AM.'
    );
    */
}
?>

