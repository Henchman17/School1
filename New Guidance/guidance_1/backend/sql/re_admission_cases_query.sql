-- Re-admission Cases Query for PLSP Guidance System
-- This query retrieves re-admission case information with user and counselor details

-- Create re-admission cases table
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
    reviewed_by INTEGER REFERENCES users(id),
    date DATE NOT NULL,
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_status ON re_admission_cases(status);
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_created_at ON re_admission_cases(created_at);

-- Re-admission Cases Query for PLSP Guidance System
-- This query retrieves re-admission case information with user and counselor details

SELECT
    rac.id,
    rac.student_name,
    rac.student_number,
    rac.date,
    rac.reason_of_absence,
    rac.notes,
    rac.status,
    rac.counselor_id,
    rac.created_at,
    rac.updated_at,
    rac.reviewed_at,
    rac.reviewed_by,
    cu.username as counselor_username,
    cu.first_name as counselor_first_name,
    cu.last_name as counselor_last_name,
    ru.username as reviewer_username,
    ru.first_name as reviewer_first_name,
    ru.last_name as reviewer_last_name
FROM re_admission_cases rac
LEFT JOIN users cu ON rac.counselor_id = cu.id
LEFT JOIN users ru ON rac.reviewed_by = ru.id
ORDER BY rac.created_at DESC;
