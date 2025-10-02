<?php
/**
 * Firebase Cloud Messaging V1 API - Notification Examples
 * 
 * Common notification patterns for your HighTech app
 */

require_once 'send_notification.php';

// ==================== EXAMPLE 1: Order Confirmation ====================
function sendOrderConfirmation($fcmToken, $orderId, $totalAmount) {
    return sendPushNotification(
        $fcmToken,
        'Order Confirmed! 🎉',
        "Order #$orderId has been confirmed. Total: $$totalAmount",
        [
            'type' => 'order_confirmed',
            'order_id' => (string)$orderId,
            'amount' => (string)$totalAmount,
            'action' => 'view_order'
        ],
        $GLOBALS['PROJECT_ID'],
        $GLOBALS['SERVICE_ACCOUNT_FILE']
    );
}

// ==================== EXAMPLE 2: Order Status Update ====================
function sendOrderStatusUpdate($fcmToken, $orderId, $status) {
    $statusMessages = [
        'processing' => 'Your order is being processed',
        'shipped' => 'Your order has been shipped! 📦',
        'delivered' => 'Your order has been delivered! ✅',
        'cancelled' => 'Your order has been cancelled'
    ];
    
    return sendPushNotification(
        $fcmToken,
        'Order Update',
        $statusMessages[$status] ?? "Order #$orderId status: $status",
        [
            'type' => 'order_status',
            'order_id' => (string)$orderId,
            'status' => $status,
            'action' => 'view_order'
        ],
        $GLOBALS['PROJECT_ID'],
        $GLOBALS['SERVICE_ACCOUNT_FILE']
    );
}

// ==================== EXAMPLE 3: Payment Received ====================
function sendPaymentReceived($fcmToken, $orderId, $amount) {
    return sendPushNotification(
        $fcmToken,
        'Payment Received! 💰',
        "We've received your payment of $$amount for Order #$orderId",
        [
            'type' => 'payment_received',
            'order_id' => (string)$orderId,
            'amount' => (string)$amount,
            'action' => 'view_receipt'
        ],
        $GLOBALS['PROJECT_ID'],
        $GLOBALS['SERVICE_ACCOUNT_FILE']
    );
}

// ==================== EXAMPLE 4: New Promotion ====================
function sendPromotion($fcmToken, $title, $description, $discountPercent) {
    return sendPushNotification(
        $fcmToken,
        "Special Offer! 🎁",
        "$title - Save $discountPercent%!",
        [
            'type' => 'promotion',
            'title' => $title,
            'description' => $description,
            'discount' => (string)$discountPercent,
            'action' => 'view_products'
        ],
        $GLOBALS['PROJECT_ID'],
        $GLOBALS['SERVICE_ACCOUNT_FILE']
    );
}

// ==================== EXAMPLE 5: Low Stock Alert (Admin) ====================
function sendLowStockAlert($fcmToken, $productName, $currentStock) {
    return sendPushNotification(
        $fcmToken,
        'Low Stock Alert! ⚠️',
        "$productName is running low (Only $currentStock left)",
        [
            'type' => 'low_stock',
            'product_name' => $productName,
            'stock' => (string)$currentStock,
            'action' => 'restock'
        ],
        $GLOBALS['PROJECT_ID'],
        $GLOBALS['SERVICE_ACCOUNT_FILE']
    );
}

// ==================== EXAMPLE 6: Send to Multiple Users ====================
function sendToMultipleUsers($fcmTokens, $title, $body, $data = []) {
    $results = [];
    foreach ($fcmTokens as $token) {
        $results[] = sendPushNotification(
            $token,
            $title,
            $body,
            $data,
            $GLOBALS['PROJECT_ID'],
            $GLOBALS['SERVICE_ACCOUNT_FILE']
        );
    }
    return $results;
}

// ==================== EXAMPLE 7: Send to Topic (V1 API) ====================
function sendToTopic($topic, $title, $body, $data = []) {
    try {
        $accessToken = getAccessToken($GLOBALS['SERVICE_ACCOUNT_FILE']);
    } catch (Exception $e) {
        return [
            'success' => false,
            'error' => $e->getMessage()
        ];
    }
    
    $url = "https://fcm.googleapis.com/v1/projects/{$GLOBALS['PROJECT_ID']}/messages:send";
    
    $message = [
        'message' => [
            'topic' => $topic,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => array_map('strval', $data),
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'sound' => 'default',
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

// ==================== USAGE EXAMPLES ====================
/*

// Example 1: Send order confirmation
$result = sendOrderConfirmation(
    $userFcmToken,
    'ORD12345',
    249.99
);

// Example 2: Update order status
$result = sendOrderStatusUpdate(
    $userFcmToken,
    'ORD12345',
    'shipped'
);

// Example 3: Send promotion to all subscribed users
$result = sendToTopic(
    'promotions',
    'Flash Sale! ⚡',
    '50% off on all electronics for the next 24 hours!',
    ['type' => 'promotion', 'category' => 'electronics']
);

// Example 4: Send to multiple admin users
$adminTokens = [
    'token1...',
    'token2...',
    'token3...'
];
$results = sendToMultipleUsers(
    $adminTokens,
    'New Order Alert',
    'A new order has been placed',
    ['type' => 'new_order', 'order_id' => 'ORD12345']
);

*/
?>
