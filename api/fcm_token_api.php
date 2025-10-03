<?php
/**
 * FCM Token Management API
 * 
 * Endpoints:
 * - POST /api/fcm_token_api.php?action=save   - Save/Update FCM token
 * - POST /api/fcm_token_api.php?action=delete - Delete FCM token (logout)
 * - GET  /api/fcm_token_api.php?action=get_user_tokens - Get all tokens for a user
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration - UPDATE THESE WITH YOUR DATABASE CREDENTIALS
$db_host = 'localhost';
$db_name = 'hightech_db';
$db_user = 'your_username';
$db_pass = 'your_password';

// Connect to database
try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8mb4", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed',
        'error' => $e->getMessage()
    ]);
    exit();
}

// Get action from query parameter
$action = $_GET['action'] ?? '';

// Route to appropriate handler
switch ($action) {
    case 'save':
        saveFCMToken($pdo);
        break;
    case 'delete':
        deleteFCMToken($pdo);
        break;
    case 'delete_by_user':
        deleteUserTokens($pdo);
        break;
    case 'get_user_tokens':
        getUserTokens($pdo);
        break;
    default:
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid action. Use: save, delete, delete_by_user, or get_user_tokens'
        ]);
        break;
}

/**
 * Save or update FCM token
 * POST Body: { user_id, fcm_token, device_type, device_info? }
 */
function saveFCMToken($pdo) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['user_id']) || !isset($data['fcm_token']) || !isset($data['device_type'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Missing required fields: user_id, fcm_token, device_type'
        ]);
        return;
    }
    
    $user_id = $data['user_id'];
    $fcm_token = $data['fcm_token'];
    $device_type = $data['device_type'];
    $device_info = $data['device_info'] ?? null;
    
    try {
        // Check if token already exists
        $stmt = $pdo->prepare("SELECT id, user_id FROM fcm_tokens WHERE fcm_token = ?");
        $stmt->execute([$fcm_token]);
        $existing = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($existing) {
            // Token exists - update it
            if ($existing['user_id'] != $user_id) {
                // Token was registered to different user - reassign it
                $stmt = $pdo->prepare("
                    UPDATE fcm_tokens 
                    SET user_id = ?, device_type = ?, device_info = ?, 
                        updated_at = NOW(), last_used_at = NOW(), is_active = TRUE
                    WHERE fcm_token = ?
                ");
                $stmt->execute([$user_id, $device_type, $device_info, $fcm_token]);
            } else {
                // Same user - just update timestamp
                $stmt = $pdo->prepare("
                    UPDATE fcm_tokens 
                    SET last_used_at = NOW(), is_active = TRUE, device_info = ?
                    WHERE fcm_token = ?
                ");
                $stmt->execute([$device_info, $fcm_token]);
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'FCM token updated successfully',
                'action' => 'updated'
            ]);
        } else {
            // New token - insert it
            $stmt = $pdo->prepare("
                INSERT INTO fcm_tokens (user_id, fcm_token, device_type, device_info, last_used_at) 
                VALUES (?, ?, ?, ?, NOW())
            ");
            $stmt->execute([$user_id, $fcm_token, $device_type, $device_info]);
            
            echo json_encode([
                'success' => true,
                'message' => 'FCM token saved successfully',
                'action' => 'inserted',
                'token_id' => $pdo->lastInsertId()
            ]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error',
            'error' => $e->getMessage()
        ]);
    }
}

/**
 * Delete FCM token (logout)
 * POST Body: { fcm_token }
 */
function deleteFCMToken($pdo) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['fcm_token'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Missing required field: fcm_token'
        ]);
        return;
    }
    
    $fcm_token = $data['fcm_token'];
    
    try {
        // Soft delete - set is_active to false
        $stmt = $pdo->prepare("UPDATE fcm_tokens SET is_active = FALSE WHERE fcm_token = ?");
        $stmt->execute([$fcm_token]);
        
        if ($stmt->rowCount() > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'FCM token deleted successfully'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'FCM token not found'
            ]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error',
            'error' => $e->getMessage()
        ]);
    }
}

/**
 * Delete all tokens for a user (complete logout)
 * POST Body: { user_id }
 */
function deleteUserTokens($pdo) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['user_id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Missing required field: user_id'
        ]);
        return;
    }
    
    $user_id = $data['user_id'];
    
    try {
        // Soft delete all user tokens
        $stmt = $pdo->prepare("UPDATE fcm_tokens SET is_active = FALSE WHERE user_id = ?");
        $stmt->execute([$user_id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'All user tokens deleted successfully',
            'deleted_count' => $stmt->rowCount()
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error',
            'error' => $e->getMessage()
        ]);
    }
}

/**
 * Get all active tokens for a user
 * Query params: user_id
 */
function getUserTokens($pdo) {
    if (!isset($_GET['user_id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Missing required parameter: user_id'
        ]);
        return;
    }
    
    $user_id = $_GET['user_id'];
    
    try {
        $stmt = $pdo->prepare("
            SELECT id, fcm_token, device_type, device_info, created_at, last_used_at 
            FROM fcm_tokens 
            WHERE user_id = ? AND is_active = TRUE
            ORDER BY last_used_at DESC
        ");
        $stmt->execute([$user_id]);
        $tokens = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'tokens' => $tokens,
            'count' => count($tokens)
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error',
            'error' => $e->getMessage()
        ]);
    }
}
?>

