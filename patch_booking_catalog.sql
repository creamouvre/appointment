-- ============================================================================
-- patch_booking_catalog.sql
--
-- Multi-service booking + catalog module. RUN AFTER patch_rename_business.sql.
--
-- Adds: service_categories, bookings, booking_items tables; catalog +
-- payment-policy columns on `services`; re-points sms_logs at bookings
-- instead of appointments; copies the existing `appointments` rows into
-- bookings/booking_items (same IDs preserved) so admin screens show
-- continuous history. `appointments` itself is left untouched as a frozen
-- historical/audit table -- the application never reads it again after
-- this patch.
--
-- Non-destructive: no DROP TABLE, no DROP COLUMN, no data loss.
-- >>> Back up `creamouvre_app` before running (see patch_rename_business.sql). <<<
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. service_categories
-- ----------------------------------------------------------------------------
CREATE TABLE `service_categories` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `business_id` INT NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `slug` VARCHAR(140) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `status` ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_business_category_slug` (`business_id`,`slug`),
  KEY `idx_service_categories_business` (`business_id`,`status`),
  CONSTRAINT `fk_service_categories_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- ----------------------------------------------------------------------------
-- 2. services: catalog + payment-policy columns (additive only)
-- ----------------------------------------------------------------------------
ALTER TABLE `services`
  ADD COLUMN `category_id` INT NULL AFTER `business_id`,
  ADD COLUMN `image_path` VARCHAR(255) NULL AFTER `description`,
  ADD COLUMN `payment_policy` ENUM('inherit','full','deposit','none') NOT NULL DEFAULT 'inherit' AFTER `image_path`,
  ADD COLUMN `deposit_type` ENUM('fixed','percent') NULL AFTER `payment_policy`,
  ADD COLUMN `deposit_value` DECIMAL(10,2) NULL AFTER `deposit_type`,
  ADD COLUMN `sort_order` INT NOT NULL DEFAULT 0 AFTER `deposit_value`,
  ADD KEY `idx_services_category` (`category_id`),
  ADD CONSTRAINT `fk_services_category` FOREIGN KEY (`category_id`) REFERENCES `service_categories` (`id`) ON DELETE SET NULL;


-- ----------------------------------------------------------------------------
-- 3. bookings (header) -- replaces `appointments` for all new activity
-- ----------------------------------------------------------------------------
CREATE TABLE `bookings` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `business_id` INT NOT NULL,
  `client_id` INT DEFAULT NULL,
  `full_name` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(30) NOT NULL,
  `booking_date` DATE NOT NULL,
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `note` TEXT,
  `status` VARCHAR(50) NOT NULL DEFAULT 'Enquiry',
  `payment_policy` ENUM('full','deposit','none') NOT NULL DEFAULT 'none',
  `subtotal_amount` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `deposit_amount` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `amount_due_at_venue` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `payment_status` ENUM('Unpaid','Partially Paid','Paid') NOT NULL DEFAULT 'Unpaid',
  `payment_amount` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `payment_date` DATETIME DEFAULT NULL,
  `payment_method` VARCHAR(100) DEFAULT NULL,
  `payment_reference` VARCHAR(255) DEFAULT NULL,
  `receipt_no` VARCHAR(100) DEFAULT NULL,
  `receipt_sent_sms` TINYINT(1) NOT NULL DEFAULT '0',
  `receipt_sent_whatsapp` TINYINT(1) NOT NULL DEFAULT '0',
  `admin_note` TEXT,
  `reschedule_count` INT NOT NULL DEFAULT '0',
  `last_rescheduled_at` DATETIME DEFAULT NULL,
  `previous_booking_date` DATE DEFAULT NULL,
  `previous_start_time` TIME DEFAULT NULL,
  `reschedule_reason` TEXT,
  `reschedule_sms_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `reschedule_whatsapp_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `reminder_24h_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `reminder_2h_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `sms_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `whatsapp_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `sms_confirmation_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `whatsapp_confirmation_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `sms_confirmation_scheduled_for` DATETIME DEFAULT NULL,
  `stk_status` VARCHAR(50) DEFAULT NULL,
  `checkout_request_id` VARCHAR(255) DEFAULT NULL,
  `merchant_request_id` VARCHAR(255) DEFAULT NULL,
  `mpesa_receipt` VARCHAR(100) DEFAULT NULL,
  `stk_response` MEDIUMTEXT,
  `mpesa_response` MEDIUMTEXT,
  `missed_sms_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `feedback_sms_sent` TINYINT(1) NOT NULL DEFAULT '0',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_bookings_business_date` (`business_id`,`booking_date`),
  KEY `idx_bookings_business_status` (`business_id`,`status`),
  KEY `idx_bookings_business_payment` (`business_id`,`payment_status`),
  KEY `idx_bookings_checkout` (`checkout_request_id`),
  KEY `idx_bookings_client` (`client_id`),
  CONSTRAINT `fk_bookings_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bookings_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- ----------------------------------------------------------------------------
-- 4. booking_items (line items)
-- ----------------------------------------------------------------------------
CREATE TABLE `booking_items` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `booking_id` INT NOT NULL,
  `business_id` INT NOT NULL,
  `service_id` INT DEFAULT NULL,
  `service_name` VARCHAR(255) NOT NULL,
  `service_price` DECIMAL(10,2) NOT NULL DEFAULT '0.00',
  `service_duration` INT NOT NULL DEFAULT '30',
  `sequence_no` INT NOT NULL DEFAULT 1,
  `item_start_time` TIME NOT NULL,
  `item_end_time` TIME NOT NULL,
  `staff_id` INT DEFAULT NULL,
  `item_status` VARCHAR(30) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_booking_items_booking` (`booking_id`),
  KEY `idx_booking_items_business` (`business_id`),
  CONSTRAINT `fk_booking_items_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_booking_items_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_booking_items_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- ----------------------------------------------------------------------------
-- 5. sms_logs: point at bookings instead of appointments
-- ----------------------------------------------------------------------------
ALTER TABLE `sms_logs` DROP FOREIGN KEY `fk_sms_logs_appointment`;
ALTER TABLE `sms_logs` CHANGE COLUMN `appointment_id` `booking_id` INT DEFAULT NULL;
ALTER TABLE `sms_logs` RENAME INDEX `idx_sms_logs_appointment` TO `idx_sms_logs_booking`;
ALTER TABLE `sms_logs` ADD CONSTRAINT `fk_sms_logs_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE SET NULL;


-- ----------------------------------------------------------------------------
-- 6. Copy existing `appointments` rows into bookings/booking_items,
--    preserving IDs so sms_logs.booking_id needs no remapping.
-- ----------------------------------------------------------------------------
INSERT INTO `bookings` (
    `id`, `business_id`, `client_id`, `full_name`, `phone`, `booking_date`, `start_time`, `end_time`,
    `note`, `status`, `payment_policy`, `subtotal_amount`, `deposit_amount`, `amount_due_at_venue`,
    `payment_status`, `payment_amount`, `payment_date`, `payment_method`, `payment_reference`,
    `receipt_no`, `receipt_sent_sms`, `receipt_sent_whatsapp`, `admin_note`, `reschedule_count`,
    `last_rescheduled_at`, `previous_booking_date`, `previous_start_time`, `reschedule_reason`,
    `reschedule_sms_sent`, `reschedule_whatsapp_sent`, `reminder_24h_sent`, `reminder_2h_sent`,
    `sms_sent`, `whatsapp_sent`, `sms_confirmation_sent`, `whatsapp_confirmation_sent`,
    `sms_confirmation_scheduled_for`, `stk_status`, `checkout_request_id`, `merchant_request_id`,
    `mpesa_receipt`, `stk_response`, `mpesa_response`, `missed_sms_sent`, `feedback_sms_sent`,
    `created_at`, `updated_at`
)
SELECT
    `id`, `business_id`, `client_id`, `full_name`, `phone`, `appointment_date`, `appointment_time`,
    ADDTIME(`appointment_time`, SEC_TO_TIME(`service_duration` * 60)),
    `note`, `status`, 'full', `service_price`, 0.00,
    IF(`payment_status` = 'Paid', 0.00, `service_price`),
    `payment_status`, `payment_amount`, `payment_date`, `payment_method`, `payment_reference`,
    `receipt_no`, `receipt_sent_sms`, `receipt_sent_whatsapp`, `admin_note`, `reschedule_count`,
    `last_rescheduled_at`, `previous_appointment_date`, `previous_appointment_time`, `reschedule_reason`,
    `reschedule_sms_sent`, `reschedule_whatsapp_sent`, `reminder_24h_sent`, `reminder_2h_sent`,
    `sms_sent`, `whatsapp_sent`, `sms_confirmation_sent`, `whatsapp_confirmation_sent`,
    `sms_confirmation_scheduled_for`, `stk_status`, `checkout_request_id`, `merchant_request_id`,
    `mpesa_receipt`, `stk_response`, `mpesa_response`, `missed_sms_sent`, `feedback_sms_sent`,
    `created_at`, `updated_at`
FROM `appointments`;

INSERT INTO `booking_items` (
    `booking_id`, `business_id`, `service_id`, `service_name`, `service_price`, `service_duration`,
    `sequence_no`, `item_start_time`, `item_end_time`
)
SELECT
    `id`, `business_id`, `service_id`, `service_name`, `service_price`, `service_duration`,
    1, `appointment_time`, ADDTIME(`appointment_time`, SEC_TO_TIME(`service_duration` * 60))
FROM `appointments`;

-- Reset bookings AUTO_INCREMENT so new bookings continue after the migrated IDs
SET @next_booking_id := (SELECT COALESCE(MAX(id), 0) + 1 FROM `appointments`);
SET @sql := CONCAT('ALTER TABLE `bookings` AUTO_INCREMENT = ', @next_booking_id);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


-- ----------------------------------------------------------------------------
-- 7. Settings defaults for the new payment-policy options (per business row)
-- ----------------------------------------------------------------------------
INSERT INTO `settings` (`business_id`, `setting_key`, `setting_value`)
SELECT `id`, 'default_payment_policy', 'none' FROM `businesses`
ON DUPLICATE KEY UPDATE `setting_value` = `setting_value`;

INSERT INTO `settings` (`business_id`, `setting_key`, `setting_value`)
SELECT `id`, 'default_deposit_type', 'percent' FROM `businesses`
ON DUPLICATE KEY UPDATE `setting_value` = `setting_value`;

INSERT INTO `settings` (`business_id`, `setting_key`, `setting_value`)
SELECT `id`, 'default_deposit_value', '0' FROM `businesses`
ON DUPLICATE KEY UPDATE `setting_value` = `setting_value`;


-- ----------------------------------------------------------------------------
-- 8. Sanity checks
-- ----------------------------------------------------------------------------
-- SELECT COUNT(*) FROM bookings;                              -- expect 5 (matches appointments)
-- SELECT COUNT(*) FROM booking_items;                          -- expect 5
-- SELECT COUNT(*) FROM sms_logs WHERE booking_id IS NOT NULL;  -- expect 9
-- SELECT id, booking_date, start_time, end_time FROM bookings ORDER BY id; -- spot-check against appointments
