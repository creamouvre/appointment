<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/includes/subscription_mpesa.php';

$pageTitle = 'Register Business';

try {
    $plans = $pdo->query("SELECT * FROM subscription_plans WHERE status='Active' ORDER BY price_monthly ASC")->fetchAll();
} catch (Throwable $e) {
    die('Subscription plans table error: ' . $e->getMessage());
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    if (
        !isset($_POST['csrf_token']) ||
        !isset($_SESSION['csrf_token']) ||
        !hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'])
    ) {
        die('Invalid CSRF token.');
    }

    $businessName = trim($_POST['business_name'] ?? '');
    $ownerName  = trim($_POST['owner_name'] ?? '');
    $email      = trim($_POST['email'] ?? '');
    $phone      = normalize_ke_phone(trim($_POST['phone'] ?? ''));
    $password   = $_POST['password'] ?? '';
    $planId     = (int)($_POST['plan_id'] ?? 0);
    $businessType = trim($_POST['business_type'] ?? 'generic') ?: 'generic';

    if (!$businessName || !$ownerName || !$email || !$phone || strlen($password) < 6 || !$planId) {
        flash('error', 'Please fill all fields. Password should be at least 6 characters.');
        redirect(BASE_URL . '/register.php');
    }

    $existing = $pdo->prepare("SELECT id FROM admins WHERE email=? LIMIT 1");
    $existing->execute([$email]);

    if ($existing->fetch()) {
        flash('error', 'That email is already registered. Please login or use another email.');
        redirect(BASE_URL . '/register.php');
    }

    $planStmt = $pdo->prepare("SELECT * FROM subscription_plans WHERE id=? AND status='Active' LIMIT 1");
    $planStmt->execute([$planId]);
    $plan = $planStmt->fetch();

    if (!$plan) {
        flash('error', 'Please select a valid subscription plan.');
        redirect(BASE_URL . '/register.php');
    }

    $amount = (float)$plan['price_monthly'];

    if ($amount <= 0) {
        flash('error', 'Selected plan amount is invalid.');
        redirect(BASE_URL . '/register.php');
    }

    $slugBase = slugify($businessName);
    $slug = $slugBase;
    $i = 2;

    while (get_business_by_slug($slug)) {
        $slug = $slugBase . '-' . $i;
        $i++;
    }

    try {
        $pdo->beginTransaction();

        $businessStmt = $pdo->prepare("
            INSERT INTO businesses
            (
                business_name,
                business_type,
                slug,
                owner_name,
                email,
                phone,
                whatsapp_number,
                status,
                plan_id,
                subscription_status,
                created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, 'Pending Payment', ?, 'Pending Payment', NOW())
        ");

        $businessStmt->execute([
            $businessName,
            $businessType,
            $slug,
            $ownerName,
            $email,
            $phone,
            $phone,
            $planId
        ]);

        $businessId = (int)$pdo->lastInsertId();

        $adminStmt = $pdo->prepare("
            INSERT INTO admins
            (
                business_id,
                name,
                email,
                password,
                role,
                status,
                created_at
            )
            VALUES (?, ?, ?, ?, 'business_owner', 'Pending', NOW())
        ");

        $adminStmt->execute([
            $businessId,
            $ownerName,
            $email,
            password_hash($password, PASSWORD_DEFAULT)
        ]);

        $paymentToken = bin2hex(random_bytes(24));

        $subStmt = $pdo->prepare("
            INSERT INTO business_subscriptions
            (
                business_id,
                plan_id,
                status,
                amount,
                starts_at,
                ends_at,
                payment_status,
                payment_phone,
                payment_token,
                created_at
            )
            VALUES
            (
                ?,
                ?,
                'Pending Payment',
                ?,
                CURDATE(),
                DATE_ADD(CURDATE(), INTERVAL 1 MONTH),
                'Pending',
                ?,
                ?,
                NOW()
            )
        ");

        $subStmt->execute([
            $businessId,
            $planId,
            $amount,
            $phone,
            $paymentToken
        ]);

        $subscriptionId = (int)$pdo->lastInsertId();

        $defaults = [
            'site_name' => $businessName,
            'whatsapp_number' => $phone,
            'currency' => 'KES',
            'sms_provider' => 'textsms',
            'sms_username' => '',
            'sms_api_key' => '',
            'sms_sender_id' => '',
            'working_days' => 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday',
            'working_hours_start' => '08:00',
            'working_hours_end' => '17:00',
            'slot_minutes' => '30',
            'whatsapp_provider' => 'none',
            'whatsapp_access_token' => '',
            'whatsapp_phone_number_id' => '',
            'whatsapp_graph_version' => 'v23.0',
            'mpesa_enabled' => '0',
            'mpesa_environment' => 'sandbox',
            'mpesa_consumer_key' => '',
            'mpesa_consumer_secret' => '',
            'mpesa_shortcode' => '',
            'mpesa_passkey' => '',
            'mpesa_callback_url' => '',
            'cron_key' => bin2hex(random_bytes(12)),
            'default_payment_policy' => 'none',
            'default_deposit_type' => 'percent',
            'default_deposit_value' => '0',
            'escrow_enabled' => '0',
            'escrow_commission_percent' => '0',
            'escrow_commission_fixed' => '0',
            'escrow_cancellation_fee_percent' => '0',
            'escrow_cancellation_fee_fixed' => '0',
            'escrow_payout_number' => '',
        ];

        $set = $pdo->prepare("
            INSERT INTO settings (business_id, setting_key, setting_value)
            VALUES (?, ?, ?)
        ");

        foreach ($defaults as $key => $value) {
            $set->execute([$businessId, $key, $value]);
        }

        $categoryStmt = $pdo->prepare("
            INSERT INTO service_categories (business_id, name, slug, sort_order, status, created_at)
            VALUES (?, 'General', 'general', 0, 'Active', NOW())
        ");
        $categoryStmt->execute([$businessId]);
        $defaultCategoryId = (int)$pdo->lastInsertId();

        $serviceStmt = $pdo->prepare("
            INSERT INTO services
            (
                business_id,
                category_id,
                service_name,
                price,
                duration_minutes,
                slot_minutes,
                description,
                status,
                created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, 'Active', NOW())
        ");

        $defaultServices = [
            ['Consultation', 1000.00, 30, 30, 'General consultation appointment.'],
            ['Follow-up', 500.00, 30, 30, 'Follow-up review appointment.'],
        ];

        foreach ($defaultServices as $service) {
            $serviceStmt->execute([
                $businessId,
                $defaultCategoryId,
                $service[0],
                $service[1],
                $service[2],
                $service[3],
                $service[4]
            ]);
        }

        $pdo->commit();

        $stk = trigger_subscription_stk_push($businessId, $subscriptionId, $phone, $amount);

        if ($stk['success']) {
            flash('success', $stk['message']);
        } else {
            flash('error', 'Account created, but STK Push failed: ' . $stk['message']);
        }

        redirect(BASE_URL . '/payment_pending.php?token=' . urlencode($paymentToken));

    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        flash('error', 'Registration failed: ' . $e->getMessage());
        redirect(BASE_URL . '/register.php');
    }
}

if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

include __DIR__ . '/includes/header.php';
?>

<div class="container py-5">
    <div class="row justify-content-center">
        <div class="col-lg-8">

            <div class="card mobile-card">
                <div class="card-body p-4 p-lg-5">

                    <h1 class="h3 fw-bold">Register a Business</h1>
                    <p class="text-muted">
                        Create your business workspace to manage bookings, services, payments, and clients online. Payment is required before login is activated.
                    </p>

                    <?php if ($msg = flash('error')): ?>
                        <div class="alert alert-danger"><?= e($msg) ?></div>
                    <?php endif; ?>

                    <?php if ($msg = flash('success')): ?>
                        <div class="alert alert-success"><?= e($msg) ?></div>
                    <?php endif; ?>

                    <?php if (!$plans): ?>
                        <div class="alert alert-warning">
                            No active subscription plans found. Please add plans in the database.
                        </div>
                    <?php else: ?>

                    <form method="post" class="row g-3">
                        <input type="hidden" name="csrf_token" value="<?= e($_SESSION['csrf_token']) ?>">

                        <div class="col-md-6">
                            <label class="form-label">Business Name</label>
                            <input name="business_name" class="form-control" required placeholder="Enter your business name">
                        </div>

                        <div class="col-md-6">
                            <label class="form-label">Business Type</label>
                            <select name="business_type" class="form-select">
                                <option value="generic">Other / General</option>
                                <option value="salon">Salon</option>
                                <option value="spa">Spa</option>
                                <option value="clinic">Clinic</option>
                                <option value="dentist">Dentist</option>
                                <option value="therapist">Therapist</option>
                                <option value="gym">Gym / Fitness</option>
                                <option value="coach">Coach / Consultant</option>
                                <option value="photographer">Photographer</option>
                                <option value="tutor">Tutor / Trainer</option>
                            </select>
                        </div>

                        <div class="col-md-6">
                            <label class="form-label">Owner Name</label>
                            <input name="owner_name" class="form-control" required placeholder="Your name">
                        </div>

                        <div class="col-md-6">
                            <label class="form-label">Email / Login</label>
                            <input type="email" name="email" class="form-control" required placeholder="owner@example.com">
                        </div>

                        <div class="col-md-6">
                            <label class="form-label">M-Pesa Phone Number</label>
                            <input name="phone" class="form-control" placeholder="0712345678" required>
                            <div class="form-text">STK Push will be sent to this number.</div>
                        </div>

                        <div class="col-md-6">
                            <label class="form-label">Password</label>
                            <input type="password" name="password" class="form-control" minlength="6" required>
                        </div>

                        <div class="col-md-6">
                            <label class="form-label">Subscription Plan</label>
                            <select name="plan_id" class="form-select" required>
                                <option value="">Choose plan</option>
                                <?php foreach ($plans as $plan): ?>
                                    <option value="<?= e((string)$plan['id']) ?>">
                                        <?= e($plan['name']) ?> - KES <?= e(number_format((float)$plan['price_monthly'])) ?>/month
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="col-12 d-grid">
                            <button class="btn btn-success btn-lg">
                                Create Account & Pay by M-Pesa
                            </button>
                        </div>

                        <div class="col-12 text-center small text-muted">
                            After successful payment, your account will be activated automatically.
                        </div>
                    </form>

                    <?php endif; ?>

                </div>
            </div>

        </div>
    </div>
</div>

<?php include __DIR__ . '/includes/footer.php'; ?>