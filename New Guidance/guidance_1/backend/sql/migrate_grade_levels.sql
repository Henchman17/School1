-- Migration script to update grade_level values to college year levels
-- This script converts existing grade levels to college year format (1st, 2nd, etc.)
-- Only works with the users table as the single source of truth for student data

-- First, drop the existing constraint if it exists
ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_grade_level;

-- Update existing grade levels to college year format
UPDATE users
SET grade_level = CASE
    WHEN grade_level = 'Grade 12' THEN '4th'
    WHEN grade_level = 'Grade 11' THEN '3rd'
    WHEN grade_level = 'Grade 10' THEN '2nd'
    WHEN grade_level = 'Grade 9' THEN '1st'
    WHEN grade_level = '12' THEN '4th'
    WHEN grade_level = '11' THEN '3rd'
    WHEN grade_level = '10' THEN '2nd'
    WHEN grade_level = '9' THEN '1st'
    WHEN grade_level IS NULL OR grade_level = '' THEN '1st'
    -- Handle any other existing values that might not be covered
    WHEN grade_level NOT IN ('1st', '2nd', '3rd', '4th', '5th') THEN '1st'
    ELSE grade_level
END
WHERE role = 'student';

-- For non-student roles, set grade_level to NULL
UPDATE users
SET grade_level = NULL
WHERE role != 'student' AND grade_level IS NOT NULL;

-- Add a check constraint to ensure only valid college year levels are entered
ALTER TABLE users
ADD CONSTRAINT chk_grade_level
CHECK (grade_level IN ('1st', '2nd', '3rd', '4th', '5th') OR grade_level IS NULL);

-- Add comment to document the grade_level field
COMMENT ON COLUMN users.grade_level IS 'College year level: 1st, 2nd, 3rd, 4th, 5th (only for students)';

-- Verify the migration
SELECT
    role,
    grade_level,
    COUNT(*) as user_count
FROM users
GROUP BY role, grade_level
ORDER BY role, grade_level;
