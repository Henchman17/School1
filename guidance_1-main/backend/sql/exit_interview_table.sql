-- Exit Interview Table for Transferring/Shifting Students
CREATE TABLE IF NOT EXISTS exit_interviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    student_name VARCHAR(255) NOT NULL,
    student_number VARCHAR(50) NOT NULL,
    interview_date DATE NOT NULL,
    grade_year_level VARCHAR(50) NOT NULL,
    present_program VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    father_name VARCHAR(255) NOT NULL,
    mother_name VARCHAR(255) NOT NULL,

    -- Reasons for Leaving (Checkboxes)
    reason_family BOOLEAN DEFAULT FALSE,
    reason_classmate BOOLEAN DEFAULT FALSE,
    reason_academic BOOLEAN DEFAULT FALSE,
    reason_financial BOOLEAN DEFAULT FALSE,
    reason_teacher BOOLEAN DEFAULT FALSE,
    reason_other TEXT,

    -- Transfer Plans
    transfer_school TEXT,
    transfer_program TEXT,

    -- Difficulties and Suggestions
    difficulties TEXT,
    suggestions TEXT,

    -- Signatures (stored as text descriptions)
    interviewee_signature TEXT,
    interviewer_signature TEXT,

    -- Consent
    consent_given BOOLEAN DEFAULT FALSE,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Foreign key constraint
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,

    -- Indexes for better performance
    INDEX idx_student_id (student_id),
    INDEX idx_interview_date (interview_date),
    INDEX idx_created_at (created_at)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_exit_interviews_student_id ON exit_interviews(student_id);
CREATE INDEX IF NOT EXISTS idx_exit_interviews_interview_date ON exit_interviews(interview_date);
CREATE INDEX IF NOT EXISTS idx_exit_interviews_created_at ON exit_interviews(created_at);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_exit_interviews_updated_at BEFORE UPDATE ON exit_interviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data (optional)
-- INSERT INTO exit_interviews (
--     student_id, student_name, student_number, interview_date,
--     grade_year_level, present_program, address, father_name, mother_name,
--     reason_family, reason_academic, difficulties, suggestions, consent_given
-- ) VALUES (
--     1, 'Juan Dela Cruz', '2021001', CURRENT_DATE,
--     '4th Year', 'Bachelor of Science in Computer Science',
--     '123 Sample Street, Sample City', 'Pedro Dela Cruz', 'Maria Dela Cruz',
--     TRUE, TRUE, 'Difficulty in balancing work and studies', 'More flexible scheduling', TRUE
-- );
