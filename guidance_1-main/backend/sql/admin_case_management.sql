-- Admin Case Management Tables for PLSP Guidance System
-- This script creates tables for re-admission, discipline, and exit interview cases

-- Re-admission Cases Table
CREATE TABLE IF NOT EXISTS re_admission_cases (
    id SERIAL PRIMARY KEY,
    student_name VARCHAR(255) NOT NULL,
    student_number VARCHAR(50),
    reason_of_absence TEXT NOT NULL,
    notes TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, under_review
    counselor_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMP,
    reviewed_by INTEGER REFERENCES users(id)
);

-- Discipline Cases Table
CREATE TABLE IF NOT EXISTS discipline_cases (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_name VARCHAR(255) NOT NULL,
    student_number VARCHAR(50),
    incident_date DATE NOT NULL,
    incident_description TEXT NOT NULL,
    incident_location VARCHAR(255),
    witnesses TEXT,
    action_taken TEXT,
    severity VARCHAR(50) NOT NULL DEFAULT 'minor', -- minor, moderate, major, severe
    status VARCHAR(50) NOT NULL DEFAULT 'open', -- open, under_investigation, resolved, closed
    admin_notes TEXT,
    counselor_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES users(id)
);

-- Exit Interviews Table (for both graduating and transferring students)
CREATE TABLE IF NOT EXISTS exit_interviews (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_name VARCHAR(255) NOT NULL,
    student_number VARCHAR(50),
    interview_type VARCHAR(50) NOT NULL, -- graduating, transferring
    interview_date DATE NOT NULL,
    reason_for_leaving TEXT NOT NULL,
    satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
    academic_experience TEXT,
    support_services_experience TEXT,
    facilities_experience TEXT,
    overall_improvements TEXT,
    future_plans TEXT,
    contact_info VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled', -- scheduled, completed, cancelled
    admin_notes TEXT,
    counselor_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Good Moral Requests Table
CREATE TABLE IF NOT EXISTS good_moral_requests (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_name VARCHAR(255) NOT NULL,
    student_number VARCHAR(50),
    course VARCHAR(255),
    year_level VARCHAR(50),
    purpose TEXT,
    ocr_data JSONB NOT NULL, -- Store extracted OCR data as JSON
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, processing
    admin_notes TEXT,
    counselor_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMP,
    reviewed_by INTEGER REFERENCES users(id),
    document_path TEXT -- Path to generated Word document
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_status ON re_admission_cases(status);
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_created_at ON re_admission_cases(created_at);

CREATE INDEX IF NOT EXISTS idx_discipline_cases_student_id ON discipline_cases(student_id);
CREATE INDEX IF NOT EXISTS idx_discipline_cases_status ON discipline_cases(status);
CREATE INDEX IF NOT EXISTS idx_discipline_cases_severity ON discipline_cases(severity);
CREATE INDEX IF NOT EXISTS idx_discipline_cases_incident_date ON discipline_cases(incident_date);

CREATE INDEX IF NOT EXISTS idx_exit_interviews_student_id ON exit_interviews(student_id);
CREATE INDEX IF NOT EXISTS idx_exit_interviews_type ON exit_interviews(interview_type);
CREATE INDEX IF NOT EXISTS idx_exit_interviews_status ON exit_interviews(status);
CREATE INDEX IF NOT EXISTS idx_exit_interviews_date ON exit_interviews(interview_date);

CREATE INDEX IF NOT EXISTS idx_good_moral_requests_student_id ON good_moral_requests(student_id);
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_status ON good_moral_requests(status);
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_created_at ON good_moral_requests(created_at);

-- Views for admin dashboard
CREATE OR REPLACE VIEW admin_case_summary AS
SELECT
    're_admission' as case_type,
    COUNT(*) as total_cases,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_cases,
    COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_cases,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_cases,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_cases
FROM re_admission_cases
UNION ALL
SELECT
    'discipline' as case_type,
    COUNT(*) as total_cases,
    COUNT(CASE WHEN status = 'open' THEN 1 END) as pending_cases,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as approved_cases,
    COUNT(CASE WHEN status = 'closed' THEN 1 END) as rejected_cases,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_cases
FROM discipline_cases
UNION ALL
SELECT
    'exit_interview' as case_type,
    COUNT(*) as total_cases,
    COUNT(CASE WHEN status = 'scheduled' THEN 1 END) as pending_cases,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as approved_cases,
    0 as rejected_cases,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_cases
FROM exit_interviews;

-- Insert sample data for testing
INSERT INTO re_admission_cases (student_name, student_number, reason_of_absence, notes, status) VALUES
('John Doe', '2021001', 'Financial difficulties', 'Resolved financial issues', 'pending'),
('Jane Smith', '2021002', 'Health issues', 'Health improved', 'approved')
ON CONFLICT DO NOTHING;

INSERT INTO discipline_cases (student_id, student_name, student_number, incident_date, incident_description, severity, status) VALUES
(3, 'Bob Johnson', '2021003', CURRENT_DATE - INTERVAL '5 days', 'Disruptive behavior in class', 'minor', 'under_investigation'),
(4, 'Alice Williams', '2021004', CURRENT_DATE - INTERVAL '10 days', 'Academic dishonesty', 'moderate', 'resolved')
ON CONFLICT DO NOTHING;

INSERT INTO exit_interviews (student_id, student_name, student_number, interview_type, interview_date, reason_for_leaving, satisfaction_rating, status) VALUES
(1, 'John Doe', '2021001', 'graduating', CURRENT_DATE + INTERVAL '7 days', 'Completed degree requirements', 4, 'scheduled'),
(2, 'Jane Smith', '2021002', 'transferring', CURRENT_DATE + INTERVAL '3 days', 'Transferring to another university', 3, 'scheduled')
ON CONFLICT DO NOTHING;

INSERT INTO good_moral_requests (student_id, student_name, student_number, course, year_level, purpose, ocr_data, status) VALUES
(3, 'Bob Johnson', '2021003', 'Bachelor of Science in Computer Science', '3rd Year', 'Employment', '{"name": "Bob Johnson", "course": "BSCS", "year_level": "3rd Year", "purpose": "Employment"}', 'pending'),
(4, 'Alice Williams', '2021004', 'Bachelor of Science in Information Technology', '4th Year', 'Scholarship Application', '{"name": "Alice Williams", "course": "BSIT", "year_level": "4th Year", "purpose": "Scholarship Application"}', 'approved')
ON CONFLICT DO NOTHING;
