# SaaS Registration + M-Pesa STK Before Login Patch

## What this patch does

New clinic registration now works like this:

1. Clinic registers.
2. Clinic/admin account is created as Pending Payment.
3. STK Push is sent to the owner phone.
4. User lands on `payment_pending.php`.
5. M-Pesa callback confirms payment.
6. Clinic status becomes Active.
7. Admin status becomes Active.
8. Clinic can now login.

## Files added/updated

- `register.php`
- `payment_pending.php`
- `admin/login.php`
- `api/subscription_mpesa_callback.php`
- `includes/subscription_mpesa.php`
- `config/platform_mpesa.php`
- `subscription_payment_upgrade.sql`

## Installation

1. Upload files into your module folder.
2. Import `subscription_payment_upgrade.sql` once.
3. Edit `config/platform_mpesa.php`.
4. Set your callback URL in Safaricom Daraja to:

```text
https://yourdomain.com/clinic_appointments_module/api/subscription_mpesa_callback.php
```

5. Test registration.

## Important

The platform M-Pesa credentials in `config/platform_mpesa.php` are for YOUR SaaS subscription collections.
Clinic-specific M-Pesa settings remain separate for clinic client payments.
