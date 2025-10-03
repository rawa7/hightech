-- FCM Tokens Table
-- This table stores Firebase Cloud Messaging tokens for push notifications

CREATE TABLE IF NOT EXISTS fcm_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    fcm_token VARCHAR(255) NOT NULL UNIQUE,
    device_type ENUM('android', 'ios', 'web') NOT NULL,
    device_info VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_fcm_token (fcm_token),
    INDEX idx_is_active (is_active),
    
    -- Foreign key to users table (adjust table name if different)
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optional: Add index for better query performance
CREATE INDEX idx_user_active ON fcm_tokens(user_id, is_active);

-- Sample query to get all active tokens for a user
-- SELECT fcm_token FROM fcm_tokens WHERE user_id = ? AND is_active = TRUE;

-- Sample query to get all active tokens (for broadcast notifications)
-- SELECT fcm_token FROM fcm_tokens WHERE is_active = TRUE;

