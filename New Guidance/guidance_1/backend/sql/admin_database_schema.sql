-- Admin Database Schema for PLSP Guidance System
-- This script creates all necessary tables and views for admin functionality

-- First, ensure the main tables exist (from guidance_database_schema.sql)
-- Users table (should already exist)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'student',
    student_id VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    grade_level VARCHAR(20),
    section VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Student info is now combined in users table - no separate students table needed

-- Appointments table (should already exist)
CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    counselor_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    appointment_date TIMESTAMP NOT NULL,
    purpose TEXT NOT NULL,
    course VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Courses table (should already exist)
CREATE TABLE IF NOT EXISTS courses (
    id SERIAL PRIMARY KEY,
    course_code VARCHAR(20) UNIQUE NOT NULL,
    course_name VARCHAR(255) NOT NULL,
    college VARCHAR(100) NOT NULL,
    grade_requirement DECIMAL(5,2),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_appointments_student_id ON appointments(student_id);
CREATE INDEX IF NOT EXISTS idx_appointments_counselor_id ON appointments(counselor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_appointment_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);

-- Admin Analytics Views
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

-- Insert sample data for testing
-- Insert sample admin user
INSERT INTO users (username, email, password, role, first_name, last_name) VALUES
('admin', 'admin@plsp.edu.ph', '\$2b\$10\$hashedpassword', 'admin', 'System', 'Administrator')
ON CONFLICT (username) DO NOTHING;

-- Insert sample counselor
INSERT INTO users (username, email, password, role, first_name, last_name) VALUES
('counselor1', 'counselor@plsp.edu.ph', '\$2b\$10\$hashedpassword', 'counselor', 'Jane', 'Smith')
ON CONFLICT (username) DO NOTHING;

-- Insert sample students
INSERT INTO users (username, email, password, role, student_id, first_name, last_name, grade_level, section) VALUES
('student1', 'student1@plsp.edu.ph', '\$2b\$10\$hashedpassword', 'student', '2021001', 'John', 'Doe', '4th', 'STEM-A'),
('student2', 'student2@plsp.edu.ph', '\$2b\$10\$hashedpassword', 'student', '2021002', 'Jane', 'Smith', '3rd', 'ABM-B'),
('student3', 'student3@plsp.edu.ph', '\$2b\$10\$hashedpassword', 'student', '2021003', 'Bob', 'Johnson', '2nd', 'HUMSS-C'),
('student4', 'student4@plsp.edu.ph', '\$2b\$10\$hashedpassword', 'student', '2021004', 'Alice', 'Williams', '1st', 'GAS-D')
ON CONFLICT (username) DO NOTHING;

-- Sample student data is already inserted into users table above - no separate students table exists

-- Insert sample appointments
INSERT INTO appointments (student_id, counselor_id, appointment_date, purpose, course, status, notes) VALUES
(1, 2, CURRENT_DATE + INTERVAL '1 day', 'Academic Advising', 'BSIT', 'scheduled', 'Discuss course selection'),
(2, 2, CURRENT_DATE + INTERVAL '2 days', 'Career Guidance', 'BSBA', 'scheduled', 'Explore career options'),
(3, 2, CURRENT_DATE - INTERVAL '1 day', 'Personal Counseling', NULL, 'completed', 'Completed session')
ON CONFLICT DO NOTHING;

-- Insert sample courses if not already present
INSERT INTO courses (course_code, course_name, college, grade_requirement, description) VALUES
('BSIT', 'Bachelor of Science in Information Technology', 'COLLEGE OF COMPUTER STUDIES AND TECHNOLOGY', 83.00, 'Grade requirements not lower than 83%'),
('BSBA', 'Bachelor of Science in Business Administration', 'COLLEGE OF BUSINESS AND HOSPITALITY MANAGEMENT', 83.00, 'Grade requirements not lower than 83%'),
('BSHM', 'Bachelor of Science in Hospitality Management', 'COLLEGE OF BUSINESS AND HOSPITALITY MANAGEMENT', 83.00, 'Grade requirements not lower than 83%')
ON CONFLICT (course_code) DO NOTHING;
