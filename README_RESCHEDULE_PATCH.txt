RESCHEDULE PATCH

1. Import sql/reschedule_upgrade.sql.
   If your MySQL says duplicate column, ignore that specific line.

2. Upload:
   admin/reschedule.php
   api/available_slots.php
   includes/reschedule_helpers.php

3. Add this to config/config.php if needed:
   require_once __DIR__ . '/../includes/reschedule_helpers.php';

4. Add a button in appointments list/details:
   <a href="<?= BASE_URL ?>/admin/reschedule.php?id=<?= $row['id'] ?>" class="btn btn-sm btn-warning">Reschedule</a>

5. This patch:
   - lets admin choose a new available slot
   - excludes the current appointment from conflict checking
   - updates service/date/time
   - resets reminders
   - sends SMS + WhatsApp update
