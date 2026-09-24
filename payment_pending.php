<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/includes/subscription_mpesa.php';

$pageTitle = 'Payment Pending';
$token = trim($_GET['token'] ?? $_POST['token'] ?? '');

if (!$token) {
    flash('error', 'Missing payment token. Please register again or contact support.');
    redirect(BASE_URL . '/register.php');
}

$stmt = $pdo->prepare("SELECT bs.*, b.business_name, b.email, b.phone, sp.name AS plan_name
    FROM business_subscriptions bs
    JOIN businesses b ON b.id = bs.business_id
    LEFT JOIN subscription_plans sp ON sp.id = bs.plan_id
    WHERE bs.payment_token=? LIMIT 1");
$stmt->execute([$token]);
$sub = $stmt->fetch();

if (!$sub) {
    flash('error', 'Payment record not found. Please contact support.');
    redirect(BASE_URL . '/register.php');
}

if (is_post() && ($_POST['action'] ?? '') === 'resend_stk') {
    verify_csrf();
    if (($sub['payment_status'] ?? '') === 'Paid') {
        redirect(BASE_URL . '/admin/login.php');
    }

    $stk = trigger_subscription_stk_push((int)$sub['business_id'], (int)$sub['id'], $sub['payment_phone'] ?: $sub['phone'], (float)$sub['amount']);
    flash($stk['success'] ? 'success' : 'error', $stk['message']);
    redirect(BASE_URL . '/payment_pending.php?token=' . urlencode($token));
}

include __DIR__ . '/includes/header.php';
?>
<div class="container py-5">
  <div class="row justify-content-center">
    <div class="col-lg-7">
      <div class="card mobile-card">
        <div class="card-body p-4 p-lg-5 text-center">
          <h1 class="h3 fw-bold mb-2">Complete M-Pesa Payment</h1>
          <p class="text-muted">Your business account will be activated automatically once M-Pesa confirms payment.</p>

          <?php if ($msg = flash('success')): ?><div class="alert alert-success"><?= e($msg) ?></div><?php endif; ?>
          <?php if ($msg = flash('error')): ?><div class="alert alert-danger"><?= e($msg) ?></div><?php endif; ?>

          <div class="border rounded p-3 mb-3 text-start">
            <div><strong>Business:</strong> <?= e($sub['business_name']) ?></div>
            <div><strong>Plan:</strong> <?= e($sub['plan_name'] ?? 'Subscription') ?></div>
            <div><strong>Amount:</strong> KES <?= e(number_format((float)$sub['amount'], 2)) ?></div>
            <div><strong>Phone:</strong> <?= e($sub['payment_phone'] ?: $sub['phone']) ?></div>
            <div><strong>Status:</strong> <?= e($sub['payment_status']) ?></div>
          </div>

          <?php if (($sub['payment_status'] ?? '') === 'Paid'): ?>
            <div class="alert alert-success">Payment received. Your account is active.</div>
            <a href="<?= e(BASE_URL . '/admin/login.php') ?>" class="btn btn-success btn-lg w-100">Go to Login</a>
          <?php else: ?>
            <div class="alert alert-warning">
              Check your phone and enter your M-Pesa PIN. After payment, refresh this page.
            </div>

            <form method="post" class="d-grid gap-2">
              <input type="hidden" name="csrf_token" value="<?= e(csrf_token()) ?>">
              <input type="hidden" name="token" value="<?= e($token) ?>">
              <input type="hidden" name="action" value="resend_stk">
              <button class="btn btn-primary btn-lg">Resend STK Push</button>
              <a href="<?= e(BASE_URL . '/payment_pending.php?token=' . urlencode($token)) ?>" class="btn btn-outline-dark">Refresh Payment Status</a>
            </form>
          <?php endif; ?>
        </div>
      </div>
    </div>
  </div>
</div>
<?php include __DIR__ . '/includes/footer.php'; ?>
