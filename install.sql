CREATE DATABASE IF NOT EXISTS colon_clinic CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE colon_clinic;

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

CREATE TABLE IF NOT EXISTS admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    clinic_id INT NULL,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('super_admin','clinic_owner','staff') NOT NULL DEFAULT 'clinic_owner',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_admin_clinic (clinic_id)
);

CREATE TABLE IF NOT EXISTS settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    clinic_id INT NOT NULL DEFAULT 1,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY clinic_setting_unique (clinic_id, setting_key)
);

CREATE TABLE IF NOT EXISTS appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    clinic_id INT NOT NULL DEFAULT 1,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    note TEXT NULL,
    status ENUM('Enquiry','Pending','Confirmed','Completed','Cancelled','Reschedule Needed') NOT NULL DEFAULT 'Enquiry',
    payment_status ENUM('Unpaid','Paid') NOT NULL DEFAULT 'Unpaid',
    payment_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    payment_date DATE NULL,
    payment_method VARCHAR(100) NULL,
    payment_reference VARCHAR(150) NULL,
    sms_sent TINYINT(1) NOT NULL DEFAULT 0,
    whatsapp_sent TINYINT(1) NOT NULL DEFAULT 0,
    admin_note TEXT NULL,
    confirmed_at DATETIME NULL,
    paid_at DATETIME NULL,
    sms_confirmation_sent TINYINT(1) NOT NULL DEFAULT 0,
    sms_confirmation_scheduled_for DATETIME NULL,
    whatsapp_confirmation_sent TINYINT(1) NOT NULL DEFAULT 0,
    reminder_24h_sent TINYINT(1) NOT NULL DEFAULT 0,
    reminder_2h_sent TINYINT(1) NOT NULL DEFAULT 0,
    stk_status VARCHAR(50) NULL,
    checkout_request_id VARCHAR(120) NULL,
    merchant_request_id VARCHAR(120) NULL,
    stk_response MEDIUMTEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_clinic_date (clinic_id, appointment_date),
    INDEX idx_clinic_status (clinic_id, status),
    INDEX idx_clinic_payment (clinic_id, payment_status),
    INDEX idx_phone (phone),
    INDEX idx_checkout_request_id (checkout_request_id)
);

CREATE TABLE IF NOT EXISTS sms_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    clinic_id INT NULL,
    appointment_id INT NULL,
    phone VARCHAR(30) NOT NULL,
    message TEXT NOT NULL,
    sms_type VARCHAR(50) NOT NULL DEFAULT 'general',
    status VARCHAR(30) NOT NULL DEFAULT 'sent',
    provider_response MEDIUMTEXT NULL,
    scheduled_for DATETIME NULL,
    sent_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sms_clinic (clinic_id),
    INDEX idx_sms_appt (appointment_id),
    INDEX idx_sms_type (sms_type)
);

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

INSERT INTO subscription_plans (id, name, price_monthly, max_appointments, sms_limit, features) VALUES
(1, 'Starter', 1500.00, 300, 500, 'Bookings, WhatsApp redirect, SMS confirmations, reports'),
(2, 'Professional', 3000.00, 1000, 2000, 'Everything in Starter plus M-Pesa, reminders, advanced reports'),
(3, 'Enterprise', 7000.00, NULL, NULL, 'Unlimited appointments, multiple staff, priority support')
ON DUPLICATE KEY UPDATE name=VALUES(name), price_monthly=VALUES(price_monthly), features=VALUES(features);

INSERT INTO clinics (id, clinic_name, slug, owner_name, email, phone, status, plan_id, trial_ends_at)
VALUES (1, 'Colon Management Clinic', 'colon-management-clinic', 'Clinic Admin', 'admin@clinic.local', '254700000000', 'Active', 2, DATE_ADD(CURDATE(), INTERVAL 14 DAY))
ON DUPLICATE KEY UPDATE clinic_name=VALUES(clinic_name), slug=VALUES(slug), status=VALUES(status), plan_id=VALUES(plan_id);

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

INSERT INTO clinic_subscriptions (clinic_id, plan_id, status, amount, starts_at, ends_at)
VALUES (1, 2, 'Active', 3000.00, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 MONTH));

-- Default admin password: admin123 (change after login)
INSERT INTO admins (clinic_id, full_name, email, password, role)
VALUES (1, 'Clinic Admin', 'admin@clinic.local', '$2y$12$T6x7FNww8cyCh/HedP.Pse6g4a2r4H1U8IFvv1sP6kVOT1e5eh1P2', 'clinic_owner')
ON DUPLICATE KEY UPDATE email = VALUES(email);
