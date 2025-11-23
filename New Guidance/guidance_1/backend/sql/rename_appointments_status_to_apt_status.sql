-- Rename the status column in appointments table to apt_status to avoid confusion with user status
-- This migration renames the column and updates any related indexes and constraints

-- Rename the column
ALTER TABLE appointments RENAME COLUMN status TO apt_status;

-- Update the index name to reflect the new column name
DROP INDEX IF EXISTS idx_appointments_status;
CREATE INDEX IF NOT EXISTS idx_appointments_apt_status ON appointments(apt_status);

-- Update any comments for documentation
COMMENT ON COLUMN appointments.apt_status IS 'Appointment status: scheduled, completed, cancelled, confirmed, approved, rejected';

-- Note: This migration should be run after updating all application code that references the old column name
