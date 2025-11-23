-- Create credential change requests table
CREATE TABLE IF NOT EXISTS credential_change_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    request_type VARCHAR(20) NOT NULL CHECK (request_type IN ('username', 'email', 'password', 'student_id')),
    current_value TEXT,
    new_value TEXT NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    reviewed_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_credential_requests_user_id ON credential_change_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_credential_requests_status ON credential_change_requests(status);
CREATE INDEX IF NOT EXISTS idx_credential_requests_created_at ON credential_change_requests(created_at);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_credential_request_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_credential_request_updated_at
    BEFORE UPDATE ON credential_change_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_credential_request_updated_at();

-- Credential Change Requests Query for PLSP Guidance System
-- This query retrieves credential change request information with user and reviewer details

SELECT
    ccr.id,
    ccr.user_id,
    ccr.request_type,
    ccr.current_value,
    ccr.new_value,
    ccr.reason,
    ccr.status,
    ccr.admin_notes,
    ccr.reviewed_by,
    ccr.created_at,
    ccr.updated_at,
    ccr.reviewed_at,
    u.username as requester_username,
    u.first_name as requester_first_name,
    u.last_name as requester_last_name,
    u.email as requester_email,
    ru.username as reviewer_username,
    ru.first_name as reviewer_first_name,
    ru.last_name as reviewer_last_name
FROM credential_change_requests ccr
LEFT JOIN users u ON ccr.user_id = u.id
LEFT JOIN users ru ON ccr.reviewed_by = ru.id
ORDER BY ccr.created_at DESC;
