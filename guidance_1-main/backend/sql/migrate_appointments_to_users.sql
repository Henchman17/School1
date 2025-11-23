-- Migration script to update appointments table to work with merged users table
-- This script fixes the foreign key references and adds missing columns

-- First, drop the existing foreign key constraint that references students table
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_student_id_fkey;

-- Update the foreign key to reference users table instead of students
ALTER TABLE appointments ADD CONSTRAINT appointments_student_id_fkey
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;

-- Add course column if it doesn't exist
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS course VARCHAR(100);

-- Add notes column if it doesn't exist (some schemas might be missing it)
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS notes TEXT;

-- Update any existing appointments to have default values for new columns
UPDATE appointments SET course = 'General' WHERE course IS NULL;
UPDATE appointments SET notes = '' WHERE notes IS NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_appointments_course ON appointments(course);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);

-- Verify the table structure
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'appointments'
ORDER BY ordinal_position;
