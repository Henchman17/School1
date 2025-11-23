-- Migration script to merge students table into users table
-- This script transfers all student data to users table and removes the students table

-- Step 1: Add student-specific columns to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS student_id VARCHAR(50) UNIQUE,
ADD COLUMN IF NOT EXISTS first_name VARCHAR(100),
ADD COLUMN IF NOT EXISTS last_name VARCHAR(100),
ADD COLUMN IF NOT EXISTS grade_level VARCHAR(20),
ADD COLUMN IF NOT EXISTS section VARCHAR(50);

-- Step 2: Transfer data from students table to users table
UPDATE users
SET
    student_id = s.student_id,
    first_name = s.first_name,
    last_name = s.last_name,
    grade_level = s.grade_level,
    section = s.section
FROM students s
WHERE users.id = s.user_id;

-- Step 3: Update appointments table to reference users instead of students
-- First, add a new column for user_id in appointments
ALTER TABLE appointments
ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

-- Update the user_id column with the correct user_id from students
UPDATE appointments
SET user_id = s.user_id
FROM students s
WHERE appointments.student_id = s.id;

-- Step 4: Drop the old foreign key constraint and column
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_student_id_fkey;
ALTER TABLE appointments DROP COLUMN IF EXISTS student_id;

-- Step 5: Rename user_id to student_id in appointments for clarity
ALTER TABLE appointments RENAME COLUMN user_id TO student_id;

-- Step 6: Add new foreign key constraint
ALTER TABLE appointments
ADD CONSTRAINT appointments_student_id_fkey
FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 7: Drop the students table
DROP TABLE IF EXISTS students CASCADE;

-- Step 8: Update indexes
DROP INDEX IF EXISTS idx_students_user_id;
DROP INDEX IF EXISTS idx_students_student_id;
CREATE INDEX IF NOT EXISTS idx_users_student_id ON users(student_id) WHERE student_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_appointments_student_user_id ON appointments(student_id);

-- Step 9: Update the users table to make student fields nullable for non-students
-- (Already handled by ADD COLUMN without NOT NULL)

-- Verification queries
-- SELECT 'Users with student data:' as info, COUNT(*) as count FROM users WHERE student_id IS NOT NULL;
-- SELECT 'Total appointments:' as info, COUNT(*) as count FROM appointments;
-- SELECT 'Orphaned appointments:' as info, COUNT(*) as count FROM appointments WHERE student_id NOT IN (SELECT id FROM users);
