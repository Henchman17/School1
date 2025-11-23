-- Create users table with sample data
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'student',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    student_id VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    status VARCHAR(50),
    program VARCHAR(255),
    admission_number VARCHAR(50)
);

-- Insert sample users (passwords are hashed with bcrypt)
-- Password for all users: admin123 (hashed)
INSERT INTO users (username, email, password, role, student_id, first_name, last_name, status, program, admission_number) VALUES
('admin', 'admin@plsp.edu.ph', '$2a$10$1T1oiAMDrMHFrKvnKoJQke8Y4lXewMBaO.EDpo8BW8MvqdCGpvzDS', 'admin', NULL, 'Admin', 'User', 'active', NULL, NULL),
('counselor1', 'counselor@plsp.edu.ph', '$2a$10$1T1oiAMDrMHFrKvnKoJQke8Y4lXewMBaO.EDpo8BW8MvqdCGpvzDS', 'counselor', NULL, 'Guidance', 'Counselor', 'active', NULL, NULL),
('student1', 'student1@plsp.edu.ph', '$2a$10$1T1oiAMDrMHFrKvnKoJQke8Y4lXewMBaO.EDpo8BW8MvqdCGpvzDS', 'student', '2021001', 'Juan', 'Dela Cruz', 'Currently Enrolled', 'Bachelor of Science in Information Technology', 'ADM2021001'),
('student2', 'student2@plsp.edu.ph', '$2a$10$1T1oiAMDrMHFrKvnKoJQke8Y4lXewMBaO.EDpo8BW8MvqdCGpvzDS', 'student', '2021002', 'Maria', 'Santos', 'Currently Enrolled', 'Bachelor of Science in Psychology', 'ADM2021002')
ON CONFLICT (username) DO NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_student_id ON users(student_id) WHERE student_id IS NOT NULL;
