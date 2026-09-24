<?php
require_once __DIR__ . '/config/config.php';

$pageTitle = 'Smart Appointment Booking System';

try {
    $plans = $pdo->query("SELECT * FROM subscription_plans WHERE status='Active' ORDER BY price_monthly ASC")->fetchAll();
} catch (Throwable $e) {
    $plans = [];
}

$demoBookingLink = BASE_URL . '/public/booking.php?business=colon-management-clinic';
$registerLink = BASE_URL . '/register.php';
$loginLink = BASE_URL . '/admin/login.php';
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= htmlspecialchars($pageTitle) ?></title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

    <style>
        :root {
            --deep-red: #810506;
            --deep-red-dark: #5f0304;
            --ash: #f2f3f5;
            --dark: #212529;
            --muted: #6c757d;
        }

        * {
            font-family: Candara, Calibri, "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
        }

        body {
            background: var(--ash);
            color: var(--dark);
            font-weight: 500;
        }

        .hero {
            background:
                radial-gradient(circle at top left, rgba(255,255,255,.18), transparent 30%),
                linear-gradient(135deg, var(--deep-red), var(--deep-red-dark));
            color: #fff;
            padding: 80px 0 120px;
            position: relative;
            overflow: hidden;
        }

        .hero-card {
            background: rgba(255,255,255,.12);
            border: 1px solid rgba(255,255,255,.22);
            backdrop-filter: blur(10px);
            border-radius: 28px;
            padding: 24px;
        }

        .hero h1 {
            font-weight: 900;
            font-size: clamp(2.4rem, 6vw, 4.8rem);
            line-height: .98;
        }

        .hero p {
            font-size: 1.2rem;
            color: rgba(255,255,255,.9);
        }

        .navbar {
            background: var(--deep-red);
        }

        .navbar-brand,
        .nav-link {
            color: #fff !important;
            font-weight: 700;
        }

        .section-lift {
            margin-top: -70px;
            position: relative;
            z-index: 3;
        }

        .card-soft {
            background: #fff;
            border: none;
            border-radius: 24px;
            box-shadow: 0 14px 38px rgba(0,0,0,.08);
        }

        .feature-icon {
            width: 58px;
            height: 58px;
            border-radius: 18px;
            background: rgba(129,5,6,.1);
            color: var(--deep-red);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 28px;
            margin-bottom: 14px;
        }

        .btn-brand {
            background: var(--deep-red);
            border-color: var(--deep-red);
            color: #fff;
            border-radius: 14px;
            font-weight: 800;
            padding: 13px 22px;
        }

        .btn-brand:hover {
            background: var(--deep-red-dark);
            border-color: var(--deep-red-dark);
            color: #fff;
        }

        .btn-light-brand {
            background: #fff;
            color: var(--deep-red);
            border-radius: 14px;
            font-weight: 800;
            padding: 13px 22px;
        }

        .pill {
            background: rgba(129,5,6,.09);
            color: var(--deep-red);
            border-radius: 999px;
            padding: 8px 14px;
            font-weight: 800;
            display: inline-block;
            margin: 4px;
        }

        .audience-card {
            border: 1px solid #eee;
            border-radius: 20px;
            padding: 20px;
            background: #fff;
            height: 100%;
            transition: .2s ease;
        }

        .audience-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 12px 28px rgba(0,0,0,.08);
        }

        .pricing-card {
            border: 2px solid transparent;
        }

        .pricing-card.featured {
            border-color: var(--deep-red);
            transform: scale(1.02);
        }

        .check {
            color: var(--deep-red);
            font-weight: 900;
        }

        .cta-section {
            background: linear-gradient(135deg, var(--deep-red), var(--deep-red-dark));
            color: #fff;
            border-radius: 32px;
            padding: 50px 25px;
        }

        .footer {
            color: #777;
            padding: 35px 0;
        }

        @media(max-width: 768px) {
            .hero {
                padding: 55px 0 100px;
            }

            .pricing-card.featured {
                transform: none;
            }
        }
    </style>
</head>

<body>

<nav class="navbar navbar-expand-lg">
    <div class="container">
        <a class="navbar-brand" href="<?= BASE_URL ?>/">SmartBookings</a>
        <button class="navbar-toggler bg-light" type="button" data-bs-toggle="collapse" data-bs-target="#navMenu">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="navMenu">
            <div class="navbar-nav ms-auto">
                <a class="nav-link" href="#features">Features</a>
                <a class="nav-link" href="#industries">Who It Helps</a>
                <a class="nav-link" href="#pricing">Pricing</a>
                <a class="nav-link" href="<?= htmlspecialchars($loginLink) ?>">Login</a>
            </div>
        </div>
    </div>
</nav>

<section class="hero">
    <div class="container">
        <div class="row align-items-center g-5">
            <div class="col-lg-7">
                <span class="pill bg-white text-dark mb-3">WhatsApp + SMS + M-Pesa + Reports</span>
                <h1>Turn social media visitors into booked clients.</h1>
                <p class="mt-4">
                    A mobile-first appointment system for clinics, salons, therapists, dentists, spas, coaches, and consultants.
                    Clients book online, you confirm availability, send SMS/WhatsApp updates, track payments, and see reports.
                </p>

                <div class="d-flex flex-wrap gap-3 mt-4">
                    <a href="<?= htmlspecialchars($registerLink) ?>" class="btn btn-light-brand btn-lg">
                        Start Your Account
                    </a>

                    <a href="<?= htmlspecialchars($demoBookingLink) ?>" class="btn btn-outline-light btn-lg rounded-4 fw-bold">
                        Try Demo Booking
                    </a>
                </div>
            </div>

            <div class="col-lg-5">
                <div class="hero-card">
                    <h4 class="fw-bold">What your clients see</h4>
                    <div class="bg-white text-dark rounded-4 p-4 mt-3">
                        <label class="form-label fw-bold">Select Service</label>
                        <select class="form-select mb-3">
                            <option>Consultation - KES 1,000</option>
                            <option>Salon Appointment - KES 2,000</option>
                            <option>Therapy Session - KES 3,000</option>
                        </select>

                        <label class="form-label fw-bold">Preferred Date</label>
                        <input type="date" class="form-control mb-3">

                        <label class="form-label fw-bold">Available Time</label>
                        <select class="form-select mb-3">
                            <option>10:00 AM</option>
                            <option>11:30 AM</option>
                            <option>2:00 PM</option>
                        </select>

                        <button class="btn btn-brand w-100">Continue to WhatsApp</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

<section class="section-lift">
    <div class="container">
        <div class="card-soft p-4 p-lg-5">
            <div class="row g-4 text-center">
                <div class="col-md-3">
                    <h3 class="fw-bold text-danger">24/7</h3>
                    <div class="text-muted">Client booking access</div>
                </div>
                <div class="col-md-3">
                    <h3 class="fw-bold text-danger">SMS</h3>
                    <div class="text-muted">Confirmations & reminders</div>
                </div>
                <div class="col-md-3">
                    <h3 class="fw-bold text-danger">M-Pesa</h3>
                    <div class="text-muted">STK payment support</div>
                </div>
                <div class="col-md-3">
                    <h3 class="fw-bold text-danger">Reports</h3>
                    <div class="text-muted">Revenue & conversions</div>
                </div>
            </div>
        </div>
    </div>
</section>

<section id="features" class="py-5">
    <div class="container">
        <div class="text-center mb-5">
            <h2 class="fw-bold">Everything needed to manage appointments</h2>
            <p class="text-muted">Built for real service businesses that receive clients from social media.</p>
        </div>

        <div class="row g-4">
            <?php
            $features = [
                ['📅', 'Smart Booking', 'Clients choose service, date, and available time slots.'],
                ['🚫', 'No Double Booking', 'Slots are blocked based on service duration and availability.'],
                ['💬', 'WhatsApp Flow', 'Clients continue the conversation on WhatsApp after booking.'],
                ['📲', 'SMS Reminders', 'Send confirmation, 24-hour, 2-hour, missed, and feedback messages.'],
                ['💰', 'M-Pesa Tracking', 'Trigger STK push and mark appointments as paid.'],
                ['📊', 'Reports', 'See revenue, conversion, busiest hours, no-shows, and returning clients.'],
                ['👥', 'Client Records', 'Track appointment history, payment history, notes, and repeat visits.'],
                ['🧾', 'Receipts', 'Generate printable receipts and send receipt messages.'],
                ['🏢', 'Multi-Business SaaS', 'Each business gets its own dashboard, link, settings, and reports.'],
            ];
            ?>

            <?php foreach ($features as $f): ?>
                <div class="col-md-6 col-lg-4">
                    <div class="card-soft p-4 h-100">
                        <div class="feature-icon"><?= $f[0] ?></div>
                        <h5 class="fw-bold"><?= htmlspecialchars($f[1]) ?></h5>
                        <p class="text-muted mb-0"><?= htmlspecialchars($f[2]) ?></p>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<section id="industries" class="py-5 bg-white">
    <div class="container">
        <div class="text-center mb-5">
            <h2 class="fw-bold">Perfect for service businesses</h2>
            <p class="text-muted">Not just clinics — any appointment-based business can use it.</p>
        </div>

        <div class="row g-4">
            <?php
            $industries = [
                ['🏥', 'Clinics', 'Manage consultations, follow-ups, payments, and reminders.'],
                ['💇', 'Salons', 'Let clients book hair, nails, beauty, and spa services.'],
                ['🧘', 'Therapists', 'Schedule sessions, reminders, and payment tracking.'],
                ['🦷', 'Dentists', 'Book dental reviews, procedures, and follow-ups.'],
                ['🧖', 'Spas', 'Manage packages, duration-based bookings, and receipts.'],
                ['🎯', 'Coaches', 'Book discovery calls, paid sessions, and follow-ups.'],
                ['👔', 'Consultants', 'Track enquiries, appointments, payments, and clients.'],
                ['❤️', 'Wellness Centers', 'Run packages, repeat visits, and client records.'],
            ];
            ?>

            <?php foreach ($industries as $i): ?>
                <div class="col-md-6 col-lg-3">
                    <div class="audience-card">
                        <div class="fs-2"><?= $i[0] ?></div>
                        <h5 class="fw-bold mt-2"><?= htmlspecialchars($i[1]) ?></h5>
                        <p class="text-muted small mb-0"><?= htmlspecialchars($i[2]) ?></p>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<section id="pricing" class="py-5">
    <div class="container">
        <div class="text-center mb-5">
            <h2 class="fw-bold">Simple monthly plans</h2>
            <p class="text-muted">Start small and upgrade as bookings grow.</p>
        </div>

        <div class="row g-4 justify-content-center">
            <?php if ($plans): ?>
                <?php foreach ($plans as $index => $plan): ?>
                    <div class="col-md-4">
                        <div class="card-soft pricing-card <?= $index == 1 ? 'featured' : '' ?> p-4 h-100">
                            <?php if ($index == 1): ?>
                                <span class="pill mb-3">Popular</span>
                            <?php endif; ?>

                            <h4 class="fw-bold"><?= htmlspecialchars($plan['name']) ?></h4>
                            <h2 class="fw-bold my-3">KES <?= number_format((float)$plan['price_monthly']) ?><span class="fs-6 text-muted">/month</span></h2>

                            <p><span class="check">✓</span> Booking link</p>
                            <p><span class="check">✓</span> Dashboard & calendar</p>
                            <p><span class="check">✓</span> SMS/WhatsApp support</p>
                            <p><span class="check">✓</span> Reports & clients</p>

                            <a href="<?= htmlspecialchars($registerLink) ?>" class="btn btn-brand w-100 mt-3">
                                Choose Plan
                            </a>
                        </div>
                    </div>
                <?php endforeach; ?>
            <?php else: ?>
                <div class="col-lg-6">
                    <div class="alert alert-warning">No pricing plans found.</div>
                </div>
            <?php endif; ?>
        </div>
    </div>
</section>

<section class="py-5">
    <div class="container">
        <div class="cta-section text-center">
            <h2 class="fw-bold">Ready to receive bookings from social media?</h2>
            <p class="mb-4">Create your booking link, share it with clients, and manage everything from your phone.</p>
            <a href="<?= htmlspecialchars($registerLink) ?>" class="btn btn-light-brand btn-lg">
                Create Your Account
            </a>
        </div>
    </div>
</section>

<footer class="footer text-center">
    <div class="container">
        <div class="fw-bold">SmartBookings</div>
        <div>Appointment booking for clinics, salons, therapists, consultants, dentists, spas, and coaches.</div>
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>
