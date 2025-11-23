-- Update credential change requests table to match current implementation
-- This migration changes the table structure to support generic credential changes

-- First, drop existing table if it exists
DROP TABLE IF EXISTS credential_change_requests;

-- Create new credential change requests table with proper structure
CREATE TABLE credential_change_requests (
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_credential_requests_user_id ON credential_change_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_credential_requests_status ON credential_change_requests(status);
CREATE INDEX IF NOT EXISTS idx_credential_requests_request_type ON credential_change_requests(request_type);
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
