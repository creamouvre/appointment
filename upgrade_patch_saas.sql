-- SaaS upgrade patch for existing single-clinic installs
-- Run once after backing up your database.

CREATE TABLE IF NOT EXISTS subscription_plans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price_monthly DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    max_appointments INT NULL,
    sms_limit INT NULL,
    features TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clinics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    clinic_name VARCHAR(150) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    owner_name VARCHAR(150) NULL,
    email VARCHAR(150) NULL,
    phone VARCHAR(30) NULL,
    status ENUM('Trial','Active','Suspended','Cancelled') NOT NULL DEFAULT 'Trial',
    plan_id INT NULL,
    trial_ends_at DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_clinic_slug (slug),
    INDEX idx_clinic_status (status)
);

INSERT INTO subscription_plans (id, name, price_monthly, max_appointments, sms_limit, features) VALUES
(1, 'Starter', 1500.00, 300, 500, 'Bookings, WhatsApp redirect, SMS confirmations, reports'),
(2, 'Professional', 3000.00, 1000, 2000, 'Everything in Starter plus M-Pesa, reminders, advanced reports'),
(3, 'Enterprise', 7000.00, NULL, NULL, 'Unlimited appointments, multiple staff, priority support')
ON DUPLICATE KEY UPDATE name=VALUES(name), price_monthly=VALUES(price_monthly), features=VALUES(features);

INSERT INTO clinics (id, clinic_name, slug, owner_name, email, phone, status, plan_id, trial_ends_at)
VALUES (1, 'Colon Management Clinic', 'colon-management-clinic', 'Clinic Admin', 'admin@clinic.local', '254700000000', 'Active', 2, DATE_ADD(CURDATE(), INTERVAL 14 DAY))
ON DUPLICATE KEY UPDATE clinic_name=VALUES(clinic_name), slug=VALUES(slug), status=VALUES(status), plan_id=VALUES(plan_id);

ALTER TABLE admins ADD COLUMN clinic_id INT NULL AFTER id;
ALTER TABLE admins ADD COLUMN role ENUM('super_admin','clinic_owner','staff') NOT NULL DEFAULT 'clinic_owner' AFTER password;
UPDATE admins SET clinic_id = 1 WHERE clinic_id IS NULL;

ALTER TABLE appointments ADD COLUMN clinic_id INT NULL AFTER id;
UPDATE appointments SET clinic_id = 1 WHERE clinic_id IS NULL;
ALTER TABLE appointments ADD INDEX idx_clinic_date (clinic_id, appointment_date);
ALTER TABLE appointments ADD INDEX idx_clinic_status (clinic_id, status);
ALTER TABLE appointments ADD INDEX idx_clinic_payment (clinic_id, payment_status);

ALTER TABLE sms_logs ADD COLUMN clinic_id INT NULL AFTER id;
UPDATE sms_logs SET clinic_id = 1 WHERE clinic_id IS NULL;
ALTER TABLE sms_logs ADD INDEX idx_sms_clinic (clinic_id);

-- Convert settings to clinic-specific settings.
ALTER TABLE settings ADD COLUMN clinic_id INT NULL AFTER id;
UPDATE settings SET clinic_id = 1 WHERE clinic_id IS NULL;
ALTER TABLE settings DROP INDEX setting_key;
ALTER TABLE settings ADD UNIQUE KEY clinic_setting_unique (clinic_id, setting_key);

INSERT INTO settings (clinic_id, setting_key, setting_value) VALUES
(1,'site_name','Colon Management Clinic'),
(1,'whatsapp_number','254700000000'),
(1,'currency','KES'),
(1,'sms_provider','textsms'),
(1,'sms_username',''),
(1,'sms_api_key',''),
(1,'sms_sender_id',''),
(1,'working_days','Monday,Tuesday,Wednesday,Thursday,Friday,Saturday'),
(1,'working_hours_start','08:00'),
(1,'working_hours_end','17:00'),
(1,'slot_minutes','30'),
(1,'whatsapp_provider','none'),
(1,'whatsapp_access_token',''),
(1,'whatsapp_phone_number_id',''),
(1,'whatsapp_graph_version','v23.0'),
(1,'mpesa_enabled','0'),
(1,'mpesa_environment','sandbox'),
(1,'mpesa_consumer_key',''),
(1,'mpesa_consumer_secret',''),
(1,'mpesa_shortcode',''),
(1,'mpesa_passkey',''),
(1,'mpesa_callback_url',''),
(1,'cron_key','')
ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value);

CREATE TABLE IF NOT EXISTS clinic_subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    clinic_id INT NOT NULL,
    plan_id INT NOT NULL,
    status ENUM('Trial','Active','Past Due','Cancelled') NOT NULL DEFAULT 'Trial',
    amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    starts_at DATE NOT NULL,
    ends_at DATE NULL,
    last_payment_reference VARCHAR(150) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sub_clinic (clinic_id),
    INDEX idx_sub_status (status)
);

INSERT INTO clinic_subscriptions (clinic_id, plan_id, status, amount, starts_at, ends_at)
VALUES (1, 2, 'Active', 3000.00, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 MONTH))
ON DUPLICATE KEY UPDATE status=VALUES(status);
