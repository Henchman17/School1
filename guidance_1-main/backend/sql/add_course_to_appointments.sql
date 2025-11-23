-- Migration script to add course column to appointments table
-- Run this script to add the course field to existing appointments tables

-- Add course column to appointments table
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS course VARCHAR(100);

-- Update existing records to have a default course value if needed
-- Uncomment the following line if you want to set a default course for existing appointments
-- UPDATE appointments SET course = 'General' WHERE course IS NULL;

-- Add index for course column for better query performance
CREATE INDEX IF NOT EXISTS idx_appointments_course ON appointments(course);

-- Verify the changes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'appointments' AND column_name = 'course';
