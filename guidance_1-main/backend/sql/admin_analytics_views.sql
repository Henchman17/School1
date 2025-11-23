-- Admin Analytics Views
-- Database views for admin dashboard analytics and reporting

-- User Statistics View
CREATE OR REPLACE VIEW user_statistics AS
SELECT
    COUNT(*) as total_users,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
    COUNT(CASE WHEN role = 'counselor' THEN 1 END) as counselor_count,
    COUNT(CASE WHEN role = 'student' THEN 1 END) as student_count,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as new_users_30_days,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as new_users_7_days
FROM users;

-- Appointment Statistics View
CREATE OR REPLACE VIEW appointment_statistics AS
SELECT
    COUNT(*) as total_appointments,
    COUNT(CASE WHEN status = 'scheduled' THEN 1 END) as scheduled_count,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_count,
    COUNT(CASE WHEN appointment_date >= CURRENT_DATE THEN 1 END) as upcoming_count,
    COUNT(CASE WHEN appointment_date < CURRENT_DATE AND status = 'scheduled' THEN 1 END) as overdue_count,
    AVG(EXTRACT(EPOCH FROM (appointment_date - created_at))/86400) as avg_days_to_appointment,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as appointments_30_days
FROM appointments;

-- Counselor Workload View
CREATE OR REPLACE VIEW counselor_workload AS
SELECT
    u.id as counselor_id,
    u.username as counselor_name,
    u.email as counselor_email,
    COUNT(a.id) as total_appointments,
    COUNT(CASE WHEN a.status = 'scheduled' THEN 1 END) as scheduled_appointments,
    COUNT(CASE WHEN a.status = 'completed' THEN 1 END) as completed_appointments,
    COUNT(CASE WHEN a.appointment_date >= CURRENT_DATE THEN 1 END) as upcoming_appointments,
    COUNT(CASE WHEN a.appointment_date < CURRENT_DATE AND a.status = 'scheduled' THEN 1 END) as overdue_appointments
FROM users u
LEFT JOIN appointments a ON u.id = a.counselor_id
WHERE u.role = 'counselor'
GROUP BY u.id, u.username, u.email;

-- Student Activity View
CREATE OR REPLACE VIEW student_activity AS
SELECT
    u.id as student_id,
    u.username as student_name,
    u.email as student_email,
    u.student_id as student_number,
    u.grade_level,
    u.section,
    COUNT(a.id) as total_appointments,
    COUNT(CASE WHEN a.status = 'completed' THEN 1 END) as completed_appointments,
    COUNT(CASE WHEN a.status = 'scheduled' THEN 1 END) as scheduled_appointments,
    MAX(a.appointment_date) as last_appointment_date,
    COUNT(CASE WHEN a.created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_appointments
FROM users u
LEFT JOIN appointments a ON u.id = a.student_id
WHERE u.role = 'student'
GROUP BY u.id, u.username, u.email, u.student_id, u.grade_level, u.section;

-- Daily Appointment Summary View (for charts)
CREATE OR REPLACE VIEW daily_appointment_summary AS
SELECT
    DATE(appointment_date) as appointment_day,
    COUNT(*) as total_appointments,
    COUNT(CASE WHEN status = 'scheduled' THEN 1 END) as scheduled,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled
FROM appointments
WHERE appointment_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(appointment_date)
ORDER BY appointment_day DESC;

-- Monthly User Registration Summary
CREATE OR REPLACE VIEW monthly_user_registrations AS
SELECT
    DATE_TRUNC('month', created_at) as registration_month,
    COUNT(*) as total_registrations,
    COUNT(CASE WHEN role = 'student' THEN 1 END) as student_registrations,
    COUNT(CASE WHEN role = 'counselor' THEN 1 END) as counselor_registrations,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_registrations
FROM users
WHERE created_at >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY registration_month DESC;

-- Appointment Purpose Distribution
CREATE OR REPLACE VIEW appointment_purpose_distribution AS
SELECT
    COALESCE(NULLIF(purpose, ''), 'No Purpose Specified') as purpose_category,
    COUNT(*) as appointment_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM appointments
GROUP BY COALESCE(NULLIF(purpose, ''), 'No Purpose Specified')
ORDER BY appointment_count DESC;
