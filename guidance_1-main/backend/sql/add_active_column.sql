-- Add active column to form tables for activation/deactivation functionality

-- Add active column to student_cumulative_records table
ALTER TABLE student_cumulative_records
ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT TRUE;

-- Add active column to routine_interviews table
ALTER TABLE routine_interviews
ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT TRUE;

-- Add active column to good_moral_requests table
ALTER TABLE good_moral_requests
ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT TRUE;

-- Create indexes for the active columns
CREATE INDEX IF NOT EXISTS idx_scrf_active ON student_cumulative_records(active);
CREATE INDEX IF NOT EXISTS idx_routine_interviews_active ON routine_interviews(active);
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_active ON good_moral_requests(active);
