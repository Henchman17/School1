-- Exit Interviews Query for PLSP Guidance System
-- This query retrieves exit interview information with user and counselor details

-- Create exit interviews table
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

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_exit_interviews_student_id ON exit_interviews(student_id);
CREATE INDEX IF NOT EXISTS idx_exit_interviews_type ON exit_interviews(interview_type);
CREATE INDEX IF NOT EXISTS idx_exit_interviews_status ON exit_interviews(status);
CREATE INDEX IF NOT EXISTS idx_exit_interviews_date ON exit_interviews(interview_date);

-- Exit Interviews Query for PLSP Guidance System
-- This query retrieves exit interview information with user and counselor details

SELECT
    ei.id,
    ei.student_id,
    ei.student_name,
    ei.student_number,
    ei.interview_type,
    ei.interview_date,
    ei.reason_for_leaving,
    ei.satisfaction_rating,
    ei.academic_experience,
    ei.support_services_experience,
    ei.facilities_experience,
    ei.overall_improvements,
    ei.future_plans,
    ei.contact_info,
    ei.status,
    ei.admin_notes,
    ei.counselor_id,
    ei.created_at,
    ei.updated_at,
    ei.completed_at,
    u.username as student_username,
    u.first_name as student_first_name,
    u.last_name as student_last_name,
    u.email as student_email,
    cu.username as counselor_username,
    cu.first_name as counselor_first_name,
    cu.last_name as counselor_last_name
FROM exit_interviews ei
LEFT JOIN users u ON ei.student_id = u.id
LEFT JOIN users cu ON ei.counselor_id = cu.id
ORDER BY ei.created_at DESC;
