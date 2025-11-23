-- Drop the grade_level constraint from users table since the column was renamed to status
ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_grade_level;
