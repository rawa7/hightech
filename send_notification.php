<?php
/**
 * Firebase Cloud Messaging V1 API - PHP Notification Sender
 * 
 * This script uses the modern FCM V1 API (not the deprecated legacy API)
 * 
 * Setup Instructions:
 * 1. Go to Firebase Console → Project Settings → Service Accounts
 * 2. Click "Generate new private key"
 * 3. Save the JSON file as "firebase-service-account.json" in this directory
 */

// ==================== CONFIGURATION ====================
$PROJECT_ID = 'hightech-bab87';
$SERVICE_ACCOUNT_FILE = __DIR__ . '/firebase-service-account.json';

// ==================== OAUTH2 TOKEN FUNCTION ====================
function getAccessToken($serviceAccountFile) {
    if (!file_exists($serviceAccountFile)) {
        throw new Exception("Service account file not found: $serviceAccountFile\n\nPlease follow these steps:\n1. Go to https://console.firebase.google.com/\n2. Select 'hightech-bab87' project\n3. Go to Project Settings → Service Accounts\n4. Click 'Generate new private key'\n5. Save as 'firebase-service-account.json' in this directory");
    }
    
    $serviceAccount = json_decode(file_get_contents($serviceAccountFile), true);
    
    // Create JWT
    $now = time();
    $header = [
        'alg' => 'RS256',
        'typ' => 'JWT'
    ];
    
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
    
    // Sign with private key
    $privateKey = openssl_pkey_get_private($serviceAccount['private_key']);
    openssl_sign($signatureInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
    openssl_free_key($privateKey);
    
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    $jwt = $signatureInput . '.' . $base64UrlSignature;
    
    // Exchange JWT for access token
    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        throw new Exception("Failed to get access token: $response");
    }
    
    $tokenData = json_decode($response, true);
    return $tokenData['access_token'];
}

// ==================== SEND NOTIFICATION FUNCTION ====================
function sendPushNotification($fcmToken, $title, $body, $data = [], $projectId, $serviceAccountFile) {
    try {
        $accessToken = getAccessToken($serviceAccountFile);
    } catch (Exception $e) {
        return [
            'success' => false,
            'error' => $e->getMessage()
        ];
    }
    
    $url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";
    
    // FCM V1 API message format
    $message = [
        'message' => [
            'token' => $fcmToken,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => array_merge([
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ], array_map('strval', $data)), // All data values must be strings
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'sound' => 'default',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ]
            ],
        ]
    ];
    
    $headers = [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json',
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    $response = [
        'success' => $httpCode === 200,
        'http_code' => $httpCode,
        'response' => json_decode($result, true),
        'error' => $error ?: null
    ];
    
    return $response;
}

// ==================== TEST NOTIFICATION ====================
// Your FCM Token
$fcmToken = 'ePm2XDf_RaG32VjbpIubjX:APA91bGV925vu7YCOFP1jmmL19CARI5F4EfR496k9XUFnzx6u9HPDp6OFkbQkm25rIM4A9QAzRZznWM-XyFimrVZoHiCd4prCKgzkm2sh7ycbl6HpoPR0JA';

// Send test notification
$result = sendPushNotification(
    $fcmToken,
    'Test Notification',
    'This is a test from PHP using FCM V1 API! 🚀',
    [
        'type' => 'test',
        'timestamp' => date('Y-m-d H:i:s'),
        'message' => 'Hello from PHP backend!'
    ],
    $PROJECT_ID,
    $SERVICE_ACCOUNT_FILE
);

// ==================== DISPLAY RESULT ====================
header('Content-Type: application/json');
echo json_encode($result, JSON_PRETTY_PRINT);

// Also log to console if running from CLI
if (php_sapi_name() === 'cli') {
    echo "\n\n";
    echo "==================== NOTIFICATION RESULT ====================\n";
    echo "Status: " . ($result['success'] ? '✅ SUCCESS' : '❌ FAILED') . "\n";
    echo "HTTP Code: " . $result['http_code'] . "\n";
    
    if ($result['success']) {
        echo "Message Name: " . ($result['response']['name'] ?? 'N/A') . "\n";
        echo "\n✅ Notification sent successfully!\n";
    } else {
        echo "Error Details:\n";
        if (isset($result['response']['error'])) {
            echo "  Code: " . ($result['response']['error']['code'] ?? 'N/A') . "\n";
            echo "  Message: " . ($result['response']['error']['message'] ?? 'N/A') . "\n";
            echo "  Status: " . ($result['response']['error']['status'] ?? 'N/A') . "\n";
        } elseif ($result['error']) {
            echo "  " . $result['error'] . "\n";
        }
    }
    echo "=============================================================\n";
}
?>
