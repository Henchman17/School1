-- Add admin_notes column to good_moral_requests table
ALTER TABLE good_moral_requests ADD COLUMN IF NOT EXISTS admin_notes TEXT;

-- Create index for admin_notes if needed
CREATE INDEX IF NOT EXISTS idx_good_moral_requests_admin_notes ON good_moral_requests(admin_notes);
