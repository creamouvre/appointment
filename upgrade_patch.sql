USE colon_clinic;

ALTER TABLE appointments ADD COLUMN confirmed_at DATETIME NULL AFTER admin_note;
ALTER TABLE appointments ADD COLUMN paid_at DATETIME NULL AFTER confirmed_at;
ALTER TABLE appointments ADD COLUMN sms_confirmation_sent TINYINT(1) NOT NULL DEFAULT 0 AFTER paid_at;
ALTER TABLE appointments ADD COLUMN sms_confirmation_scheduled_for DATETIME NULL AFTER sms_confirmation_sent;
ALTER TABLE appointments ADD COLUMN whatsapp_confirmation_sent TINYINT(1) NOT NULL DEFAULT 0 AFTER sms_confirmation_scheduled_for;
ALTER TABLE appointments ADD COLUMN reminder_24h_sent TINYINT(1) NOT NULL DEFAULT 0 AFTER whatsapp_confirmation_sent;
ALTER TABLE appointments ADD COLUMN reminder_2h_sent TINYINT(1) NOT NULL DEFAULT 0 AFTER reminder_24h_sent;
ALTER TABLE appointments ADD COLUMN stk_status VARCHAR(50) NULL AFTER reminder_2h_sent;
ALTER TABLE appointments ADD COLUMN checkout_request_id VARCHAR(120) NULL AFTER stk_status;
ALTER TABLE appointments ADD COLUMN merchant_request_id VARCHAR(120) NULL AFTER checkout_request_id;
ALTER TABLE appointments ADD COLUMN stk_response MEDIUMTEXT NULL AFTER merchant_request_id;
CREATE INDEX idx_checkout_request_id ON appointments (checkout_request_id);

CREATE TABLE IF NOT EXISTS sms_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NULL,
    phone VARCHAR(30) NOT NULL,
    message TEXT NOT NULL,
    sms_type VARCHAR(50) NOT NULL DEFAULT 'general',
    status VARCHAR(30) NOT NULL DEFAULT 'sent',
    provider_response MEDIUMTEXT NULL,
    scheduled_for DATETIME NULL,
    sent_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sms_appt (appointment_id),
    INDEX idx_sms_type (sms_type)
);

INSERT INTO settings (setting_key, setting_value) VALUES
('whatsapp_provider', 'none'),
('whatsapp_access_token', ''),
('whatsapp_phone_number_id', ''),
('whatsapp_graph_version', 'v23.0'),
('mpesa_enabled', '0'),
('mpesa_environment', 'sandbox'),
('mpesa_consumer_key', ''),
('mpesa_consumer_secret', ''),
('mpesa_shortcode', ''),
('mpesa_passkey', ''),
('mpesa_callback_url', ''),
('cron_key', '')
ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value);


INSERT INTO settings (setting_key, setting_value) VALUES
('working_days', 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday'),
('working_hours_start', '08:00'),
('working_hours_end', '17:00'),
('slot_minutes', '30')
ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value);
