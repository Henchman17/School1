-- Add cancellation_reason column to appointments table
-- This allows counselors to provide a reason when canceling appointments

ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
ADD COLUMN IF NOT EXISTS cancelled_by INTEGER REFERENCES users(id),
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_appointments_cancelled_by ON appointments(cancelled_by);

-- Add comments for documentation
COMMENT ON COLUMN appointments.cancellation_reason IS 'Reason for cancellation if status is cancelled';
COMMENT ON COLUMN appointments.cancelled_by IS 'ID of the counselor who cancelled the appointment';
COMMENT ON COLUMN appointments.cancelled_at IS 'Timestamp when the appointment was cancelled';
