# Clinic Appointments Module

## Upgrade patch features
- Auto WhatsApp + SMS on confirmation
- Optional scheduled confirmation SMS
- M-Pesa STK push trigger from appointment management
- Automatic mark as Paid from callback
- Reminder cron for 24h and 2h before appointment
- Extended reports: revenue, conversion, peak times, top clients

## Upgrade steps
1. Replace your module files with this patch.
2. Import `upgrade_patch.sql` into your existing database once.
3. Go to Admin > Settings and fill SMS, WhatsApp, and M-Pesa credentials.
4. Set M-Pesa callback URL to `YOUR_DOMAIN/clinic_appointments_module/api/mpesa_callback.php` if you prefer to override the default.
5. Add a cron job for reminders, for example every 10 minutes:
   `php /path/to/clinic_appointments_module/cron/send_reminders.php`

## Notes
- Confirmation notifications are sent when status changes to Confirmed.
- If you set a future datetime in the confirmation SMS field, the module schedules the SMS instead of sending instantly.
- STK push is only attempted when the appointment is Confirmed and payment amount is greater than 0.


Patch v3 additions:
- Auto slot generation from working days, working hours, and slot minutes
- Public endpoint to load free slots dynamically
- Double-booking prevention during booking submit
- New landing/demo pager at the module root
- Settings page now includes working days and slot controls
