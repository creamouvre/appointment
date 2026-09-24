RECEIPT / INVOICE PATCH

1. Import sql/receipt_invoice_upgrade.sql
2. Upload:
   includes/receipt_helpers.php
   admin/receipt.php
   admin/send_receipt.php
3. Add this to config/config.php if needed:
   require_once __DIR__ . '/../includes/receipt_helpers.php';
4. Add a Receipt button in appointment list/edit page:
   <a href="<?= BASE_URL ?>/admin/receipt.php?id=<?= $row['id'] ?>" class="btn btn-sm btn-outline-primary">Receipt</a>
