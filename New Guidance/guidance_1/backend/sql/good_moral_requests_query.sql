-- Good Moral Requests Query for PLSP Guidance System
-- This query retrieves good moral request information with user and counselor details

-- Create good moral requests table
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

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_student_id ON good_moral_requests(student_id);
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_status ON good_moral_requests(status);
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_created_at ON good_moral_requests(created_at);

-- Good Moral Requests Query for PLSP Guidance System
-- This query retrieves good moral request information with user and counselor details

SELECT
    gmr.id,
    gmr.student_id,
    gmr.student_name,
    gmr.student_number,
    gmr.course,
    gmr.year_level,
    gmr.purpose,
    gmr.ocr_data,
    gmr.status,
    gmr.admin_notes,
    gmr.counselor_id,
    gmr.created_at,
    gmr.updated_at,
    gmr.reviewed_at,
    gmr.reviewed_by,
    gmr.document_path,
    u.username as student_username,
    u.first_name as student_first_name,
    u.last_name as student_last_name,
    u.email as student_email,
    cu.username as counselor_username,
    cu.first_name as counselor_first_name,
    cu.last_name as counselor_last_name,
    ru.username as reviewer_username,
    ru.first_name as reviewer_first_name,
    ru.last_name as reviewer_last_name
FROM good_moral_requests gmr
LEFT JOIN users u ON gmr.student_id = u.id
LEFT JOIN users cu ON gmr.counselor_id = cu.id
LEFT JOIN users ru ON gmr.reviewed_by = ru.id
ORDER BY gmr.created_at DESC;
