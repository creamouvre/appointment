-- =========================================================
-- SaaS Registration + STK Push Before Login Upgrade
-- Run this once in phpMyAdmin before using the new register.php
-- =========================================================

-- 1. Allow Pending Payment clinic status
ALTER TABLE clinics
MODIFY status ENUM('Pending Payment','Trial','Active','Suspended','Cancelled') NOT NULL DEFAULT 'Pending Payment';

-- 2. Ensure admins table supports SaaS login blocking
ALTER TABLE admins
ADD COLUMN IF NOT EXISTS clinic_id INT NULL AFTER id,
ADD COLUMN IF NOT EXISTS role VARCHAR(50) NOT NULL DEFAULT 'clinic_owner' AFTER password,
ADD COLUMN IF NOT EXISTS status VARCHAR(50) NOT NULL DEFAULT 'Active' AFTER role;

-- 3. Assign old admin to default clinic
UPDATE admins SET clinic_id = 1 WHERE clinic_id IS NULL;

-- 4. Ensure clinic subscriptions can track M-Pesa STK payment
ALTER TABLE clinic_subscriptions
ADD COLUMN IF NOT EXISTS checkout_request_id VARCHAR(255) NULL,
ADD COLUMN IF NOT EXISTS merchant_request_id VARCHAR(255) NULL,
ADD COLUMN IF NOT EXISTS mpesa_receipt VARCHAR(100) NULL,
ADD COLUMN IF NOT EXISTS payment_phone VARCHAR(30) NULL,
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) NOT NULL DEFAULT 'Pending',
ADD COLUMN IF NOT EXISTS payment_token VARCHAR(100) NULL,
ADD COLUMN IF NOT EXISTS mpesa_response MEDIUMTEXT NULL,
ADD COLUMN IF NOT EXISTS paid_at DATETIME NULL;

-- 5. Make old subscription active if it exists and is already in use
UPDATE clinic_subscriptions
SET payment_status = 'Paid', paid_at = COALESCE(paid_at, NOW())
WHERE clinic_id = 1 AND status = 'Active' AND (payment_status IS NULL OR payment_status = 'Pending');

-- 6. Helpful indexes
CREATE INDEX IF NOT EXISTS idx_clinic_subscriptions_checkout ON clinic_subscriptions(checkout_request_id);
CREATE INDEX IF NOT EXISTS idx_clinic_subscriptions_token ON clinic_subscriptions(payment_token);
CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(email);
CREATE INDEX IF NOT EXISTS idx_admins_clinic ON admins(clinic_id);
