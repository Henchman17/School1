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
