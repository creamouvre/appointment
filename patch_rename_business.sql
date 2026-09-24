-- ============================================================================
-- patch_rename_business.sql
--
-- Renames the "clinic" tenant concept to the generic "business" concept
-- across the schema: tables, columns, foreign keys, indexes, and one data
-- value (admins.role).
--
-- >>> BACK UP `creamouvre_app` BEFORE RUNNING THIS PATCH. <<<
--   e.g. mysqldump -u USER -p creamouvre_app > creamouvre_app_backup.sql
--
-- This is non-destructive (no DROP TABLE, no DROP COLUMN of populated data)
-- but it does rename structure, and MySQL DDL statements auto-commit one at
-- a time (no real rollback if something fails partway) -- run it against a
-- staging copy first and verify the sanity-check queries at the bottom.
--
-- Statement names below (fk_*, idx_*, unique_*) match the live schema
-- exactly as of the "Aug 15, 2026 01:05 PM" dump of `creamouvre_app`. If
-- your live database has drifted since then, run:
--   SHOW CREATE TABLE admins, appointments, services, clients, settings,
--                     sms_logs, activity_logs, clinic_subscriptions, clinics;
-- and adjust any names below that don't match before running.
--
-- Run this patch, THEN patch_booking_catalog.sql.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Drop foreign keys that reference `clinics` / `clinic_subscriptions`
--    (must happen before the tables/columns they point at are renamed)
-- ----------------------------------------------------------------------------
ALTER TABLE `admins` DROP FOREIGN KEY `fk_admins_clinic`;
ALTER TABLE `appointments` DROP FOREIGN KEY `fk_appointments_clinic`;
ALTER TABLE `clients` DROP FOREIGN KEY `fk_clients_clinic`;
ALTER TABLE `clinic_subscriptions` DROP FOREIGN KEY `fk_clinic_subscriptions_clinic`;
ALTER TABLE `clinic_subscriptions` DROP FOREIGN KEY `fk_clinic_subscriptions_plan`;
ALTER TABLE `services` DROP FOREIGN KEY `fk_services_clinic`;
ALTER TABLE `settings` DROP FOREIGN KEY `fk_settings_clinic`;
ALTER TABLE `sms_logs` DROP FOREIGN KEY `fk_sms_logs_clinic`;


-- ----------------------------------------------------------------------------
-- 2. Rename tables
-- ----------------------------------------------------------------------------
RENAME TABLE `clinics` TO `businesses`;
RENAME TABLE `clinic_subscriptions` TO `business_subscriptions`;


-- ----------------------------------------------------------------------------
-- 3. Rename / add columns on `businesses`
-- ----------------------------------------------------------------------------
ALTER TABLE `businesses`
  CHANGE COLUMN `clinic_name` `business_name` VARCHAR(255) NOT NULL,
  ADD COLUMN `business_type` VARCHAR(30) NOT NULL DEFAULT 'generic' AFTER `business_name`;


-- ----------------------------------------------------------------------------
-- 4. Rename `clinic_id` -> `business_id` on every tenant table
--    (nullability/defaults preserved exactly as in the live schema)
-- ----------------------------------------------------------------------------
ALTER TABLE `admins`                 CHANGE COLUMN `clinic_id` `business_id` INT NOT NULL DEFAULT '1';
ALTER TABLE `appointments`           CHANGE COLUMN `clinic_id` `business_id` INT NOT NULL;
ALTER TABLE `clients`                CHANGE COLUMN `clinic_id` `business_id` INT NOT NULL;
ALTER TABLE `services`               CHANGE COLUMN `clinic_id` `business_id` INT NOT NULL;
ALTER TABLE `settings`               CHANGE COLUMN `clinic_id` `business_id` INT NOT NULL;
ALTER TABLE `sms_logs`               CHANGE COLUMN `clinic_id` `business_id` INT NOT NULL;
ALTER TABLE `activity_logs`          CHANGE COLUMN `clinic_id` `business_id` INT DEFAULT NULL;
ALTER TABLE `business_subscriptions` CHANGE COLUMN `clinic_id` `business_id` INT NOT NULL;


-- ----------------------------------------------------------------------------
-- 5. Re-add foreign keys with new names, pointing at the renamed tables
-- ----------------------------------------------------------------------------
ALTER TABLE `admins`
  ADD CONSTRAINT `fk_admins_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE;

ALTER TABLE `appointments`
  ADD CONSTRAINT `fk_appointments_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE;

ALTER TABLE `clients`
  ADD CONSTRAINT `fk_clients_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE;

ALTER TABLE `services`
  ADD CONSTRAINT `fk_services_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE;

ALTER TABLE `settings`
  ADD CONSTRAINT `fk_settings_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE;

ALTER TABLE `sms_logs`
  ADD CONSTRAINT `fk_sms_logs_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE;

ALTER TABLE `business_subscriptions`
  ADD CONSTRAINT `fk_business_subscriptions_business` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_business_subscriptions_plan` FOREIGN KEY (`plan_id`) REFERENCES `subscription_plans` (`id`) ON DELETE RESTRICT;


-- ----------------------------------------------------------------------------
-- 6. Rename indexes (MySQL 8 native RENAME INDEX, no data rewrite)
-- ----------------------------------------------------------------------------
ALTER TABLE `admins`                 RENAME INDEX `idx_admins_clinic` TO `idx_admins_business`;
ALTER TABLE `appointments`           RENAME INDEX `idx_appointments_clinic` TO `idx_appointments_business`;
ALTER TABLE `clients`                RENAME INDEX `idx_clients_clinic` TO `idx_clients_business`;
ALTER TABLE `clients`                RENAME INDEX `unique_clinic_client_phone` TO `unique_business_client_phone`;
ALTER TABLE `businesses`             RENAME INDEX `idx_clinics_slug` TO `idx_business_slug`;
ALTER TABLE `businesses`             RENAME INDEX `idx_clinics_status` TO `idx_business_status`;
ALTER TABLE `services`               RENAME INDEX `idx_services_clinic` TO `idx_services_business`;
ALTER TABLE `settings`               RENAME INDEX `idx_settings_clinic` TO `idx_settings_business`;
ALTER TABLE `settings`               RENAME INDEX `unique_clinic_setting` TO `unique_business_setting`;
ALTER TABLE `sms_logs`               RENAME INDEX `idx_sms_logs_clinic` TO `idx_sms_logs_business`;
ALTER TABLE `business_subscriptions` RENAME INDEX `idx_clinic_subscriptions_clinic` TO `idx_business_subscriptions_business`;


-- ----------------------------------------------------------------------------
-- 7. Data update: admin role value + default
-- ----------------------------------------------------------------------------
UPDATE `admins` SET `role` = 'business_owner' WHERE `role` = 'clinic_owner';
ALTER TABLE `admins` ALTER COLUMN `role` SET DEFAULT 'business_owner';


-- ----------------------------------------------------------------------------
-- 8. Sanity checks -- run these and compare against your pre-patch counts.
-- ----------------------------------------------------------------------------
-- SELECT COUNT(*) FROM businesses;              -- expect 3
-- SELECT COUNT(*) FROM admins;                  -- expect 3
-- SELECT COUNT(*) FROM appointments;             -- expect 5
-- SELECT COUNT(*) FROM clients;                  -- expect 3
-- SELECT COUNT(*) FROM services;                 -- expect 12
-- SELECT COUNT(*) FROM sms_logs;                 -- expect 9
-- SELECT COUNT(*) FROM business_subscriptions;   -- expect 3
-- SHOW TABLES LIKE 'clinic%';                    -- expect empty result set
-- SELECT DISTINCT role FROM admins;              -- expect only 'business_owner' / 'super_admin'
