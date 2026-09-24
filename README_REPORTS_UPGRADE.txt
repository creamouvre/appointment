REPORTS UPGRADE PATCH

Replace admin/reports.php with this file.

Adds:
- Revenue by service
- Revenue by month
- No-show rate
- Enquiry-to-paid conversion
- Busiest days
- Busiest hours
- Returning clients
- Filters by date, status, payment status, and service

Requirements:
- appointments.status may include 'Missed'
- appointments.service_name, service_id, payment_amount, payment_status exist
- clients table exists
- Chart.js included in footer/header
