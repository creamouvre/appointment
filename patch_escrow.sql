-- ============================================================================
-- patch_escrow.sql
--
-- Adds platform escrow for booking payments: the platform collects the
-- client's payment first, automatically retains a commission (+ a
-- cancellation fee if the booking is cancelled after payment), and a
-- super_admin manually settles the remaining payout/refund via
-- admin/payouts.php (no automatic B2C transfer -- see README notes in the
-- implementation plan for why).
--
-- Opt-in per business via settings.escrow_enabled (defaults '0' / off).
-- Existing businesses keep their current direct-to-shortcode flow untouched
-- until a super_admin turns escrow on for them.
--
-- Non-destructive: no DROP TABLE, no DROP COLUMN, no data loss.
-- >>> Back up `creamouvre_app` before running. <<<
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. bookings: escrow lifecycle + payout columns
-- ----------------------------------------------------------------------------
ALTER TABLE `bookings`
  ADD COLUMN `escrow_status` ENUM('None','Held','Released','Cancelled_Pending_Refund','Refunded') NOT NULL DEFAULT 'None' AFTER `mpesa_response`,
  ADD COLUMN `commission_amount` DECIMAL(10,2) NOT NULL DEFAULT '0.00' AFTER `escrow_status`,
  ADD COLUMN `cancellation_fee_amount` DECIMAL(10,2) NOT NULL DEFAULT '0.00' AFTER `commission_amount`,
  ADD COLUMN `retained_amount` DECIMAL(10,2) NOT NULL DEFAULT '0.00' AFTER `cancellation_fee_amount`,
  ADD COLUMN `payout_amount` DECIMAL(10,2) NOT NULL DEFAULT '0.00' AFTER `retained_amount`,
  ADD COLUMN `refund_amount` DECIMAL(10,2) NOT NULL DEFAULT '0.00' AFTER `payout_amount`,
  ADD COLUMN `payout_status` ENUM('Pending','Paid') NOT NULL DEFAULT 'Pending' AFTER `refund_amount`,
  ADD COLUMN `payout_reference` VARCHAR(150) DEFAULT NULL AFTER `payout_status`,
  ADD COLUMN `payout_date` DATETIME DEFAULT NULL AFTER `payout_reference`,
  ADD KEY `idx_bookings_escrow_payout` (`payout_status`, `escrow_status`);


-- ----------------------------------------------------------------------------
-- 2. settings: per-business escrow configuration, backfilled for every
--    existing business. escrow_enabled stays '0' (opt-in) until a
--    super_admin flips it in admin/settings.php.
-- ----------------------------------------------------------------------------
INSERT INTO `settings` (`business_id`, `setting_key`, `setting_value`)
SELECT `id`, 'escrow_enabled', '0' FROM `businesses`
ON DUPLICATE KEY UPDATE `setting_value` = `setting_value`;

INSERT INTO `settings` (`business_id`, `setting_key`, `setting_value`)
SELECT `id`, 'escrow_commission_percent', '0' FROM `businesses`
ON DUPLICATE KEY UPDATE `setting_value` = `setting_value`;

INSERT INTO `settings` (`business_id`, `setting_key`, `setting_value`)
SELECT `id`, 'escrow_commission_fixed', '0' FROM `businesses`
ON DUPLICATE KEY UPDATE `setting_value` = `setting_value`;

INSERT INTO `settings` (`business_id`, `setting_key`, `setting_value`)
SELECT `id`, 'escrow_cancellation_fee_percent', '0' FROM `businesses`
ON DUPLICATE KEY UPDATE `setting_value` = `setting_value`;

INSERT INTO `settings` (`business_id`, `setting_key`, `setting_value`)
SELECT `id`, 'escrow_cancellation_fee_fixed', '0' FROM `businesses`
ON DUPLICATE KEY UPDATE `setting_value` = `setting_value`;

INSERT INTO `settings` (`business_id`, `setting_key`, `setting_value`)
SELECT `id`, 'escrow_payout_number', '' FROM `businesses`
ON DUPLICATE KEY UPDATE `setting_value` = `setting_value`;


-- ----------------------------------------------------------------------------
-- 3. Sanity checks
-- ----------------------------------------------------------------------------
-- SHOW COLUMNS FROM bookings LIKE 'escrow%';
-- SHOW COLUMNS FROM bookings LIKE 'payout%';
-- SELECT setting_key, COUNT(*) FROM settings WHERE setting_key LIKE 'escrow_%' GROUP BY setting_key;
