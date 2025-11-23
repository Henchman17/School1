-- Add approval column to appointments table for guidance schedule approval
-- This allows counselors to approve or reject guidance schedules

ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS approved_by INTEGER REFERENCES users(id),
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Update existing records to have 'approved' status if they are scheduled or completed
UPDATE appointments
SET approval_status = 'approved'
WHERE status IN ('scheduled', 'completed');

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_appointments_approval_status ON appointments(approval_status);
CREATE INDEX IF NOT EXISTS idx_appointments_approved_by ON appointments(approved_by);

-- Add comments for documentation
COMMENT ON COLUMN appointments.approval_status IS 'Approval status: pending, approved, rejected';
COMMENT ON COLUMN appointments.approved_by IS 'ID of the counselor who approved/rejected the appointment';
COMMENT ON COLUMN appointments.approved_at IS 'Timestamp when the appointment was approved/rejected';
COMMENT ON COLUMN appointments.rejection_reason IS 'Reason for rejection if status is rejected';
