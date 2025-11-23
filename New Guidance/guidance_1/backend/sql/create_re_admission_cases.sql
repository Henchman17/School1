-- Create Re-admission Cases Table
-- This table stores re-admission case requests for students

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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_status ON re_admission_cases(status);
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_created_at ON re_admission_cases(created_at);
CREATE INDEX IF NOT EXISTS idx_re_admission_cases_counselor_id ON re_admission_cases(counselor_id);

-- Insert sample data for testing
INSERT INTO re_admission_cases (student_name, student_number, reason_of_absence, notes, status) VALUES
('John Doe', '2021001', 'Financial difficulties', 'Resolved financial issues', 'pending'),
('Jane Smith', '2021002', 'Health issues', 'Health improved', 'approved')
ON CONFLICT DO NOTHING;
