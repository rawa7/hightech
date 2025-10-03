<?php
/**
 * Simple Test Notification Script
 * Run this to send a test notification to your device
 */

// Configuration
$PROJECT_ID = 'hightech-bab87';
$SERVICE_ACCOUNT_FILE = __DIR__ . '/firebase-service-account.json';

// YOUR CURRENT FCM TOKEN
$fcmToken = 'fxXJSNCkROS_jrhPyYJFNC:APA91bHqnKTD7WDJ0DxicSDrc2A5VdiyCBjQZNuipTStSrdEgIaxkq2C0O0VnHMVsJIwdM2MUCzk5usZs9IlKRkmZPr1tVXgqUp99SENbJTxgtFl2pyId4M';

// Get access token function
function getAccessToken($serviceAccountFile) {
    if (!file_exists($serviceAccountFile)) {
        die("❌ Error: Service account file not found!\n");
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
    
    return json_decode($response, true)['access_token'];
}

echo "🚀 Sending test notification...\n\n";

try {
    $accessToken = getAccessToken($SERVICE_ACCOUNT_FILE);
    
    $url = "https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send";
    
    $message = [
        'message' => [
            'token' => $fcmToken,
            'notification' => [
                'title' => '🎉 Hello from HighTech!',
                'body' => 'This notification was sent at ' . date('H:i:s'),
            ],
            'data' => [
                'type' => 'test',
                'timestamp' => (string)time(),
            ],
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
                            'title' => '🎉 Hello from HighTech!',
                            'body' => 'This notification was sent at ' . date('H:i:s'),
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
    
    echo "HTTP Code: $httpCode\n";
    echo "Response: $result\n\n";
    
    if ($httpCode === 200) {
        echo "✅ SUCCESS! Notification sent!\n";
        echo "Check your device now - you should see the notification.\n\n";
        echo "If you DON'T see it, check:\n";
        echo "1. Is your Flutter app running?\n";
        echo "2. Are notifications enabled in device settings?\n";
        echo "3. Check Flutter console for 'Received foreground message' or similar logs\n";
    } else {
        echo "❌ FAILED! Response: $result\n";
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
?>

