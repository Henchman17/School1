-- Discipline Cases Table for PLSP Guidance System
-- This table stores information about student discipline cases

CREATE TABLE IF NOT EXISTS discipline_cases (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES users(id),
    student_name VARCHAR(255) NOT NULL,
    student_number VARCHAR(50) NOT NULL,
    incident_date DATE NOT NULL,
    incident_description TEXT NOT NULL,
    incident_location VARCHAR(255),
    witnesses TEXT,
    severity VARCHAR(50) NOT NULL CHECK (severity IN ('light_offenses', 'less_grave_offenses', 'grave_offenses')),
    status VARCHAR(50) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'under_investigation', 'resolved', 'closed')),
    action_taken TEXT,
    admin_notes TEXT,
    counselor_id INTEGER REFERENCES users(id),
    grade_level VARCHAR(50),
    program VARCHAR(255),
    section VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES users(id)
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_discipline_cases_status ON discipline_cases(status);
CREATE INDEX IF NOT EXISTS idx_discipline_cases_severity ON discipline_cases(severity);
CREATE INDEX IF NOT EXISTS idx_discipline_cases_counselor_id ON discipline_cases(counselor_id);
CREATE INDEX IF NOT EXISTS idx_discipline_cases_created_at ON discipline_cases(created_at);

-- Discipline Cases Query for PLSP Guidance System
-- This query retrieves discipline case information with student and counselor details

SELECT
    dc.id,
    dc.student_id,
    dc.student_name,
    dc.student_number,
    dc.incident_date,
    dc.incident_description,
    dc.incident_location,
    dc.witnesses,
    dc.action_taken,
    dc.severity,
    dc.status,
    dc.admin_notes,
    dc.counselor_id,
    dc.created_at,
    dc.updated_at,
    dc.resolved_at,
    dc.resolved_by,
    u.username as counselor,
    ru.username as resolved_by_name,
    s.grade_level as grade,
    s.program as course,
    s.section
FROM discipline_cases dc
LEFT JOIN users u ON dc.counselor_id = u.id
LEFT JOIN users ru ON dc.resolved_by = ru.id
LEFT JOIN users s ON dc.student_id = s.id
ORDER BY dc.created_at DESC;
