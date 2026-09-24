# SaaS Upgrade Patch

This patch converts the clinic appointment system into a multi-clinic SaaS structure.

## New Features

- Multiple clinics can register from `/register.php`
- Each clinic gets its own booking link: `/public/booking.php?clinic=clinic-slug`
- Each clinic has isolated:
  - Appointments
  - Dashboard
  - Calendar
  - Reports
  - SMS settings
  - WhatsApp settings
  - M-Pesa settings
  - Working days/hours/slot settings
- Subscription plans and clinic subscriptions are now in the database
- Clinic admin login is tied to one clinic workspace

## Existing Install Upgrade

1. Back up your database.
2. Upload/replace files from this ZIP.
3. Run `upgrade_patch_saas.sql` once.
4. Login using your existing admin account.
5. Visit Admin > Settings and confirm clinic-specific settings.
6. Visit Admin > Subscription to view the clinic plan and booking link.

## Fresh Install

1. Create database/import `install.sql`.
2. Edit `config/database.php`.
3. Edit `config/config.php` and set `BASE_URL` correctly.
4. Login:
   - Email: `admin@clinic.local`
   - Password: `admin123`

## New Public Links

- SaaS landing page: `/index.php`
- Register clinic: `/register.php`
- Clinic booking example: `/public/booking.php?clinic=colon-management-clinic`

## Next recommended SaaS upgrades

- Super admin dashboard for platform owner
- Plan switching with M-Pesa STK for subscription payments
- Staff/receptionist accounts per clinic
- Clinic subscription expiry enforcement
- SaaS billing reports
